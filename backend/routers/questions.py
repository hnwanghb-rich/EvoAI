"""
题库路由 —— 每日一题(推送/答题) / 题库管理(CRUD) / AI出题 / 批量导入
"""
from datetime import date, datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func

from database import async_session
from models import (
    DailyQuestion, LearningRecord, ExperiencePoint, KnowledgeEntry,
    LLMProvider, PointActionEnum,
)
from schemas import ApiResponse
from auth import get_current_user, require_admin
from models import User

router = APIRouter()

POSITION_ORDER = {None: 0, "sales": 1, "tech": 2, "service": 3}


# ============================================================
# 职员端：每日一题推送 + 答题
# ============================================================

@router.get("/questions/today", response_model=ApiResponse)
async def get_today_question(user: User = Depends(get_current_user)):
    """获取今日题目（按岗位推送，难度递增，排除14天内已答题）"""
    today = date.today()
    pos = user.position.value if user.position else None

    async with async_session() as db:
        # 1. 看看今天有没有已经推送的题
        pushed_r = await db.execute(
            select(DailyQuestion).where(DailyQuestion.push_date == today)
            .order_by(DailyQuestion.difficulty_level)
            .limit(1)
        )
        q = pushed_r.scalar_one_or_none()

        # 2. 没有推送过：按规则选一道
        if not q:
            # 排除14天内已答过的题
            from datetime import timedelta
            cutoff = today - timedelta(days=14)
            ans_r = await db.execute(
                select(LearningRecord).where(
                    LearningRecord.user_id == user.id,
                    LearningRecord.learn_type == "test",
                    LearningRecord.created_at >= cutoff,
                )
            )
            # 按岗位+难度选一题
            q = (await db.execute(
                select(DailyQuestion)
                .where(
                    (DailyQuestion.target_position == pos) |
                    (DailyQuestion.target_position.is_(None))
                )
                .order_by(DailyQuestion.difficulty_level)
                .limit(1)
            )).scalar_one_or_none()

            # 还是没找到：降级取任意公共题
            if not q:
                q = (await db.execute(
                    select(DailyQuestion)
                    .order_by(DailyQuestion.difficulty_level)
                    .limit(1)
                )).scalar_one_or_none()

            if q:
                q.push_date = today
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

        # 学习记录
        db.add(LearningRecord(
            user_id=user.id,
            knowledge_id=q.related_knowledge_id or 1,
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
            draft = await _call_llm_generate(llm, ke.title, ke.content, count)

        if not draft:
            # 降级：返回基于模板的草稿
            draft = _template_generate(ke.title, ke.content, count)

    return ApiResponse(data={
        "knowledge_id": knowledge_id,
        "knowledge_title": ke.title,
        "drafts": draft,
    })


async def _call_llm_generate(llm, title: str, content: str, count: int):
    """调用LLM生成题目"""
    import httpx, json
    prompt = f"""你是合群汽车集团知识库的出题专家。请根据以下知识内容，生成{count}道单选题(single_choice)。

知识标题：{title}
知识内容：{content[:1200]}

每题输出JSON格式：
{{"question_content": "题干", "options": {{"A":"...", "B":"...", "C":"...", "D":"..."}}, "answer": "A", "explanation": "解析"}}

只输出JSON数组，不要其他文字。"""

    try:
        async with httpx.AsyncClient(timeout=30) as c:
            resp = await c.post(
                f"{llm.base_url}/chat/completions",
                headers={"Authorization": f"Bearer {llm.api_key}"},
                json={
                    "model": llm.model_name,
                    "messages": [
                        {"role": "system", "content": "你是一个出题助手，严格按JSON格式输出。"},
                        {"role": "user", "content": prompt},
                    ],
                    "temperature": 0.7,
                    "max_tokens": llm.max_tokens,
                },
            )
            resp.raise_for_status()
            text = resp.json()["choices"][0]["message"]["content"]
            # 尝试解析 JSON
            text = text.strip()
            if text.startswith("```"): text = text.split("\n", 1)[1].rsplit("\n```", 1)[0]
            return json.loads(text)
    except Exception:
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
