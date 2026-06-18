"""
跨线协同任务中心 (FW-08)
- 汇总所有来自客服/销售/维修/知识缺口发起的跨线整改任务
- 接收方确认/处理/关闭任务
- 管理员可查全部；staff 只看与自己业务线相关的任务
"""
import logging
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text

from database import async_session
from models import User
from schemas import ApiResponse
from auth import get_current_user, require_admin
from routers.logs import audit_log
import asyncio

logger = logging.getLogger(__name__)
router = APIRouter()

LINE_LABELS = {
    "service": "客服线",
    "sales": "销售线",
    "tech": "维修线",
    "pdi": "PDI/交车",
    "factory": "厂家/产品",
    "gap": "知识缺口",
}

STATUS_LABELS = {
    "pending": "待处理",
    "accepted": "已接收",
    "resolved": "已处理",
    "closed": "已关闭",
}


def _user_line(user: User) -> str | None:
    """根据岗位返回对应业务线，管理员返回 None（看全部）"""
    if user.role == "admin":
        return None
    pos = getattr(user, "position", "") or ""
    return {"sales": "sales", "tech": "tech", "service": "service"}.get(pos)


@router.get("/flywheel/crossline/tasks", response_model=ApiResponse)
async def crossline_task_list(
    target_line: str = Query("", max_length=20),
    status: str = Query("", max_length=20),
    current_user: User = Depends(get_current_user),
):
    """跨线任务列表。admin 看全部，staff 只看自己业务线接收的任务。"""
    async with async_session() as db:
        conds = ["1=1"]
        params: dict = {}

        user_line = _user_line(current_user)
        if user_line:
            conds.append("t.target_line = :user_line")
            params["user_line"] = user_line
        elif target_line:
            conds.append("t.target_line = :tl")
            params["tl"] = target_line

        if status:
            conds.append("t.status = :status")
            params["status"] = status

        rows = (await db.execute(text(f"""
            SELECT t.id, t.source_line, t.target_line, t.title, t.description,
                   t.status, t.priority, t.note, t.resolve_note,
                   t.created_at, t.updated_at, t.resolved_at,
                   t.source_entry_id,
                   u.real_name AS creator_name
            FROM cross_line_tasks t
            LEFT JOIN users u ON u.id = t.created_by
            WHERE {' AND '.join(conds)}
            ORDER BY t.priority DESC, t.created_at DESC
            LIMIT 100
        """), params)).all()

        items = [{
            "id": r[0],
            "source_line": r[1],
            "source_line_label": LINE_LABELS.get(r[1], r[1]),
            "target_line": r[2],
            "target_line_label": LINE_LABELS.get(r[2], r[2]),
            "title": r[3],
            "description": r[4],
            "status": r[5],
            "status_label": STATUS_LABELS.get(r[5], r[5]),
            "priority": r[6],
            "note": r[7],
            "resolve_note": r[8],
            "created_at": r[9].isoformat() if r[9] else None,
            "updated_at": r[10].isoformat() if r[10] else None,
            "resolved_at": r[11].isoformat() if r[11] else None,
            "source_entry_id": r[12],
            "creator_name": r[13],
        } for r in rows]

    return ApiResponse(data={"items": items, "total": len(items)})


@router.post("/flywheel/crossline/{task_id}/accept", response_model=ApiResponse)
async def crossline_accept(
    task_id: int,
    current_user: User = Depends(get_current_user),
):
    """接收任务：pending → accepted"""
    async with async_session() as db:
        row = (await db.execute(
            text("SELECT id, status, target_line, title FROM cross_line_tasks WHERE id = :id"),
            {"id": task_id},
        )).first()
        if not row:
            raise HTTPException(status_code=404, detail="任务不存在")
        if row[1] != "pending":
            raise HTTPException(status_code=400, detail=f"任务当前状态为「{STATUS_LABELS.get(row[1], row[1])}」，无法接收")

        await db.execute(text("""
            UPDATE cross_line_tasks
            SET status = 'accepted', updated_at = NOW()
            WHERE id = :id
        """), {"id": task_id})
        await db.commit()

    asyncio.ensure_future(audit_log(
        current_user.id, current_user.username,
        "crossline_accept", "cross_line_task", task_id,
        f"接收跨线任务: {row[3][:80]}",
    ))
    return ApiResponse(data={"task_id": task_id, "status": "accepted"}, msg="任务已接收")


@router.post("/flywheel/crossline/{task_id}/resolve", response_model=ApiResponse)
async def crossline_resolve(
    task_id: int,
    resolve_note: str = Query(..., max_length=500),
    current_user: User = Depends(get_current_user),
):
    """处理完成：accepted → resolved"""
    async with async_session() as db:
        row = (await db.execute(
            text("SELECT id, status, title FROM cross_line_tasks WHERE id = :id"),
            {"id": task_id},
        )).first()
        if not row:
            raise HTTPException(status_code=404, detail="任务不存在")
        if row[1] not in ("pending", "accepted"):
            raise HTTPException(status_code=400, detail=f"任务当前状态为「{STATUS_LABELS.get(row[1], row[1])}」，无法标记处理")

        await db.execute(text("""
            UPDATE cross_line_tasks
            SET status = 'resolved', resolve_note = :note,
                resolved_at = NOW(), updated_at = NOW()
            WHERE id = :id
        """), {"id": task_id, "note": resolve_note})
        await db.commit()

    asyncio.ensure_future(audit_log(
        current_user.id, current_user.username,
        "crossline_resolve", "cross_line_task", task_id,
        f"处理跨线任务: {row[2][:80]} | {resolve_note[:100]}",
    ))
    return ApiResponse(data={"task_id": task_id, "status": "resolved"}, msg="任务已标记处理完成")


@router.post("/flywheel/crossline/{task_id}/close", response_model=ApiResponse)
async def crossline_close(
    task_id: int,
    admin: User = Depends(require_admin),
):
    """关闭任务（发起方/管理员确认）：resolved → closed"""
    async with async_session() as db:
        row = (await db.execute(
            text("SELECT id, status, title FROM cross_line_tasks WHERE id = :id"),
            {"id": task_id},
        )).first()
        if not row:
            raise HTTPException(status_code=404, detail="任务不存在")
        if row[1] != "resolved":
            raise HTTPException(status_code=400, detail=f"任务当前状态为「{STATUS_LABELS.get(row[1], row[1])}」，需先标记处理完成才能关闭")

        await db.execute(text("""
            UPDATE cross_line_tasks
            SET status = 'closed', updated_at = NOW()
            WHERE id = :id
        """), {"id": task_id})
        await db.commit()

    asyncio.ensure_future(audit_log(
        admin.id, admin.username,
        "crossline_close", "cross_line_task", task_id,
        f"关闭跨线任务: {row[2][:80]}",
    ))
    return ApiResponse(data={"task_id": task_id, "status": "closed"}, msg="任务已关闭")
