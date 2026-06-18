"""
知识缺口飞轮路由 (FW-01) —— 候选缺口聚合 / 指派建单 / 关闭
- 候选缺口：实时从 chat_logs(is_hit=0) 按问题文本聚合，排除已建单(assigned)
- 懒持久化：仅"指派"时写入 knowledge_gaps
- 不修改 chat.py / chat_logs，沿用现有未命中精确文本聚类口径
"""
import logging
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, text

from database import async_session
from models import User, KnowledgeCategory
from schemas import ApiResponse
from auth import require_admin
from routers.logs import audit_log

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/flywheel/gap/list", response_model=ApiResponse)
async def gap_list(_admin: User = Depends(require_admin)):
    """缺口工作台数据：候选缺口(未建单) + 已建单缺口"""
    async with async_session() as db:
        # 已建单(assigned)的问题文本集合，用于从候选中排除
        assigned_rows = (await db.execute(
            text("SELECT question FROM knowledge_gaps WHERE status = 'assigned'")
        )).all()
        assigned_questions = {r[0] for r in assigned_rows}

        # 候选缺口：chat_logs is_hit=0 按问题文本聚合
        cand_sql = text("""
            SELECT cl.question,
                   COUNT(*)            AS hit_count,
                   MAX(cl.created_at)  AS last_at,
                   MIN(cl.created_at)  AS first_at,
                   MAX(u.position)     AS position
            FROM chat_logs cl
            LEFT JOIN users u ON u.id = cl.user_id
            WHERE cl.is_hit = 0
            GROUP BY cl.question
            ORDER BY COUNT(*) DESC, MAX(cl.created_at) DESC
        """)
        cand_rows = (await db.execute(cand_sql)).all()
        candidates = []
        for r in cand_rows:
            q = r[0]
            if q in assigned_questions:
                continue  # 已建单的不再作为候选
            candidates.append({
                "question": q,
                "hit_count": r[1],
                "last_at": r[2].isoformat() if r[2] else None,
                "first_at": r[3].isoformat() if r[3] else None,
                "position": r[4] or "",
            })

        # 已建单缺口列表（关联指派人 / 建议分类名称）
        gaps_sql = text("""
            SELECT g.id, g.question, g.hit_count, g.target_kb,
                   g.suggest_category_id, kc.name AS category_name,
                   g.status, g.assignee_id, u.real_name AS assignee_name,
                   g.related_knowledge_id, g.created_at, g.closed_at
            FROM knowledge_gaps g
            LEFT JOIN knowledge_categories kc ON kc.id = g.suggest_category_id
            LEFT JOIN users u ON u.id = g.assignee_id
            ORDER BY (g.status = 'assigned') DESC, g.created_at DESC
        """)
        gap_rows = (await db.execute(gaps_sql)).all()
        gaps = [{
            "id": r[0], "question": r[1], "hit_count": r[2], "target_kb": r[3],
            "suggest_category_id": r[4], "category_name": r[5],
            "status": r[6], "assignee_id": r[7], "assignee_name": r[8],
            "related_knowledge_id": r[9],
            "created_at": r[10].isoformat() if r[10] else None,
            "closed_at": r[11].isoformat() if r[11] else None,
        } for r in gap_rows]

    return ApiResponse(data={"candidates": candidates, "gaps": gaps})


@router.get("/flywheel/gap/options", response_model=ApiResponse)
async def gap_options(_admin: User = Depends(require_admin)):
    """指派下拉数据：可指派用户 + 知识分类"""
    async with async_session() as db:
        users_r = await db.execute(
            select(User.id, User.real_name, User.position)
            .where(User.status == 1)
            .order_by(User.real_name)
        )
        users = [{"id": r[0], "real_name": r[1], "position": r[2] or ""} for r in users_r.all()]

        cats_r = await db.execute(
            select(KnowledgeCategory.id, KnowledgeCategory.name, KnowledgeCategory.knowledge_base)
            .where(KnowledgeCategory.is_active == True)
            .order_by(KnowledgeCategory.knowledge_base, KnowledgeCategory.sort_order)
        )
        categories = [{
            "id": r[0], "name": r[1],
            "knowledge_base": r[2].value if r[2] else "",
        } for r in cats_r.all()]

    return ApiResponse(data={"users": users, "categories": categories})


