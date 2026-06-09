"""阿能对话路由 —— 核心对话 + LLM + 反馈"""
import asyncio
import json
import time
import logging
import httpx
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func

from database import async_session
from models import (
    User, ChatLog, LLMProvider, KnowledgeEntry,
    DailyQuestion, ExperiencePoint, Department,
)
from schemas import ApiResponse
from auth import get_current_user
from retrieval import hybrid_search

logger = logging.getLogger(__name__)
router = APIRouter()

SYSTEM_PROMPT = """你是合群汽车集团的数字老师"阿能"。你的任务是用简洁专业的语言回答员工问题。

当前员工：{real_name}，岗位：{position}，部门：{dept}。

{stats}

以下是从知识库中检索到的相关内容：
{context}

回答要求：
1. 优先基于上面检索到的知识库内容回答，用【1】【2】标注引用
2. 对于"当前系统有多少XX"这类事实性问题，直接用上面给出的系统统计数据回答
3. 如果检索内容和统计数据都无法回答，可以基于你的通用知识回答，但要注明"以下为通用知识回答，非企业知识库内容"
4. 简洁专业，适合一线员工理解
5. 每次回答结束后加上："还有什么不清楚的地方？" """


def _get_position_label(pos: str) -> str:
    m = {"sales": "销售顾问", "tech": "技师", "service": "客服专员"}
    return m.get(pos, pos or "员工")


async def _get_default_llm():
    async with async_session() as db:
        r = await db.execute(
            select(LLMProvider).where(
                LLMProvider.is_active == True,
                LLMProvider.is_default == True,
            )
        )
        return r.scalar_one_or_none()


async def _get_system_stats() -> str:
    """获取系统实时统计信息，注入 LLM 上下文"""
    try:
        async with async_session() as db:
            ke_r = await db.execute(
                select(func.count(KnowledgeEntry.id))
                .where(KnowledgeEntry.status == "approved")
            )
            ke_count = ke_r.scalar() or 0

            q_r = await db.execute(select(func.count(DailyQuestion.id)))
            q_count = q_r.scalar() or 0

            u_r = await db.execute(
                select(func.count(User.id)).where(User.status == 1)
            )
            u_count = u_r.scalar() or 0

            return (
                f"【系统实时数据】\n"
                f"- 知识库共有 {ke_count} 条已通过的知识条目\n"
                f"- 题库共有 {q_count} 道题目\n"
                f"- 系统共有 {u_count} 名员工\n"
            )
    except Exception:
        return ""


async def _chat_fallback(query: str, contexts: list[dict]) -> str:
    if not contexts:
        return "抱歉，我在知识库中没有找到与您问题相关的信息。建议您联系部门主管或等待知识库更新。\n\n还有什么不清楚的地方？"
    parts = ["根据知识库中的相关内容，为您整理如下：\n"]
    for i, ctx in enumerate(contexts[:3]):
        parts.append(f"**{i+1}. {ctx['title']}**")
        parts.append(ctx['content'][:300])
        parts.append("")
    parts.append("\n还有什么不清楚的地方？")
    return "\n".join(parts)


@router.get("/chat/ask")
async def chat_ask(
    question: str = Query("", max_length=2000),
    mode: str = Query("knowledge_qa", max_length=30),
    user: User = Depends(get_current_user),
):
    """核心对话接口 —— 混合检索 + LLM 生成"""
    if not question.strip():
        return ApiResponse(data={"answer": "请输入问题", "references": [], "is_hit": 0, "response_time_ms": 0})

    start_time = time.time()

    # 1. 可见知识库
    pos = user.position.value if user.position else "sales"
    if user.role.value in ("admin", "boss"):
        kbs = ["public", "sales", "tech", "service"]
    else:
        m = {"sales": ["public", "sales"], "tech": ["public", "tech"], "service": ["public", "service"]}
        kbs = m.get(pos, ["public"])

    # 2. 混合检索 + 系统统计（并行）
    contexts_raw, stats_text = await asyncio.gather(
        hybrid_search(question, kbs, top_k=5),
        _get_system_stats(),
    )
    contexts = list(contexts_raw)

    # 3. 组装引用
    references = [{"title": c["title"], "id": c["id"]} for c in contexts]
    context_text = "\n\n".join(
        f"【{i+1}】{c['title']}\n{c['content'][:500]}"
        for i, c in enumerate(contexts)
    ) or "（知识库中未检索到直接匹配的内容）"

    # 4. 部门名
    dept_name = "未知"
    if user.dept_id:
        async with async_session() as db:
            dr = await db.execute(select(Department.name).where(Department.id == user.dept_id))
            d = dr.scalar_one_or_none()
            if d: dept_name = d

    prompt = SYSTEM_PROMPT.format(
        real_name=user.real_name,
        position=_get_position_label(pos),
        dept=dept_name,
        stats=stats_text or "（系统统计数据暂不可用）",
        context=context_text,
    )

    # 5. 调 LLM
    llm = await _get_default_llm()
    answer_text = ""

    if llm and llm.api_key:
        from cryptography.fernet import Fernet
        import hashlib, base64
        from config import LLM_ENCRYPTION_KEY
        key = LLM_ENCRYPTION_KEY.encode("utf-8")
        digest = hashlib.sha256(key).digest()
        b64_key = base64.urlsafe_b64encode(digest)
        api_key = Fernet(b64_key).decrypt(llm.api_key.encode()).decode()

        try:
            async with httpx.AsyncClient(timeout=30) as client:
                resp = await client.post(
                    f"{llm.base_url}/chat/completions",
                    headers={"Authorization": f"Bearer {api_key}"},
                    json={
                        "model": llm.model_name,
                        "messages": [
                            {"role": "system", "content": prompt},
                            {"role": "user", "content": question},
                        ],
                        "temperature": float(llm.temperature or 0.7),
                        "max_tokens": int(llm.max_tokens or 2048),
                    },
                )
                resp.raise_for_status()
                answer_text = resp.json()["choices"][0]["message"]["content"]
        except Exception as e:
            logger.warning(f"LLM调用失败: {e}")
            answer_text = await _chat_fallback(question, contexts)
    else:
        answer_text = await _chat_fallback(question, contexts)

    # 6. 写日志
    response_time_ms = int((time.time() - start_time) * 1000)
    is_hit = 1 if contexts else 0
    try:
        async with async_session() as db:
            db.add(ChatLog(user_id=user.id, question=question,
                answer=answer_text[:4000], references_json=references,
                is_hit=is_hit, response_time_ms=response_time_ms))
            await db.commit()
    except Exception as e:
        logger.warning(f"对话日志写入失败: {e}")

    return ApiResponse(data={
        "answer": answer_text,
        "references": references,
        "response_time_ms": response_time_ms,
        "is_hit": is_hit,
    })
