"""
LLM 模型配置路由 —— 列表 / 更新 / 测试连接 / 设为默认 / 新增自定义
API Key 用 AES(Fernet) 加密存储
"""
import json
import logging
import time
from cryptography.fernet import Fernet
from fastapi import APIRouter, Depends, HTTPException, Query

from database import async_session
from models import LLMProvider
from schemas import ApiResponse, LLMProviderUpdate, LLMProviderCreate
from auth import require_admin
from models import User
from config import LLM_ENCRYPTION_KEY

logger = logging.getLogger(__name__)
router = APIRouter()


def _get_fernet():
    """从 JWT_SECRET 派生 Fernet 密钥"""
    key = LLM_ENCRYPTION_KEY.encode("utf-8")
    # Fernet 需要 32 字节 base64 编码的 key
    import base64, hashlib
    digest = hashlib.sha256(key).digest()
    b64_key = base64.urlsafe_b64encode(digest)
    return Fernet(b64_key)


def _encrypt(plain: str) -> str:
    if not plain:
        return ""
    try:
        return (_get_fernet().encrypt(plain.encode("utf-8"))).decode("utf-8")
    except Exception:
        return plain


def _decrypt(cipher: str) -> str:
    if not cipher:
        return ""
    try:
        return (_get_fernet().decrypt(cipher.encode("utf-8"))).decode("utf-8")
    except Exception:
        return cipher  # 解密失败返回原值（可能未加密）


def _mask_key(key: str) -> str:
    """脱敏显示：只显示前4后4位"""
    if len(key) <= 8:
        return "****"
    return key[:4] + "*" * (len(key) - 8) + key[-4:]


# ============================================================
# 列表
# ============================================================

@router.get("/llm/providers", response_model=ApiResponse)
async def list_providers(_admin: User = Depends(require_admin)):
    """全部模型列表（API Key 脱敏）"""
    async with async_session() as db:
        from sqlalchemy import select
        result = await db.execute(
            select(LLMProvider).order_by(LLMProvider.id)
        )
        rows = result.scalars().all()
        items = [
            {
                "id": p.id,
                "name": p.name,
                "provider_type": p.provider_type.value,
                "base_url": p.base_url,
                "api_key": _mask_key(_decrypt(p.api_key)),
                "api_key_set": bool(p.api_key),
                "model_name": p.model_name,
                "is_active": p.is_active,
                "is_default": p.is_default,
                "max_tokens": p.max_tokens,
                "temperature": p.temperature,
                "created_at": p.created_at.isoformat() if p.created_at else None,
                "updated_at": p.updated_at.isoformat() if p.updated_at else None,
            }
            for p in rows
        ]
    return ApiResponse(data=items)


# ============================================================
# 更新配置
# ============================================================

@router.put("/llm/providers/{provider_id}", response_model=ApiResponse)
async def update_provider(
    provider_id: int,
    body: LLMProviderUpdate,
    _admin: User = Depends(require_admin),
):
    """更新模型配置"""
    async with async_session() as db:
        from sqlalchemy import select
        result = await db.execute(
            select(LLMProvider).where(LLMProvider.id == provider_id)
        )
        p = result.scalar_one_or_none()
        if not p:
            raise HTTPException(status_code=404, detail="模型不存在")

        if body.name is not None:
            p.name = body.name
        if body.base_url is not None:
            p.base_url = body.base_url
        if body.api_key is not None:
            p.api_key = _encrypt(body.api_key)
        if body.model_name is not None:
            p.model_name = body.model_name
        if body.is_active is not None:
            p.is_active = body.is_active
        if body.max_tokens is not None:
            p.max_tokens = body.max_tokens
        if body.temperature is not None:
            p.temperature = body.temperature

        await db.commit()
    return ApiResponse(msg="配置已更新")


# ============================================================
# 测试连接
# ============================================================

@router.post("/llm/providers/{provider_id}/test", response_model=ApiResponse)
async def test_connection(
    provider_id: int,
    _admin: User = Depends(require_admin),
):
    """测试连接：向模型发送简短消息，成功返回耗时"""
    async with async_session() as db:
        from sqlalchemy import select
        result = await db.execute(
            select(LLMProvider).where(LLMProvider.id == provider_id)
        )
        p = result.scalar_one_or_none()
        if not p:
            raise HTTPException(status_code=404, detail="模型不存在")

        api_key = _decrypt(p.api_key)
        if not api_key:
            raise HTTPException(status_code=400, detail="请先配置 API Key")

        try:
            import httpx
            start = time.time()
            async with httpx.AsyncClient(timeout=30) as client:
                resp = await client.post(
                    f"{p.base_url}/chat/completions",
                    headers={"Authorization": f"Bearer {api_key}"},
                    json={
                        "model": p.model_name,
                        "messages": [
                            {"role": "user", "content": "你好，请只回复：连接成功"},
                        ],
                        "temperature": 0.1,
                        "max_tokens": 20,
                    },
                )
                resp.raise_for_status()
                elapsed_ms = int((time.time() - start) * 1000)
                body = resp.json()
                reply = body.get("choices", [{}])[0].get("message", {}).get("content", "")

                return ApiResponse(
                    data={
                        "success": True,
                        "elapsed_ms": elapsed_ms,
                        "reply": reply[:100],
                    },
                    msg=f"连接成功，耗时 {elapsed_ms}ms",
                )
        except httpx.HTTPStatusError as e:
            raise HTTPException(
                status_code=400,
                detail=f"连接失败 [{e.response.status_code}]：{e.response.text[:200]}",
            )
        except Exception as e:
            raise HTTPException(
                status_code=400,
                detail=f"连接失败：{str(e)[:300]}",
            )


# ============================================================
# 设为默认
# ============================================================

@router.put("/llm/providers/{provider_id}/set-default", response_model=ApiResponse)
async def set_default(
    provider_id: int,
    _admin: User = Depends(require_admin),
):
    """设为默认模型（有且仅有一个默认）"""
    async with async_session() as db:
        from sqlalchemy import select, update
        # 清除所有默认
        await db.execute(
            update(LLMProvider).values(is_default=False)
        )
        # 设置新的默认
        result = await db.execute(
            select(LLMProvider).where(LLMProvider.id == provider_id)
        )
        p = result.scalar_one_or_none()
        if not p:
            raise HTTPException(status_code=404, detail="模型不存在")
        p.is_default = True
        await db.commit()
    return ApiResponse(msg="已设为默认模型，即刻生效")


# ============================================================
# 新增自定义模型
# ============================================================

@router.post("/llm/providers", response_model=ApiResponse)
async def create_provider(
    body: LLMProviderCreate,
    _admin: User = Depends(require_admin),
):
    """新增自定义模型"""
    async with async_session() as db:
        p = LLMProvider(
            name=body.name,
            provider_type=body.provider_type,
            base_url=body.base_url,
            api_key=_encrypt(body.api_key or ""),
            model_name=body.model_name,
            is_active=False,
            is_default=False,
        )
        db.add(p)
        await db.commit()
        await db.refresh(p)
    return ApiResponse(data={"id": p.id}, msg="自定义模型已添加")
