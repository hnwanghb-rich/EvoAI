"""
视频处理器 —— 视频上传 → 提取音频 → 转写 → 带时间戳分段 → 写入 knowledge_entries
依赖：ffmpeg（系统安装），ASR API（腾讯云/通义千问，可选）
"""
import os
import uuid
import logging
import subprocess
import tempfile
from datetime import datetime
from pathlib import Path

from database import async_session
from models import (
    KnowledgeEntry, KnowledgeCategory,
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
        # 转写失败：创建单条
        return await _create_single_entry(
            base_title, "[视频转写未完成]", category_id, knowledge_base,
            source_person, source_dept, tags, video_path, content_type="video",
        )

    # 3. 分段写入知识条目
    entry_ids = []
    async with async_session() as db:
        for i, seg in enumerate(segments):
            seg_title = f"{base_title} - 片段{i+1} ({_format_ts(seg['start'])})"
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
                media_url=f"/uploads/{Path(video_path).name}",
                media_start_sec=seg["start"],
                media_end_sec=seg["end"],
                tags=tags,
                status=EntryStatusEnum.approved,
            )
            db.add(entry)
            await db.flush()
            entry_ids.append(entry.id)
        await db.commit()

    # 清理临时文件
    try:
        os.remove(audio_path)
    except:
        pass

    logger.info(f"视频处理完成: {len(entry_ids)} 个片段 → {video_path}")
    return entry_ids


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
    ASR 转写（带时间戳分段）
    当前返回空列表表示 ASR 不可用，使用构造的静态分段
    """
    # TODO: 生产环境接入腾讯云/通义千问 ASR API
    # 当前用构造的演示分段
    logger.info(f"ASR 未配置，使用静态分段（每分钟一段）")

    # 获取音频时长（秒）
    try:
        result = subprocess.run(
            ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
             "-of", "csv=p=0", audio_path],
            capture_output=True, text=True, timeout=10,
        )
        duration = float(result.stdout.strip())
    except Exception:
        duration = 60

    # 每分钟一段
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


async def _create_single_entry(
    title: str, content: str, category_id: int, knowledge_base: str,
    source_person: str, source_dept: str, tags: str,
    file_path: str = "", content_type: str = "video",
) -> list[int]:
    """创建单条知识条目（无音频或无分段时）"""
    async with async_session() as db:
        entry = KnowledgeEntry(
            title=title,
            content=content or f"视频文件：{Path(file_path).name}",
            content_type=content_type,
            category_id=category_id,
            knowledge_base=knowledge_base,
            source_type=SourceTypeEnum.video,
            source_file_path=file_path,
            source_person=source_person or "系统导入",
            source_dept=source_dept,
            media_url=f"/uploads/{Path(file_path).name}" if file_path else None,
            tags=tags,
            status=EntryStatusEnum.approved,
        )
        db.add(entry)
        await db.commit()
        await db.refresh(entry)
        return [entry.id]
