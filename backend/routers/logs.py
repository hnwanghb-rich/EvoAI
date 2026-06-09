"""
审计日志路由 —— 列表查询 / 业务埋点工具函数
"""
import logging
from datetime import datetime
from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy import select, func, text

from database import async_session
from models import User
from schemas import ApiResponse
from auth import require_admin

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/logs/audit", response_model=ApiResponse)
async def list_audit_logs(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    action: str = Query("", max_length=50),
    user_id: int = Query(0),
    keyword: str = Query("", max_length=200),
    _admin: User = Depends(require_admin),
):
    """审计日志列表（分页/筛选）"""
    async with async_session() as db:
        where_clauses = []
        cond_params = {}

        if action:
            where_clauses.append("action = :action")
            cond_params["action"] = action
        if user_id > 0:
            where_clauses.append("user_id = :uid")
            cond_params["uid"] = user_id
        if keyword:
            where_clauses.append("(username ILIKE :kw OR detail ILIKE :kw)")
            cond_params["kw"] = f"%{keyword}%"

        where_sql = "WHERE " + " AND ".join(where_clauses) if where_clauses else ""

        # 总数（copy params 避免污染）
        total_params = dict(cond_params)
        count_sql = text(f"SELECT COUNT(*) FROM audit_logs {where_sql}")
        total = (await db.execute(count_sql, total_params)).scalar() or 0

        # 列表
        offset = (page - 1) * page_size
        list_params = dict(cond_params)
        list_params["lim"] = page_size
        list_params["off"] = offset
        list_sql = text(f"""
            SELECT id, user_id, username, action, target_type, target_id,
                   detail, ip_address, created_at
            FROM audit_logs
            {where_sql}
            ORDER BY created_at DESC
            LIMIT :lim OFFSET :off
        """)
        rows = (await db.execute(list_sql, list_params)).all()

        items = [
            {
                "id": r[0], "user_id": r[1], "username": r[2],
                "action": r[3], "target_type": r[4], "target_id": r[5],
                "detail": r[6], "ip_address": r[7],
                "created_at": r[8].isoformat() if r[8] else None,
            }
            for r in rows
        ]
    return ApiResponse(data={"items": items, "total": total, "page": page, "page_size": page_size})


# ============================================================
# 业务埋点工具（其他路由中异步调用）
# ============================================================

async def audit_log(
    user_id: int | None,
    username: str | None,
    action: str,
    target_type: str = "",
    target_id: int = 0,
    detail: str = "",
    ip_address: str = "127.0.0.1",
):
    """异步写入审计日志（DB + 文件）"""
    # 1. 文件日志
    try:
        audit_logger = logging.getLogger("audit")
        audit_logger.info(
            f"user={username}(id={user_id}) | action={action} | "
            f"target={target_type}#{target_id} | detail={detail[:200]} | ip={ip_address}"
        )
    except Exception:
        pass

    # 2. 数据库日志
    try:
        async with async_session() as db:
            sql = text("""
                INSERT INTO audit_logs (user_id, username, action, target_type, target_id, detail, ip_address, created_at)
                VALUES (:uid, :uname, :action, :ttype, :tid, :detail, :ip, :ts)
            """)
            await db.execute(sql, {
                "uid": user_id,
                "uname": username or "",
                "action": action,
                "ttype": target_type,
                "tid": target_id,
                "detail": detail[:500] if detail else "",
                "ip": ip_address or "127.0.0.1",
                "ts": datetime.utcnow(),
            })
            await db.commit()
    except Exception as e:
        logger.warning(f"审计日志写入失败: {e}")
