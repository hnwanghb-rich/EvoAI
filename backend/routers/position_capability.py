"""岗位知识能力路由 —— 配置各岗位应掌握的知识分类"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, delete

from database import async_session
from models import PositionCapability, KnowledgeCategory, User
from schemas import ApiResponse
from auth import require_admin

router = APIRouter()

POSITIONS = ["sales", "tech", "service", "clerk"]


@router.get("/position-capabilities", response_model=ApiResponse)
async def get_all_capabilities(_admin: User = Depends(require_admin)):
    """获取所有岗位的知识能力配置"""
    async with async_session() as db:
        result = await db.execute(
            select(PositionCapability).order_by(PositionCapability.position)
        )
        rows = result.scalars().all()

        # 按岗位分组
        data = {}
        for pos in POSITIONS:
            data[pos] = []

        for r in rows:
            if r.position in POSITIONS:
                data[r.position].append({
                    "id": r.id,
                    "category_id": r.category_id,
                })

    return ApiResponse(data=data)


@router.put("/position-capabilities/{position}", response_model=ApiResponse)
async def save_capabilities(
    position: str,
    body: dict,
    _admin: User = Depends(require_admin),
):
    """保存某个岗位的知识能力配置（全量替换）"""
    if position not in POSITIONS:
        raise HTTPException(status_code=400, detail=f"无效岗位: {position}")

    category_ids = body.get("category_ids", [])
    if not isinstance(category_ids, list):
        raise HTTPException(status_code=400, detail="category_ids 必须是数组")

    async with async_session() as db:
        # 删除该岗位已有配置
        await db.execute(
            delete(PositionCapability).where(
                PositionCapability.position == position
            )
        )

        # 批量插入新配置
        for cid in category_ids:
            db.add(PositionCapability(
                position=position,
                category_id=int(cid),
            ))

        await db.commit()

    return ApiResponse(data={"position": position, "count": len(category_ids)}, msg="保存成功")
