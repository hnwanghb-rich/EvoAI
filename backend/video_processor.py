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
import re
import asyncio
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

# ═══════════════════════════════════════════════════════════════
# ffmpeg/ffprobe 智能查找（Windows 兼容）
# ═══════════════════════════════════════════════════════════════

_FFMPEG_PATH = None
_FFPROBE_PATH = None


def _find_ffmpeg() -> str | None:
    """查找 ffmpeg 可执行文件：先 PATH，再 winget 常见安装目录"""
    global _FFMPEG_PATH
    if _FFMPEG_PATH:
        return _FFMPEG_PATH
    _FFMPEG_PATH = _which("ffmpeg")
    if _FFMPEG_PATH:
        return _FFMPEG_PATH
    for candidate in _winget_search("ffmpeg.exe"):
        _FFMPEG_PATH = candidate
        logger.info(f"找到 ffmpeg: {_FFMPEG_PATH}")
        return _FFMPEG_PATH
    logger.error("ffmpeg 未找到！请安装 ffmpeg: winget install BtbN.FFmpeg.GPL.8.1")
    return None


def _find_ffprobe() -> str | None:
    """查找 ffprobe 可执行文件"""
    global _FFPROBE_PATH
    if _FFPROBE_PATH:
        return _FFPROBE_PATH
    _FFPROBE_PATH = _which("ffprobe")
    if _FFPROBE_PATH:
        return _FFPROBE_PATH
    for candidate in _winget_search("ffprobe.exe"):
        _FFPROBE_PATH = candidate
        logger.info(f"找到 ffprobe: {_FFPROBE_PATH}")
        return _FFPROBE_PATH
    logger.error("ffprobe 未找到！请安装 ffmpeg: winget install BtbN.FFmpeg.GPL.8.1")
    return None


def _which(cmd: str) -> str | None:
    """跨平台 which"""
    import shutil
    result = shutil.which(cmd)
    if result:
        if os.path.islink(result) or os.path.isfile(result):
            return os.path.abspath(result)
    return None


def _winget_search(pattern: str) -> list[str]:
    """在 winget 包目录下搜索可执行文件"""
    results = []
    packages_root = os.path.join(os.environ.get("LOCALAPPDATA", ""),
                                 "Microsoft", "WinGet", "Packages")
    if not os.path.isdir(packages_root):
        return results
    for f_name in os.listdir(packages_root):
        if "FFmpeg" not in f_name and "ffmpeg" not in f_name.lower():
            continue
        base = os.path.join(packages_root, f_name)
        if not os.path.isdir(base):
            continue
        for root, _dirs, files in os.walk(base):
            for f in files:
                if f.lower() == pattern.lower():
                    results.append(os.path.join(root, f))
            if results:
                break
    return results


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

    # 1. 提取音频 → 临时 MP3 文件（异步非阻塞）
    audio_path = os.path.join(tempfile.gettempdir(), f"vocal_{uuid.uuid4().hex[:8]}.mp3")
    try:
        await _extract_audio_async(video_path, audio_path)
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
    """ffmpeg 提取音频 → 16kHz 单声道 WAV（同步版，兼容旧调用）"""
    _run_ffmpeg_sync(video_path, output_wav)


