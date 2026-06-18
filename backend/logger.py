"""
统一日志配置 —— INFO→控制台 + 文件轮转, ERROR→单独文件
"""
import os
import logging
import logging.handlers
from pathlib import Path

# 日志目录
LOG_DIR = Path(__file__).parent / "logs"
LOG_DIR.mkdir(exist_ok=True)

# 格式
FORMAT = "%(asctime)s | %(levelname)-7s | %(name)s | %(message)s"
formatter = logging.Formatter(FORMAT, datefmt="%Y-%m-%d %H:%M:%S")


class SafeTimedRotatingFileHandler(logging.handlers.TimedRotatingFileHandler):
    """Windows 多进程（reload / 多 workers）下，午夜轮转执行 os.rename 时，
    日志文件常被其他进程占用而抛 PermissionError([WinError 32])，导致 logging
    模块向 stderr 刷错误栈。此处静默跳过本次轮转——继续写入当前文件，下次轮转
    时再试。日志内容不丢失，仅当天文件可能不切分。"""

    def rotate(self, source, dest):
        try:
            super().rotate(source, dest)
        except (PermissionError, OSError):
            # 文件被占用，跳过本次轮转，保持写入当前文件
            pass


def setup_logging(app_name: str = "hqevoai"):
    """初始化全局日志配置"""
    root = logging.getLogger()
    root.setLevel(logging.INFO)

    # 清除已有 handler（避免重复）
    root.handlers.clear()

    # 1. 控制台 INFO
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    console.setFormatter(formatter)
    root.addHandler(console)

    # 2. 全部日志文件（INFO+，按天轮转，保留30天）
    info_file = LOG_DIR / f"{app_name}.log"
    file_handler = SafeTimedRotatingFileHandler(
        info_file, when="midnight", interval=1, backupCount=30, encoding="utf-8"
    )
    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(formatter)
    root.addHandler(file_handler)

    # 3. 错误日志单独文件（ERROR+，按天轮转，保留90天）
    error_file = LOG_DIR / f"{app_name}_error.log"
    error_handler = SafeTimedRotatingFileHandler(
        error_file, when="midnight", interval=1, backupCount=90, encoding="utf-8"
    )
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(formatter)
    root.addHandler(error_handler)

    # 4. 审计日志文件（INFO+，永久保留）
    audit_file = LOG_DIR / f"{app_name}_audit.log"
    audit_handler = SafeTimedRotatingFileHandler(
        audit_file, when="midnight", interval=1, backupCount=365, encoding="utf-8"
    )
    audit_handler.setLevel(logging.INFO)
    audit_handler.setFormatter(formatter)
    audit_logger = logging.getLogger("audit")
    audit_logger.propagate = False
    audit_logger.addHandler(audit_handler)

    # 抑制第三方库日志
    logging.getLogger("sqlalchemy").setLevel(logging.WARNING)
    logging.getLogger("asyncpg").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)

    return root


# 应用启动时调用
logger = setup_logging()
audit = logging.getLogger("audit")
