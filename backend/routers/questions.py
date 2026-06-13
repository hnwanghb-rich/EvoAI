"""
题库路由 —— 每日一题(推送/答题) / 题库管理(CRUD) / AI出题 / 批量导入
"""
import json
import logging
from datetime import date, datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, or_

from database import async_session
from models import (
    DailyQuestion, LearningRecord, ExperiencePoint, KnowledgeEntry,
    LLMProvider, PointActionEnum, PositionCapability, KnowledgeCategory,
)
from schemas import ApiResponse, BatchAIQuestionRequest, BatchQuestionImport
from auth import get_current_user, require_admin
from models import User

logger = logging.getLogger(__name__)
router = APIRouter()

POSITION_ORDER = {None: 0, "sales": 1, "tech": 2, "service": 3}


# ============================================================
# 职员端：每次一题推送 + 答题
# ============================================================

@router.get("/questions/today", response_model=ApiResponse)
async def get_today_question(user: User = Depends(get_current_user)):
    """
    每日一题：从用户岗位对应的知识分类试题中选出，排除最近轮过的题目
    """
    pos = user.position.value if user.position else None

    async with async_session() as db:
        # 1. 从 position_capabilities 获取该岗位对应的知识分类
        pos_cat_ids = []
        pos_kb = set()
        if pos:
            pc_r = await db.execute(
                select(PositionCapability.category_id).where(
                    PositionCapability.position == pos,
                )
            )
            pos_cat_ids = [r[0] for r in pc_r.all()]

            # 获取这些分类所属的知识库（用于 target_position 匹配）
            if pos_cat_ids:
                kb_r = await db.execute(
                    select(func.distinct(KnowledgeCategory.knowledge_base)).where(
                        KnowledgeCategory.id.in_(pos_cat_ids),
                    )
                )
                for r in kb_r:
                    pos_kb.add(r[0])

        # 2. 查找已答过的题目和14天内已推送的题目
        answered_ids = set()
        answered_r = await db.execute(
            select(LearningRecord.knowledge_id).where(
                LearningRecord.user_id == user.id,
                LearningRecord.learn_type == "test",
            )
        )
        # 通过 related_knowledge_id 反向找已答的 daily_question
        for row in answered_r:
            dq_r = await db.execute(
                select(DailyQuestion.id).where(
                    DailyQuestion.related_knowledge_id == row[0]
                )
            )
            for dq in dq_r:
                answered_ids.add(dq[0])

        cutoff = date.today() - timedelta(days=14)
        used_ids_r = await db.execute(
            select(DailyQuestion.id).where(
                DailyQuestion.push_date >= cutoff,
            )
        )
        used_ids = answered_ids | set(r[0] for r in used_ids_r.all())

        # 3. 按岗位知识分类筛选（category_id 优先，target_position 作为兼容）
        def where_clause(q):
            conditions = []
            if pos_cat_ids:
                # 优选：category_id 在岗位配置分类中
                conditions.append(DailyQuestion.category_id.in_(pos_cat_ids))
            if pos_kb:
                # 兼容：target_position 匹配岗位知识库
                kb_values = [kb for kb in pos_kb if kb in ("public", "sales", "tech", "service")]
                if kb_values:
                    conditions.append(DailyQuestion.target_position.in_(kb_values))
                if "public" in pos_kb:
                    conditions.append(DailyQuestion.target_position.is_(None))
            if conditions:
                q = q.where(or_(*conditions))
            return q

        base_q = select(DailyQuestion)
        if used_ids:
            base_q = where_clause(base_q).where(~DailyQuestion.id.in_(used_ids))
        else:
            base_q = where_clause(base_q)

        q = (await db.execute(
            base_q.order_by(DailyQuestion.difficulty_level).limit(1)
        )).scalar_one_or_none()

        # 4. 岗位题已轮完 → 重置，重新取第一道
        if not q and pos_cat_ids:
            q = (await db.execute(
                where_clause(select(DailyQuestion))
                .order_by(DailyQuestion.difficulty_level)
                .limit(1)
            )).scalar_one_or_none()

        # 5. 兜底：取题库任意一题
        if not q:
            q = (await db.execute(
                select(DailyQuestion).order_by(DailyQuestion.difficulty_level).limit(1)
            )).scalar_one_or_none()

        if q:
            q.push_date = date.today()
            await db.commit()
            await db.refresh(q)

        if not q:
            return ApiResponse(data=None, msg="暂无题目")

        data = {
            "id": q.id,
            "question_type": q.question_type.value,
            "question_content": q.question_content,
            "options": q.options,
            "difficulty_level": q.difficulty_level,
            "push_date": q.push_date.isoformat() if q.push_date else None,
        }
    return ApiResponse(data=data)


