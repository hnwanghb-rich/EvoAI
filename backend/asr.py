"""
ASR 语音识别模块 —— 统一入口，根据系统配置选择引擎
支持：tencent（腾讯云）/ whisper（本地 faster-whisper）
"""
import os
import uuid
import json
import time
import hmac
import hashlib
import base64
import logging
import httpx
from datetime import datetime

logger = logging.getLogger(__name__)

# 运行时缓存
_cached_secret_id: str | None = None
_cached_secret_key: str | None = None
_cached_asr_provider: str | None = None  # "tencent" / "whisper"

# 腾讯云 API 配置
ASR_ENDPOINT = "asr.tencentcloudapi.com"
SERVICE = "asr"
VERSION = "2019-06-14"
REGION = "ap-guangzhou"


def reset_asr_cache():
    global _cached_secret_id, _cached_secret_key, _cached_asr_provider
    _cached_secret_id = None
    _cached_secret_key = None
    _cached_asr_provider = None
    logger.info("ASR 缓存已重置")


async def _load_keys_from_db():
    """仅从 system_config 表读取密钥，不读 .env"""
    global _cached_secret_id, _cached_secret_key
    # 缓存为空字符串时也视为未初始化，重新查 DB
    if _cached_secret_id and _cached_secret_key:
        return _cached_secret_id, _cached_secret_key
    try:
        from database import async_session
        from sqlalchemy import text
        import base64 as _b64
        from cryptography.fernet import Fernet
        from config import LLM_ENCRYPTION_KEY

        k = LLM_ENCRYPTION_KEY.encode()
        d = hashlib.sha256(k).digest()
        b = _b64.urlsafe_b64encode(d)
        f = Fernet(b)

        async with async_session() as db:
            r = await db.execute(text(
                "SELECT config_key, config_value FROM system_config "
                "WHERE config_key IN ('asr_secret_id', 'asr_secret_key')"
            ))
            db_id, db_key = "", ""
            for key_name, val in r.fetchall():
                if key_name == "asr_secret_id" and val:
                    try: db_id = f.decrypt(val.encode()).decode()
                    except: pass
                elif key_name == "asr_secret_key" and val:
                    try: db_key = f.decrypt(val.encode()).decode()
                    except: pass
            _cached_secret_id = db_id or ""
            _cached_secret_key = db_key or ""
            if db_id and db_key:
                logger.info("ASR 密钥已从 DB 加载")
                return db_id, db_key
            logger.info("ASR 密钥未在 DB 配置")
    except Exception as e:
        logger.warning(f"从DB读ASR密钥失败: {e}")
    _cached_secret_id = ""
    _cached_secret_key = ""
    return "", ""


async def get_active_asr_provider() -> str:
    """获取当前选择的 ASR 引擎: 'tencent' 或 'whisper'"""
    global _cached_asr_provider
    if _cached_asr_provider is not None:
        return _cached_asr_provider
    try:
        from database import async_session
        from sqlalchemy import text
        async with async_session() as db:
            r = await db.execute(text("SELECT config_value FROM system_config WHERE config_key='asr_provider'"))
            val = r.scalar_one_or_none()
            _cached_asr_provider = val if val in ("tencent", "whisper") else "whisper"
    except Exception:
        _cached_asr_provider = "whisper"
    return _cached_asr_provider


def get_tencent_keys() -> tuple[str, str]:
    """同步获取缓存的密钥"""
    import asyncio
    if _cached_secret_id is None:
        try:
            asyncio.get_event_loop().run_until_complete(_load_keys_from_db())
        except Exception:
            return "", ""
    return _cached_secret_id or "", _cached_secret_key or ""