async def _extract_audio_async(
    video_path: str,
    output_path: str,
    on_progress=None,
) -> None:
    """
    ffmpeg 提取音频 → MP3 (libmp3lame) 异步非阻塞版。
    使用线程池运行 ffmpeg，通过队列回调进度（兼容 Windows ProactorEventLoop）。
    """
    ffmpeg = _find_ffmpeg()
    if not ffmpeg:
        raise RuntimeError("ffmpeg 未安装，无法提取音频。请执行: winget install BtbN.FFmpeg.GPL.8.1")

    # 先异步获取视频时长（使用线程池 ffprobe）
    vid_dur = await _get_audio_duration(video_path)

    cmd = [
        ffmpeg, "-i", video_path,
        "-vn", "-acodec", "libmp3lame",
        "-ar", "16000", "-ac", "1", "-b:a", "64k",
        "-y", output_path,
    ]

    import queue
    import threading

    progress_q: queue.Queue = queue.Queue()

    def _run_ffmpeg_thread():
        """在独立线程中运行 ffmpeg，解析 stderr 上报进度"""
        try:
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=False,
            )
            last_pct = 0
            # 读取 stderr 直到进程结束
            for line_bytes in proc.stderr:
                line = line_bytes.decode("utf-8", errors="ignore")
                tm = re.search(r"time=(\d+):(\d+):(\d+\.\d+)", line)
                if tm and vid_dur > 0 and on_progress:
                    secs = int(tm.group(1)) * 3600 + int(tm.group(2)) * 60 + float(tm.group(3))
                    pct = min(int(secs / vid_dur * 100), 99)
                    if pct > last_pct + 4:
                        last_pct = pct
                        progress_q.put(("progress", pct, f"正在提取音频... {pct}%"))
            proc.wait()
            if proc.returncode != 0:
                progress_q.put(("error", proc.returncode, f"ffmpeg exit code {proc.returncode}"))
            else:
                progress_q.put(("done", 100, "音频提取完成 ✓"))
        except FileNotFoundError:
            progress_q.put(("error", -1, f"找不到 ffmpeg: {ffmpeg}"))
        except Exception as e:
            progress_q.put(("error", -1, str(e)))

    loop = asyncio.get_running_loop()
    thread = threading.Thread(target=_run_ffmpeg_thread, daemon=True)
    thread.start()

    # 轮询线程进度队列
    while thread.is_alive() or not progress_q.empty():
        try:
            msg = progress_q.get(timeout=0.3)
            status = msg[0]
            if status == "progress":
                _, pct, detail = msg
                if on_progress:
                    on_progress(pct, detail)
            elif status == "done":
                _, pct, detail = msg
                if on_progress:
                    on_progress(pct, detail)
                logger.info(f"音频提取完成: {output_path}")
                return
            elif status == "error":
                _, code, detail = msg
                raise subprocess.CalledProcessError(code, cmd, output=detail)
        except queue.Empty:
            await asyncio.sleep(0.3)

    thread.join()
    logger.info(f"音频提取完成: {output_path}")


def _run_ffmpeg_sync(video_path: str, output_path: str):
    """同步 ffmpeg 提取 WAV（旧接口兼容）"""
    ffmpeg = _find_ffmpeg()
    if not ffmpeg:
        raise RuntimeError("ffmpeg 未安装")
    cmd = [
        ffmpeg, "-i", video_path,
        "-vn", "-acodec", "pcm_s16le",
        "-ar", "16000", "-ac", "1",
        "-y", output_path,
    ]
    subprocess.run(cmd, capture_output=True, timeout=300, check=True)
    logger.info(f"音频提取完成: {output_path}")


async def _transcribe_with_timestamps(audio_path: str) -> list[dict]:
    """
    ASR 统一转写入口 —— 系统配置的引擎优先，失败自动回退 Whisper
    返回: [{"start": float, "end": float, "text": str}, ...] 或空列表(兜底)
    """
    from asr import get_active_asr_provider
    provider = await get_active_asr_provider()
    logger.info(f"ASR 引擎配置: {provider}")

    # 腾讯云模式：先试腾讯云，失败自动回退本地 Whisper
    if provider == "tencent":
        try:
            result = await _transcribe_tencent(audio_path)
            if result:
                logger.info(f"腾讯云 ASR: {len(result)} 段")
                return result
            logger.warning("腾讯云 ASR 返回空（密钥无效或API失败），回退到本地 Whisper")
        except Exception as e:
            logger.warning(f"腾讯云 ASR 异常: {e}，回退到本地 Whisper")

        # 自动回退
        try:
            result = await _transcribe_local_whisper(audio_path)
            if result:
                logger.info(f"Whisper 回退成功: {len(result)} 段")
                return result
        except Exception as e:
            logger.warning(f"Whisper 回退也失败: {e}")

    # Whisper 模式
    if provider == "whisper":
        try:
            result = await _transcribe_local_whisper(audio_path)
            if result:
                logger.info(f"本地 Whisper: {len(result)} 段")
                return result
        except Exception as e:
            logger.warning(f"Whisper 失败: {e}")

    logger.warning("所有 ASR 均不可用，回退到静态分段(pending)")
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
# 本地 faster-whisper 转写（离线 · 免费 · CPU）
# ═══════════════════════════════════════════════════════════════

