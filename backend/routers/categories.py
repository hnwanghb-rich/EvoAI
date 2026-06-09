"""分类路由 —— 分类树(缓存1h) / 单个分类"""
from fastapi import APIRouter, HTTPException
from sqlalchemy import select

from database import async_session
from models import KnowledgeCategory
from schemas import ApiResponse
from cache import cache_get, cache_set

router = APIRouter()
CAT_CACHE_KEY = "categories:all"
CAT_CACHE_TTL = 3600


@router.get("/categories", response_model=ApiResponse)
async def list_categories():
    """获取全部分类（缓存1小时）"""
    cached = await cache_get(CAT_CACHE_KEY)
    if cached:
        return ApiResponse(data=cached)

    async with async_session() as db:
        result = await db.execute(
            select(KnowledgeCategory).order_by(
                KnowledgeCategory.knowledge_base,
                KnowledgeCategory.sort_order,
            )
        )
        rows = result.scalars().all()
        items = [
            {"id": c.id, "name": c.name, "parent_id": c.parent_id,
             "knowledge_base": c.knowledge_base.value,
             "sort_order": c.sort_order, "icon": c.icon}
            for c in rows
        ]
    await cache_set(CAT_CACHE_KEY, items, CAT_CACHE_TTL)
    return ApiResponse(data=items)


@router.get("/categories/{cat_id}", response_model=ApiResponse)
async def get_category(cat_id: int):
    """获取单个分类详情"""
    async with async_session() as db:
        result = await db.execute(
            select(KnowledgeCategory).where(KnowledgeCategory.id == cat_id)
        )
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="分类不存在")
        data = {
            "id": cat.id, "name": cat.name, "parent_id": cat.parent_id,
            "knowledge_base": cat.knowledge_base.value,
            "sort_order": cat.sort_order, "icon": cat.icon,
        }
    return ApiResponse(data=data)