@router.post("/questions/{qid}/answer", response_model=ApiResponse)
async def answer_question(
    qid: int,
    user_answer: str = Query(..., max_length=500),
    user: User = Depends(get_current_user),
):
    """答题：判断对错，写入 learning_records，答对+1积分"""
    async with async_session() as db:
        result = await db.execute(
            select(DailyQuestion).where(DailyQuestion.id == qid)
        )
        q = result.scalar_one_or_none()
        if not q:
            raise HTTPException(status_code=404, detail="题目不存在")

        is_correct = user_answer.strip().lower() == q.answer.strip().lower()
        score = 100 if is_correct else 0

        # 学习记录：优先用 related_knowledge_id，否则按 category_id 查找知识条目
        kid = q.related_knowledge_id
        if not kid and q.category_id:
            entry_r = await db.execute(
                select(KnowledgeEntry.id).where(
                    KnowledgeEntry.category_id == q.category_id,
                    KnowledgeEntry.status == "approved",
                ).limit(1)
            )
            kid_row = entry_r.scalar_one_or_none()
            kid = kid_row or None
        # 兜底1：按题目的 target_position 匹配知识库（如 sales→销售知识库）
        if not kid and q.target_position:
            kb = q.target_position.value
            fallback_r = await db.execute(
                select(KnowledgeEntry.id).where(
                    KnowledgeEntry.status == "approved",
                    KnowledgeEntry.knowledge_base == kb,
                ).limit(1)
            )
            fbr = fallback_r.scalar_one_or_none()
            kid = fbr or None
        # 兜底2：找任意一条已批准的知识条目
        if not kid:
            fallback_r = await db.execute(
                select(KnowledgeEntry.id).where(
                    KnowledgeEntry.status == "approved",
                ).limit(1)
            )
            fbr = fallback_r.scalar_one_or_none()
            kid = fbr or None
        if kid:
            db.add(LearningRecord(
                user_id=user.id,
                knowledge_id=kid,
                learn_type="test",
                score=score,
            ))

        # 答对+1积分
        if is_correct:
            db.add(ExperiencePoint(
                user_id=user.id,
                points=1,
                action_type=PointActionEnum.submit,
            ))

        await db.commit()

    return ApiResponse(data={
        "correct": is_correct,
        "answer": q.answer,
        "explanation": q.explanation,
        "score": score,
    }, msg="回答正确！+1积分" if is_correct else "回答错误，已加入错题本")


