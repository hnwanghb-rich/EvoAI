"""
考试路由 —— 试卷管理 / 自动手动组卷 / 职员考试入口 / 答卷判分
"""
import json
import logging
from datetime import datetime, date, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, and_, or_

from database import async_session
from models import (
    ExamPaper, ExamPaperQuestion, ExamAttempt,
    DailyQuestion, KnowledgeCategory, User,
)
from schemas import (
    ApiResponse, ExamPaperAutoGenerate, ExamPaperManualCreate,
    ExamPaperUpdate, ExamSubmit,
)
from auth import get_current_user, require_admin

logger = logging.getLogger(__name__)
router = APIRouter()


# ============================================================
# 管理员：试卷列表
# ============================================================

@router.get("/exam/papers", response_model=ApiResponse)
async def list_papers(
    status: str = Query("", max_length=20),
    _admin: User = Depends(require_admin),
):
    """试卷列表（管理员）"""
    async with async_session() as db:
        q = select(ExamPaper).order_by(ExamPaper.created_at.desc())
        if status:
            q = q.where(ExamPaper.status == status)
        result = await db.execute(q)
        papers = result.scalars().all()

        items = []
        for p in papers:
            items.append({
                "id": p.id, "title": p.title,
                "target_type": p.target_type,
                "target_value": p.target_value,
                "time_mode": p.time_mode,
                "start_time": p.start_time.isoformat() if p.start_time else None,
                "end_time": p.end_time.isoformat() if p.end_time else None,
                "duration_minutes": p.duration_minutes,
                "total_questions": p.total_questions,
                "status": p.status,
                "created_at": p.created_at.isoformat() if p.created_at else None,
            })
    return ApiResponse(data={"items": items, "total": len(items)})


# ============================================================
# 管理员：试卷详情（含试题列表）
# ============================================================

@router.get("/exam/papers/{paper_id}", response_model=ApiResponse)
async def get_paper(
    paper_id: int,
    _admin: User = Depends(require_admin),
):
    """试卷详情 + 题目列表"""
    async with async_session() as db:
        result = await db.execute(
            select(ExamPaper).where(ExamPaper.id == paper_id)
        )
        p = result.scalar_one_or_none()
        if not p:
            raise HTTPException(status_code=404, detail="试卷不存在")

        # 获取关联题目
        pq_r = await db.execute(
            select(ExamPaperQuestion, DailyQuestion)
            .join(DailyQuestion, ExamPaperQuestion.question_id == DailyQuestion.id)
            .where(ExamPaperQuestion.paper_id == paper_id)
            .order_by(ExamPaperQuestion.sort_order)
        )
        questions = []
        for epq, dq in pq_r:
            questions.append({
                "epq_id": epq.id,
                "id": dq.id,
                "question_type": dq.question_type.value if hasattr(dq.question_type, 'value') else dq.question_type,
                "question_content": dq.question_content[:200],
                "options": dq.options,
                "answer": dq.answer,
                "explanation": dq.explanation,
                "difficulty_level": dq.difficulty_level,
                "sort_order": epq.sort_order,
            })

        data = {
            "id": p.id, "title": p.title,
            "target_type": p.target_type,
            "target_value": p.target_value,
            "time_mode": p.time_mode,
            "start_time": p.start_time.isoformat() if p.start_time else None,
            "end_time": p.end_time.isoformat() if p.end_time else None,
            "duration_minutes": p.duration_minutes,
            "total_questions": p.total_questions,
            "status": p.status,
            "created_at": p.created_at.isoformat() if p.created_at else None,
            "questions": questions,
        }
    return ApiResponse(data=data)


# ============================================================
# 管理员：自动组卷
# ============================================================

