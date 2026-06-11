"""阿能对话路由 —— 核心逻辑: 知识库优先 → LLM兜底 + 会话记忆"""
import asyncio
import time
import logging
import httpx
import hashlib
import base64
from collections import defaultdict
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func
from cryptography.fernet import Fernet

from database import async_session
from models import (
    User, ChatLog, LLMProvider, KnowledgeEntry,
    DailyQuestion, Department,
)
from schemas import ApiResponse
from auth import get_current_user
from retrieval import hybrid_search, CONFIDENCE_THRESHOLD
from config import LLM_ENCRYPTION_KEY

logger = logging.getLogger(__name__)
router = APIRouter()

# ============================================================
# 会话记忆（服务重启会丢失，生产可换 Redis）
# ============================================================
conversation_memory: dict[int, list[dict]] = defaultdict(list)
MAX_HISTORY = 20  # 每个用户最多保留20轮


def _add_memory(user_id: int, role: str, content: str):
    conversation_memory[user_id].append({"role": role, "content": content})
    if len(conversation_memory[user_id]) > MAX_HISTORY * 2:
        conversation_memory[user_id] = conversation_memory[user_id][-MAX_HISTORY * 2:]


def _get_memory(user_id: int) -> list[dict]:
    return conversation_memory.get(user_id, [])[-MAX_HISTORY * 2:]


def _clear_memory(user_id: int):
    conversation_memory[user_id] = []


# ============================================================
# 通用工具
# ============================================================

def _get_position_label(pos: str) -> str:
    m = {"sales": "销售顾问", "tech": "技师", "service": "客服专员"}
    return m.get(pos, pos or "员工")


def _decrypt_api_key(encrypted: str) -> str:
    if not encrypted:
        return ""
    key = LLM_ENCRYPTION_KEY.encode("utf-8")
    digest = hashlib.sha256(key).digest()
    b64_key = base64.urlsafe_b64encode(digest)
    return Fernet(b64_key).decrypt(encrypted.encode()).decode()


async def _get_default_llm():
    async with async_session() as db:
        r = await db.execute(
            select(LLMProvider).where(
                LLMProvider.is_active == True,
                LLMProvider.is_default == True,
            )
        )
        return r.scalar_one_or_none()


async def _get_system_stats() -> dict:
    """获取系统实时统计（结构化，方便注入）"""
    try:
        async with async_session() as db:
            ke = (await db.execute(
                select(func.count(KnowledgeEntry.id))
                .where(KnowledgeEntry.status == "approved")
            )).scalar() or 0
            qc = (await db.execute(
                select(func.count(DailyQuestion.id))
            )).scalar() or 0
            uc = (await db.execute(
                select(func.count(User.id)).where(User.status == 1)
            )).scalar() or 0
            return {"knowledge_total": ke, "question_total": qc, "staff_total": uc}
    except Exception:
        return {"knowledge_total": 0, "question_total": 0, "staff_total": 0}


# ============================================================
# 回答生成策略
# ============================================================

def _kb_direct_answer(contexts: list[dict], query: str) -> str:
    """知识库匹配度足够 → 直接拼接返回，不调用 LLM"""
    if not contexts:
        return ""
    parts = ["根据知识库中的相关内容，为您整理如下："]
    for i, ctx in enumerate(contexts[:3]):
        parts.append(f"\n📄 **{i+1}. {ctx['title']}**")
        parts.append(ctx['content'][:400])
    parts.append("\n\n还有什么不清楚的地方？")
    return "\n".join(parts)


async def _call_llm(
    llm, system_prompt: str, messages: list[dict],
    query: str, fallback: str,
) -> str:
    """调用大模型生成回答"""
    if not llm or not llm.api_key:
        return fallback

    api_key = _decrypt_api_key(llm.api_key)
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                f"{llm.base_url}/chat/completions",
                headers={"Authorization": f"Bearer {api_key}"},
                json={
                    "model": llm.model_name,
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        *messages[-6:],  # 最近6条历史
                        {"role": "user", "content": query},
                    ],
                    "temperature": float(llm.temperature or 0.7),
                    "max_tokens": int(llm.max_tokens or 2048),
                },
            )
            resp.raise_for_status()
            return resp.json()["choices"][0]["message"]["content"]
    except Exception as e:
        logger.warning(f"LLM调用失败: {e}")
        return fallback


# ============================================================
# 核心接口
# ============================================================