def _tc3_sign(method: str, action: str, payload: dict, secret_id: str = "", secret_key: str = "") -> dict:
    """腾讯云 API V3 签名"""
    if not secret_id or not secret_key:
        raise ValueError("secret_id and secret_key are required")
    timestamp = int(time.time())
    date_str = datetime.fromtimestamp(timestamp, tz=__import__("datetime").timezone.utc).strftime("%Y-%m-%d")
    ct = "application/json; charset=utf-8"
    payload_bytes = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
    logger.debug(f"TC3 sign: timestamp={timestamp} date={date_str} action={action} body_len={len(payload_bytes)}")
    hashed_payload = hashlib.sha256(payload_bytes).hexdigest()

    canonical_headers = f"content-type:{ct}\nhost:{ASR_ENDPOINT}\nx-tc-action:{action.lower()}\n"
    signed_headers = "content-type;host;x-tc-action"
    canonical_request = f"{method}\n/\n\n{canonical_headers}\n{signed_headers}\n{hashed_payload}"

    algorithm = "TC3-HMAC-SHA256"
    credential_scope = f"{date_str}/{SERVICE}/tc3_request"
    hashed_canonical = hashlib.sha256(canonical_request.encode("utf-8")).hexdigest()
    string_to_sign = f"{algorithm}\n{timestamp}\n{credential_scope}\n{hashed_canonical}"

    def _sign(key_bytes, msg):
        return hmac.new(key_bytes, msg.encode("utf-8"), hashlib.sha256).digest()

    secret_date = _sign(("TC3" + secret_key).encode(), date_str)
    secret_service = _sign(secret_date, SERVICE)
    secret_signing = _sign(secret_service, "tc3_request")
    signature = hmac.new(secret_signing, string_to_sign.encode("utf-8"), hashlib.sha256).hexdigest()

    authorization = (
        f"{algorithm} "
        f"Credential={secret_id}/{credential_scope}, "
        f"SignedHeaders={signed_headers}, "
        f"Signature={signature}"
    )
    return {
        "Authorization": authorization,
        "Content-Type": ct,
        "Host": ASR_ENDPOINT,
        "X-TC-Action": action,
        "X-TC-Timestamp": str(timestamp),
        "X-TC-Version": VERSION,
        "X-TC-Region": REGION,
    }, payload_bytes


async def sentence_recognition(audio_path: str, engine_type: str = "16k_zh") -> str:
    """一句话识别（≤60秒短音频）"""
    sid, skey = await _load_keys_from_db()
    if not sid or not skey:
        return ""

    with open(audio_path, "rb") as f:
        audio_data = f.read()
    if len(audio_data) > 6 * 1024 * 1024:
        audio_data = audio_data[:6 * 1024 * 1024]

    audio_base64 = base64.b64encode(audio_data).decode("utf-8")
    fmt = os.path.splitext(audio_path)[1].replace(".", "")
    if fmt not in ("wav", "pcm", "mp3", "amr", "silk", "m4a", "ogg", "opus"):
        fmt = "wav"
    payload = {
        "Data": audio_base64,
        "DataLen": len(audio_data),
        "EngSerViceType": engine_type,
        "SourceType": 1,
        "VoiceFormat": fmt,
    }
    headers, body_bytes = _tc3_sign("POST", "SentenceRecognition", payload, sid, skey)
    logger.info(f"ASR payload keys: {list(payload.keys())}")
    logger.info(f"ASR body len: {len(body_bytes)}, DataLen: {payload.get('DataLen')}")

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                f"https://{ASR_ENDPOINT}/",
                headers=headers,
                content=body_bytes,
            )
            resp.raise_for_status()
            result = resp.json()
            if "Response" in result:
                err = result["Response"].get("Error")
                if err:
                    logger.warning(f"腾讯云ASR错误: {err.get('Code')} - {err.get('Message')}")
                    return ""
                return result["Response"].get("Result", "")
    except Exception as e:
        logger.warning(f"腾讯云ASR调用失败: {e}")
    return ""


async def create_rec_task(audio_url: str, engine_type: str = "16k_zh") -> int | None:
    """录音文件识别（长音频 ≤5小时）"""
    sid, skey = await _load_keys_from_db()
    if not sid or not skey:
        return None
    payload = {
        "EngineModelType": engine_type,
        "ChannelNum": 1,
        "ResTextFormat": 3,
        "SourceType": 0,
        "Url": audio_url,
    }
    headers, body_bytes = _tc3_sign("POST", "CreateRecTask", payload, sid, skey)
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(f"https://{ASR_ENDPOINT}/", headers=headers, content=body_bytes)
            resp.raise_for_status()
            result = resp.json()
            if "Response" in result:
                if "Error" in result["Response"]:
                    logger.warning(f"腾讯云创建任务失败: {result['Response']['Error']}")
                    return None
                return result["Response"]["Data"]["TaskId"]
    except Exception as e:
        logger.warning(f"腾讯云创建任务失败: {e}")
    return None