@router.get("/questions/history", response_model=ApiResponse)
async def answer_history(user: User = Depends(get_current_user)):
    """答题历史（最近30条）"""
    async with async_session() as db:
        rows_r = await db.execute(
            select(LearningRecord)
            .where(LearningRecord.user_id == user.id, LearningRecord.learn_type == "test")
            .order_by(LearningRecord.created_at.desc())
            .limit(30)
        )
        items = [
            {
                "id": r.id, "knowledge_id": r.knowledge_id,
                "score": float(r.score) if r.score else 0,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in rows_r.scalars().all()
        ]
    return ApiResponse(data=items)


# ============================================================
# 管理员端：题库管理 CRUD
# ============================================================

@router.get("/questions/list", response_model=ApiResponse)
async def list_questions(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    position: str = Query("", max_length=20),
    difficulty: int = Query(0),
    question_type: str = Query("", max_length=20),
    keyword: str = Query("", max_length=200),
    category_id: int = Query(0),
    _admin: User = Depends(require_admin),
):
    """题库管理列表"""
    async with async_session() as db:
        q = select(DailyQuestion)
        cq = select(func.count(DailyQuestion.id))

        if position:
            q = q.where(DailyQuestion.target_position == position)
            cq = cq.where(DailyQuestion.target_position == position)
        if difficulty > 0:
            q = q.where(DailyQuestion.difficulty_level == difficulty)
            cq = cq.where(DailyQuestion.difficulty_level == difficulty)
        if question_type:
            q = q.where(DailyQuestion.question_type == question_type)
            cq = cq.where(DailyQuestion.question_type == question_type)
        if category_id > 0:
            q = q.where(DailyQuestion.category_id == category_id)
            cq = cq.where(DailyQuestion.category_id == category_id)
        if keyword:
            like = f"%{keyword}%"
            q = q.where(DailyQuestion.question_content.ilike(like))
            cq = cq.where(DailyQuestion.question_content.ilike(like))

        total = (await db.execute(cq)).scalar() or 0
        rows = (await db.execute(
            q.order_by(DailyQuestion.id.desc())
            .offset((page - 1) * page_size).limit(page_size)
        )).scalars().all()

        items = [
            {
                "id": dq.id,
                "question_type": dq.question_type.value,
                "question_content": dq.question_content[:120],
                "options": dq.options,
                "answer": dq.answer,
                "explanation": dq.explanation,
                "target_position": dq.target_position.value if dq.target_position else None,
                "difficulty_level": dq.difficulty_level,
                "related_knowledge_id": dq.related_knowledge_id,
                "created_at": dq.created_at.isoformat() if dq.created_at else None,
            }
            for dq in rows
        ]
    return ApiResponse(data={"items": items, "total": total, "page": page, "page_size": page_size})


@router.post("/questions", response_model=ApiResponse)
async def create_question(
    question_type: str = Query("single_choice", max_length=20),
    question_content: str = Query(..., max_length=2000),
    answer: str = Query(..., max_length=500),
    options_json: str = Query("{}", max_length=2000),
    explanation: str = Query("", max_length=2000),
    target_position: str = Query("", max_length=20),
    difficulty_level: int = Query(1, ge=1, le=5),
    related_knowledge_id: int = Query(0),
    _admin: User = Depends(require_admin),
):
    """新增题目"""
    import json
    opts = json.loads(options_json) if options_json else None
    async with async_session() as db:
        dq = DailyQuestion(
            question_type=question_type,
            question_content=question_content,
            options=opts,
            answer=answer,
            explanation=explanation,
            target_position=target_position if target_position else None,
            difficulty_level=difficulty_level,
            related_knowledge_id=related_knowledge_id if related_knowledge_id > 0 else None,
        )
        db.add(dq)
        await db.commit()
        await db.refresh(dq)
    return ApiResponse(data={"id": dq.id}, msg="题目创建成功")


@router.put("/questions/{qid}", response_model=ApiResponse)
async def update_question(
    qid: int,
    question_content: str = Query(None, max_length=2000),
    answer: str = Query(None, max_length=500),
    options_json: str = Query(None, max_length=2000),
    explanation: str = Query(None, max_length=2000),
    target_position: str = Query(None, max_length=20),
    difficulty_level: int = Query(None, ge=1, le=5),
    _admin: User = Depends(require_admin),
):
    """修改题目"""
    import json
    async with async_session() as db:
        dq = (await db.execute(select(DailyQuestion).where(DailyQuestion.id == qid))).scalar_one_or_none()
        if not dq:
            raise HTTPException(status_code=404, detail="题目不存在")
        if question_content is not None: dq.question_content = question_content
        if answer is not None: dq.answer = answer
        if options_json is not None: dq.options = json.loads(options_json) if options_json.strip() else None
        if explanation is not None: dq.explanation = explanation
        if target_position is not None: dq.target_position = target_position if target_position else None
        if difficulty_level is not None: dq.difficulty_level = difficulty_level
        await db.commit()
    return ApiResponse(msg="题目已更新")


@router.put("/questions/{qid}/status", response_model=ApiResponse)
async def toggle_question_status(
    qid: int,
    _admin: User = Depends(require_admin),
):
    """作废/恢复题目（简化：直接删除记录）"""
    async with async_session() as db:
        dq = (await db.execute(select(DailyQuestion).where(DailyQuestion.id == qid))).scalar_one_or_none()
        if not dq:
            raise HTTPException(status_code=404, detail="题目不存在")
        await db.delete(dq)
        await db.commit()
    return ApiResponse(msg="题目已移除")


@router.get("/questions/stats", response_model=ApiResponse)
async def question_stats(_admin: User = Depends(require_admin)):
    """题库健康度统计"""
    async with async_session() as db:
        total_r = await db.execute(select(func.count(DailyQuestion.id)))
        total = total_r.scalar() or 0

        by_pos_r = await db.execute(
            select(DailyQuestion.target_position, func.count(DailyQuestion.id))
            .group_by(DailyQuestion.target_position)
        )
        by_position = [{"position": r[0] or "public", "count": r[1]} for r in by_pos_r.all()]

        avg_diff_r = await db.execute(
            select(func.avg(DailyQuestion.difficulty_level))
        )
        avg_difficulty = round(float(avg_diff_r.scalar() or 0), 1)

        # 近期新增（近7天）
        from datetime import timedelta
        recent = datetime.utcnow() - timedelta(days=7)
        recent_r = await db.execute(
            select(func.count(DailyQuestion.id)).where(DailyQuestion.created_at >= recent)
        )
        recent_new = recent_r.scalar() or 0

    return ApiResponse(data={
        "total": total,
        "by_position": by_position,
        "avg_difficulty": avg_difficulty,
        "recent_new": recent_new,
    })


@router.post("/questions/ai-generate", response_model=ApiResponse)
async def ai_generate(
    knowledge_id: int = Query(...),
    count: int = Query(3, ge=1, le=5),
    _admin: User = Depends(require_admin),
):
    """
    AI自动出题：选中知识条目 → 调用默认LLM生成题目草稿 → 返回草稿列表(不入库)
    管理员确认后通过 POST /api/questions 逐一入库
    """
    async with async_session() as db:
        ke = (await db.execute(
            select(KnowledgeEntry).where(KnowledgeEntry.id == knowledge_id)
        )).scalar_one_or_none()
        if not ke:
            raise HTTPException(status_code=404, detail="知识条目不存在")

        # 尝试调用 LLM
        llm_r = await db.execute(
            select(LLMProvider).where(
                LLMProvider.is_active == True,
                LLMProvider.is_default == True,
            )
        )
        llm = llm_r.scalar_one_or_none()

        draft = None
        if llm and llm.api_key:
            draft = await _call_llm_batch_generate(llm, ke.title + "\n" + ke.content, "")

        if not draft:
            # 降级：返回基于模板的草稿
            draft = _template_generate(ke.title, ke.content, count)

    return ApiResponse(data={
        "knowledge_id": knowledge_id,
        "knowledge_title": ke.title,
        "drafts": draft,
    })


@router.post("/questions/batch-ai-generate", response_model=ApiResponse)
async def batch_ai_generate(
    body: BatchAIQuestionRequest,
    _admin: User = Depends(require_admin),
):
    """
    AI批量出题：POST body JSON: {"content_text":"大段文本...","target_position":"sales","count":0}
    count=0 表示由AI根据内容自行判断出题数量。
    LLM分析大段文本内容 → 拆解知识点 → 生成多道题目 → 直接入库
    """
    content_text = body.content_text
    target_position = body.target_position
    if not content_text.strip():
        raise HTTPException(status_code=400, detail="请输入文本内容")

    async with async_session() as db:
        llm_r = await db.execute(
            select(LLMProvider).where(
                LLMProvider.is_active == True,
                LLMProvider.is_default == True,
            )
        )
        llm = llm_r.scalar_one_or_none()

        generated = []
        if llm and llm.api_key:
            generated = await _call_llm_batch_generate(llm, content_text, target_position)

        if not generated:
            return ApiResponse(
                code=400,
                data={"drafts": []},
                msg="LLM未配置或生成失败，请检查LLM模型设置"
            )

        # 返回草稿，不直接入库（等待人工复核）
        return ApiResponse(data={
            "drafts": generated,
            "count": len(generated),
        }, msg=f"AI 已生成 {len(generated)} 道题目草稿，请人工复核后确认入库")


@router.post("/questions/batch-import", response_model=ApiResponse)
async def batch_import_questions(
    body: BatchQuestionImport,
    _admin: User = Depends(require_admin),
):
    """人工复核确认 → 批量写入题库"""
    questions = body.questions
    if not questions:
        raise HTTPException(status_code=400, detail="没有要入库的题目")

    async with async_session() as db:
        inserted = 0
        for q in questions:
            try:
                qtype = q.get("question_type", "single_choice")
                if qtype not in ("single_choice", "multi_choice", "true_false", "fill_blank"):
                    qtype = "single_choice"
                dq = DailyQuestion(
                    question_type=qtype,
                    question_content=str(q.get("question_content", ""))[:2000],
                    options=q.get("options"),
                    answer=str(q.get("answer", "A"))[:500],
                    explanation=str(q.get("explanation", ""))[:2000],
                    target_position=q.get("target_position") or None,
                    difficulty_level=int(q.get("difficulty_level") or 2),
                    related_knowledge_id=q.get("related_knowledge_id") or None,
                    category_id=q.get("category_id") or None,
                )
                db.add(dq)
                inserted += 1
            except Exception as e:
                logger.warning(f"题目入库失败: {e}")
        await db.commit()

    return ApiResponse(data={"inserted": inserted}, msg=f"已入库 {inserted} 道题目")


async def _call_llm_batch_generate(llm, content_text: str, target_position: str) -> list:
    """调用LLM对大段文本分析拆解，批量出题"""
    import httpx
    from cryptography.fernet import Fernet
    import hashlib, base64
    from config import LLM_ENCRYPTION_KEY

    pos_label = {"sales": "销售", "tech": "技术", "service": "客服"}.get(target_position, "通用")

    prompt = f"""你是合群汽车集团知识库的出题专家。请仔细阅读以下文档内容，根据内容实际含有的知识点数量，拆分出1-3道题目即可。内容少、知识点单一的只出1题；内容较丰富的出2-3题。严禁为了凑数生成重复、浅显或无意义的题目。

目标岗位：{pos_label}
文档内容：
{content_text[:8000]}

请生成一个JSON数组，每道题格式如下：
{{
  "question_type": "single_choice",
  "question_content": "题目题干",
  "options": {{"A": "选项A", "B": "选项B", "C": "选项C", "D": "选项D"}},
  "answer": "A",
  "explanation": "答案解析说明",
  "difficulty_level": 2
}}

要求：
1. 题目覆盖文档中的重要知识点，不重复
2. 选项要有干扰性，不能太明显
3. 难度1-5，根据知识点复杂度合理分配
4. 只输出JSON数组，不要其他任何文字"""

    key = LLM_ENCRYPTION_KEY.encode("utf-8")
    digest = hashlib.sha256(key).digest()
    b64_key = base64.urlsafe_b64encode(digest)
    api_key = Fernet(b64_key).decrypt(llm.api_key.encode()).decode()

    try:
        async with httpx.AsyncClient(timeout=60) as c:
            resp = await c.post(
                f"{llm.base_url}/chat/completions",
                headers={"Authorization": f"Bearer {api_key}"},
                json={
                    "model": llm.model_name,
                    "messages": [
                        {"role": "system", "content": "你是一个专业的出题助手，只输出JSON数组，不要任何额外文字。"},
                        {"role": "user", "content": prompt},
                    ],
                    "temperature": 0.8,
                    "max_tokens": 8192,
                },
            )
            resp.raise_for_status()
            text = resp.json()["choices"][0]["message"]["content"]
            text = text.strip()
            if text.startswith("```"): text = text.split("\n", 1)[1].rsplit("\n```", 1)[0]
            if text.startswith("```json"): text = text.split("\n", 1)[1].rsplit("\n```", 1)[0]
            return json.loads(text)
    except Exception as e:
        logger.warning(f"LLM批量出题失败: {e}")
        return None


def _template_generate(title: str, content: str, count: int) -> list:
    """基于模板的简易出题（无LLM时备用）"""
    drafts = []
    for i in range(count):
        drafts.append({
            "question_content": f"关于[{title}]，以下说法正确的是？",
            "options": {
                "A": f"{title}的核心要点之一是提升客户满意度",
                "B": f"{title}主要适用于高级技师岗位",
                "C": f"{title}与客户服务完全无关",
                "D": f"{title}不适用于合群汽车集团",
            },
            "answer": "A",
            "explanation": f"请参考知识[{title}]的详细内容，确认正确选项。此为AI草稿，请人工核实。",
            "_draft": True,
        })
    return drafts
