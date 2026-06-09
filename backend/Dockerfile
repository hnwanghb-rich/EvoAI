# ============================================================
# 合群汽车AI+业务能力知识库 —— 生产 Dockerfile
# 多阶段构建：前端 build → 后端 + 前端静态文件
# ============================================================

# ---- Stage 1: 前端构建 ----
FROM node:24-alpine AS frontend-builder

WORKDIR /frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci --production=false

COPY frontend/ ./
RUN npm run build

# ---- Stage 2: 后端运行 ----
FROM python:3.12-slim

WORKDIR /app

# 系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Python 依赖
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制后端源码
COPY backend/ .

# 从前端构建阶段复制 dist 静态文件
COPY --from=frontend-builder /frontend/dist /app/static

# 创建必要目录
RUN mkdir -p /app/uploads /app/logs

# 服务端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/api/health')" || exit 1

# 启动 (4 workers)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
