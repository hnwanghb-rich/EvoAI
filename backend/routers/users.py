"""
用户路由 —— 登录 / 当前用户 / 皮肤 / 用户管理
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, or_
from passlib.context import CryptContext

from database import async_session
from models import User, SkinPreference, ExperiencePoint, Department
from schemas import (
    LoginRequest, UserCreate, UserUpdate, SkinUpdate, ApiResponse,
)
from auth import create_access_token, get_current_user, require_admin
from routers.logs import audit_log

router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ============================================================
# 登录
# ============================================================

@router.post("/auth/login", response_model=ApiResponse)
async def login(body: LoginRequest):
    """用户登录，返回 JWT + 皮肤ID"""
    async with async_session() as db:
        result = await db.execute(
            select(User).where(User.username == body.username)
        )
        user = result.scalar_one_or_none()
        if not user or not pwd_context.verify(body.password, user.password_hash):
            raise HTTPException(status_code=401, detail="用户名或密码错误")
        if user.status != 1:
            raise HTTPException(status_code=403, detail="账号已被停用")

        skin_id = 1
        skin_result = await db.execute(
            select(SkinPreference.skin_id).where(SkinPreference.user_id == user.id)
        )
        row = skin_result.scalar_one_or_none()
        if row:
            skin_id = row

        token = create_access_token({
            "user_id": user.id,
            "role": user.role.value,
            "position": user.position.value if user.position else None,
        })

        # 审计日志
        import asyncio
        asyncio.ensure_future(audit_log(
            user.id, user.username, "login", "user", user.id,
            f"{user.real_name} 登录系统",
        ))

        return ApiResponse(data={
            "token": token,
            "user_id": user.id,
            "username": user.username,
            "real_name": user.real_name,
            "role": user.role.value,
            "position": user.position.value if user.position else None,
            "skin_id": skin_id,
        })


@router.get("/auth/me", response_model=ApiResponse)
async def get_me(user: User = Depends(get_current_user)):
    """获取当前登录用户信息"""
    return ApiResponse(data={
        "id": user.id,
        "username": user.username,
        "real_name": user.real_name,
        "role": user.role.value,
        "position": user.position.value if user.position else None,
        "dept_id": user.dept_id,
        "store_id": user.store_id,
        "phone": user.phone,
        "avatar_url": user.avatar_url,
        "status": user.status,
        "created_at": user.created_at.isoformat() if user.created_at else None,
    })


@router.put("/auth/skin", response_model=ApiResponse)
async def save_skin(body: SkinUpdate, user: User = Depends(get_current_user)):
    """保存皮肤选择"""
    async with async_session() as db:
        result = await db.execute(
            select(SkinPreference).where(SkinPreference.user_id == user.id)
        )
        pref = result.scalar_one_or_none()
        if pref:
            pref.skin_id = body.skin_id
        else:
            db.add(SkinPreference(user_id=user.id, skin_id=body.skin_id))
        await db.commit()
    return ApiResponse(msg="皮肤已保存")


# ============================================================
# 用户管理（管理员）
# ============================================================

@router.get("/users/list", response_model=ApiResponse)
async def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    keyword: str = Query("", max_length=100),
    role: str = Query("", max_length=20),
    position: str = Query("", max_length=20),
    _admin: User = Depends(require_admin),
):
    """管理员：用户列表（分页）"""
    async with async_session() as db:
        q = select(User)
        count_q = select(func.count(User.id))
        if keyword:
            like = f"%{keyword}%"
            q = q.where(or_(User.username.ilike(like), User.real_name.ilike(like)))
            count_q = count_q.where(or_(User.username.ilike(like), User.real_name.ilike(like)))
        if role:
            q = q.where(User.role == role)
            count_q = count_q.where(User.role == role)
        if position:
            q = q.where(User.position == position)
            count_q = count_q.where(User.position == position)

        total = (await db.execute(count_q)).scalar() or 0
        rows = (await db.execute(
            q.order_by(User.id).offset((page - 1) * page_size).limit(page_size)
        )).scalars().all()

        items = [
            {
                "id": u.id, "username": u.username, "real_name": u.real_name,
                "role": u.role.value, "position": u.position.value if u.position else None,
                "dept_id": u.dept_id, "store_id": u.store_id,
                "phone": u.phone, "status": u.status,
                "created_at": u.created_at.isoformat() if u.created_at else None,
            }
            for u in rows
        ]
        return ApiResponse(data={"items": items, "total": total, "page": page, "page_size": page_size})


@router.post("/users", response_model=ApiResponse)
async def create_user(body: UserCreate, _admin: User = Depends(require_admin)):
    """管理员：新建用户"""
    async with async_session() as db:
        exist = (await db.execute(
            select(func.count(User.id)).where(User.username == body.username)
        )).scalar()
        if exist:
            raise HTTPException(status_code=400, detail="用户名已存在")

        u = User(
            username=body.username,
            real_name=body.real_name,
            password_hash=pwd_context.hash(body.password),
            role=body.role,
            position=body.position if body.position else None,
            dept_id=body.dept_id,
            store_id=body.store_id,
            phone=body.phone,
        )
        db.add(u)
        await db.commit()
        await db.refresh(u)
        db.add(SkinPreference(user_id=u.id, skin_id=1))
        await db.commit()
    # 审计
    import asyncio
    asyncio.ensure_future(audit_log(
        _admin.id, _admin.username, "create_user", "user", u.id,
        f"创建用户 {body.username}({body.real_name})",
    ))
    return ApiResponse(data={"id": u.id}, msg="用户创建成功")


@router.put("/users/{user_id}", response_model=ApiResponse)
async def update_user(user_id: int, body: UserUpdate, _admin: User = Depends(require_admin)):
    """管理员：编辑用户"""
    async with async_session() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        u = result.scalar_one_or_none()
        if not u:
            raise HTTPException(status_code=404, detail="用户不存在")

        if body.real_name is not None:
            u.real_name = body.real_name
        if body.password is not None:
            u.password_hash = pwd_context.hash(body.password)
        if body.role is not None:
            u.role = body.role
        if body.position is not None:
            u.position = body.position
        if body.dept_id is not None:
            u.dept_id = body.dept_id
        if body.store_id is not None:
            u.store_id = body.store_id
        if body.phone is not None:
            u.phone = body.phone
        if body.avatar_url is not None:
            u.avatar_url = body.avatar_url
        await db.commit()
    return ApiResponse(msg="用户信息已更新")


@router.put("/users/{user_id}/status", response_model=ApiResponse)
async def toggle_user_status(user_id: int, _admin: User = Depends(require_admin)):
    """管理员：启用/停用用户"""
    async with async_session() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        u = result.scalar_one_or_none()
        if not u:
            raise HTTPException(status_code=404, detail="用户不存在")
        u.status = 0 if u.status == 1 else 1
        await db.commit()
    return ApiResponse(data={"status": u.status}, msg="状态已更新")


# ============================================================
# 积分排行榜
# ============================================================

@router.get("/users/ranking", response_model=ApiResponse)
async def ranking(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=50),
    scope: str = Query("company", max_length=20),
    user: User = Depends(get_current_user),
):
    """
    积分排行榜（分全公司/本部门）
    scope=company: 全公司排名, scope=dept: 本部门排名
    """
    async with async_session() as db:
        # 构建子查询：每个用户的总积分
        base_q = select(
            User.id,
            User.real_name,
            User.position,
            User.username,
            func.coalesce(func.sum(ExperiencePoint.points), 0).label("total_points"),
        ).join(ExperiencePoint, ExperiencePoint.user_id == User.id, isouter=True)

        if scope == "dept" and user.dept_id:
            base_q = base_q.where(User.dept_id == user.dept_id)

        base_q = base_q.group_by(User.id, User.real_name, User.position, User.username)
        base_q = base_q.order_by(func.sum(ExperiencePoint.points).desc().nulls_last())

        # 总数
        count_sql = select(func.count()).select_from(base_q.subquery())
        total = (await db.execute(count_sql)).scalar() or 0

        # 分页
        rows = (await db.execute(
            base_q.offset((page - 1) * page_size).limit(page_size)
        )).all()

        items = [
            {
                "user_id": r[0],
                "real_name": r[1],
                "position": r[2],
                "username": r[3],
                "points": int(r[4]) if r[4] else 0,
            }
            for r in rows
        ]

        # 当前用户的排名
        my_rank = 1
        my_total_points_r = await db.execute(
            select(func.coalesce(func.sum(ExperiencePoint.points), 0))
            .where(ExperiencePoint.user_id == user.id)
        )
        my_pts = my_total_points_r.scalar() or 0
        if my_pts > 0:
            higher_sub = select(
                ExperiencePoint.user_id,
                func.sum(ExperiencePoint.points).label("tp")
            ).group_by(ExperiencePoint.user_id).having(
                func.sum(ExperiencePoint.points) > my_pts
            ).subquery()

            urq = select(func.count()).select_from(higher_sub)
            if scope == "dept" and user.dept_id:
                urq = urq.where(
                    higher_sub.c.user_id.in_(select(User.id).where(User.dept_id == user.dept_id))
                )
            my_rank = ((await db.execute(urq)).scalar() or 0) + 1

    return ApiResponse(data={
        "items": items,
        "total": total,
        "page": page,
        "page_size": page_size,
        "my_rank": my_rank if my_rank else 1,
    })
