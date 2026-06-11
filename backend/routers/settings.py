"""
系统设置路由 —— 积分规则 / 飞轮阈值 / 分类标签管理
"""
import logging
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func

from database import async_session
from models import SystemConfig, KnowledgeCategory
from schemas import ApiResponse
from auth import require_admin
from models import User

logger = logging.getLogger(__name__)
router = APIRouter()

DEFAULT_KEYS = {
    "points_submit": "提交经验积分", "points_approved": "审核通过积分",
    "points_useful": "被标记有用积分", "points_monthly_top5": "月度TOP5积分",
    "points_daily_question": "每次一题答对积分", "points_complete_course": "完成课程积分",
    "flywheel_view_threshold": "低效经验浏览阈值(次)", "flywheel_month_threshold": "知识更新周期(月)",
    "flywheel_effective_month": "有效经验有用率阈值", "flywheel_dead_month": "待优化经验有用率阈值",
}


@router.get("/settings", response_model=ApiResponse)
async def get_settings(_admin: User = Depends(require_admin)):
    """获取全部系统配置"""
    async with async_session() as db:
        result = await db.execute(select(SystemConfig).order_by(SystemConfig.config_key))
        rows = result.scalars().all()
        items = {
            r.config_key: {
                "value": r.config_value, "type": r.config_type,
                "description": r.description or DEFAULT_KEYS.get(r.config_key, ""),
                "id": r.id, "updated_at": r.updated_at.isoformat() if r.updated_at else None,
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
    async with async_session() as db:
        result = await db.execute(select(SystemConfig).where(SystemConfig.config_key == config_key))
        cfg = result.scalar_one_or_none()
        if cfg: cfg.config_value = config_value
        else: db.add(SystemConfig(config_key=config_key, config_value=config_value, config_type="string"))
        await db.commit()
    return ApiResponse(msg="配置已更新")


# ============================================================
# 知识分类标签管理
# ============================================================

@router.get("/settings/categories", response_model=ApiResponse)
async def list_categories():
    """获取全部分类标签（管理员+职员均可）"""
    async with async_session() as db:
        rows = (await db.execute(
            select(KnowledgeCategory).order_by(KnowledgeCategory.knowledge_base, KnowledgeCategory.sort_order)
        )).scalars().all()
        items = [{
            "id": c.id, "name": c.name, "knowledge_base": c.knowledge_base.value,
            "sort_order": c.sort_order, "icon": c.icon, "parent_id": c.parent_id,
            "knowledge_count": await _count_by_category(db, c.id, "knowledge"),
            "question_count": await _count_by_category(db, c.id, "question"),
        } for c in rows]
    return ApiResponse(data=items)


@router.post("/settings/categories", response_model=ApiResponse)
async def create_category(
    name: str = Query(..., max_length=50),
    knowledge_base: str = Query("public", max_length=20),
    icon: str = Query("📄", max_length=10),
    sort_order: int = Query(0),
    _admin: User = Depends(require_admin),
):
    async with async_session() as db:
        c = KnowledgeCategory(name=name, knowledge_base=knowledge_base, icon=icon, sort_order=sort_order)
        db.add(c); await db.commit(); await db.refresh(c)
    return ApiResponse(data={"id": c.id}, msg="分类已创建")


@router.put("/settings/categories/{cat_id}", response_model=ApiResponse)
async def update_category(
    cat_id: int,
    name: str = Query(None, max_length=50),
    knowledge_base: str = Query(None, max_length=20),
    icon: str = Query(None, max_length=10),
    sort_order: int = Query(None),
    _admin: User = Depends(require_admin),
):
    async with async_session() as db:
        c = (await db.execute(select(KnowledgeCategory).where(KnowledgeCategory.id == cat_id))).scalar_one_or_none()
        if not c: raise HTTPException(status_code=404, detail="分类不存在")
        if name is not None: c.name = name
        if knowledge_base is not None: c.knowledge_base = knowledge_base
        if icon is not None: c.icon = icon
        if sort_order is not None: c.sort_order = sort_order
        await db.commit()
    return ApiResponse(msg="分类已更新")


@router.delete("/settings/categories/{cat_id}", response_model=ApiResponse)
async def delete_category(cat_id: int, _admin: User = Depends(require_admin)):
    async with async_session() as db:
        c = (await db.execute(select(KnowledgeCategory).where(KnowledgeCategory.id == cat_id))).scalar_one_or_none()
        if not c: raise HTTPException(status_code=404, detail="分类不存在")
        await db.delete(c); await db.commit()
    return ApiResponse(msg="分类已删除")


async def _count_by_category(db, cat_id: int, item_type: str) -> int:
    if item_type == "question":
        from models import DailyQuestion
        r = await db.execute(select(func.count(DailyQuestion.id)).where(DailyQuestion.category_id == cat_id))
    else:
        from models import KnowledgeEntry
        r = await db.execute(select(func.count(KnowledgeEntry.id)).where(
            KnowledgeEntry.category_id == cat_id, KnowledgeEntry.status == "approved"))
    return r.scalar() or 0