@router.post("/exam/papers/auto-generate", response_model=ApiResponse)
async def auto_generate_paper(
    body: ExamPaperAutoGenerate,
    admin: User = Depends(require_admin),
):
    """自动组卷：按岗位+分类+数量随机抽题，创建试卷"""
    async with async_session() as db:
        # 构建筛选条件
        q = select(DailyQuestion)

        conditions = []
        # 按岗位筛选
        if body.target_type == "position" and body.target_value:
            conditions.append(DailyQuestion.target_position == body.target_value)
        elif body.target_type == "all":
            pass  # 不筛选岗位

        # 按知识类别筛选
        if body.category_ids:
            conditions.append(DailyQuestion.category_id.in_(body.category_ids))

        if conditions:
            q = q.where(and_(*conditions))

        # 随机抽取
        q = q.order_by(func.random()).limit(body.question_count)
        result = await db.execute(q)
        questions = result.scalars().all()

        if len(questions) == 0:
            raise HTTPException(status_code=400, detail="没有符合条件的题目，请调整筛选条件")

        # 创建试卷
        start_time = None
        end_time = None
        if body.time_mode == "scheduled":
            if body.start_time:
                start_time = datetime.fromisoformat(body.start_time.replace("Z", "+00:00"))
            if body.end_time:
                end_time = datetime.fromisoformat(body.end_time.replace("Z", "+00:00"))

        paper = ExamPaper(
            title=body.title,
            target_type=body.target_type,
            target_value=body.target_value if body.target_value else None,
            time_mode=body.time_mode,
            start_time=start_time,
            end_time=end_time,
            duration_minutes=body.duration_minutes,
            total_questions=len(questions),
            created_by=admin.id,
        )
        db.add(paper)
        await db.flush()

        # 关联题目
        for i, dq in enumerate(questions):
            db.add(ExamPaperQuestion(
                paper_id=paper.id,
                question_id=dq.id,
                sort_order=i + 1,
            ))

        await db.commit()
        await db.refresh(paper)

    return ApiResponse(data={
        "id": paper.id,
        "title": paper.title,
        "total_questions": paper.total_questions,
    }, msg=f"试卷创建成功，共 {paper.total_questions} 道题目")


# ============================================================
# 管理员：手动组卷
# ============================================================

@router.post("/exam/papers", response_model=ApiResponse)
async def create_paper_manual(
    body: ExamPaperManualCreate,
    admin: User = Depends(require_admin),
):
    """手动组卷：指定题目ID列表创建试卷"""
    if not body.question_ids:
        raise HTTPException(status_code=400, detail="请至少选择1道题目")

    async with async_session() as db:
        start_time = None
        end_time = None
        if body.time_mode == "scheduled":
            if body.start_time:
                start_time = datetime.fromisoformat(body.start_time.replace("Z", "+00:00"))
            if body.end_time:
                end_time = datetime.fromisoformat(body.end_time.replace("Z", "+00:00"))

        paper = ExamPaper(
            title=body.title,
            target_type=body.target_type,
            target_value=body.target_value if body.target_value else None,
            time_mode=body.time_mode,
            start_time=start_time,
            end_time=end_time,
            duration_minutes=body.duration_minutes,
            total_questions=len(body.question_ids),
            created_by=admin.id,
        )
        db.add(paper)
        await db.flush()

        for i, qid in enumerate(body.question_ids):
            db.add(ExamPaperQuestion(
                paper_id=paper.id,
                question_id=qid,
                sort_order=i + 1,
            ))

        await db.commit()
        await db.refresh(paper)

    return ApiResponse(data={
        "id": paper.id,
        "title": paper.title,
        "total_questions": paper.total_questions,
    }, msg=f"试卷创建成功，共 {paper.total_questions} 道题目")


# ============================================================
# 管理员：修改/删除试卷
# ============================================================

@router.put("/exam/papers/{paper_id}", response_model=ApiResponse)
async def update_paper(
    paper_id: int,
    body: ExamPaperUpdate,
    _admin: User = Depends(require_admin),
):
    """修改试卷（时间、状态）"""
    async with async_session() as db:
        result = await db.execute(
            select(ExamPaper).where(ExamPaper.id == paper_id)
        )
        p = result.scalar_one_or_none()
        if not p:
            raise HTTPException(status_code=404, detail="试卷不存在")

        if body.title is not None:
            p.title = body.title
        if body.time_mode is not None:
            p.time_mode = body.time_mode
        if body.start_time is not None:
            p.start_time = datetime.fromisoformat(body.start_time.replace("Z", "+00:00")) if body.start_time else None
        if body.end_time is not None:
            p.end_time = datetime.fromisoformat(body.end_time.replace("Z", "+00:00")) if body.end_time else None
        if body.duration_minutes is not None:
            p.duration_minutes = body.duration_minutes
        if body.status is not None:
            p.status = body.status

        await db.commit()
    return ApiResponse(msg="试卷已更新")


@router.delete("/exam/papers/{paper_id}", response_model=ApiResponse)
async def delete_paper(
    paper_id: int,
    _admin: User = Depends(require_admin),
):
    """删除试卷（级联删除关联题目和答卷）"""
    async with async_session() as db:
        result = await db.execute(
            select(ExamPaper).where(ExamPaper.id == paper_id)
        )
        p = result.scalar_one_or_none()
        if not p:
            raise HTTPException(status_code=404, detail="试卷不存在")
        await db.delete(p)
        await db.commit()
    return ApiResponse(msg="试卷已删除")


