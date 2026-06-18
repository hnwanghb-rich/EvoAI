"""
知识时效·保质期中心 (FW-04) —— 列表 + 续期
只做页面管理：到期提醒、续期、归档。
降权（检索排序）单独确认后再改，本模块不动 chat.py。
"""
import logging
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text

from database import async_session
from models import User
from schemas import ApiResponse
from auth import require_admin
from routers.logs import audit_log

logger = logging.getLogger(__name__)
router = APIRouter()

# 各分类建议默认保质期（天）—— 管理员页面可手动覆盖
DEFAULT_EXPIRE_DAYS = 180  # 未设置时的兜底默认值


@router.get("/flywheel/expiry/list", response_model=ApiResponse)
async def expiry_list(
    scope: str = Query("all", regex="^(all|expired|soon|ok)$"),
    _admin: User = Depends(require_admin),
):
    """
    保质期列表
    scope: all=全部有设 expire_at 的 | expired=已过期 | soon=7天内到期 | ok=未到期
    """
    async with async_session() as db:
        now_ts = datetime.now(timezone.utc)
        soon_ts = now_ts + timedelta(days=7)

        base = """
            SELECT e.id, e.title, e.knowledge_base, e.status,
                   e.expire_at, e.last_reviewed_at,
                   e.source_person, e.version, e.updated_at
            FROM knowledge_entries e
            WHERE e.expire_at IS NOT NULL
              AND e.status NOT IN ('archived', 'rejected')
        """
        if scope == "expired":
            base += " AND e.expire_at < NOW()"
        elif scope == "soon":
            base += " AND e.expire_at >= NOW() AND e.expire_at < :soon"
        elif scope == "ok":
            base += " AND e.expire_at >= :soon"

        base += " ORDER BY e.expire_at ASC LIMIT 200"

        params = {"soon": soon_ts}
        rows = (await db.execute(text(base), params)).all()

        def _status(expire_at):
            if expire_at < now_ts:
                return "expired"
            if expire_at < soon_ts:
                return "soon"
            return "ok"

        items = []
        for r in rows:
            exp = r[4]
            items.append({
                "id": r[0],
                "title": r[1],
                "knowledge_base": str(r[2].value if hasattr(r[2], 'value') else r[2]),
                "status": r[3],
                "expire_at": exp.isoformat() if exp else None,
                "last_reviewed_at": r[5].isoformat() if r[5] else None,
                "source_person": r[6],
                "version": r[7],
                "updated_at": r[8].isoformat() if r[8] else None,
                "expiry_status": _status(exp) if exp else "ok",
                "days_left": (exp - now_ts).days if exp else None,
            })

        # 统计
        total_expired = sum(1 for x in items if x["expiry_status"] == "expired")
        total_soon = sum(1 for x in items if x["expiry_status"] == "soon")

    return ApiResponse(data={
        "items": items,
        "total": len(items),
        "total_expired": total_expired,
        "total_soon": total_soon,
    })


@router.post("/flywheel/expiry/{entry_id}/set", response_model=ApiResponse)
async def expiry_set(
    entry_id: int,
    days: int = Query(..., ge=1, le=3650),
    admin: User = Depends(require_admin),
):
    """为一条知识设置（或更新）保质期天数"""
    async with async_session() as db:
        row = (await db.execute(
            text("SELECT id, title FROM knowledge_entries WHERE id = :id"),
            {"id": entry_id},
        )).first()
        if not row:
            raise HTTPException(status_code=404, detail="知识条目不存在")

        expire_at = datetime.now(timezone.utc) + timedelta(days=days)
        await db.execute(text("""
            UPDATE knowledge_entries
            SET expire_at = :exp, last_reviewed_at = NOW(), updated_at = NOW()
            WHERE id = :id
        """), {"exp": expire_at, "id": entry_id})
        await db.commit()

    import asyncio
    asyncio.ensure_future(audit_log(
        admin.id, admin.username, "flywheel_expiry_set", "knowledge_entry", entry_id,
        f"设置保质期 {days} 天: {row[1][:80]}",
    ))
    return ApiResponse(msg=f"保质期已设置为 {days} 天")


@router.post("/flywheel/expiry/{entry_id}/renew", response_model=ApiResponse)
async def expiry_renew(
    entry_id: int,
    days: int = Query(DEFAULT_EXPIRE_DAYS, ge=1, le=3650),
    admin: User = Depends(require_admin),
):
    """续期复审：version+1，刷新 expire_at，旧版本不变"""
    async with async_session() as db:
        row = (await db.execute(
            text("SELECT id, title, version, expire_at FROM knowledge_entries WHERE id = :id"),
            {"id": entry_id},
        )).first()
        if not row:
            raise HTTPException(status_code=404, detail="知识条目不存在")

        new_expire = datetime.now(timezone.utc) + timedelta(days=days)
        new_version = (row[2] or 1) + 1
        await db.execute(text("""
            UPDATE knowledge_entries
            SET expire_at = :exp,
                last_reviewed_at = NOW(),
                version = :ver,
                updated_at = NOW()
            WHERE id = :id
        """), {"exp": new_expire, "ver": new_version, "id": entry_id})
        await db.commit()

    import asyncio
    asyncio.ensure_future(audit_log(
        admin.id, admin.username, "flywheel_expiry_renew", "knowledge_entry", entry_id,
        f"续期 {days} 天 v{new_version}: {row[1][:80]}",
    ))
    return ApiResponse(msg=f"续期成功，版本升至 v{new_version}，{days} 天后到期")


@router.post("/flywheel/expiry/{entry_id}/archive", response_model=ApiResponse)
async def expiry_archive(
    entry_id: int,
    admin: User = Depends(require_admin),
):
    """确认失效，归档知识"""
    async with async_session() as db:
        row = (await db.execute(
            text("SELECT id, title, status FROM knowledge_entries WHERE id = :id"),
            {"id": entry_id},
        )).first()
        if not row:
            raise HTTPException(status_code=404, detail="知识条目不存在")
        if row[2] == "archived":
            raise HTTPException(status_code=400, detail="已经是归档状态")

        await db.execute(text("""
            UPDATE knowledge_entries
            SET status = 'archived', updated_at = NOW()
            WHERE id = :id
        """), {"id": entry_id})
        await db.commit()

    import asyncio
    asyncio.ensure_future(audit_log(
        admin.id, admin.username, "flywheel_expiry_archive", "knowledge_entry", entry_id,
        f"归档过期知识: {row[1][:80]}",
    ))
    return ApiResponse(msg="已归档")
