"""
学习记录路由 —— 记录学习行为 / 查询学习历史
"""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, extract

from database import async_session
from models import LearningRecord, KnowledgeEntry
from schemas import ApiResponse
from auth import get_current_user
from models import User

router = APIRouter()


@router.post("/learning/record", response_model=ApiResponse)
async def record_learning(
    knowledge_id: int = Query(...),
    learn_type: str = Query("view", max_length=20),
    duration_sec: int = Query(0),
    score: float = Query(0),
    user: User = Depends(get_current_user),
):
    """记录学习行为（浏览/完成/测试）"""
    async with async_session() as db:
        # 校验知识存在
        ke = await db.execute(
            select(KnowledgeEntry.id).where(KnowledgeEntry.id == knowledge_id)
        )
        if not ke.scalar_one_or_none():
            raise HTTPException(status_code=404, detail="知识不存在")

        rec = LearningRecord(
            user_id=user.id,
            knowledge_id=knowledge_id,
            learn_type=learn_type,
            duration_sec=duration_sec,
            score=score,
            created_at=datetime.utcnow(),
        )
        db.add(rec)
        await db.commit()
        await db.refresh(rec)
    return ApiResponse(data={"id": rec.id}, msg="学习记录已保存")


@router.get("/learning/history", response_model=ApiResponse)
async def learning_history(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=50),
    user: User = Depends(get_current_user),
):
    """学习历史（最近N条，带知识标题）"""
    async with async_session() as db:
        total_r = await db.execute(
            select(func.count(LearningRecord.id)).where(LearningRecord.user_id == user.id)
        )
        total = total_r.scalar() or 0

        rows_r = await db.execute(
            select(
                LearningRecord.id,
                LearningRecord.knowledge_id,
                LearningRecord.learn_type,
                LearningRecord.duration_sec,
                LearningRecord.score,
                LearningRecord.created_at,
                KnowledgeEntry.title,
            )
            .join(KnowledgeEntry, KnowledgeEntry.id == LearningRecord.knowledge_id, isouter=True)
            .where(LearningRecord.user_id == user.id)
            .order_by(LearningRecord.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        items = [
            {
                "id": r[0], "knowledge_id": r[1], "learn_type": r[2],
                "duration_sec": r[3], "score": float(r[4]) if r[4] else 0,
                "created_at": r[5].isoformat() if r[5] else None,
                "knowledge_title": r[6] or "",
            }
            for r in rows_r.all()
        ]
    return ApiResponse(data={"items": items, "total": total, "page": page, "page_size": page_size})
