"""
语音路由 —— 音频上传 / 转写状态查询 / 转为经验草稿
转写方案：本地 faster-whisper（离线免费）→ 轮询获取结果
"""
import os
import uuid
import logging
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File

from database import async_session
from models import VoiceMessage, KnowledgeEntry, ExperiencePoint, User
from models import TranscriptStatusEnum, SourceTypeEnum, EntryStatusEnum, PointActionEnum
from schemas import ApiResponse
from auth import get_current_user, require_admin
from config import UPLOAD_DIR

logger = logging.getLogger(__name__)
router = APIRouter()

ALLOWED_AUDIO = {".mp3", ".wav", ".webm", ".m4a", ".ogg"}


async def _do_transcribe(vm_id: int, audio_path: str):
    """后台任务：根据系统 ASR 设置选择引擎转写（WebM 先转 WAV）"""
    from asr import get_active_asr_provider, transcribe_local, transcribe_audio
    import subprocess, tempfile

    # 浏览器录音 webm → 统一转 16kHz mono WAV
    work_path = audio_path
    tmp_file = None
    if not audio_path.lower().endswith('.wav'):
        tmp_file = os.path.join(tempfile.gettempdir(), f"voice_{uuid.uuid4().hex}.wav")
        r = subprocess.run(
            ["ffmpeg", "-i", audio_path, "-ar", "16000", "-ac", "1", "-y", tmp_file],
            capture_output=True, timeout=30,
        )
        if r.returncode == 0 and os.path.exists(tmp_file) and os.path.getsize(tmp_file) > 0:
            work_path = tmp_file

    provider = await get_active_asr_provider()
    text = ""
    if provider == "tencent":
        segments = await transcribe_audio(work_path)
        if segments:
            text = " ".join(s.get("text", "") for s in segments)
    else:
        text = await transcribe_local(work_path)

    if tmp_file:
        try: os.remove(tmp_file)
        except: pass
    async with async_session() as db:
        from sqlalchemy import update
        try:
            if text:
                await db.execute(update(VoiceMessage).where(VoiceMessage.id == vm_id).values(transcript=text, transcript_status=TranscriptStatusEnum.done))
                logger.info(f"ASR[{provider}] ok (vm_id={vm_id}): {text[:50]}...")
            else:
                await db.execute(update(VoiceMessage).where(VoiceMessage.id == vm_id).values(transcript_status=TranscriptStatusEnum.failed))
                logger.warning(f"ASR[{provider}] empty (vm_id={vm_id})")
            await db.commit()
        except Exception as e:
            logger.error(f"DB update error (vm_id={vm_id}): {e}")


@router.post("/voice/upload", response_model=ApiResponse)
async def upload_voice(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
):
    """上传音频文件，触发本地 Whisper 异步转写"""
    suffix = Path(file.filename).suffix.lower()
    if suffix not in ALLOWED_AUDIO:
        raise HTTPException(status_code=400, detail=f"Unsupported format: {suffix}, supports mp3/wav/webm/m4a/ogg")

    os.makedirs(UPLOAD_DIR, exist_ok=True)
    safe_name = f"voice_{uuid.uuid4().hex[:12]}{suffix}"
    save_path = os.path.join(UPLOAD_DIR, safe_name)

    content = await file.read()
    with open(save_path, "wb") as f:
        f.write(content)

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

    # 异步转写
    import asyncio
    asyncio.create_task(_do_transcribe(vm_id, save_path))
    logger.info(f"Voice uploaded: {save_path}, transcribing...")

    return ApiResponse(data={
        "id": vm_id,
        "filename": safe_name,
        "size": len(content),
        "transcript_status": "pending",
    }, msg="Uploaded, transcribing")


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
            raise HTTPException(status_code=404, detail="Voice not found")

        if vm.user_id != user.id and user.role.value not in ("admin", "boss"):
            raise HTTPException(status_code=403, detail="Forbidden")

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
    """将转写结果转为经验草稿"""
    async with async_session() as db:
        from sqlalchemy import select
        result = await db.execute(
            select(VoiceMessage).where(VoiceMessage.id == vm_id)
        )
        vm = result.scalar_one_or_none()
        if not vm:
            raise HTTPException(status_code=404, detail="Voice not found")

        if not vm.transcript:
            raise HTTPException(status_code=400, detail="Not transcribed yet")

        entry = KnowledgeEntry(
            title=title or f"Voice-{vm.created_at.strftime('%m%d%H%M') if vm.created_at else vm_id}",
            content=vm.transcript,
            category_id=category_id or 1,
            knowledge_base=knowledge_base,
            source_type=SourceTypeEnum.experience,
            source_person=user.real_name,
            status=EntryStatusEnum.pending,
        )
        db.add(entry)
        await db.flush()

        db.add(ExperiencePoint(
            user_id=user.id,
            knowledge_id=entry.id,
            points=1,
            action_type=PointActionEnum.submit,
        ))

        vm.related_knowledge_id = entry.id
        vm.transcript_status = TranscriptStatusEnum.done
        await db.commit()
        await db.refresh(entry)

    return ApiResponse(data={"knowledge_id": entry.id}, msg="Experience submitted, +1 point")
