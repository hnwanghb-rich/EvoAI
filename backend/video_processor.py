"""
视频处理器 —— 视频上传 → 提取音频 → 转写 → 带时间戳分段 → 写入 knowledge_entries
依赖：ffmpeg（系统安装），ASR API（OpenAI Whisper / 腾讯云，可选）
ASR 三级回退：OpenAI Whisper → 腾讯云 → 静态分段(pending)
"""
import os
import uuid
import hashlib
import base64
import logging
import subprocess
import tempfile
from datetime import datetime
from pathlib import Path

import httpx
from cryptography.fernet import Fernet

from config import (
    LLM_ENCRYPTION_KEY,
    ASR_PROVIDER, TENCENT_SECRET_ID, TENCENT_SECRET_KEY, TENCENT_ASR_APP_ID,
)
from database import async_session
from models import (
    KnowledgeEntry, KnowledgeCategory, LLMProvider,
    EntryStatusEnum, SourceTypeEnum, ContentTypeEnum, KnowledgeBaseEnum,
)

logger = logging.getLogger(__name__)


async def process_video(
    video_path: str,
    category_id: int,
    knowledge_base: str = "public",
    title: str = "",
    source_person: str = "",
    source_dept: str = "",
    tags: str = "",
) -> list[int]:
    """
    处理视频：提取音频 → 转写 → 按时间戳分段 → 写入 knowledge_entries
    返回创建的知识条目 ID 列表
    """
    video_name = Path(video_path).stem
    base_title = title or video_name

    # 1. 提取音频 → 临时 WAV 文件
    audio_path = os.path.join(tempfile.gettempdir(), f"vocal_{uuid.uuid4().hex[:8]}.wav")
    try:
        _extract_audio(video_path, audio_path)
    except Exception as e:
        logger.warning(f"音频提取失败: {e}")
        # 无音频时：创建单条视频知识
        return await _create_single_entry(
            base_title, "", category_id, knowledge_base,
            source_person, source_dept, tags, video_path, content_type="video",
        )

    # 2. ASR 转写（带时间戳）
    segments = await _transcribe_with_timestamps(audio_path)
    if not segments:
        # ASR 全部不可用 → 静态分段，标记 pending 等人工处理
        duration = _get_audio_duration(audio_path)
        segments = _static_segments(duration, audio_path)
        # 用 pending 状态创建，等管理员手动填写转写文本
        return await _create_segments(
            base_title, segments, category_id, knowledge_base,
            source_person, source_dept, tags, video_path,
            status=EntryStatusEnum.pending,
        )

    # 3. 分段写入知识条目
    return await _create_segments(
        base_title, segments, category_id, knowledge_base,
        source_person, source_dept, tags, video_path,
        status=EntryStatusEnum.approved,
    )


def _extract_audio(video_path: str, output_wav: str):
    """ffmpeg 提取音频 → 16kHz 单声道 WAV"""
    cmd = [
        "ffmpeg", "-i", video_path,
        "-vn", "-acodec", "pcm_s16le",
        "-ar", "16000", "-ac", "1",
        "-y", output_wav,
    ]
    subprocess.run(cmd, capture_output=True, timeout=300, check=True)
    logger.info(f"音频提取完成: {output_wav}")


