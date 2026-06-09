# 合群汽车集团 AI+业务能力知识库

> 基于 FastAPI + Vue 3 + PostgreSQL 16 + Redis 的企业知识管理系统

## 快速开始

### 前置条件
- Docker 29+ & Docker Compose v5+
- (开发环境) Python 3.12+, Node.js 24+, PostgreSQL 16+

### 一键部署

```bash
# 1. 克隆项目
cd D:\HqEvoAI

# 2. 配置环境变量（生产环境务必修改密钥）
cp .env .env.production
nano .env.production  # 修改 JWT_SECRET, LLM_ENCRYPTION_KEY

# 3. 启动全部服务
docker compose up -d

# 4. 查看状态
docker compose ps
docker compose logs -f api

# 5. 访问系统
# 浏览器打开 http://localhost:8000
# API 文档: http://localhost:8000/docs
```

### 开发环境

```bash
# 终端1: 启动 PostgreSQL + Redis
docker compose up -d postgres redis

# 终端2: 后端
cd backend
pip install -r requirements.txt
python -m uvicorn main:app --reload --port 8000

# 终端3: 前端
cd frontend
npm install
npm run dev
# 打开 http://localhost:5173
```

## 项目结构

```
HqEvoAI/
├── docker-compose.yml      # Docker Compose 编排
├── nginx.conf              # Nginx 反向代理（生产）
├── .env                    # 环境变量模板
├── README.md
├── backend/
│   ├── main.py             # FastAPI 入口
│   ├── config.py           # 配置中心
│   ├── database.py         # 数据库连接
│   ├── models.py           # ORM 模型 (14张表)
│   ├── schemas.py          # Pydantic 模型
│   ├── auth.py             # JWT + 权限
│   ├── cache.py            # Redis 缓存
│   ├── rate_limit.py       # 限流中间件
│   ├── retrieval.py        # 混合检索 (tsvector+ILIKE)
│   ├── recommendation.py   # 个性化推荐引擎
│   ├── video_processor.py  # 视频处理
│   ├── import_data.py      # 批量导入工具
│   ├── logger.py           # 日志配置
│   ├── seed_data.py        # 种子数据
│   ├── Dockerfile          # 多阶段构建
│   ├── sql/init.sql        # 数据库初始化 SQL
│   └── routers/            # API 路由 (14模块)
├── frontend/
│   └── src/                # Vue 3 源码
└── uploads/                # 上传文件目录
```

## 默认测试账号

| 用户名 | 密码 | 角色 | 可见知识库 |
|--------|------|------|-----------|
| boss | hequn123 | 老板 | 全部 |
| admin | hequn123 | 管理员 | 全部 |
| sales01 | hequn123 | 销售职员 | 公共+销售 |
| tech01 | hequn123 | 技术技师 | 公共+技术 |
| service01 | hequn123 | 客服专员 | 公共+客服 |

## 技术栈

| 层级 | 选型 |
|------|------|
| 后端 | FastAPI (Python 3.12+) |
| 前端 | Vue 3 + Vite |
| 数据库 | PostgreSQL 16 + pgvector |
| 缓存 | Redis 7 |
| 检索引擎 | tsvector + ILIKE 中文降级 |
| 部署 | Docker Compose (+ Nginx 可选) |

## 容器清单

| 容器 | 端口 | 持久化 |
|------|------|--------|
| hqevoai-pg | 5432 | pgdata volume |
| hqevoai-redis | 6379 | redisdata volume |
| hqevoai-api | 8000 | uploads + logs volumes |
| hqevoai-nginx (可选) | 80/443 | - |

## 关键链接

- API 文档: http://localhost:8000/docs
- 健康检查: http://localhost:8000/api/health
- 日志目录: `backend/logs/`
- LLM 配置: 管理员登录 → LLM 模型配置

## 安全建议

1. 生产环境务必修改 `JWT_SECRET` 和 `LLM_ENCRYPTION_KEY`
2. 建议启用 Nginx 反向代理（`docker compose --profile production up -d`）
3. 定期备份 `pgdata` 和 `uploads` 两个卷
4. API Key 使用 AES-256 加密存储

## License

内部项目 — 合群汽车集团 IT 部