_LOCAL_WHISPER_MODEL = None


def _get_local_whisper():
    """懒加载 faster-whisper 模型（首次调用自动下载 ~500MB）"""
    global _LOCAL_WHISPER_MODEL
    if _LOCAL_WHISPER_MODEL is None:
        from faster_whisper import WhisperModel
        # small 模型：中文识别精度好，CPU 上约 0.3x 实时（1分钟音频≈20秒转写）
        logger.info("正在加载本地 Whisper 模型 (small)... 首次使用会自动下载 (~500MB)")
        _LOCAL_WHISPER_MODEL = WhisperModel("small", device="cpu", compute_type="int8")
        logger.info("本地 Whisper 模型加载完成")
    return _LOCAL_WHISPER_MODEL


async def _transcribe_local_whisper(audio_path: str) -> list[dict] | None:
    """用本地 faster-whisper 离线转写，带时间戳"""
    try:
        model = await asyncio.to_thread(_get_local_whisper)
        # 在线程池中执行转写（避免阻塞事件循环）
        segments = await asyncio.to_thread(
            _run_local_whisper, model, audio_path
        )
        return segments if segments else None
    except FileNotFoundError:
        logger.warning("本地 Whisper 模型文件未找到")
        return None
    except Exception as e:
        logger.warning(f"本地 Whisper 转写异常: {type(e).__name__}: {e}")
        return None


def _run_local_whisper(model, audio_path: str) -> list[dict]:
    """同步执行转写，在线程中运行"""
    segments_out = []
    # beam_size=3 精度更高，vad_filter=True 自动跳过静音
    gen_segments, info = model.transcribe(
        audio_path,
        beam_size=3,
        vad_filter=True,
        language="zh",
    )
    logger.info(f"本地 Whisper 检测语言: {info.language} (概率 {info.language_probability:.2f})")
    for seg in gen_segments:
        text = seg.text.strip()
        if text:
            segments_out.append({
                "start": round(seg.start, 2),
                "end": round(seg.end, 2),
                "text": text,
            })
    return segments_out


# ═══════════════════════════════════════════════════════════════
# 腾讯云 ASR 转写
# ═══════════════════════════════════════════════════════════════

async def _transcribe_tencent(audio_path: str) -> list[dict] | None:
    """腾讯云语音识别 —— 调用 asr.py 模块"""
    from asr import transcribe_audio
    segments = await transcribe_audio(audio_path)
    if segments:
        return segments
    return None


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


async def _get_duration_async(file_path: str) -> float:
    """异步获取音/视频时长（秒），使用线程池运行 ffprobe 避免阻塞事件循环"""
    ffprobe = _find_ffprobe()
    if not ffprobe:
        logger.warning("ffprobe 不可用，使用默认时长 60s")
        return 60.0
    log_msg = f"ffprobe [{ffprobe}] -> {file_path}"
    try:
        stdout = await asyncio.to_thread(
            _run_ffprobe_sync, ffprobe, file_path
        )
        val = stdout.strip()
        dur = float(val) if val else 60.0
        logger.info(f"{log_msg} => {dur:.1f}s")
        return dur if dur > 0 else 60.0
    except Exception as e:
        logger.warning(f"ffprobe 失败 ({type(e).__name__}: {e})")
        return 60.0


def _run_ffprobe_sync(ffprobe_path: str, file_path: str) -> str:
    """同步运行 ffprobe 获取时长"""
    result = subprocess.run(
        [ffprobe_path, "-v", "quiet", "-show_entries", "format=duration",
         "-of", "csv=p=0", file_path],
        capture_output=True, text=True, timeout=15,
    )
    result.check_returncode()
    return result.stdout


async def _get_audio_duration(audio_path: str) -> float:
    """获取音频时长（秒）—— 异步版本"""
    return await _get_duration_async(audio_path)


async def _get_video_duration(video_path: str) -> float:
    """获取视频时长（秒）—— 异步版本"""
    return await _get_duration_async(video_path)


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