async def _transcribe_with_timestamps(audio_path: str) -> list[dict]:
    """
    ASR 三级回退：
    1. OpenAI Whisper 兼容 API（复用已配置的 LLM）
    2. 腾讯云 ASR（需单独配置 TENCENT_SECRET_ID/KEY）
    3. 静态分段 pending（兜底，await 人工填写）
    返回: [{"start": float, "end": float, "text": str}, ...] 或空列表(兜底)
    """
    provider = ASR_PROVIDER or "openai_compatible"

    # Tier 1: OpenAI Whisper 兼容
    if provider in ("openai_compatible",):
        try:
            result = await _transcribe_openai_compatible(audio_path)
            if result:
                logger.info(f"OpenAI Whisper 转写完成: {len(result)} 段, {sum(len(s['text']) for s in result)} 字符")
                return result
        except Exception as e:
            logger.warning(f"OpenAI Whisper 转写失败: {e}")

    # Tier 2: 腾讯云 ASR
    if provider == "tencent" and TENCENT_SECRET_ID and TENCENT_SECRET_KEY:
        try:
            result = await _transcribe_tencent(audio_path)
            if result:
                logger.info(f"腾讯云 ASR 转写完成: {len(result)} 段")
                return result
        except Exception as e:
            logger.warning(f"腾讯云 ASR 转写失败: {e}")

    # Tier 3: 兜底 —— 返回空列表，上层用静态分段 pending
    logger.warning("无可用 ASR，回退到静态分段(pending)")
    return []


# ═══════════════════════════════════════════════════════════════
# OpenAI Whisper 兼容转写
# ═══════════════════════════════════════════════════════════════

async def _transcribe_openai_compatible(audio_path: str) -> list[dict] | None:
    """调用 OpenAI 兼容 /audio/transcriptions 端点，复用 LLMProvider 配置"""
    async with async_session() as db:
        from sqlalchemy import select as sa_select
        llm_r = await db.execute(
            sa_select(LLMProvider).where(
                LLMProvider.is_active == True,
                LLMProvider.is_default == True,
            )
        )
        llm = llm_r.scalar_one_or_none()
        if not llm or not llm.api_key:
            logger.warning("无可用 LLM 配置，跳过 Whisper 转写")
            return None

        # 解密 API key
        key = LLM_ENCRYPTION_KEY.encode("utf-8")
        digest = hashlib.sha256(key).digest()
        b64_key = base64.urlsafe_b64encode(digest)
        api_key = Fernet(b64_key).decrypt(llm.api_key.encode()).decode()

        # Whisper model name: 尝试用 llm.model_name 去掉 -chat 后缀
        whisper_model = "whisper-1"
        if hasattr(llm, 'model_name') and llm.model_name:
            whisper_model = llm.model_name

        base_url = llm.base_url.rstrip("/")

    try:
        async with httpx.AsyncClient(timeout=120) as client:
            with open(audio_path, "rb") as f:
                resp = await client.post(
                    f"{base_url}/audio/transcriptions",
                    headers={"Authorization": f"Bearer {api_key}"},
                    files={"file": (os.path.basename(audio_path), f, "audio/wav")},
                    data={
                        "model": whisper_model,
                        "response_format": "verbose_json",
                        "timestamp_granularities[]": "segment",
                    },
                )
            if resp.status_code == 404:
                logger.warning(f"LLM 不支持 /audio/transcriptions 端点 (404)")
                return None
            resp.raise_for_status()
            data = resp.json()

            # verbose_json 格式：segments 数组含 start/end/text
            segments = data.get("segments", [])
            if segments:
                return [
                    {"start": s["start"], "end": s["end"], "text": s["text"].strip()}
                    for s in segments if s.get("text", "").strip()
                ]
            # 无 segments 时：用全文估算分段
            full_text = data.get("text", "").strip()
            if full_text:
                return _split_by_sentences(full_text)
            return None
    except httpx.HTTPStatusError as e:
        logger.warning(f"Whisper API HTTP {e.response.status_code}: {e.response.text[:200]}")
        return None
    except Exception as e:
        logger.warning(f"Whisper 转写异常: {e}")
        return None


# ═══════════════════════════════════════════════════════════════
# 腾讯云 ASR 转写
# ═══════════════════════════════════════════════════════════════

