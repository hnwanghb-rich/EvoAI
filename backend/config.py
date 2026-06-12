"""
配置中心 —— 所有环境变量读取
"""
import os
from pathlib import Path

# 项目根目录
BASE_DIR = Path(__file__).resolve().parent.parent

# 数据库
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://hqevoai:hqevoai@localhost:5432/hqevoai"
)
DATABASE_URL_SYNC = os.getenv(
    "DATABASE_URL_SYNC",
    "postgresql://hqevoai:hqevoai@localhost:5432/hqevoai"
)

# Redis
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# JWT
JWT_SECRET = os.getenv("JWT_SECRET", "hqevoai-dev-secret-change-in-production")
JWT_EXPIRE_MINUTES = int(os.getenv("JWT_EXPIRE_MINUTES", "480"))  # 8小时

# 文件上传
UPLOAD_DIR = os.getenv("UPLOAD_DIR", str(BASE_DIR / "uploads"))

# LLM API Key 加密
LLM_ENCRYPTION_KEY = os.getenv(
    "LLM_ENCRYPTION_KEY",
    "hqevoai-llm-encryption-key-change-me"
)

# 语音转写
ASR_PROVIDER = os.getenv("ASR_PROVIDER", "tencent")
HF_ENDPOINT = os.getenv("HF_ENDPOINT", "https://hf-mirror.com")
os.environ.setdefault("HF_ENDPOINT", HF_ENDPOINT)  # HuggingFace 国内镜像，本地 Whisper 模型下载用
TENCENT_SECRET_ID = os.getenv("TENCENT_SECRET_ID", "")
TENCENT_SECRET_KEY = os.getenv("TENCENT_SECRET_KEY", "")
TENCENT_ASR_APP_ID = os.getenv("TENCENT_ASR_APP_ID", "")

# 服务端口
SERVER_HOST = os.getenv("SERVER_HOST", "0.0.0.0")
SERVER_PORT = int(os.getenv("SERVER_PORT", "8000"))

# 调试模式
DEBUG = os.getenv("DEBUG", "false").lower() == "true"
