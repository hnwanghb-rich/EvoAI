"""
Redis 滑动窗口限流
策略：全局 100次/min/IP / 登录 10次/min/IP / AI对话 30次/min/用户
"""
import time
import logging
from typing import Optional

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

from cache import get_redis

logger = logging.getLogger(__name__)

# 限流规则：路径前缀 → (窗口秒数, 最大请求数, key来源)
RATE_LIMITS = {
    "/api/auth/login": (60, 10, "ip"),          # 登录: 10次/min/IP
    "/api/chat/ask": (60, 30, "user"),           # AI对话: 30次/min/用户
    "/api/": (60, 200, "ip"),                    # 全局: 200次/min/IP
}

DEFAULT_LIMIT = (60, 200, "ip")  # 默认规则


class RateLimitMiddleware(BaseHTTPMiddleware):
    """滑动窗口限流中间件"""

    async def dispatch(self, request: Request, call_next):
        # 查找匹配的限流规则
        path = request.url.path
        rule = DEFAULT_LIMIT
        for prefix, r in RATE_LIMITS.items():
            if path.startswith(prefix):
                rule = r
                break

        window_sec, max_req, key_type = rule

        # 确定限流 key
        if key_type == "ip":
            client_ip = request.client.host if request.client else "unknown"
            rate_key = f"rate:{path}:{client_ip}"
        elif key_type == "user":
            # 尝试从 Authorization header 提取 user_id
            auth = request.headers.get("Authorization", "")
            uid = "anon"
            if auth.startswith("Bearer "):
                try:
                    from jose import jwt
                    from config import JWT_SECRET
                    payload = jwt.decode(auth[7:], JWT_SECRET, algorithms=["HS256"])
                    uid = str(payload.get("user_id", "anon"))
                except Exception:
                    pass
            rate_key = f"rate:{path}:user:{uid}"
        else:
            rate_key = f"rate:{path}:global"

        # Redis 限流检查
        r = await get_redis()
        if r:
            try:
                now = time.time()
                window_start = now - window_sec

                # 滑动窗口: 移除窗口外的记录 + 计数
                pipe = r.pipeline()
                pipe.zremrangebyscore(rate_key, 0, window_start)
                pipe.zcard(rate_key)
                pipe.zadd(rate_key, {str(now): now})
                pipe.expire(rate_key, window_sec + 5)
                _, count, _, _ = await pipe.execute()

                if count >= max_req:
                    logger.warning(f"限流触发: {rate_key} count={count}/{max_req}")
                    return JSONResponse(
                        status_code=429,
                        content={
                            "code": 429,
                            "data": None,
                            "msg": f"请求过于频繁，请稍后再试（{window_sec}秒内最多{max_req}次）",
                        },
                    )
            except Exception as e:
                logger.warning(f"限流检查异常（放行）: {e}")
                pass  # Redis 不可用时放行

        response = await call_next(request)
        return response