# ============================================================
# 题库查询（手动组卷用）
# ============================================================

@router.get("/exam/questions/pool", response_model=ApiResponse)
async def question_pool(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    keyword: str = Query("", max_length=200),
    question_type: str = Query("", max_length=20),
    target_position: str = Query("", max_length=20),
    difficulty: int = Query(0),
    category_id: int = Query(0),
    _admin: User = Depends(require_admin),
):
    """题库查询（手动组卷用）"""
    async with async_session() as db:
        q = select(DailyQuestion)
        cq = select(func.count(DailyQuestion.id))

        conditions = []
        if keyword:
            like = f"%{keyword}%"
            conditions.append(DailyQuestion.question_content.ilike(like))
        if question_type:
            conditions.append(DailyQuestion.question_type == question_type)
        if target_position:
            conditions.append(DailyQuestion.target_position == target_position)
        if difficulty > 0:
            conditions.append(DailyQuestion.difficulty_level == difficulty)
        if category_id > 0:
            conditions.append(DailyQuestion.category_id == category_id)

        if conditions:
            q = q.where(and_(*conditions))
            cq = cq.where(and_(*conditions))

        total = (await db.execute(cq)).scalar() or 0

        rows = (await db.execute(
            q.order_by(DailyQuestion.id.desc())
            .offset((page - 1) * page_size).limit(page_size)
        )).scalars().all()

        items = [
            {
                "id": dq.id,
                "question_type": dq.question_type.value if hasattr(dq.question_type, 'value') else dq.question_type,
                "question_content": dq.question_content[:150],
                "options": dq.options,
                "answer": dq.answer,
                "target_position": dq.target_position.value if hasattr(dq.target_position, 'value') and dq.target_position else None,
                "difficulty_level": dq.difficulty_level,
                "category_id": dq.category_id,
            }
            for dq in rows
        ]

    return ApiResponse(data={"items": items, "total": total, "page": page, "page_size": page_size})


# ============================================================
# 所有用户可查的公开试卷列表（含倒计时信息）
# ============================================================

@router.get("/exam/public-papers", response_model=ApiResponse)
async def public_papers(user: User = Depends(get_current_user)):
    """所有用户可查的公开试卷列表（不含试题详情）"""
    async with async_session() as db:
        now = datetime.now(timezone.utc)
        pos = user.position.value if user.position else ""

        result = await db.execute(
            select(ExamPaper)
            .where(ExamPaper.status == "active")
            .order_by(ExamPaper.created_at.desc())
        )
        papers = result.scalars().all()

        items = []
        for p in papers:
            # 判断该用户是否可以参加
            can_enter = True
            if p.target_type == "position" and p.target_value and p.target_value != pos:
                can_enter = False

            # 检查定时考试是否在窗口内
            in_window = True
            if p.time_mode == "scheduled":
                if p.start_time and now < p.start_time:
                    in_window = False
                if p.end_time and now > p.end_time:
                    in_window = False

            # 检查是否已提交
            att_r = await db.execute(
                select(ExamAttempt).where(
                    ExamAttempt.user_id == user.id,
                    ExamAttempt.paper_id == p.id,
                    ExamAttempt.status == "submitted",
                )
            )
            already_submitted = att_r.scalar_one_or_none() is not None

            items.append({
                "id": p.id, "title": p.title,
                "target_type": p.target_type,
                "target_value": p.target_value,
                "time_mode": p.time_mode,
                "start_time": p.start_time.isoformat() if p.start_time else None,
                "end_time": p.end_time.isoformat() if p.end_time else None,
                "duration_minutes": p.duration_minutes,
                "total_questions": p.total_questions,
                "can_enter": can_enter and in_window,
                "in_window": in_window,
                "already_submitted": already_submitted,
                "created_at": p.created_at.isoformat() if p.created_at else None,
            })

    return ApiResponse(data={"items": items, "total": len(items)})


# ============================================================
# 职员端：可参加考试列表
# ============================================================

