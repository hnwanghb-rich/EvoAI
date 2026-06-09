"""
数据库连接 —— SQLAlchemy 2.0 async engine + async session
"""
import logging

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from config import DATABASE_URL, DEBUG

logger = logging.getLogger(__name__)

engine = create_async_engine(
    DATABASE_URL,
    echo=DEBUG,
    pool_size=20,
    max_overflow=40,
    pool_pre_ping=True,
)

async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    """SQLAlchemy ORM 基类"""
    pass


async def get_db() -> AsyncSession:
    """FastAPI 依赖注入 —— 获取数据库会话"""
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    """
    初始化数据库：
    1. Docker 环境下 init.sql 由 docker-entrypoint-initdb.d 自动执行
    2. 本地开发手动执行: psql -U postgres -d hqevoai -f backend/sql/init.sql
    3. ORM create_all(checkfirst=True) 作为兜底兼容
    """
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all, checkfirst=True)
            logger.info("ORM 表检查完成")
    except Exception as e:
        logger.warning(f"ORM create_all 异常（可忽略，init.sql 已建表）: {e}")