@router.post("/flywheel/gap/assign", response_model=ApiResponse)
async def gap_assign(
    question: str = Query(..., max_length=2000),
    assignee_id: int = Query(..., ge=1),
    target_kb: str = Query("", max_length=20),
    suggest_category_id: int = Query(0),
    admin: User = Depends(require_admin),
):
    """指派建单（懒持久化）：从候选缺口生成 knowledge_gaps 工单"""
    q = question.strip()
    if not q:
        raise HTTPException(status_code=400, detail="问题不能为空")

    async with async_session() as db:
        # 防重复：同一问题已有 assigned 工单则拒绝
        dup = (await db.execute(
            text("SELECT id FROM knowledge_gaps WHERE question = :q AND status = 'assigned'"),
            {"q": q},
        )).scalar()
        if dup:
            raise HTTPException(status_code=400, detail="该问题已有进行中的缺口工单")

        # 校验指派人存在
        assignee = (await db.execute(
            select(User.id).where(User.id == assignee_id, User.status == 1)
        )).scalar()
        if not assignee:
            raise HTTPException(status_code=404, detail="指派人不存在或已停用")

        # 建单时快照"被问次数"
        hit_count = (await db.execute(
            text("SELECT COUNT(*) FROM chat_logs WHERE question = :q AND is_hit = 0"),
            {"q": q},
        )).scalar() or 0

        cat_id = suggest_category_id if suggest_category_id > 0 else None
        ins = text("""
            INSERT INTO knowledge_gaps
                (question, hit_count, target_kb, suggest_category_id,
                 status, assignee_id, created_by, created_at)
            VALUES (:q, :hc, :kb, :cat, 'assigned', :aid, :cb, :ts)
            RETURNING id
        """)
        gap_id = (await db.execute(ins, {
            "q": q, "hc": hit_count, "kb": target_kb or None, "cat": cat_id,
            "aid": assignee_id, "cb": admin.id, "ts": datetime.utcnow(),
        })).scalar()
        await db.commit()

    import asyncio
    asyncio.ensure_future(audit_log(
        admin.id, admin.username, "flywheel_gap_assign", "knowledge_gap", gap_id,
        f"指派知识缺口: {q[:100]}",
    ))
    return ApiResponse(data={"id": gap_id}, msg="缺口已指派")


@router.post("/flywheel/gap/{gap_id}/close", response_model=ApiResponse)
async def gap_close(
    gap_id: int,
    related_knowledge_id: int = Query(0),
    admin: User = Depends(require_admin),
):
    """关闭缺口：status → closed，可关联补充的知识条目"""
    async with async_session() as db:
        row = (await db.execute(
            text("SELECT status, question FROM knowledge_gaps WHERE id = :id"),
            {"id": gap_id},
        )).first()
        if not row:
            raise HTTPException(status_code=404, detail="缺口工单不存在")
        if row[0] == "closed":
            raise HTTPException(status_code=400, detail="该缺口已关闭")

        rel = related_knowledge_id if related_knowledge_id > 0 else None
        await db.execute(text("""
            UPDATE knowledge_gaps
            SET status = 'closed', related_knowledge_id = :rel, closed_at = :ts
            WHERE id = :id
        """), {"rel": rel, "ts": datetime.utcnow(), "id": gap_id})
        await db.commit()
        question = row[1]

    import asyncio
    asyncio.ensure_future(audit_log(
        admin.id, admin.username, "flywheel_gap_close", "knowledge_gap", gap_id,
        f"关闭知识缺口: {question[:100]}",
    ))
    return ApiResponse(msg="缺口已关闭")
