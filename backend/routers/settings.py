"""
系统设置路由 —— 积分规则 / 飞轮阈值 / 分类标签管理
"""
import logging
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func

import os
import os
import hashlib, base64
from cryptography.fernet import Fernet
from config import LLM_ENCRYPTION_KEY
from database import async_session
from models import SystemConfig, KnowledgeCategory
from schemas import ApiResponse
from auth import require_admin
from models import User
from config import TENCENT_SECRET_ID, TENCENT_SECRET_KEY

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
# 腾讯云 ASR 配置
# ============================================================

def _asr_encrypt(plain: str) -> str:
    if not plain: return ""
    key = LLM_ENCRYPTION_KEY.encode("utf-8")
    digest = hashlib.sha256(key).digest()
    b64_key = base64.urlsafe_b64encode(digest)
    return Fernet(b64_key).encrypt(plain.encode()).decode()

def _asr_decrypt(cipher: str) -> str:
    if not cipher: return ""
    try:
        key = LLM_ENCRYPTION_KEY.encode("utf-8")
        digest = hashlib.sha256(key).digest()
        b64_key = base64.urlsafe_b64encode(digest)
        return Fernet(b64_key).decrypt(cipher.encode()).decode()
    except Exception:
        return cipher

def _asr_mask(val: str) -> str:
    if len(val) <= 8: return "****"
    return val[:4] + "*" * (len(val) - 8) + val[-4:]


@router.get("/settings/asr", response_model=ApiResponse)
async def get_asr_config(_admin: User = Depends(require_admin)):
    """获取腾讯云ASR配置（脱敏显示）"""
    async with async_session() as db:
        id_r = await db.execute(select(SystemConfig).where(SystemConfig.config_key == "asr_secret_id"))
        key_r = await db.execute(select(SystemConfig).where(SystemConfig.config_key == "asr_secret_key"))
        pv_r = await db.execute(select(SystemConfig).where(SystemConfig.config_key == "asr_provider"))
        secret_id_cfg = id_r.scalar_one_or_none()
        secret_key_cfg = key_r.scalar_one_or_none()
        provider_cfg = pv_r.scalar_one_or_none()
        s_id = _asr_decrypt(secret_id_cfg.config_value) if secret_id_cfg else ""
        s_key = _asr_decrypt(secret_key_cfg.config_value) if secret_key_cfg else ""
        provider = (provider_cfg.config_value if provider_cfg else "whisper") or "whisper"
    return ApiResponse(data={
        "secret_id": _asr_mask(s_id) if s_id else "",
        "secret_id_set": bool(s_id),
        "secret_key_set": bool(s_key),
        "configured": bool(s_id and s_key) if provider == "tencent" else True,  # whisper 无需密钥
        "provider": provider,
    })


@router.put("/settings/asr", response_model=ApiResponse)
async def update_asr_config(
    secret_id: str = Query("", max_length=200),
    secret_key: str = Query("", max_length=200),
    provider: str = Query("", max_length=20),
    _admin: User = Depends(require_admin),
):
    """更新腾讯云ASR密钥 / ASR引擎选择"""
    async with async_session() as db:
        if secret_id and secret_id.strip() and not secret_id.startswith("*"):
            id_r = await db.execute(select(SystemConfig).where(SystemConfig.config_key == "asr_secret_id"))
            cfg = id_r.scalar_one_or_none()
            if cfg:
                cfg.config_value = _asr_encrypt(secret_id.strip())
            else:
                db.add(SystemConfig(config_key="asr_secret_id", config_value=_asr_encrypt(secret_id.strip()), config_type="encrypted", description="腾讯云ASR SecretId"))
        if secret_key and secret_key.strip() and not secret_key.startswith("*"):
            key_r = await db.execute(select(SystemConfig).where(SystemConfig.config_key == "asr_secret_key"))
            cfg2 = key_r.scalar_one_or_none()
            if cfg2:
                cfg2.config_value = _asr_encrypt(secret_key.strip())
            else:
                db.add(SystemConfig(config_key="asr_secret_key", config_value=_asr_encrypt(secret_key.strip()), config_type="encrypted", description="腾讯云ASR SecretKey"))
        # 引擎选择
        if provider and provider in ("tencent", "whisper"):
            pv_r = await db.execute(select(SystemConfig).where(SystemConfig.config_key == "asr_provider"))
            pv_cfg = pv_r.scalar_one_or_none()
            if pv_cfg:
                pv_cfg.config_value = provider
            else:
                db.add(SystemConfig(config_key="asr_provider", config_value=provider, config_type="string", description="ASR引擎选择 tencent/whisper"))
        await db.commit()
    # 清除 ASR 缓存
    from asr import reset_asr_cache
    reset_asr_cache()
    return ApiResponse(msg="ASR配置已保存，立即生效")


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