@router.get("/chat/ask")
async def chat_ask(
    question: str = Query("", max_length=2000),
    mode: str = Query("knowledge_qa", max_length=30),
    user: User = Depends(get_current_user),
):
    """
    阿能对话核心逻辑：
    1. 检索企业知识库 → 匹配度高 → 直接返回（不调LLM）
    2. 匹配度低或无匹配 → 调用通用大模型兜底
    3. 附带会话记忆上下文
    """
    if not question.strip():
        return ApiResponse(data={"answer": "请输入问题", "references": [], "is_hit": 0, "response_time_ms": 0, "source": "none"})

    start_time = time.time()
    _add_memory(user.id, "user", question)

    # ---- 1. 确定可见知识库 ----
    pos = user.position.value if user.position else "sales"
    if user.role.value in ("admin", "boss"):
        kbs = ["public", "sales", "tech", "service"]
    else:
        m = {"sales": ["public", "sales"], "tech": ["public", "tech"], "service": ["public", "service"]}
        kbs = m.get(pos, ["public"])

    # ---- 2. 检索企业知识库 ----
    contexts = await hybrid_search(question, kbs, top_k=5)

    # ---- 3. 计算置信度 ----
    top_confidence = contexts[0]["confidence"] if contexts else 0
    best_match = contexts[0] if contexts else None

    # 如果有某条结果置信度很高（≥0.4），认为是有效匹配
    is_confident = best_match and best_match.get("confidence", 0) >= 0.4

    # ---- 4. 分支决策 ----
    references = [{"title": c["title"], "id": c["id"], "confidence": c["confidence"]} for c in contexts]
    llm = await _get_default_llm()
    answer_text = ""
    source = ""

    if is_confident:
        # ====== 路径A：知识库命中，直接返回 ======
        answer_text = _kb_direct_answer(contexts, question)
        source = "knowledge_base"
        logger.info(f"知识库直接回答 | confidence={top_confidence:.4f} | title={best_match['title'][:30]}")

    else:
        # ====== 路径B：知识库无匹配/低置信度 → 调用大模型 ======
        stats = await _get_system_stats()
        stats_text = (
            f"【系统实时数据】\n"
            f"- 知识库共 {stats['knowledge_total']} 条已通过知识\n"
            f"- 题库共 {stats['question_total']} 道题目\n"
            f"- 系统共 {stats['staff_total']} 名员工\n"
        )

        dept_name = "未知"
        if user.dept_id:
            async with async_session() as db:
                dr = await db.execute(select(Department.name).where(Department.id == user.dept_id))
                d = dr.scalar_one_or_none()
                if d: dept_name = d

        context_text = "\n\n".join(
            f"【{i+1}】{c['title']}\n{c['content'][:500]}"
            for i, c in enumerate(contexts)
        ) or "（知识库中未检索到直接匹配的内容）"

        system_prompt = f"""你是合群汽车集团的数字老师"阿能"。你的任务是用简洁专业的语言回答员工问题。

当前员工：{user.real_name}，岗位：{_get_position_label(pos)}，部门：{dept_name}。

{stats_text}

以下是从知识库中检索到的相关内容：
{context_text}

回答要求：
1. 如果有相关知识，优先基于检索到的内容回答，用【1】【2】标注引用
2. 对于系统统计类问题（"有多少题""多少员工"），直接用上面给出的系统数据回答
3. 如果检索内容和系统数据都无法回答，可以用你的通用知识，但要注明"以下为通用知识回答，非企业知识库内容"
4. 简洁专业，适合一线员工理解
5. 每次回答结束后加上："还有什么不清楚的地方？" """

        memory = _get_memory(user.id)
        fallback = "抱歉，我在知识库中没有找到与您问题相关的信息。建议您联系部门主管。\n\n还有什么不清楚的地方？"

        answer_text = await _call_llm(llm, system_prompt, memory, question, fallback)
        source = "llm" if contexts else "llm_no_match"
        logger.info(f"LLM回答 | confidence={top_confidence:.4f} | source={source}")

    _add_memory(user.id, "assistant", answer_text)

    # ---- 5. 写日志 ----
    response_time_ms = int((time.time() - start_time) * 1000)
    is_hit = 1 if is_confident else 0
    try:
        async with async_session() as db:
            db.add(ChatLog(
                user_id=user.id, question=question,
                answer=answer_text[:4000], references_json=references,
                is_hit=is_hit, response_time_ms=response_time_ms,
            ))
            await db.commit()
    except Exception as e:
        logger.warning(f"对话日志写入失败: {e}")

    return ApiResponse(data={
        "answer": answer_text,
        "references": references,
        "response_time_ms": response_time_ms,
        "is_hit": is_hit,
        "source": source,
        "confidence": top_confidence if contexts else 0,
    })


@router.post("/chat/clear", response_model=ApiResponse)
async def chat_clear(user: User = Depends(get_current_user)):
    """清空当前用户的会话记忆"""
    _clear_memory(user.id)
    return ApiResponse(msg="会话已清空")


@router.post("/chat/feedback", response_model=ApiResponse)
async def chat_feedback(
    chat_id: int = Query(0),
    is_satisfied: int = Query(1, ge=0, le=1),
    user: User = Depends(get_current_user),
):
    """对话反馈（满意/不满意）"""
    if chat_id > 0:
        async with async_session() as db:
            r = await db.execute(select(ChatLog).where(ChatLog.id == chat_id))
            log = r.scalar_one_or_none()
            if log:
                log.is_satisfied = is_satisfied
                await db.commit()
    return ApiResponse(msg="感谢反馈！")


@router.get("/chat/stats", response_model=ApiResponse)
async def chat_stats(user: User = Depends(get_current_user)):
    """对话统计（管理员可查看全局）"""
    async with async_session() as db:
        total = (await db.execute(select(func.count(ChatLog.id)))).scalar() or 0
        hit = (await db.execute(
            select(func.count(ChatLog.id)).where(ChatLog.is_hit == 1)
        )).scalar() or 0
        satisfied = (await db.execute(
            select(func.count(ChatLog.id)).where(ChatLog.is_satisfied == 1)
        )).scalar() or 0
        # 最近7天热门问题 TOP5
        from datetime import datetime, timedelta
        week = datetime.utcnow() - timedelta(days=7)
        hot_r = await db.execute(
            select(ChatLog.question, func.count(ChatLog.id))
            .where(ChatLog.created_at >= week)
            .group_by(ChatLog.question)
            .order_by(func.count(ChatLog.id).desc())
            .limit(5)
        )
        hot = [{"question": r[0][:80], "count": r[1]} for r in hot_r.all()]

    return ApiResponse(data={
        "total": total,
        "hit_count": hit,
        "hit_rate": round(hit / total * 100, 1) if total > 0 else 0,
        "satisfied_count": satisfied,
        "hot_questions": hot,
    })
