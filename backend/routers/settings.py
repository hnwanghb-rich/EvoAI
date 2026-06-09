"""
系统设置路由 —— 积分规则 / 飞轮阈值 / 自动提醒
"""
import logging
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, text

from database import async_session
from models import SystemConfig
from schemas import ApiResponse
from auth import require_admin
from models import User

logger = logging.getLogger(__name__)
router = APIRouter()

# 默认配置项 + 描述
DEFAULT_KEYS = {
    "points_submit": "提交经验积分",
    "points_approved": "审核通过积分",
    "points_useful": "被标记有用积分",
    "points_monthly_top5": "月度TOP5积分",
    "points_daily_question": "每日一题答对积分",
    "points_complete_course": "完成课程积分",
    "flywheel_view_threshold": "低效经验浏览阈值(次)",
    "flywheel_month_threshold": "知识更新周期(月)",
    "flywheel_effective_month": "有效经验有用率阈值",
    "flywheel_dead_month": "待优化经验有用率阈值",
}


@router.get("/settings", response_model=ApiResponse)
async def get_settings(_admin: User = Depends(require_admin)):
    """获取全部系统配置"""
    async with async_session() as db:
        result = await db.execute(
            select(SystemConfig).order_by(SystemConfig.config_key)
        )
        rows = result.scalars().all()
        items = {
            r.config_key: {
                "value": r.config_value,
                "type": r.config_type,
                "description": r.description or DEFAULT_KEYS.get(r.config_key, ""),
                "id": r.id,
                "updated_at": r.updated_at.isoformat() if r.updated_at else None,
            }
            for r in rows
        }
    return ApiResponse(data=items)


@router.put("/settings", response_model=ApiResponse)
async def update_settings(
    config_key: str = Query(..., max_length=100),
    config_value: str = Query(..., max_length=500),
    _admin: User = Depends(require_admin),
):
    """更新单个系统配置"""
    async with async_session() as db:
        result = await db.execute(
            select(SystemConfig).where(SystemConfig.config_key == config_key)
        )
        cfg = result.scalar_one_or_none()
        if cfg:
            cfg.config_value = config_value
        else:
            db.add(SystemConfig(config_key=config_key, config_value=config_value, config_type="string"))
        await db.commit()
    return ApiResponse(msg="配置已更新")


@router.put("/settings/batch", response_model=ApiResponse)
async def batch_update_settings(
    _admin: User = Depends(require_admin),
):
    """批量更新（从 POST body 解析 JSON 对象）"""
    # 实现略——前端用单个 PUT 逐项更新即可
    return ApiResponse(msg="OK")