async def _transcribe_tencent(audio_path: str) -> list[dict] | None:
    """腾讯云语音识别 —— 短音频 SentenceRecognition，长音频 CreateRecTask"""
    import hmac
    import time
    import json as json_mod

    secret_id = TENCENT_SECRET_ID
    secret_key = TENCENT_SECRET_KEY
    app_id = TENCENT_ASR_APP_ID
    if not secret_id or not secret_key:
        return None

    # 获取音频时长
    try:
        result = subprocess.run(
            ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
             "-of", "csv=p=0", audio_path],
            capture_output=True, text=True, timeout=10,
        )
        duration = float(result.stdout.strip())
    except Exception:
        duration = 60

    # 读取音频为 base64
    with open(audio_path, "rb") as f:
        audio_b64 = base64.b64encode(f.read()).decode()

    service = "asr"
    host = "asr.tencentcloudapi.com"
    endpoint = f"https://{host}"
    action = "SentenceRecognition" if duration <= 60 else "CreateRecTask"
    version = "2019-06-14"
    region = "ap-guangzhou"
    timestamp = int(time.time())

    # 签名
    payload = json_mod.dumps({
        "ProjectId": 0,
        "SubServiceType": 2,
        "EngSerViceType": "16k_zh" if duration <= 60 else "16k_zh_video",
        "SourceType": 1,
        "VoiceFormat": "wav",
        "Data": audio_b64,
        "DataLen": os.path.getsize(audio_path),
    })
    if action == "CreateRecTask":
        payload_data = {
            "EngineModelType": "16k_zh_video",
            "ChannelNum": 1,
            "ResTextFormat": 3,  # 带时间戳
            "SourceType": 1,
            "Data": audio_b64,
            "DataLen": os.path.getsize(audio_path),
        }
        payload = json_mod.dumps(payload_data)

    algorithm = "TC3-HMAC-SHA256"
    date_str = datetime.utcfromtimestamp(timestamp).strftime("%Y-%m-%d")
    canonical_headers = f"content-type:application/json; charset=utf-8\nhost:{host}\n"
    signed_headers = "content-type;host"
    hashed_payload = hashlib.sha256(payload.encode("utf-8")).hexdigest()
    canonical_request = (
        f"POST\n/\n\n{canonical_headers}\n{signed_headers}\n{hashed_payload}"
    )
    credential_scope = f"{date_str}/{service}/tc3_request"
    string_to_sign = (
        f"{algorithm}\n{timestamp}\n{credential_scope}\n"
        f"{hashlib.sha256(canonical_request.encode('utf-8')).hexdigest()}"
    )
    def _sign(key_bytes, msg):
        return hmac.new(key_bytes, msg.encode("utf-8"), hashlib.sha256).digest()
    secret_date = _sign(f"TC3{secret_key}".encode("utf-8"), date_str)
    secret_service = _sign(secret_date, service)
    secret_signing = _sign(secret_service, "tc3_request")
    signature = hmac.new(secret_signing, string_to_sign.encode("utf-8"),
                         hashlib.sha256).hexdigest()
    authorization = (
        f"{algorithm} Credential={secret_id}/{credential_scope}, "
        f"SignedHeaders={signed_headers}, Signature={signature}"
    )

    try:
        async with httpx.AsyncClient(timeout=120) as client:
            headers = {
                "Authorization": authorization,
                "Content-Type": "application/json; charset=utf-8",
                "Host": host,
                "X-TC-Action": action,
                "X-TC-Version": version,
                "X-TC-Timestamp": str(timestamp),
                "X-TC-Region": region,
            }
            resp = await client.post(endpoint, headers=headers, content=payload)
            resp.raise_for_status()
            data = resp.json()

            if "Response" not in data or "Error" in data.get("Response", {}):
                err = data.get("Response", {}).get("Error", {})
                logger.warning(f"腾讯云 ASR 错误: {err.get('Code')} {err.get('Message')}")
                return None

            response = data["Response"]

            # SentenceRecognition 直接返回结果
            if action == "SentenceRecognition":
                text = response.get("Result", "")
                if text.strip():
                    return [{"start": 0, "end": duration, "text": text.strip()}]
                return None

            # CreateRecTask → 轮询结果
            task_id = response.get("Data", {}).get("TaskId", 0)
            if not task_id:
                return None

            # 轮询（最多 30 次，每次 2 秒）
            for _ in range(30):
                await _async_sleep(2)
                poll_payload = json_mod.dumps({"TaskId": task_id})
                hashed = hashlib.sha256(poll_payload.encode("utf-8")).hexdigest()
                can_req = (
                    f"POST\n/\n\n{canonical_headers}\n{signed_headers}\n{hashed}"
                )
                ts2 = int(time.time())
                scope2 = f"{datetime.utcfromtimestamp(ts2).strftime('%Y-%m-%d')}/{service}/tc3_request"
                sig2_str = f"{algorithm}\n{ts2}\n{scope2}\n{hashlib.sha256(can_req.encode('utf-8')).hexdigest()}"
                sd2 = _sign(f"TC3{secret_key}".encode("utf-8"), datetime.utcfromtimestamp(ts2).strftime("%Y-%m-%d"))
                ss2 = _sign(sd2, service)
                sn2 = _sign(ss2, "tc3_request")
                sig2 = hmac.new(sn2, sig2_str.encode("utf-8"), hashlib.sha256).hexdigest()
                auth2 = (
                    f"{algorithm} Credential={secret_id}/{scope2}, "
                    f"SignedHeaders={signed_headers}, Signature={sig2}"
                )
                p_headers = {
                    "Authorization": auth2,
                    "Content-Type": "application/json; charset=utf-8",
                    "Host": host,
                    "X-TC-Action": "DescribeTaskStatus",
                    "X-TC-Version": version,
                    "X-TC-Timestamp": str(ts2),
                    "X-TC-Region": region,
                }
                pr = await client.post(endpoint, headers=p_headers, content=poll_payload)
                pr.raise_for_status()
                pd = pr.json()
                status = pd.get("Response", {}).get("Data", {}).get("StatusStr", "")
                if status == "success":
                    result_text = pd.get("Response", {}).get("Data", {}).get("Result", "")
                    # Result 可能是带时间戳的数组
                    if isinstance(result_text, list) and len(result_text) > 0:
                        return [
                            {"start": s.get("StartTime", 0) / 1000.0,
                             "end": s.get("EndTime", 0) / 1000.0,
                             "text": s.get("Text", "")}
                            for s in result_text if s.get("Text")
                        ]
                    elif isinstance(result_text, str) and result_text.strip():
                        return [{"start": 0, "end": duration, "text": result_text.strip()}]
                    break
                elif status == "failed":
                    logger.warning("腾讯云 ASR 任务失败")
                    return None
            return None
    except Exception as e:
        logger.warning(f"腾讯云 ASR 异常: {e}")
        return None


