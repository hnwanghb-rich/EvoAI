"""
Redis 缓存层 —— 装饰器 + 手动缓存工具
热点数据缓存策略：热门知识 10min / 首页数据 5min / 排行榜 30min / 分类树 1h
"""
import json
import logging
import functools
from typing import Any, Callable, Optional

import redis.asyncio as aioredis

from config import REDIS_URL

logger = logging.getLogger(__name__)

# Redis 连接（延迟初始化）
_pool: Optional[aioredis.Redis] = None


async def get_redis() -> Optional[aioredis.Redis]:
    """获取 Redis 连接（不可用时返回 None）"""
    global _pool
    if _pool is not None:
        return _pool
    try:
        _pool = aioredis.from_url(REDIS_URL, decode_responses=True)
        await _pool.ping()
        logger.info("Redis 连接成功")
        return _pool
    except Exception as e:
        logger.warning(f"Redis 不可用（缓存将跳过）: {e}")
        _pool = None
        return None


async def close_redis():
    """优雅关闭 Redis 连接（防止 Event loop closed 告警）"""
    global _pool
    if _pool is not None:
        try:
            await _pool.aclose()
        except Exception:
            pass
        _pool = None
        logger.info("Redis 连接已关闭")


# ============================================================
# 缓存装饰器
# ============================================================

def cached(ttl_seconds: int = 300, prefix: str = "cache"):
    """
    异步函数返回值缓存装饰器
    用法：
        @cached(ttl_seconds=600, prefix="hot")
        async def get_hot_knowledge():
            ...
    """
    def decorator(func: Callable):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            r = await get_redis()
            if not r:
                return await func(*args, **kwargs)

            # 构造缓存 key
            key_parts = [prefix, func.__name__]
            if args:
                key_parts.append(str(args))
            if kwargs:
                sorted_kwargs = sorted(kwargs.items())
                key_parts.append(str(sorted_kwargs))
            cache_key = ":".join(key_parts)

            # 尝试读缓存
            try:
                cached_val = await r.get(cache_key)
                if cached_val is not None:
                    return json.loads(cached_val)
            except Exception:
                pass

            # 缓存未命中 → 执行函数
            result = await func(*args, **kwargs)

            # 写缓存
            try:
                await r.setex(cache_key, ttl_seconds, json.dumps(result, ensure_ascii=False, default=str))
            except Exception:
                pass

            return result
        return wrapper
    return decorator


# ============================================================
# 手动缓存工具
# ============================================================

async def cache_get(key: str) -> Optional[Any]:
    """从 Redis 读取缓存"""
    r = await get_redis()
    if not r:
        return None
    try:
        val = await r.get(key)
        if val is not None:
            return json.loads(val)
    except Exception:
        pass
    return None


async def cache_set(key: str, value: Any, ttl_seconds: int = 300):
    """写入 Redis 缓存"""
    r = await get_redis()
    if not r:
        return
    try:
        await r.setex(key, ttl_seconds, json.dumps(value, ensure_ascii=False, default=str))
    except Exception:
        pass


async def cache_delete(key: str):
    """删除缓存"""
    r = await get_redis()
    if not r:
        return
    try:
        await r.delete(key)
    except Exception:
        pass


async def cache_delete_pattern(pattern: str):
    """按模式删除缓存（如 "hot:*"）"""
    r = await get_redis()
    if not r:
        return
    try:
        keys = await r.keys(pattern)
        if keys:
            await r.delete(*keys)
    except Exception:
        pass


# ============================================================
# 预设缓存 Key + TTL
# ============================================================

CACHE_KEYS = {
    "hot_knowledge": {"ttl": 600, "desc": "热门知识 TOP10"},
    "latest_knowledge": {"ttl": 300, "desc": "最新知识 TOP10"},
    "categories": {"ttl": 3600, "desc": "分类树"},
    "dashboard_home": {"ttl": 300, "desc": "首页数据（按用户）"},
    "ranking_company": {"ttl": 1800, "desc": "全公司排行"},
    "leaderboard_dept": {"ttl": 1800, "desc": "部门排行"},
}
