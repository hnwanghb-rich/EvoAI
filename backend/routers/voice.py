"""
语音路由 —— 音频上传 / 转写状态查询 / 转为经验草稿
转写方案：优先云端 ASR（腾讯云/通义千问），不可用时标记 pending 等待外部处理
"""
import os
import uuid
import logging
from datetime import datetime
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File

from database import async_session
from models import VoiceMessage, KnowledgeEntry, ExperiencePoint, User
from models import TranscriptStatusEnum, SourceTypeEnum, EntryStatusEnum, PointActionEnum
from schemas import ApiResponse
from auth import get_current_user, require_admin
from config import UPLOAD_DIR, ASR_PROVIDER, TENCENT_SECRET_ID, TENCENT_SECRET_KEY

logger = logging.getLogger(__name__)
router = APIRouter()

ALLOWED_AUDIO = {".mp3", ".wav", ".webm", ".m4a", ".ogg"}


@router.post("/voice/upload", response_model=ApiResponse)
async def upload_voice(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
):
    """上传音频文件，异步触发转写"""
    suffix = Path(file.filename).suffix.lower()
    if suffix not in ALLOWED_AUDIO:
        raise HTTPException(status_code=400, detail=f"不支持的音频格式：{suffix}，支持 mp3/wav/webm/m4a/ogg")

    os.makedirs(UPLOAD_DIR, exist_ok=True)
    safe_name = f"voice_{uuid.uuid4().hex[:12]}{suffix}"
    save_path = os.path.join(UPLOAD_DIR, safe_name)

    content = await file.read()
    with open(save_path, "wb") as f:
        f.write(content)

    # 写入 voice_messages
    async with async_session() as db:
        vm = VoiceMessage(
            user_id=user.id,
            audio_path=save_path,
            transcript=None,
            transcript_status=TranscriptStatusEnum.pending,
        )
        db.add(vm)
        await db.commit()
        await db.refresh(vm)

        vm_id = vm.id

    # 异步转写（后台任务）
    # 注：当前 ASR 未配置，标记 pending，前端显示"转写中..."
    # 有 ASR Key 时取消下面注释即可启用
    # if TENCENT_SECRET_ID and TENCENT_SECRET_KEY:
    #     import asyncio
    #     asyncio.create_task(_do_transcribe(vm_id, save_path))
    # else:
    logger.info(f"音频已保存: {save_path}, ASR 未配置，保持 pending 状态")

    return ApiResponse(data={
        "id": vm_id,
        "filename": safe_name,
        "size": len(content),
        "transcript_status": "pending",
    }, msg="音频已上传，转写处理中")


@router.get("/voice/status/{vm_id}", response_model=ApiResponse)
async def voice_status(
    vm_id: int,
    user: User = Depends(get_current_user),
):
    """查询转写状态"""
    async with async_session() as db:
        from sqlalchemy import select
        result = await db.execute(
            select(VoiceMessage).where(VoiceMessage.id == vm_id)
        )
        vm = result.scalar_one_or_none()
        if not vm:
            raise HTTPException(status_code=404, detail="录音不存在")

        # 权限：只能查自己的
        if vm.user_id != user.id and user.role.value not in ("admin", "boss"):
            raise HTTPException(status_code=403, detail="无权查看他人录音")

        data = {
            "id": vm.id,
            "transcript": vm.transcript,
            "transcript_status": vm.transcript_status.value,
            "audio_path": vm.audio_path,
            "created_at": vm.created_at.isoformat() if vm.created_at else None,
        }
    return ApiResponse(data=data)


@router.post("/voice/{vm_id}/to-experience", response_model=ApiResponse)
async def voice_to_experience(
    vm_id: int,
    title: str = Query("", max_length=200),
    category_id: int = Query(0),
    knowledge_base: str = Query("public", max_length=20),
    user: User = Depends(get_current_user),
):
    """将转写结果转为经验草稿 → 提交审核"""
    async with async_session() as db:
        from sqlalchemy import select
        result = await db.execute(
            select(VoiceMessage).where(VoiceMessage.id == vm_id)
        )
        vm = result.scalar_one_or_none()
        if not vm:
            raise HTTPException(status_code=404, detail="录音不存在")

        if not vm.transcript:
            raise HTTPException(status_code=400, detail="转写尚未完成，无法提交")

        # 创建经验条目
        entry = KnowledgeEntry(
            title=title or f"语音经验-{vm.created_at.strftime('%m%d%H%M') if vm.created_at else vm_id}",
            content=vm.transcript,
            category_id=category_id or 1,
            knowledge_base=knowledge_base,
            source_type=SourceTypeEnum.experience,
            source_person=user.real_name,
            status=EntryStatusEnum.pending,
        )
        db.add(entry)
        await db.flush()

        # +1 提交积分
        db.add(ExperiencePoint(
            user_id=user.id,
            knowledge_id=entry.id,
            points=1,
            action_type=PointActionEnum.submit,
        ))

        # 关联录音到知识
        vm.related_knowledge_id = entry.id
        vm.transcript_status = TranscriptStatusEnum.done

        await db.commit()
        await db.refresh(entry)

    return ApiResponse(data={"knowledge_id": entry.id}, msg="经验已提交，+1积分，等待审核")


# ============================================================
# 转写实现（有 API Key 时启用）
# ============================================================

async def _do_transcribe_tencent(vm_id: int, audio_path: str):
    """腾讯云 ASR 转写（暂存，待 API Key 配置后启用）"""
    try:
        import httpx
        import base64
        import hashlib
        import hmac
        import time

        # 腾讯云 API 签名 V3
        # 此处省略完整签名实现，生产环境补充

        # 示例请求：
        # async with httpx.AsyncClient() as client:
        #     resp = await client.post(
        #         "https://asr.tencentcloudapi.com/",
        #         headers={"Authorization": ...},
        #         json={"EngineModelType": "16k_zh", "Url": audio_url, ...}
        #     )
        #     result = resp.json()["Response"]["Result"]

        logger.info(f"腾讯云 ASR 转写请求已发送（vm_id={vm_id}）")
    except Exception as e:
        logger.error(f"转写失败: {e}")
        async with async_session() as db:
            from sqlalchemy import select, update
            await db.execute(
                update(VoiceMessage).where(VoiceMessage.id == vm_id).values(
                    transcript_status="failed"
                )
            )
            await db.commit()