async def _async_sleep(seconds: float):
    """异步等待"""
    import asyncio
    await asyncio.sleep(seconds)


# ═══════════════════════════════════════════════════════════════
# 工具函数
# ═══════════════════════════════════════════════════════════════

def _split_by_sentences(text: str, max_chars: int = 500) -> list[dict]:
    """按句子边界分段（无时间戳时估算）"""
    import re
    # 按句末标点切分
    parts = re.split(r'(?<=[。！？；\n])\s*', text)
    segments = []
    current = ""
    current_start = 0
    for part in parts:
        current += part
        if len(current) >= max_chars or part is parts[-1]:
            txt = current.strip()
            if txt:
                # 粗略估算：中文约 4 字/秒
                dur = len(txt) / 4
                segments.append({"start": current_start, "end": current_start + dur, "text": txt})
                current_start += dur
            current = ""
    if not segments and text.strip():
        segments.append({"start": 0, "end": len(text) / 4, "text": text.strip()})
    return segments


def _get_audio_duration(audio_path: str) -> float:
    """获取音频时长（秒）"""
    try:
        result = subprocess.run(
            ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
             "-of", "csv=p=0", audio_path],
            capture_output=True, text=True, timeout=10,
        )
        return float(result.stdout.strip()) or 60
    except Exception:
        return 60