@router.get("/exam/available", response_model=ApiResponse)
async def available_exams(user: User = Depends(get_current_user)):
    """当前用户可参加的考试"""
    async with async_session() as db:
        now = datetime.now(timezone.utc)
        pos = user.position.value if user.position else ""

        # 查询所有 active 试卷
        q = select(ExamPaper).where(ExamPaper.status == "active")

        # 按时间模式过滤
        # anytime: 始终可用
        # scheduled: 在当前时间窗口内
        q = q.where(
            or_(
                ExamPaper.time_mode == "anytime",
                and_(
                    ExamPaper.time_mode == "scheduled",
                    ExamPaper.start_time <= now,
                    ExamPaper.end_time >= now,
                )
            )
        )

        result = await db.execute(q.order_by(ExamPaper.created_at.desc()))
        papers = result.scalars().all()

        items = []
        for p in papers:
            # 判断用户是否符合目标范围
            if p.target_type == "position" and p.target_value and p.target_value != pos:
                continue
            # dept 暂不判断（可后续扩展）

            # 检查用户是否已提交过
            att_r = await db.execute(
                select(ExamAttempt).where(
                    ExamAttempt.user_id == user.id,
                    ExamAttempt.paper_id == p.id,
                    ExamAttempt.status == "submitted",
                )
            )
            already_submitted = att_r.scalar_one_or_none() is not None

            items.append({
                "id": p.id,
                "title": p.title,
                "target_type": p.target_type,
                "time_mode": p.time_mode,
                "start_time": p.start_time.isoformat() if p.start_time else None,
                "end_time": p.end_time.isoformat() if p.end_time else None,
                "duration_minutes": p.duration_minutes,
                "total_questions": p.total_questions,
                "already_submitted": already_submitted,
            })

    return ApiResponse(data={"items": items, "total": len(items)})


# ============================================================
# 职员端：开始考试
# ============================================================

@router.get("/exam/start/{paper_id}", response_model=ApiResponse)
async def start_exam(
    paper_id: int,
    user: User = Depends(get_current_user),
):
    """开始考试，返回试题列表（不含答案）"""
    async with async_session() as db:
        # 检查试卷存在且有效
        result = await db.execute(
            select(ExamPaper).where(ExamPaper.id == paper_id, ExamPaper.status == "active")
        )
        paper = result.scalar_one_or_none()
        if not paper:
            raise HTTPException(status_code=404, detail="试卷不存在或已归档")

        # 检查时间
        now = datetime.now(timezone.utc)
        if paper.time_mode == "scheduled":
            if paper.start_time and now < paper.start_time:
                raise HTTPException(status_code=400, detail="考试尚未开始")
            if paper.end_time and now > paper.end_time:
                raise HTTPException(status_code=400, detail="考试已结束")

        # 获取题目（不含答案）
        pq_r = await db.execute(
            select(ExamPaperQuestion, DailyQuestion)
            .join(DailyQuestion, ExamPaperQuestion.question_id == DailyQuestion.id)
            .where(ExamPaperQuestion.paper_id == paper_id)
            .order_by(ExamPaperQuestion.sort_order)
        )
        questions = []
        for epq, dq in pq_r:
            qtype = dq.question_type.value if hasattr(dq.question_type, 'value') else dq.question_type
            questions.append({
                "epq_id": epq.id,
                "id": dq.id,
                "question_type": qtype,
                "question_content": dq.question_content,
                "options": dq.options,
                "difficulty_level": dq.difficulty_level,
                "sort_order": epq.sort_order,
                # 不返回 answer
            })

        # 创建答题记录
        attempt = ExamAttempt(
            user_id=user.id,
            paper_id=paper_id,
            answers={},
            total_questions=len(questions),
        )
        db.add(attempt)
        await db.commit()
        await db.refresh(attempt)

    return ApiResponse(data={
        "attempt_id": attempt.id,
        "paper_id": paper.id,
        "title": paper.title,
        "duration_minutes": paper.duration_minutes,
        "total_questions": len(questions),
        "questions": questions,
        "started_at": attempt.started_at.isoformat() if attempt.started_at else None,
    })


# ============================================================
# 职员端：提交答卷
# ============================================================

