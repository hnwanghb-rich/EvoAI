"""分类路由 —— 分类树(缓存1h) + CRUD + 树形统计"""
from fastapi import APIRouter, HTTPException
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload

from database import async_session
from models import KnowledgeCategory, KnowledgeEntry, DailyQuestion
from schemas import ApiResponse, CategoryCreate, CategoryUpdate
from cache import cache_get, cache_set, cache_delete

router = APIRouter()
CAT_CACHE_KEY = "categories:all"
CAT_TREE_CACHE_KEY = "categories:tree"
CAT_CACHE_TTL = 3600


async def clear_cat_cache():
    """清除分类相关缓存"""
    await cache_delete(CAT_CACHE_KEY)
    await cache_delete(CAT_TREE_CACHE_KEY)


@router.get("/categories", response_model=ApiResponse)
async def list_categories():
    """获取全部分类（缓存1小时，仅活跃分类）"""
    cached = await cache_get(CAT_CACHE_KEY)
    if cached:
        return ApiResponse(data=cached)

    async with async_session() as db:
        result = await db.execute(
            select(KnowledgeCategory)
            .where(KnowledgeCategory.is_active == True)
            .order_by(
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


@router.get("/categories/tree", response_model=ApiResponse)
async def get_category_tree():
    """获取分类树（含统计信息）"""
    cached = await cache_get(CAT_TREE_CACHE_KEY)
    if cached:
        return ApiResponse(data=cached)

    async with async_session() as db:
        # 获取所有分类
        result = await db.execute(
            select(KnowledgeCategory).order_by(
                KnowledgeCategory.knowledge_base,
                KnowledgeCategory.sort_order,
            )
        )
        cats = result.scalars().all()

        # 批量统计：每个分类的知识数和试题数
        cat_ids = [c.id for c in cats]

        # 知识条目统计
        ke_counts = {}
        if cat_ids:
            ke_result = await db.execute(
                select(
                    KnowledgeEntry.category_id,
                    func.count(KnowledgeEntry.id).label("cnt")
                )
                .where(KnowledgeEntry.category_id.in_(cat_ids))
                .group_by(KnowledgeEntry.category_id)
            )
            for row in ke_result:
                ke_counts[row[0]] = row[1]

        # 试题统计
        dq_counts = {}
        if cat_ids:
            dq_result = await db.execute(
                select(
                    DailyQuestion.category_id,
                    func.count(DailyQuestion.id).label("cnt")
                )
                .where(DailyQuestion.category_id.in_(cat_ids))
                .group_by(DailyQuestion.category_id)
            )
            for row in dq_result:
                dq_counts[row[0]] = row[1]

        items = [
            {
                "id": c.id, "name": c.name, "parent_id": c.parent_id,
                "knowledge_base": c.knowledge_base.value,
                "sort_order": c.sort_order, "icon": c.icon,
                "description": c.description, "is_active": c.is_active,
                "knowledge_count": ke_counts.get(c.id, 0),
                "question_count": dq_counts.get(c.id, 0),
            }
            for c in cats
        ]

    data = {"items": items}
    await cache_set(CAT_TREE_CACHE_KEY, data, CAT_CACHE_TTL)
    return ApiResponse(data=data)


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
            "description": cat.description, "is_active": cat.is_active,
        }
    return ApiResponse(data=data)


@router.post("/categories", response_model=ApiResponse)
async def create_category(data: CategoryCreate):
    """创建新分类"""
    name = data.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="分类名称不能为空")

    if data.knowledge_base not in ("public", "sales", "tech", "service"):
        raise HTTPException(status_code=400, detail="knowledge_base 无效")

    async with async_session() as db:
        cat = KnowledgeCategory(
            name=name,
            parent_id=data.parent_id,
            knowledge_base=data.knowledge_base,
            icon=data.icon,
            sort_order=data.sort_order,
        )
        db.add(cat)
        await db.commit()
        await db.refresh(cat)
        new_id = cat.id

    await clear_cat_cache()
    return ApiResponse(data={"id": new_id, "name": cat.name})


@router.put("/categories/{cat_id}", response_model=ApiResponse)
async def update_category(cat_id: int, data: CategoryUpdate):
    """修改分类"""
    async with async_session() as db:
        result = await db.execute(
            select(KnowledgeCategory).where(KnowledgeCategory.id == cat_id)
        )
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="分类不存在")

        if data.name is not None and data.name.strip():
            cat.name = data.name.strip()
        if data.icon is not None:
            cat.icon = data.icon if data.icon else None
        if data.sort_order is not None:
            cat.sort_order = data.sort_order
        if data.knowledge_base is not None and data.knowledge_base in ("public", "sales", "tech", "service"):
            cat.knowledge_base = data.knowledge_base
        if data.parent_id is not None:
            cat.parent_id = data.parent_id if data.parent_id else None

        await db.commit()

    await clear_cat_cache()
    return ApiResponse(data={"id": cat_id})


@router.delete("/categories/{cat_id}", response_model=ApiResponse)
async def delete_category(cat_id: int):
    """删除分类：有引用时停用，无引用时物理删除"""
    async with async_session() as db:
        result = await db.execute(
            select(KnowledgeCategory).where(KnowledgeCategory.id == cat_id)
        )
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="分类不存在")

        # 检查是否有知识条目引用
        ke_count = await db.execute(
            select(func.count(KnowledgeEntry.id)).where(
                KnowledgeEntry.category_id == cat_id
            )
        )
        # 检查是否有试题引用
        dq_count = await db.execute(
            select(func.count(DailyQuestion.id)).where(
                DailyQuestion.category_id == cat_id
            )
        )

        ke_n = ke_count.scalar() or 0
        dq_n = dq_count.scalar() or 0

        if ke_n > 0 or dq_n > 0:
            # 有引用 → 停用
            cat.is_active = False
            await db.commit()
            await clear_cat_cache()
            return ApiResponse(
                code=1,
                msg=f"该分类下有 {ke_n} 条知识、{dq_n} 道试题，已停用（不可物理删除）",
                data={"deleted": False, "disabled": True, "knowledge_count": ke_n, "question_count": dq_n}
            )
        else:
            # 无引用 → 物理删除
            await db.delete(cat)
            await db.commit()
            await clear_cat_cache()
            return ApiResponse(data={"deleted": True, "disabled": False})