def _get_video_duration(video_path: str) -> float:
    """获取视频时长（秒），从原视频而非音频获取"""
    return _get_audio_duration(video_path)  # ffprobe 对视频同样可用


def _static_segments(duration: float, audio_path: str = "") -> list[dict]:
    """无 ASR 时生成静态 60 秒分段，文本为占位提示"""
    segments = []
    seg_duration = 60
    for start in range(0, max(int(duration), 60), seg_duration):
        end = min(start + seg_duration, duration)
        segments.append({
            "start": start,
            "end": end,
            "text": f"[视频片段 {_format_ts(start)} - {_format_ts(end)}] 此内容为视频转写片段，请管理员填写文字内容。",
        })
    return segments


def _format_ts(seconds: float) -> str:
    """秒 → mm:ss"""
    m = int(seconds // 60)
    s = int(seconds % 60)
    return f"{m:02d}:{s:02d}"


async def _create_segments(
    title: str, segments: list[dict],
    category_id: int, knowledge_base: str,
    source_person: str, source_dept: str, tags: str,
    video_path: str = "",
    status: EntryStatusEnum = EntryStatusEnum.approved,
) -> list[int]:
    """将转写片段批量写入 KnowledgeEntry，清理临时文件"""
    entry_ids = []
    audio_temp = None
    # 查找音频临时文件以便清理
    import tempfile as _tmp
    for fname in os.listdir(_tmp.gettempdir()):
        if fname.startswith("vocal_") and fname.endswith(".wav"):
            audio_temp = os.path.join(_tmp.gettempdir(), fname)
            break

    async with async_session() as db:
        for i, seg in enumerate(segments):
            seg_title = f"{title} - 片段{i+1} ({_format_ts(seg['start'])})"
            entry = KnowledgeEntry(
                title=seg_title,
                content=seg["text"],
                content_type=ContentTypeEnum.video,
                category_id=category_id,
                knowledge_base=knowledge_base,
                source_type=SourceTypeEnum.video,
                source_file_path=video_path,
                source_person=source_person or "系统导入",
                source_dept=source_dept,
                media_url=f"/uploads/{Path(video_path).name}" if video_path else None,
                media_start_sec=seg["start"],
                media_end_sec=seg["end"],
                tags=tags,
                status=status,
            )
            db.add(entry)
            await db.flush()
            entry_ids.append(entry.id)
        await db.commit()

    # 清理临时音频文件
    if audio_temp:
        try:
            os.remove(audio_temp)
        except Exception:
            pass

    label = "approved" if status == EntryStatusEnum.approved else "pending(待人工转写)"
    logger.info(f"视频处理完成: {len(entry_ids)} 个片段 [{label}] → {video_path}")
    return entry_ids


async def _create_single_entry(
    title: str, content: str, category_id: int, knowledge_base: str,
    source_person: str, source_dept: str, tags: str,
    file_path: str = "", content_type: str = "video",
) -> list[int]:
    """创建单条知识条目（无音频时使用）"""
    async with async_session() as db:
        content_type_enum = ContentTypeEnum.video if content_type == "video" else ContentTypeEnum.audio
        entry = KnowledgeEntry(
            title=title,
            content=content or f"视频文件：{Path(file_path).name}",
            content_type=content_type_enum,
            category_id=category_id,
            knowledge_base=knowledge_base,
            source_type=SourceTypeEnum.video if content_type == "video" else SourceTypeEnum.audio,
            source_file_path=file_path,
            source_person=source_person or "系统导入",
            source_dept=source_dept,
            media_url=f"/uploads/{Path(file_path).name}" if file_path else None,
            tags=tags,
            status=EntryStatusEnum.pending,
        )
        db.add(entry)
        await db.commit()
        await db.refresh(entry)
        return [entry.id]
