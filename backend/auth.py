"""
JWT 认证 + 权限依赖注入
"""
from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from sqlalchemy import select

from config import JWT_SECRET, JWT_EXPIRE_MINUTES
from database import get_db, async_session
from models import User

ALGORITHM = "HS256"
security = HTTPBearer(auto_error=False)


def create_access_token(data: dict) -> str:
    """生成 JWT，payload: {user_id, role, position, exp}"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=JWT_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, JWT_SECRET, algorithm=ALGORITHM)


def decode_token(token: str) -> Optional[dict]:
    """解密 JWT，失败返回 None"""
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
    except JWTError:
        return None


async def get_current_user(
    request: Request,
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
) -> User:
    """从 Authorization Header 提取当前用户，未登录抛出 401"""
    if not credentials:
        raise HTTPException(status_code=401, detail="请先登录")

    payload = decode_token(credentials.credentials)
    if not payload:
        raise HTTPException(status_code=401, detail="登录已过期，请重新登录")

    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="无效的登录凭证")

    async with async_session() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=401, detail="用户不存在或已被删除")
        if user.status != 1:
            raise HTTPException(status_code=403, detail="账号已被停用")
        return user


def require_role(*roles: str):
    """权限守卫工厂：仅允许指定角色的用户访问"""
    async def checker(user: User = Depends(get_current_user)):
        if user.role.value not in roles:
            raise HTTPException(status_code=403, detail="权限不足")
        return user
    return checker


async def require_admin(user: User = Depends(get_current_user)) -> User:
    """仅管理员可访问"""
    if user.role.value not in ("admin", "boss"):
        raise HTTPException(status_code=403, detail="需要管理员权限")
    return user


async def require_boss(user: User = Depends(get_current_user)) -> User:
    """仅老板可访问"""
    if user.role.value != "boss":
        raise HTTPException(status_code=403, detail="需要老板权限")
    return user