@router.post("/exam/submit/{paper_id}", response_model=ApiResponse)
async def submit_exam(
    paper_id: int,
    body: ExamSubmit,
    user: User = Depends(get_current_user),
):
    """提交答卷 → 判分 → 保存记录"""
    async with async_session() as db:
        # 查找进行中的答卷
        result = await db.execute(
            select(ExamAttempt).where(
                ExamAttempt.user_id == user.id,
                ExamAttempt.paper_id == paper_id,
                ExamAttempt.status == "started",
            ).order_by(ExamAttempt.started_at.desc())
        )
        attempt = result.scalars().first()
        if not attempt:
            raise HTTPException(status_code=400, detail="没有进行中的考试")

        # 获取正确答案
        pq_r = await db.execute(
            select(ExamPaperQuestion, DailyQuestion)
            .join(DailyQuestion, ExamPaperQuestion.question_id == DailyQuestion.id)
            .where(ExamPaperQuestion.paper_id == paper_id)
        )
        correct_answers = {}
        for epq, dq in pq_r:
            correct_answers[str(dq.id)] = dq.answer.strip().lower()

        # 判分
        correct_count = 0
        user_answers = body.answers
        for qid_str, user_ans in user_answers.items():
            if qid_str in correct_answers:
                if str(user_ans).strip().lower() == correct_answers[qid_str]:
                    correct_count += 1

        total = len(correct_answers)
        score = round(correct_count / total * 100) if total > 0 else 0

        # 保存
        attempt.answers = body.answers
        attempt.score = score
        attempt.correct_count = correct_count
        attempt.total_questions = total
        attempt.submitted_at = datetime.now(timezone.utc)
        attempt.status = "submitted"
        await db.commit()

    return ApiResponse(data={
        "attempt_id": attempt.id,
        "score": score,
        "correct_count": correct_count,
        "total_questions": total,
    }, msg=f"考试完成！得分 {score} 分（{correct_count}/{total}）")


# ============================================================
# 职员端：答卷历史
# ============================================================

@router.get("/exam/history", response_model=ApiResponse)
async def exam_history(user: User = Depends(get_current_user)):
    """当前用户的答卷历史"""
    async with async_session() as db:
        result = await db.execute(
            select(ExamAttempt)
            .where(ExamAttempt.user_id == user.id)
            .order_by(ExamAttempt.submitted_at.desc().nullslast())
            .limit(50)
        )
        attempts = result.scalars().all()

        items = []
        for a in attempts:
            # 获取试卷标题
            paper_r = await db.execute(
                select(ExamPaper.title).where(ExamPaper.id == a.paper_id)
            )
            paper_title = paper_r.scalar_one_or_none() or "已删除的试卷"

            items.append({
                "id": a.id,
                "paper_id": a.paper_id,
                "paper_title": paper_title,
                "score": a.score,
                "correct_count": a.correct_count,
                "total_questions": a.total_questions,
                "status": a.status,
                "started_at": a.started_at.isoformat() if a.started_at else None,
                "submitted_at": a.submitted_at.isoformat() if a.submitted_at else None,
            })

    return ApiResponse(data={"items": items, "total": len(items)})


# ============================================================
# 职员端：答卷详情
# ============================================================

@router.get("/exam/attempt/{attempt_id}", response_model=ApiResponse)
async def attempt_detail(
    attempt_id: int,
    user: User = Depends(get_current_user),
):
    """查看答卷详情（含对错）"""
    async with async_session() as db:
        result = await db.execute(
            select(ExamAttempt).where(
                ExamAttempt.id == attempt_id,
                ExamAttempt.user_id == user.id,
            )
        )
        a = result.scalar_one_or_none()
        if not a:
            raise HTTPException(status_code=404, detail="答卷不存在")

        # 获取试卷题目含答案
        pq_r = await db.execute(
            select(ExamPaperQuestion, DailyQuestion)
            .join(DailyQuestion, ExamPaperQuestion.question_id == DailyQuestion.id)
            .where(ExamPaperQuestion.paper_id == a.paper_id)
            .order_by(ExamPaperQuestion.sort_order)
        )

        questions = []
        user_answers = a.answers if a.answers else {}
        for epq, dq in pq_r:
            qid_str = str(dq.id)
            user_ans = user_answers.get(qid_str, "")
            correct_ans = dq.answer
            qtype = dq.question_type.value if hasattr(dq.question_type, 'value') else dq.question_type
            is_correct = str(user_ans).strip().lower() == correct_ans.strip().lower()

            questions.append({
                "id": dq.id,
                "question_type": qtype,
                "question_content": dq.question_content,
                "options": dq.options,
                "answer": correct_ans,  # 返回正确答案
                "explanation": dq.explanation,
                "user_answer": user_ans,
                "is_correct": is_correct,
            })

    return ApiResponse(data={
        "id": a.id,
        "paper_id": a.paper_id,
        "score": a.score,
        "correct_count": a.correct_count,
        "total_questions": a.total_questions,
        "submitted_at": a.submitted_at.isoformat() if a.submitted_at else None,
        "questions": questions,
    })
