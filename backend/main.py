"""FastAPI 入口 —— 应用工厂 + CORS + 全局异常 + 健康检查"""
import logging
import os
from contextlib import asynccontextmanager

# 抑制 passlib bcrypt 版本警告（不影响功能）
os.environ.setdefault("PASSLIB_BUILTIN_BCRYPT_BACKEND_WARNINGS", "none")

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from config import UPLOAD_DIR

# 初始化日志（必须在其他模块之前）
from logger import setup_logging, audit
setup_logging()
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期：启动时初始化，关闭时清理"""
    logger.info("=" * 50)
    logger.info("合群汽车AI+业务能力知识库 启动中...")
    logger.info("=" * 50)
    try:
        from database import init_db
        await init_db()
        from seed_data import seed_all
        await seed_all()
    except Exception:
        logger.warning("数据库初始化失败（可能PG未启动），跳过自动建表和种子数据")
    yield
    logger.info("应用关闭")
    try:
        from database import engine
        await engine.dispose()
    except Exception:
        pass


app = FastAPI(
    title="合群汽车AI+业务能力知识库",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 限流中间件
from rate_limit import RateLimitMiddleware
app.add_middleware(RateLimitMiddleware)

# 静态文件
import os
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# 生产环境：前端静态文件（放在所有路由之后挂载）


# ============================================================
# 全局异常处理器（统一错误格式）
# ============================================================

@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """401/403/404 等 HTTP 异常 —— 统一格式"""
    logger.warning(f"HTTP {exc.status_code}: {exc.detail} | {request.method} {request.url.path}")
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "code": exc.status_code,
            "data": None,
            "msg": exc.detail if isinstance(exc.detail, str) else str(exc.detail),
        },
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """422 参数校验失败"""
    details = []
    for err in exc.errors():
        details.append(f"{'.'.join(str(loc) for loc in err['loc'])}: {err['msg']}")
    msg = "; ".join(details[:3])
    logger.warning(f"参数校验失败: {msg} | {request.method} {request.url.path}")
    return JSONResponse(
        status_code=422,
        content={
            "code": 422,
            "data": {"errors": exc.errors()},
            "msg": f"参数校验失败: {msg}",
        },
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """500 服务器内部错误"""
    logger.error(f"未捕获异常: {type(exc).__name__}: {exc} | {request.method} {request.url.path}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "code": 500,
            "data": None,
            "msg": "服务器内部错误，请稍后重试" if not __debug__ else str(exc)[:200],
        },
    )


@app.get("/api/health")
async def health_check():
    """健康检查"""
    return {"code": 0, "data": "ok", "msg": "健康"}


# ============================================================
# 注册路由
# ============================================================

from routers.users import router as users_router
from routers.categories import router as categories_router
from routers.knowledge import router as knowledge_router
from routers.review import router as review_router
from routers.upload import router as upload_router
from routers.learning import router as learning_router
from routers.dashboard import router as dashboard_router
app.include_router(users_router, prefix="/api")
app.include_router(categories_router, prefix="/api")
app.include_router(knowledge_router, prefix="/api")
app.include_router(review_router, prefix="/api")
app.include_router(upload_router, prefix="/api")
app.include_router(learning_router, prefix="/api")
app.include_router(dashboard_router, prefix="/api")
from routers.questions import router as questions_router
app.include_router(questions_router, prefix="/api")
from routers.chat import router as chat_router
app.include_router(chat_router, prefix="/api")
from routers.llm import router as llm_router
app.include_router(llm_router, prefix="/api")
from routers.settings import router as settings_router
app.include_router(settings_router, prefix="/api")
from routers.logs import router as logs_router
app.include_router(logs_router, prefix="/api")
from routers.voice import router as voice_router
app.include_router(voice_router, prefix="/api")

# 生产环境：挂载前端静态文件（必须在所有 API 路由之后）
STATIC_DIR = os.path.join(os.path.dirname(__file__), "static")
if os.path.isdir(STATIC_DIR) and os.path.isfile(os.path.join(STATIC_DIR, "index.html")):
    app.mount("/", StaticFiles(directory=STATIC_DIR, html=True), name="static")
    logger.info(f"前端静态文件已挂载: {STATIC_DIR}")

if __name__ == "__main__":
    import uvicorn
    from config import SERVER_HOST, SERVER_PORT
    uvicorn.run("main:app", host=SERVER_HOST, port=SERVER_PORT, reload=True)