async def query_rec_task(task_id: int) -> dict | None:
    """查询录音文件识别结果"""
    sid, skey = await _load_keys_from_db()
    if not sid or not skey:
        return None
    headers, body_bytes = _tc3_sign("POST", "DescribeTaskStatus", {"TaskId": task_id}, sid, skey)
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(f"https://{ASR_ENDPOINT}/", headers=headers, content=body_bytes)
            resp.raise_for_status()
            result = resp.json()
            if "Response" not in result:
                return None
            response = result["Response"]
            if "Error" in response:
                return {"status": "failed", "error": response["Error"]}
            status_code = response["Data"]["Status"]
            if status_code in (0, 1):
                return {"status": "waiting"}
            elif status_code == 2:
                detail = response["Data"].get("ResultDetail", [])
                segments = [{
                    "start": int(it.get("StartMs", 0)) / 1000.0,
                    "end": int(it.get("EndMs", 0)) / 1000.0,
                    "text": it.get("FinalSentence", ""),
                } for it in detail]
                return {"status": "success", "segments": segments}
            else:
                return {"status": "failed", "error": f"Status={status_code}"}
    except Exception as e:
        logger.warning(f"查询任务失败: {e}")
        return None


async def transcribe_audio(audio_path: str) -> list[dict]:
    """统一转写入口：短音频一句话识别 / 长音频分段识别"""
    sid, skey = await _load_keys_from_db()
    if not sid or not skey:
        logger.info("ASR 密钥未配置，跳过转写")
        return []

    import subprocess
    try:
        result = subprocess.run(
            ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
             "-of", "csv=p=0", audio_path],
            capture_output=True, text=True, timeout=10,
        )
        duration = float(result.stdout.strip())
    except Exception:
        duration = 60

    if duration <= 60:
        text = await sentence_recognition(audio_path, "16k_zh")
        if text:
            return [{"start": 0, "end": duration, "text": text}]
        return []
    else:
        # 长音频：按60秒分段逐段识别
        import tempfile
        segments = []
        seg_dur = 50
        for start in range(0, int(duration), seg_dur):
            end = min(start + seg_dur, int(duration))
            chunk_path = os.path.join(tempfile.gettempdir(), f"chunk_{start}_{end}.mp3")
            subprocess.run(
                ["ffmpeg", "-i", audio_path, "-ss", str(start), "-t", str(end - start),
                 "-acodec", "libmp3lame", "-ar", "16000", "-ac", "1", "-y", chunk_path],
                capture_output=True, timeout=30,
            )
            text = await sentence_recognition(chunk_path, "16k_zh")
            if text.strip():
                segments.append({"start": start, "end": end, "text": text})
            try: os.remove(chunk_path)
            except: pass
        return segments
import asyncio

_LOCAL_WHISPER_MODEL = None

def _get_local_whisper():
    """懒加载 faster-whisper 模型"""
    global _LOCAL_WHISPER_MODEL
    if _LOCAL_WHISPER_MODEL is None:
        from faster_whisper import WhisperModel
        logger.info("正在加载本地 Whisper 模型 (small)...")
        _LOCAL_WHISPER_MODEL = WhisperModel("small", device="cpu", compute_type="int8")
        logger.info("本地 Whisper 模型加载完成")
    return _LOCAL_WHISPER_MODEL

def _run_local_whisper(model, audio_path: str) -> str:
    """同步执行转写，返回纯文本"""
    segments_out = []
    gen_segments, _ = model.transcribe(audio_path, beam_size=3, vad_filter=True,
        language="zh", initial_prompt="合群汽车集团，销售，技术，客服，维修，保养")
    for seg in gen_segments:
        segments_out.append(seg.text.strip())
    return " ".join(segments_out)

async def transcribe_local(audio_path: str) -> str:
    """用本地 faster-whisper 离线转写，返回纯文本"""
    import subprocess, tempfile
    trans_path = audio_path
    tmp_file = None
    # 浏览器录音 webm/opus → ffmpeg 转 16kHz WAV（Whisper 不认 webm）
    if not audio_path.lower().endswith('.wav'):
        tmp_file = os.path.join(tempfile.gettempdir(), f"asr_{uuid.uuid4().hex}.wav")
        r = subprocess.run(["ffmpeg", "-i", audio_path, "-ar", "16000", "-ac", "1", "-y", tmp_file], capture_output=True, timeout=30)
        if r.returncode == 0 and os.path.getsize(tmp_file) > 0:
            trans_path = tmp_file
    try:
        model = await asyncio.to_thread(_get_local_whisper)
        text = await asyncio.to_thread(_run_local_whisper, model, trans_path)
        return text.strip() if text else ""
    except Exception as e:
        logger.warning(f"Whisper 转写失败: {type(e).__name__}: {e}")
        return ""
    finally:
        if tmp_file:
            try: os.remove(tmp_file)
            except: pass
