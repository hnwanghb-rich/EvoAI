# 合群汽车集团 AI+业务能力知识库 —— 每日开发任务卡

> 版本：V2.0 | 2026-06-08
> 总工期：23个工作日 | 技术栈：FastAPI + Vue 3 + PostgreSQL 16 + Redis
> 开发原则：最简实现、响应式一体三端、逐日可验收、所有SQL和帮助系统在此任务卡内完整定义

---

## 全局约定

### 技术栈最简落地

| 层级 | 选型 | 原因 |
|------|------|------|
| 后端 | FastAPI (Python 3.12+) | 异步高性能，自动生成API文档 |
| 前端 | Vue 3 + Vite (纯响应式) | 一套代码适配PC/Pad/手机 |
| 数据库 | PostgreSQL 16 | JSON原生支持，全文搜索够用 |
| 缓存 | Redis 7 | 会话 + 热点数据缓存 |
| 检索引擎 | **混合检索**：PostgreSQL `tsvector`(关键词) + `pgvector`(语义向量) + RRF融合排序 | 召回质量优先，不引入独立向量数据库，见附录E |
| LLM | 配置化多模型接入 | 支持国内主流大模型，管理员后台切换 |
| 语音识别 | 对接云端ASR API | 不本地部署Whisper，降复杂度 |
| 文件存储 | 本地 `./uploads/` | 不引入MinIO |
| 部署 | `docker compose up -d` | 3容器：PG + Redis + FastAPI(含Vue) |

### 项目目录结构（Day 1 创建）

```
D:\HqEvoAI\
├── docker-compose.yml
├── .env
├── README.md
├── backend/
│   ├── main.py               # FastAPI入口
│   ├── config.py             # 配置中心
│   ├── database.py           # PG连接 + session
│   ├── models.py             # SQLAlchemy ORM（全部表）
│   ├── schemas.py            # Pydantic模型
│   ├── auth.py               # JWT + 权限
│   ├── cache.py              # Redis缓存
│   ├── rate_limit.py         # API限流
│   ├── logger.py             # 日志
│   ├── seed_data.py          # 种子数据
│   ├── import_data.py        # 批量导入
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── users.py
│   │   ├── knowledge.py
│   │   ├── categories.py
│   │   ├── review.py
│   │   ├── learning.py
│   │   ├── questions.py
│   │   ├── chat.py
│   │   ├── dashboard.py
│   │   ├── upload.py
│   │   ├── voice.py
│   │   ├── llm.py            # LLM模型配置
│   │   ├── settings.py       # 系统设置
│   │   └── logs.py           # 审计日志
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── package.json
│   ├── vite.config.ts
│   ├── index.html
│   ├── public/
│   │   └── banner.svg         # 顶部标题图
│   └── src/
│       ├── main.ts
│       ├── App.vue
│       ├── router.ts
│       ├── helpContent.ts     # 全部页面的帮助文案定义
│       ├── stores/
│       │   ├── auth.ts
│       │   ├── skin.ts
│       │   └── chat.ts
│       ├── styles/
│       │   ├── variables.css
│       │   └── global.css
│       ├── components/
│       │   ├── TopBanner.vue
│       │   ├── SkinSwitcher.vue
│       │   ├── PageHelp.vue         # 页面帮助(?)按钮+弹窗
│       │   ├── SideMenu.vue
│       │   ├── BottomTabs.vue
│       │   ├── RadarChart.vue
│       │   ├── HeatMap.vue
│       │   └── ANengChat.vue
│       └── views/
│           ├── Login.vue
│           ├── Home.vue
│           ├── KnowledgeBase.vue
│           ├── KnowledgeDetail.vue
│           ├── KnowledgeManage.vue
│           ├── ReviewCenter.vue
│           ├── ExperienceSubmit.vue
│           ├── PersonalDashboard.vue
│           ├── TeamDashboard.vue
│           ├── BIBoard.vue
│           ├── LearningCenter.vue
│           ├── QuestionAnswer.vue
│           ├── ExamManage.vue
│           ├── Profile.vue
│           ├── UserManage.vue
│           ├── LLMSettings.vue       # LLM模型配置
│           └── SystemSettings.vue
└── uploads/                   # 上传文件目录
```

### 命名与代码风格

- 后端：Python 类型标注、async/await、函数式
- 前端：Vue 3 `<script setup>` Composition API
- 命名用英文，注释用中文
- 每个视图组件 ≤350行
- 所有API统一返回：`{"code": 0, "data": {...}, "msg": "ok"}`

---

## 附录A：完整数据库建表SQL（Day 2 执行）

以下SQL在 `backend/sql/init.sql` 文件中保存，并在Day 2的models.py中通过 `CREATE TABLE IF NOT EXISTS` 方式，或在 `docker-entrypoint-initdb.d/` 中挂载自动执行。

> **重要**：以下15张表的所有SQL，在Day 2必须全部执行完成。

### A.1 部门表

```sql
CREATE TABLE IF NOT EXISTS departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    parent_id INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (parent_id) REFERENCES departments(id) ON DELETE SET NULL
);
```

### A.2 门店表

```sql
CREATE TABLE IF NOT EXISTS stores (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(300),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### A.3 用户表

```sql
CREATE TYPE user_role_enum AS ENUM ('boss', 'admin', 'staff');
CREATE TYPE user_position_enum AS ENUM ('sales', 'tech', 'service');

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    real_name VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role_enum NOT NULL DEFAULT 'staff',
    position user_position_enum,
    dept_id INT,
    store_id INT,
    phone VARCHAR(20),
    avatar_url VARCHAR(200),
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE SET NULL,
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE SET NULL
);
```

### A.4 知识分类表

```sql
CREATE TYPE knowledge_base_enum AS ENUM ('public', 'sales', 'tech', 'service');

CREATE TABLE IF NOT EXISTS knowledge_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    parent_id INT,
    knowledge_base knowledge_base_enum NOT NULL,
    sort_order INT DEFAULT 0,
    icon VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (parent_id) REFERENCES knowledge_categories(id) ON DELETE SET NULL
);
```

### A.5 知识条目主表

```sql
CREATE TYPE content_type_enum AS ENUM ('text', 'video', 'audio', 'image');
CREATE TYPE source_type_enum AS ENUM ('manual', 'experience', 'exam', 'policy', 'video', 'audio');
CREATE TYPE entry_status_enum AS ENUM ('draft', 'pending', 'approved', 'rejected', 'archived');

CREATE TABLE IF NOT EXISTS knowledge_entries (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL DEFAULT '',
    content_type content_type_enum NOT NULL DEFAULT 'text',
    category_id INT NOT NULL,
    sub_category VARCHAR(50),
    knowledge_base knowledge_base_enum NOT NULL,
    source_type source_type_enum NOT NULL DEFAULT 'manual',
    source_file_path VARCHAR(500),
    source_person VARCHAR(50),
    source_dept VARCHAR(50),
    media_url VARCHAR(500),
    media_start_sec REAL DEFAULT 0,
    media_end_sec REAL DEFAULT 0,
    tags VARCHAR(500),
    car_brand VARCHAR(50),
    car_model VARCHAR(100),
    difficulty_level SMALLINT DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
    view_count INT DEFAULT 0,
    useful_count INT DEFAULT 0,
    status entry_status_enum NOT NULL DEFAULT 'draft',
    auditor_id INT,
    audit_comment VARCHAR(500),
    version INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (category_id) REFERENCES knowledge_categories(id) ON DELETE RESTRICT,
    FOREIGN KEY (auditor_id) REFERENCES users(id) ON DELETE SET NULL
);
```

### A.6 经验积分表

```sql
CREATE TYPE point_action_enum AS ENUM ('submit', 'approved', 'used');

CREATE TABLE IF NOT EXISTS experience_points (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    knowledge_id INT,
    points INT NOT NULL DEFAULT 0,
    action_type point_action_enum NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (knowledge_id) REFERENCES knowledge_entries(id) ON DELETE SET NULL
);
```

### A.7 学习记录表

```sql
CREATE TABLE IF NOT EXISTS learning_records (
    id BIGSERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    knowledge_id INT NOT NULL,
    learn_type VARCHAR(20) NOT NULL DEFAULT 'view',
    duration_sec INT DEFAULT 0,
    score DECIMAL(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (knowledge_id) REFERENCES knowledge_entries(id) ON DELETE CASCADE
);
```

### A.8 语音留言表

```sql
CREATE TYPE transcript_status_enum AS ENUM ('pending', 'done', 'failed');

CREATE TABLE IF NOT EXISTS voice_messages (
    id BIGSERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    audio_path VARCHAR(500) NOT NULL,
    transcript TEXT,
    transcript_status transcript_status_enum NOT NULL DEFAULT 'pending',
    related_knowledge_id BIGINT,
    tags VARCHAR(200),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (related_knowledge_id) REFERENCES knowledge_entries(id) ON DELETE SET NULL
);
```

### A.9 向量索引映射表

```sql
CREATE TABLE IF NOT EXISTS vector_index_map (
    id BIGSERIAL PRIMARY KEY,
    knowledge_id BIGINT NOT NULL,
    chunk_index INT NOT NULL DEFAULT 0,
    chunk_text TEXT NOT NULL,
    embedding_model VARCHAR(50),
    vector_store_id VARCHAR(200),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (knowledge_id) REFERENCES knowledge_entries(id) ON DELETE CASCADE
);
```

### A.10 每日一题表

```sql
CREATE TYPE question_type_enum AS ENUM ('single_choice', 'multi_choice', 'true_false', 'fill_blank');

CREATE TABLE IF NOT EXISTS daily_questions (
    id SERIAL PRIMARY KEY,
    question_type question_type_enum NOT NULL DEFAULT 'single_choice',
    question_content TEXT NOT NULL,
    options JSONB,
    answer TEXT NOT NULL,
    explanation TEXT,
    target_position user_position_enum,
    difficulty_level SMALLINT DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
    related_knowledge_id BIGINT,
    push_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (related_knowledge_id) REFERENCES knowledge_entries(id) ON DELETE SET NULL
);
```

### A.11 对话日志表

```sql
CREATE TABLE IF NOT EXISTS chat_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL DEFAULT '',
    references_json JSONB,
    is_satisfied SMALLINT,
    is_hit SMALLINT DEFAULT 1,
    response_time_ms INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### A.12 皮肤偏好表

```sql
CREATE TABLE IF NOT EXISTS skin_preferences (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,
    skin_id SMALLINT NOT NULL DEFAULT 1 CHECK (skin_id BETWEEN 1 AND 8),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### A.13 LLM模型配置表

```sql
CREATE TYPE llm_provider_type_enum AS ENUM (
    'tongyi', 'deepseek', 'zhipu', 'kimi', 'baichuan',
    'xfyun', 'siliconflow', 'dify', 'custom'
);

CREATE TABLE IF NOT EXISTS llm_providers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    provider_type llm_provider_type_enum NOT NULL,
    base_url VARCHAR(500) NOT NULL,
    api_key VARCHAR(500) NOT NULL DEFAULT '',
    model_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT false,
    is_default BOOLEAN NOT NULL DEFAULT false,
    max_tokens INT DEFAULT 2048,
    temperature REAL DEFAULT 0.7,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### A.14 系统配置表

```sql
CREATE TABLE IF NOT EXISTS system_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    config_type VARCHAR(20) NOT NULL DEFAULT 'string',
    description VARCHAR(200),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### A.15 审计日志表

```sql
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id INT,
    username VARCHAR(50),
    action VARCHAR(50) NOT NULL,
    target_type VARCHAR(50),
    target_id BIGINT,
    detail TEXT,
    ip_address VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);
```

### A.16 数据库索引（Day 2 随建表执行）

```sql
-- knowledge_entries 核心索引
CREATE INDEX IF NOT EXISTS idx_ke_category ON knowledge_entries(category_id);
CREATE INDEX IF NOT EXISTS idx_ke_status ON knowledge_entries(status);
CREATE INDEX IF NOT EXISTS idx_ke_kb ON knowledge_entries(knowledge_base);
CREATE INDEX IF NOT EXISTS idx_ke_brand ON knowledge_entries(car_brand);
CREATE INDEX IF NOT EXISTS idx_ke_created ON knowledge_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ke_source_person ON knowledge_entries(source_person);
CREATE INDEX IF NOT EXISTS idx_ke_view ON knowledge_entries(view_count DESC);
-- 全文搜索索引（中文分词需安装 zhparser 扩展）
-- 若未装 zhparser，回退用 simple 词典
CREATE INDEX IF NOT EXISTS idx_ke_fulltext ON knowledge_entries
    USING gin(to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(content,'')));
-- 学习记录索引
CREATE INDEX IF NOT EXISTS idx_lr_user ON learning_records(user_id);
CREATE INDEX IF NOT EXISTS idx_lr_knowledge ON learning_records(knowledge_id);
CREATE INDEX IF NOT EXISTS idx_lr_created ON learning_records(created_at DESC);
-- 积分索引
CREATE INDEX IF NOT EXISTS idx_ep_user ON experience_points(user_id);
CREATE INDEX IF NOT EXISTS idx_ep_created ON experience_points(created_at DESC);
-- 对话日志索引
CREATE INDEX IF NOT EXISTS idx_cl_user ON chat_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_cl_created ON chat_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cl_hit ON chat_logs(is_hit);
-- 审计日志索引
CREATE INDEX IF NOT EXISTS idx_al_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_al_created ON audit_logs(created_at DESC);
```

---

## 附录B：LLM多模型接入配置设计

### B.1 设计原理

系统不绑定单一LLM，管理员后台可配置多个国内主流大模型，随时切换、随时启用/停用。前端"阿能"对话时，后端读取当前激活的默认模型进行调用。

### B.2 预设模型清单（安装时种子数据自动写入）

| ID | 模型名称 | provider_type | 默认 Base URL | 默认 Model |
|----|---------|---------------|---------------|-----------|
| 1 | 通义千问 | tongyi | `https://dashscope.aliyuncs.com/compatible-mode/v1` | `qwen-plus` |
| 2 | DeepSeek | deepseek | `https://api.deepseek.com/v1` | `deepseek-chat` |
| 3 | 智谱GLM | zhipu | `https://open.bigmodel.cn/api/paas/v4` | `glm-4-flash` |
| 4 | 月之暗面Kimi | kimi | `https://api.moonshot.cn/v1` | `moonshot-v1-8k` |
| 5 | 百川智能 | baichuan | `https://api.baichuan-ai.com/v1` | `Baichuan4` |
| 6 | 讯飞星火 | xfyun | `https://spark-api-open.xf-yun.com/v1` | `generalv3.5` |
| 7 | 硅基流动 | siliconflow | `https://api.siliconflow.cn/v1` | `Qwen/Qwen2.5-7B-Instruct` |
| 8 | Dify平台 | dify | `https://api.dify.ai/v1` | `chat-messages` |

> 所有模型API Key默认留空，管理员填入后方可激活使用。Base URL和Model Name均可手工修改。**所有模型接口统一用 OpenAI 兼容的 `/v1/chat/completions` 调用格式。**

### B.3 LLM配置页面功能

- 列表展示全部8个预设模型（表格：名称 / 类型 / API地址 / 模型名 / 状态开关 / 设为默认 / 操作）
- 编辑弹窗：修改 Base URL / API Key / Model Name / Temperature / Max Tokens
- 启用/停用开关（停用的模型不参与对话）
- 设为默认（有且仅有一个默认，radio behavior）
- 测试连接按钮：向该模型发送一条简短测试消息 `{"role":"user","content":"你好，请回复：连接成功"}`，成功则弹绿框"连接成功，耗时XXms"，失败则弹红框"连接失败：{错误信息}"
- 新增自定义模型：手动填写上述字段，provider_type 选 `custom`

### B.4 对话接口改动

阿能对话 `POST /api/chat/ask` 改造：

```
原流程：PostgreSQL全文搜索 → 组装Prompt → 调Dify固定API
新流程：混合检索(关键词+语义向量+RRF) → 组装Prompt → 查 llm_providers 表 is_default=true → 调对应 base_url/chat/completions（流式SSE）
完整实现见附录E
```

调用格式（兼容所有国内主流模型）：
```python
response = await httpx.AsyncClient().post(
    f"{provider.base_url}/chat/completions",
    headers={"Authorization": f"Bearer {provider.api_key}"},
    json={
        "model": provider.model_name,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_question}
        ],
        "temperature": provider.temperature,
        "max_tokens": provider.max_tokens
    },
    timeout=30.0
)
```

### B.5 路由与文件

- `backend/routers/llm.py`：完整的LLM配置CRUD + 测试连接接口
  - `GET /api/llm/providers` → 全部模型列表
  - `PUT /api/llm/providers/{id}` → 更新模型配置
  - `POST /api/llm/providers/{id}/test` → 测试连接
  - `PUT /api/llm/providers/{id}/set-default` → 设为默认
  - `POST /api/llm/providers` → 新增自定义模型
- `frontend/src/views/LLMSettings.vue`：LLM配置管理页面

---

## 附录C：页面帮助系统设计（全部页面统一规范）

### C.1 PageHelp 组件设计

`frontend/src/components/PageHelp.vue`：

```vue
<template>
  <!-- 右下角固定?按钮 + 点击弹出帮助抽屉 -->
  <div class="page-help">
    <button class="help-trigger" @click="open = true" title="页面帮助">?</button>
    <Teleport to="body">
      <div v-if="open" class="help-overlay" @click.self="open = false">
        <div class="help-drawer">
          <div class="help-header">
            <h3>{{ help.title }}</h3>
            <button @click="open = false">×</button>
          </div>
          <div class="help-body">
            <section v-if="help.what">
              <h4>📋 功能说明</h4>
              <p>{{ help.what }}</p>
            </section>
            <section v-if="help.how && help.how.length">
              <h4>📝 操作步骤</h4>
              <ol>
                <li v-for="(step, i) in help.how" :key="i">{{ step }}</li>
              </ol>
            </section>
            <section v-if="help.related && help.related.length">
              <h4>🔗 相关操作页面</h4>
              <ul>
                <li v-for="(r, i) in help.related" :key="i">
                  <router-link :to="r.link" @click="open = false">{{ r.name }}</router-link>
                  <span v-if="r.desc"> — {{ r.desc }}</span>
                </li>
              </ul>
            </section>
            <section v-if="help.logic">
              <h4>⚙️ 业务逻辑说明</h4>
              <div v-html="help.logic"></div>
            </section>
            <section v-if="help.note">
              <h4>⚠️ 注意事项</h4>
              <p>{{ help.note }}</p>
            </section>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref } from 'vue'
defineProps({ help: { type: Object, required: true } })
const open = ref(false)
</script>
```

- `?` 按钮固定位于页面右下角（在阿能悬浮按钮上方），圆形、40px、半透明、跟随皮肤 `--primary` 色
- 帮助抽屉从右侧滑出，宽480px（手机端全宽），高100vh，滚动查看

### C.2 帮助内容定义文件

`frontend/src/helpContent.ts` 集中定义所有页面的帮助内容。
每个页面组件通过 `import { helpContent } from '@/helpContent'` + `helpContent['KnowledgeBase']` 引用。

### C.3 全部页面的帮助文案（完整定义）

以下是全部页面的帮助内容，开发时直接复制到 `helpContent.ts`：

#### 登录页

```
what: 合群汽车集团AI+业务能力知识库系统的统一登录入口。所有员工使用公司分配的账号密码登录本系统。

how:
  - 输入您的用户名（由管理员分配）
  - 输入您的登录密码（首次登录后建议修改密码）
  - 点击"登录"按钮进入系统
  - 如果忘记密码，请联系系统管理员重置

related:
  - name: 联系管理员 / link: （无）
  - name: 修改密码 / link: /profile

logic: 系统根据您的账号角色<b>自动判断权限</b>：<br>• <b>职员(staff)</b> → 查看本岗位知识、提交经验、个人学习看板<br>• <b>管理员(admin)</b> → 知识库管理、内容审核、用户管理、系统设置<br>• <b>老板(boss)</b> → 全局数据看板、BI大屏、战略配置<br><br>系统支持<b>三级岗位隔离</b>：销售岗、技术岗、客服岗各自只能看到所属知识库的内容。

note: 连续登录失败5次，账号将被临时锁定15分钟。
```

#### 首页

```
what: 登录后的默认页面。根据您的角色（职员/管理员/老板）展示不同的内容卡片和数据摘要。是您每天工作的起点。

how:
  - 职员：查看今日知识推送、每日一题入口、个人学习进度、积分排名
  - 管理员：查看待审核数量、本周经验沉淀统计、团队学习达标率、知识库健康状态
  - 老板：查看知识总量、月新增、员工总数、学习达标率四大核心指标
  - 点击任意卡片即可跳转到对应的功能页面

related:
  - name: 知识库浏览 / link: /knowledge
  - name: 数字老师阿能 / link: （点击右下角阿能头像）
  - name: 个人看板（职员）/ link: /personal-dashboard
  - name: 审核中心（管理员）/ link: /review
  - name: BI大屏（老板）/ link: /bi-board

logic: 首页数据通过 <b>GET /api/dashboard/home</b> 接口获取，后端根据当前登录用户的角色返回不同数据。首页数据缓存5分钟，减少数据库查询压力。右下角的"召唤阿能"按钮始终可见，无论您在哪个页面都可以随时唤起对话。

note: 首页每日0点自动刷新统计数据。如有未读的审核任务或预警信息，会在对应卡片上显示红色角标。
```

#### 知识库浏览

```
what: 浏览和搜索合群汽车集团的全部知识内容。知识按四大知识库分类存储：公共通用知识、销售专属知识、技术服务知识、售后客服知识。

how:
  - 在顶部搜索框输入关键词搜索知识（支持车型、故障描述、话术关键词等）
  - 左侧分类树可按知识库和子分类筛选浏览
  - 点击知识卡片进入详情页查看完整内容
  - 手机端点击顶部"筛选"按钮可展开分类抽屉
  - 搜索结果按匹配度和浏览量排序

related:
  - name: 知识详情 / link: /knowledge/:id
  - name: 知识管理（管理员）/ link: /knowledge-manage
  - name: 提交经验 / link: /submit-experience

logic: <b>岗位知识隔离规则</b>：<br>• 销售职员 → 只能看到"公共通用"+"销售专属"知识库<br>• 技术职员 → 只能看到"公共通用"+"技术服务"知识库<br>• 客服职员 → 只能看到"公共通用"+"售后客服"知识库<br>• 管理员/老板 → 可以看到全部四个知识库<br><br><b>全文搜索原理</b>：系统使用PostgreSQL的全文搜索功能，对知识标题和正文做分词索引。搜索关键词支持空格分隔的多词组合搜索。

note: 涉密经验（如技师独家维修技术）默认不对非技术岗位开放，如需跨岗共享，需管理员在知识管理页面标记"可跨岗查看"。
```

#### 知识详情

```
what: 查看某条知识条目的完整内容，包括正文、视频、音频、来源信息、标签和相关推荐。

how:
  - 阅读知识正文内容
  - 视频类知识可在线播放，自动从关键时间点开始
  - 音频类知识可在线收听
  - 点击"收藏"可将知识加入个人收藏夹
  - 点击"有用"可为知识投票（影响知识排名和淘汰判断）
  - 浏览超过30秒系统自动记录为"已学习"

related:
  - name: 知识库浏览 / link: /knowledge
  - name: 个人学习中心 / link: /learning
  - name: 阿能对话 / link: （右下角阿能）

logic: 打开详情页自动 <b>+1浏览次数</b>。浏览≥30秒自动写入 <b>learning_records</b> 表(learn_type='view')，计入个人学习统计。点击"有用"按钮写入 useful_count 字段，并给提交人+2积分（如果此知识是经验类知识）。底部"相关推荐"按同类目的热门知识TOP5展示。

note: 如果该知识有对应的视频/音频原始文件，且在阿能对话中通过引用跳转过来，页面会自动定位到对应的时间戳位置。
```

#### 知识管理（管理员）

```
what: 管理员对知识库条目的全生命周期管理。包括新增、编辑、删除（归档）、状态变更、批量导入知识。

how:
  - 使用搜索和筛选栏快速定位目标知识条目
  - 点击"新增知识"弹出表单，填写标题、内容、选择分类和知识库
  - 点击某条知识的"编辑"修改内容
  - 对过期或低质量知识，点击"归档"将其移出知识库（软删除）
  - 状态操作：可将知识标记为已通过(approved)/已驳回(rejected)/已归档(archived)
  - 批量导入：上传PDF/Word/Excel/视频文件，系统自动解析入库

related:
  - name: 审核中心 / link: /review
  - name: 分类管理（在系统设置中）/ link: /system-settings
  - name: LLM模型配置 / link: /llm-settings

logic: <b>知识状态流转</b>：<br>草稿(draft) → 待审核(pending) → 已通过(approved) / 已驳回(rejected)<br>已通过的知识可随时归档(archived)。<br><br>归档不是物理删除，已归档的知识仅管理员可见，前端搜索不会返回。如需彻底删除，需要通过数据库直接操作（一般不推荐）。<br><br><b>批量导入原理</b>：PDF/DOCX → 提取文本 → 分块(500字/块) → 写入knowledge_entries。Excel → 每行模板化为自然语言段落。视频 → 上传后后台异步转写分段。

note: 编辑已通过的知识会自动创建新版本(version+1)，旧版本保留在数据库中。删除操作为软删除（status改为archived），不会真正删除数据。
```

#### 审核中心（管理员）

```
what: 管理员审核员工提交的经验内容。这是知识飞轮的核心环节——经验只有通过审核才能正式进入企业知识库，被全员使用。

how:
  - 左侧待审核列表显示所有status=pending的知识条目
  - 点击某条，右侧展示该条目的完整内容
  - 审核通过：点击"通过"按钮，知识status变为approved，提交人自动获得+10积分
  - 驳回：点击"驳回"，填写驳回原因（必填），知识status变为rejected
  - 审核历史可查看过往所有审核记录

related:
  - name: 知识管理 / link: /knowledge-manage
  - name: 经验提交（职员端）/ link: /submit-experience
  - name: 积分排行榜 / link: /profile

logic: <b>审核通过的连锁动作</b>：<br>1. knowledge_entries.status → 'approved'<br>2. experience_points 写入一条 action_type='approved', points=+10 的记录<br>3. 知识在前端知识库对相应岗位可见<br><br><b>驳回的连锁动作</b>：<br>1. status → 'rejected'<br>2. audit_comment 记录驳回原因<br>3. 提交人在"我的提交"中可以看到驳回原因，可修改后重新提交<br><br>驳回的知识不会给积分，也不会出现在知识库搜索结果中。

note: 审核操作不可撤销，请在确认内容质量后再点击通过。建议审核标准：内容真实、对业务有实际指导价值、不与已有知识重复。
```

#### 经验提交（职员）

```
what: 一线员工将自己的实战经验、技巧、话术沉淀为企业知识的入口。销售、技师、客服岗位均可在此提交。

how:
  - 填写经验标题（简洁概括，如"星瑞客户谈价三步法"）
  - 在内容区详细描述经验（支持Markdown格式）
  - 选择对应的知识分类
  - 添加标签（如"星瑞/谈判/价格"便于搜索）
  - 点击"语音录入"可通过录音+自动转写快速输入经验
  - 点击"提交审核"后经验进入管理员审核队列

related:
  - name: 审核中心 / link: /review
  - name: 我的提交记录 / link: /profile
  - name: 积分排行榜 / link: /profile

logic: <b>提交经验的连锁动作</b>：<br>1. knowledge_entries 新建(status='pending', source_type='experience')<br>2. experience_points 写入 action_type='submit', points=+1<br>3. 审核通过后 → +10积分<br>4. 被同事点击"有用" → +2积分/次<br>5. 进入月度TOP5 → +50积分<br><br>语音录入流程：录音→上传→后台转写→回显文字→用户编辑→提交。

note: 经验提交后不可直接修改，需等待管理员审核。如被驳回，可在"我的提交"中查看驳回原因，修改后重新提交。请确保提交的内容真实有效，勿提交重复经验。
```

#### 个人看板（职员）

```
what: 查看您个人的知识掌握情况。通过雷达图直观展示您在各知识分类上的掌握程度，以及和岗位期望水平的差距。

how:
  - 雷达图：蓝色实线=您的掌握度，橙色虚线=岗位期望水平
  - 薄弱领域：自动标红掌握度最低的3个分类，点击可直接跳转学习
  - 学习进度：显示本周已学条目数、总学习时长
  - 积分和排名：显示当前积分和在全公司/本部门的排名
  - 最近学习记录：最近10条学习行为

related:
  - name: 学习中心 / link: /learning
  - name: 每日一题 / link: /question
  - name: 知识库浏览 / link: /knowledge

logic: <b>掌握度计算公式</b>：<br>个人某分类掌握度 = 该分类下您已学习的条目数 / 该分类下您岗位应学的条目总数 × 100%<br><br>总掌握度 = 所有分类掌握度的加权平均。<br><br>"已学习"定义为：在learning_records表中有记录(learn_type='view'或'complete'或'test')。<br>"岗位应学条目"定义为：该知识库+该岗位分类下所有 status='approved' 的条目。<br><br>薄弱领域 = 掌握度最低的3个分类，按从低到高排列。

note: 雷达图的期望值线是根据初级岗位标准设定的默认值(80%)，管理员可在系统设置中调整。排名数据每30分钟刷新一次。
```

#### 团队看板（管理员）

```
what: 查看本部门全员的整体知识掌握情况。可了解团队整体能力水平、各成员的知识掌握差异、团队薄弱领域。

how:
  - 顶部：团队总掌握度(环形图) + 部门人数 + 本月新增学习条目
  - 中部：团队雷达图（各分类平均掌握度）vs 岗位期望
  - 下部：团队成员排行榜（按掌握度排序）+ 薄弱领域提示
  - 可切换查看不同部门的数据（如有权限）

related:
  - name: BI大屏（老板看全局）/ link: /bi-board
  - name: 个人看板 / link: /personal-dashboard
  - name: 用户管理 / link: /user-manage

logic: <b>部门掌握度</b> = 部门内所有职员个人掌握度的算术平均。<br><b>团队薄弱领域</b> = 部门平均值最低的3个分类。<br>数据统计口径：仅统计status='approved'的知识条目，不含已归档。<br>管理员默认看到自己所属部门的数据，可切换查看其他部门。

note: 团队看板数据每小时刷新一次。如发现某成员掌握度异常低，建议安排专项培训。
```

#### BI大屏（老板专属）

```
what: 集团级全景数据大屏，展示合群汽车集团知识库系统的整体运转状态和全员能力分布。这是集团的"知识大脑"。

how:
  - 全屏大屏模式（建议在大屏幕显示器或投影上查看）
  - 按住F11或点击全屏按钮进入全屏模式
  - 所有图表自动刷新（每5分钟）
  - 鼠标悬停图表可查看详细数据
  - 支持按季度、按部门筛选数据

图表布局（4×2网格）：
  左上：知识库总量+月度增长趋势（折线图+数字卡片）
  中上：四大知识库占比（饼图）
  右上：各门店×知识分类能力热力图
  左下：经验贡献TOP10排行榜（柱状图）
  中下：三大飞轮运转指标（新沉淀/迭代/复用率）
  右下：预警区（长期无沉淀部门 + 高频未命中问题TOP5）

related:
  - name: 团队看板 / link: /team-dashboard
  - name: 首页仪表盘 / link: /home
  - name: 用户管理 / link: /user-manage

logic: <b>数据来源</b>：<br>• 知识总量 = knowledge_entries WHERE status='approved' 的count<br>• 月新增 = 本月创建的 approved 条目数<br>• 热力图数据 = 按部门×分类统计 learning_records 完成率<br>• 飞轮指标 = 本月experience_points记录数(沉淀) + 本月archived数(淘汰) + chat_logs.is_hit比率(复用率)<br>• 预警 = 连续30天无经验沉淀的部门 + chat_logs.is_hit=0 的高频问题TOP5<br><br><b>口径切换</b>：支持按季度(Q1/Q2/Q3/Q4)和按部门筛选，所有图表联动。

note: 大屏建议使用1920×1080及以上分辨率。首次加载数据可能需要2-3秒。大屏模式按ESC退出全屏。
```

#### 学习中心（职员）

```
what: 您的个人学习空间。包含岗位必修课进度、学习日历、错题本、学习时长统计。

how:
  - 必修课列表：该岗位分类下所有知识条目，已学标绿，未学标灰
  - 点击任一课程进入知识详情开始学习
  - 学习日历：每个日期方格颜色深浅表示当天学习条目数
  - 错题本：所有答错的每日一题，可重新作答
  - 学习时长：统计总学习时长和日均学习时长

related:
  - name: 每日一题 / link: /question
  - name: 个人看板 / link: /personal-dashboard
  - name: 知识库浏览 / link: /knowledge

logic: <b>"已学"判断标准</b>：learning_records 中存在该知识条目+该用户的记录。<br>学习日历的颜色深浅 = 当天学习的条目数 / 单日最大学习条目数。<br>错题本数据 = daily_questions 中该用户回答过且score=0的记录。<br>学习时长 = sum(learning_records.duration_sec)。

note: 建议每天至少学习3条知识，每周20条以上。学习日历可帮助你发现学习的规律和盲区。
```

#### 每日一题（职员）

```
what: 每天一道与您岗位相关的测试题，帮助巩固知识。答对获得积分，答错进入错题本可复习重答。

how:
  - 页面显示今天的题目（按您的岗位推送）
  - 选择题点击选项，判断题选对/错，填空题输入文字
  - 点击"提交答案"
  - 立即显示结果：正确/错误 + 详细解析
  - 答对自动+1积分，答错题目自动加入错题本
  - 如果今天已经答过，显示历史答案和解析

related:
  - name: 学习中心 / link: /learning
  - name: 考试管理（管理员）/ link: /exam-manage
  - name: 知识库浏览 / link: /knowledge

logic: <b>题目推送规则</b>：<br>1. 按用户岗位匹配 target_position 相同的题目<br>2. 排除该用户最近14天已经答过的题目<br>3. 按 difficulty_level 递增排序（先推简单的）<br>4. 如果岗位题目已轮完，推送公共知识库题目<br><br>答对：写 learning_records(learn_type='test', score=100)，写 experience_points(+1)<br>答错：写 learning_records(learn_type='test', score=0)，不加积分，题目入错题本

note: 每天只有一道题，答完后当天不会再推送新题。第二天0点刷新题目。
```

#### 考试管理（管理员）

```
what: 管理每日一题的题库。可以新增、编辑、删除题目，支持批量导入。

how:
  - 题目列表可按岗位、难度、题型筛选
  - 点击"新增题目"弹出表单
  - 选择题：填写题目、选项A/B/C/D、正确答案、解析
  - 判断题：填写题目、正确/错误、解析
  - 填空题：填写题目、标准答案、解析
  - 选择目标岗位（销售/技术/客服/全员）
  - 设置难度等级(1-5)
  - 可选择关联知识点（链接到某条knowledge_entry）
  - 批量导入：下载Excel模板 → 填充题目 → 上传导入

related:
  - name: 每日一题（职员端）/ link: /question
  - name: 学习中心 / link: /learning

logic: 题目类型支持4种：<br>• single_choice：单选题，options为 {"A":"...","B":"...","C":"...","D":"..."}<br>• multi_choice：多选题，同上<br>• true_false：判断题，options为null<br>• fill_blank：填空题，options为null<br><br>关联知识点的作用：职员答错时，系统推荐先学习关联的知识条目。

note: 建议每周新增10-20道题，保持题库新鲜度。批量导入模板中的"关联知识点ID"可选填。
```

#### 个人中心

```
what: 您的个人信息、积分情况、提交记录、收藏列表、皮肤设置的总览页面。

how:
  - 顶部：头像 + 姓名 + 岗位 + 部门 + 门店
  - 积分区：总积分（大数字）+ 全公司排名 + 本部门排名
  - 提交记录：我提交的所有经验列表，状态标签（待审/通过/驳回），驳回可查看原因
  - 我的收藏：收藏的知识列表
  - 皮肤切换：点击进入皮肤选择面板
  - 底部：退出登录按钮

related:
  - name: 经验提交 / link: /submit-experience
  - name: 知识库浏览 / link: /knowledge
  - name: 积分排行榜（全公司）/ link: /profile（本页底部）

logic: 积分统计 = SUM(experience_points.points) WHERE user_id = 当前用户。<br>排名 = 按积分降序排列的序号（全公司排名和本部门排名分别计算）。<br>提交记录 = knowledge_entries WHERE source_person = 当前用户姓名 ORDER BY created_at DESC。<br>收藏列表 = 前端localStorage存储的收藏ID数组，对应查 knowledge_entries。

note: 退出登录会清除本地token和对话历史。建议每次使用完毕后退出登录，尤其是在公共设备上。
```

#### 用户管理（管理员）

```
what: 管理系统的所有用户账号。包括创建新用户、编辑用户信息、启用/停用账号、分配岗位权限。

how:
  - 搜索和筛选：按用户名、角色、岗位、部门、门店筛选
  - 新增用户：填写用户名、真实姓名、密码、角色、岗位、部门、门店、手机号
  - 编辑用户：修改除用户名外的所有信息
  - 停用/启用：状态开关（停用后该用户无法登录，但历史数据保留）
  - 重置密码：为忘记密码的用户重置密码

related:
  - name: 系统设置 / link: /system-settings
  - name: 审核中心 / link: /review
  - name: 团队看板 / link: /team-dashboard

logic: <b>角色与岗位的权限矩阵</b>：<br>• boss = 老板 → 可查看所有数据，不可操作系统细节<br>• admin = 管理员 → 可管理知识库、用户、审核、系统设置<br>• staff = 职员 → 只能查看本岗位知识和自己的数据<br><br>岗位(position)决定知识库可见范围：sales→销售库 / tech→技术库 / service→客服库。<br>角色为boss或admin的用户，position可为空（表示可看所有知识库）。<br><br>停用用户不会删除其历史贡献数据（经验、积分、学习记录保留）。

note: 新建用户的默认密码为 hequn123，首次登录系统会提示修改密码。请勿将管理员权限分配给不相关人员。
```

#### LLM模型配置（管理员）

```
what: 配置系统对接的大语言模型(LLM)。支持国内主流大模型：通义千问、DeepSeek、智谱GLM、月之暗面Kimi、百川智能、讯飞星火、硅基流动、Dify平台，以及任何兼容OpenAI接口格式的自定义模型。

how:
  - 模型列表：8个预设模型 + 自定义模型
  - 点击编辑图标修改：Base URL / API Key / 模型名称 / Temperature / Max Tokens
  - 填入正确的API Key后，打开"启用"开关
  - 点击"设为默认"选择当前使用的模型（有且仅有一个默认）
  - 点击"测试连接"验证配置是否正确
  - 测试成功显示"连接成功，耗时XXms"；失败显示具体错误信息
  - 支持新增自定义模型（provider_type=custom），填写任意Base URL和Model Name

related:
  - name: 系统设置 / link: /system-settings
  - name: 阿能对话 / link: （右下角阿能）
  - name: 对话日志（在系统设置中）/ link: /system-settings（日志页签）

logic: <b>调用流程</b>：<br>1. 用户在阿能对话窗口提问<br>2. 后端检索PostgreSQL全文搜索，获取Top-5匹配知识<br>3. 后端查询 llm_providers 表 is_active=true AND is_default=true 的记录<br>4. 用该模型的 base_url + api_key + model_name 发起 /chat/completions 请求<br>5. 所有请求使用OpenAI兼容格式（{model, messages, temperature, max_tokens}）<br>6. 返回答案给前端<br><br><b>测试连接原理</b>：发送一条简短的 {"role":"user","content":"你好，请只回复：连接成功"} 到目标模型，检查响应状态码和内容。30秒超时。

note: API Key以加密方式存储（AES对称加密，密钥由JWT_SECRET派生）。Base URL必须以 https:// 开头（生产环境）或以 http:// 开头（内网私有化部署）。切换默认模型会立即影响所有用户的阿能对话体验。
```

#### 系统设置（管理员）

```
what: 管理系统的全局配置，包括积分规则、飞轮阈值、自动提醒、审计日志查看、数据导出。

how:
  - 积分规则页签：设置各行为对应的积分值（提交经验、被采用、被标记有用、月度TOP5、每日一题答对、完成课程）
  - 飞轮阈值页签：设置低效经验阈值（默认：浏览<5且>6月）、政策更新提醒周期（默认：6月）
  - 自动提醒页签：开关每周萃取推送、每月迭代提醒
  - 审计日志页签：查看系统操作日志（按用户/时间/操作类型筛选）
  - 数据导出页签：导出知识库为CSV文件

related:
  - name: LLM模型配置 / link: /llm-settings
  - name: 用户管理 / link: /user-manage
  - name: 审核中心 / link: /review

logic: <b>积分规则存储</b>：system_config 表，config_key 格式为 "points_{action}"。<br>系统启动时从 system_config 读取，缓存到内存，修改后实时更新缓存。<br><br><b>飞轮规则存储</b>：<br>• "flywheel_view_threshold" = 5（低效经验浏览阈值）<br>• "flywheel_month_threshold" = 6（知识更新周期，月）<br>• "flywheel_useful_rate" = 0.7（有效经验有用率阈值）<br>• "flywheel_low_useful_rate" = 0.3（待优化经验有用率阈值）<br><br><b>审计日志分类</b>：login/logout/create_knowledge/edit_knowledge/delete_knowledge/review_approve/review_reject/create_user/edit_user/toggle_user/update_settings

note: 修改飞轮规则会影响后续的知识自动筛选和淘汰建议。修改积分规则不会追溯影响历史积分。数据导出生成CSV文件后自动下载，不保留在服务器上。
```

---

## 附录D：宋式美学 8 套皮肤色值定义

### 暖色系（3套）

**皮肤1：朱砂红 · Vermilion**
```
--primary: #C0403B        --primary-light: #D46864
--bg-main: #FEF9F6        --bg-card: #FFF5F0
--text-main: #3D2B28      --text-sub: #8B6E67
--border: #E8D0C8         --shadow: rgba(192,64,59,0.12)
--accent: #E8824A         --success: #7BA668
```

**皮肤2：琥珀金 · Amber Gold**
```
--primary: #B8860B        --primary-light: #D4A843
--bg-main: #FDFAF3        --bg-card: #FFF9E6
--text-main: #3D3528      --text-sub: #8B7D5E
--border: #E0D5B8         --shadow: rgba(184,134,11,0.12)
--accent: #CD853F         --success: #6B8E5A
```

**皮肤3：檀木棕 · Sandalwood**
```
--primary: #8B5E3C        --primary-light: #A67B5B
--bg-main: #FBF6F0        --bg-card: #F5EDE3
--text-main: #3D2E24      --text-sub: #8B7355
--border: #D4C4B0         --shadow: rgba(139,94,60,0.12)
--accent: #C67B4B         --success: #739B5E
```

### 冷色系（3套）

**皮肤4：汝窑青 · Ru Kiln Celadon**
```
--primary: #6B8E7B        --primary-light: #8FAD9C
--bg-main: #F5F9F6        --bg-card: #EEF5F0
--text-main: #2D3A32      --text-sub: #6B8072
--border: #C8DCD0         --shadow: rgba(107,142,123,0.12)
--accent: #5B8C7A          --success: #6A9B71
```

**皮肤5：霁蓝釉 · Sacrificial Blue**
```
--primary: #4A688B        --primary-light: #6885A6
--bg-main: #F5F7FB        --bg-card: #EDF1F8
--text-main: #2A3240      --text-sub: #6B7890
--border: #C8D4E4         --shadow: rgba(74,104,139,0.12)
--accent: #5B7EA8         --success: #6B9B7A
```

**皮肤6：水墨灰 · Ink Wash Gray**
```
--primary: #6B7B8B        --primary-light: #8E9CAA
--bg-main: #F6F7F8        --bg-card: #EEF0F3
--text-main: #303840      --text-sub: #7B8490
--border: #D0D4D8         --shadow: rgba(107,123,139,0.10)
--accent: #5B7288         --success: #6B8B73
```

### 简约色系（2套）

**皮肤7：素白 · Plain White**
```
--primary: #4A4A4A        --primary-light: #7A7A7A
--bg-main: #FFFFFF        --bg-card: #F8F8F8
--text-main: #1A1A1A      --text-sub: #8A8A8A
--border: #E5E5E5         --shadow: rgba(0,0,0,0.06)
--accent: #5A5A5A         --success: #6AAA6A
```

**皮肤8：墨韵黑 · Ink Rhythm Black**
```
--primary: #C0C0C0        --primary-light: #D8D8D8
--bg-main: #1A1A1A        --bg-card: #252525
--text-main: #E8E8E8      --text-sub: #A0A0A0
--border: #3A3A3A         --shadow: rgba(255,255,255,0.04)
--accent: #A0A0A0         --success: #80C080
```

### 皮肤切换机制

- `stores/skin.ts` 管理当前皮肤ID (1-8)
- `<body>` 设置 `data-skin="1"` 属性
- 所有组件颜色用 `var(--primary)` 等CSS变量引用
- 用户选择皮肤后存 localStorage + 调后端API保存到 skin_preferences 表
- `SkinSwitcher.vue`：右上角调色板图标，hover弹出8色块选择面板

---

## 每日任务卡

---

### Day 1 · 项目骨架 + 基础设施

**前置条件**：无

**任务内容**：

1. 创建完整项目目录结构（按全局约定的目录树，包括所有空文件）

2. `docker-compose.yml`：定义 PostgreSQL 16 + Redis 7 + FastAPI 三个容器
   - PostgreSQL：端口5432，挂载 `./backend/sql/init.sql` 到 `docker-entrypoint-initdb.d/`
   - Redis：端口6379，开启AOF持久化
   - FastAPI：端口8000，挂载 `./backend` 和 `./uploads` 目录

3. `backend/requirements.txt`：
   ```
   fastapi==0.115.0
   uvicorn[standard]==0.30.0
   sqlalchemy[asyncio]==2.0.35
   asyncpg==0.30.0
   redis==5.2.0
   python-jose[cryptography]==3.3.0
   passlib[bcrypt]==1.7.4
   python-multipart==0.0.12
   pydantic==2.9.0
   aiofiles==24.1.0
   httpx==0.28.0
   PyPDF2==3.0.1
   python-docx==1.1.2
   openpyxl==3.1.5
   cryptography==43.0.0
   ```

4. `backend/config.py`：读取所有环境变量
   - DATABASE_URL, REDIS_URL, JWT_SECRET, JWT_EXPIRE_MINUTES
   - UPLOAD_DIR, LLM_ENCRYPTION_KEY（API Key加密用）

5. `backend/database.py`：SQLAlchemy 2.0 async engine + async_session factory

6. `backend/main.py`：FastAPI应用，CORS，静态文件挂载，健康检查 `GET /api/health`

7. 前端 `npm create vite@latest frontend -- --template vue-ts`，装 echarts, pinia, vue-router, axios, @vueuse/core

8. `frontend/vite.config.ts`：代理 `/api` → `http://localhost:8000`，代理 `/uploads` → `http://localhost:8000/uploads`

**验收标准**：
- `docker compose up -d` 成功启动
- `http://localhost:8000/api/health` 返回 `{"code":0,"data":"ok"}`
- `npm run dev` 前端启动无报错

**输出物**：docker-compose.yml, backend/main.py, config.py, database.py, requirements.txt, frontend/ 项目骨架

---

### Day 2 · 创建全部数据表 + 种子数据

**前置条件**：Day 1 完成

**任务内容**：

1. 创建 `backend/sql/init.sql`，将 **附录A 全部15张表的DDL** 完整写入。此SQL在容器首次启动时自动执行建表。

2. `backend/models.py`：为15张表中的14张表定义 SQLAlchemy ORM 模型（audit_logs 使用原生SQL写入，不建ORM模型）
   - 每个Enum类型用 Python `enum.Enum` + SQLAlchemy `Enum`
   - JSON字段用 `sqlalchemy.JSON`
   - 外键关系完整定义
   - 建表策略：先用ORM `Base.metadata.create_all`，init.sql 作为备用

3. `backend/seed_data.py`：首次启动时的种子数据
   - departments：销售部、技术部、客服部
   - stores：合群旗舰店、合群城西店
   - knowledge_categories：附录A中预设的30条分类树
   - users：5个测试用户（密码 hequn123，bcrypt加密）
     - boss / hequn123 → role=boss
     - admin / hequn123 → role=admin
     - sales01 / hequn123 → role=staff, position=sales, dept=销售部
     - tech01 / hequn123 → role=staff, position=tech, dept=技术部
     - service01 / hequn123 → role=staff, position=service, dept=客服部
   - llm_providers：8条预设模型记录（附录B.2），所有 api_key 为空，is_active=false
   - system_config：默认积分规则和飞轮阈值
   - skin_preferences：所有用户默认 skin_id=1

4. 在 `main.py` startup事件中检查是否需要执行种子数据

**验收标准**：
- 启动后 `psql -U hqevoai -d hqevoai -c "\dt"` 列出全部15张表
- `SELECT * FROM users;` 有5个测试用户
- `SELECT * FROM llm_providers;` 有8条预设模型
- `SELECT * FROM knowledge_categories;` 有30条分类

**输出物**：backend/sql/init.sql, models.py, seed_data.py

---

### Day 3 · JWT认证 + 权限 + 登录页 + 页面帮助系统

**前置条件**：Day 2 完成

**任务内容**：

1. `backend/auth.py`：
   - JWT生成/验证，payload: {user_id, role, position}
   - `get_current_user()` FastAPI依赖注入
   - 三个权限函数：`require_role(*roles)`, `require_admin()`, `require_boss()`

2. `backend/schemas.py`：所有Pydantic模型
   - LoginRequest, LoginResponse, UserInfo
   - PageParams（page, page_size, keyword...）

3. `backend/routers/users.py`：
   - `POST /api/auth/login` → 登录 + 查skin_preferences返回皮肤ID
   - `GET /api/auth/me` → 当前用户信息
   - `PUT /api/auth/skin` → 保存皮肤选择
   - `GET /api/users/list` → 用户列表（管理员，分页筛选）
   - `POST /api/users` → 新建用户
   - `PUT /api/users/{id}` → 编辑用户
   - `PUT /api/users/{id}/status` → 启用/停用

4. `frontend/src/router.ts`：完整路由树 + beforeEach守卫

5. `frontend/src/stores/auth.ts`：Pinia登录态管理

6. `frontend/src/views/Login.vue`：宋式美学登录页
   - 登录表单下方放置知情同意区域（见附录M）
   - 首次登录必须勾选同意才可提交
   - 已同意用户不再重复弹出

7. **`frontend/src/helpContent.ts`**：将**附录C 全部页面的帮助文案**原样定义在 `export const helpContent = { ... }` 中

8. **`frontend/src/components/PageHelp.vue`**：按附录C.1设计实现（?按钮 + 右侧抽屉 + Teleport）

9. 在`App.vue`中放置 `<PageHelp>` 组件（全局一份），根据 `route.path` 自动切换对应帮助内容

**验收标准**：
- 5个测试用户可登录，返回正确的角色和岗位
- 登录后任何页面右下角显示"?"按钮，点击弹出帮助抽屉
- 切换到不同页面，"?"按钮弹出的帮助内容不同
- 未登录无法访问任何页面

**输出物**：backend/auth.py, schemas.py, routers/users.py
frontend/src/router.ts, stores/auth.ts, views/Login.vue
frontend/src/helpContent.ts, components/PageHelp.vue

---

### Day 4 · 框架布局 + 顶部Banner + 8套皮肤

**前置条件**：Day 3 完成

**任务内容**：

1. `frontend/public/banner.svg`：标题图 "合群汽车集团AI+业务能力知识库"
   - 1600×120px，毛笔楷体风格汉字，渐变色底纹

2. `frontend/src/styles/variables.css`：附录D的全部8套皮肤CSS变量，用 `body[data-skin="1"]` ~ `body[data-skin="8"]` 选择器

3. `frontend/src/styles/global.css`：全局样式 + 响应式断点工具类

4. `frontend/src/stores/skin.ts`：Pinia皮肤管理

5. `frontend/src/components/TopBanner.vue`：固定顶部banner条

6. `frontend/src/components/SkinSwitcher.vue`：右上角调色板图标 + 8色块弹出面板

7. `frontend/src/components/SideMenu.vue`：PC/Pad端左侧导航（按角色显示不同菜单）

8. `frontend/src/components/BottomTabs.vue`：手机端底部Tab导航

9. `frontend/src/App.vue`：组合 TopBanner + SkinSwitcher + PageHelp + SideMenu/BottomTabs + router-view

**验收标准**：
- Banner和各导航在所有页面可见
- 切换8个皮肤全部颜色同步变化
- 不同角色看到不同的导航菜单
- 刷新保持皮肤

**输出物**：banner.svg, variables.css, global.css, stores/skin.ts, TopBanner.vue, SkinSwitcher.vue, SideMenu.vue, BottomTabs.vue, App.vue

---

### Day 5 · 知识库浏览 + 搜索

**前置条件**：Day 4 完成

**任务内容**：

1. `backend/routers/categories.py`：
   - `GET /api/categories` → 全部分类树（按知识库分组）
   - `GET /api/categories/{id}` → 单个分类详情

2. `backend/routers/knowledge.py`：
   - `GET /api/knowledge` → 分页列表（keyword/category_id/knowledge_base/car_brand/sort_by/status筛选）
   - `GET /api/knowledge/{id}` → 详情（+view_count）
   - `GET /api/knowledge/hot` → 热门TOP10
   - `GET /api/knowledge/latest` → 最新TOP10
   - 权限控制：职员岗位隔离

3. `frontend/src/views/KnowledgeBase.vue`：搜索栏 + 分类树 + 知识卡片列表 + 响应式
   - 使用 `helpContent['KnowledgeBase']` 传入 PageHelp

4. `frontend/src/views/KnowledgeDetail.vue`：正文/视频/音频 + 收藏 + 有用按钮 + 相关推荐
   - 使用 `helpContent['KnowledgeDetail']`

5. seed_data.py 补充4条示例知识

**验收标准**：
- 知识列表分页展示
- 分类筛选正确
- 关键词搜索返回结果
- 职员岗位隔离正确
- 帮助按钮弹出对应页面的帮助内容（以下每页同，不再重复）

> **🔴 测试门A（Day 5 必须通过）**：运行 `./tests/run_gate.sh A`，全部 PASSED 后方可进入 Day 6。
> 覆盖：健康检查 / 登录与权限 / 知识列表与岗位隔离。

**输出物**：backend/routers/categories.py, knowledge.py, frontend/KnowledgeBase.vue, KnowledgeDetail.vue

---

### Day 6 · 知识管理（管理员）

**前置条件**：Day 5 完成

**任务内容**：

1. `backend/routers/knowledge.py` 补充管理接口：
   - `POST /api/knowledge` → 新增
   - `PUT /api/knowledge/{id}` → 编辑
   - `DELETE /api/knowledge/{id}` → 软删除 (status='archived')
   - `PUT /api/knowledge/{id}/status` → 状态变更

2. `backend/routers/upload.py`：
   - `POST /api/upload/file` → 文件上传到 ./uploads/
   - 附件解析：PDF→PyPDF2, DOCX→python-docx, XLSX→openpyxl

3. `frontend/src/views/KnowledgeManage.vue`：表格 + 新增/编辑表单 + 批量导入 + 状态操作
   - 使用 `helpContent['KnowledgeManage']`

**验收标准**：管理员可完整CRUD知识条目、上传文件自动解析

**输出物**：backend/routers/knowledge.py(补充), upload.py, frontend/KnowledgeManage.vue

---

### Day 7 · 审核中心 + 经验提交

**前置条件**：Day 6 完成

**任务内容**：

1. `backend/routers/review.py`：
   - `GET /api/review/pending` → 待审核列表
   - `POST /api/review/{id}/approve` → 通过 + 自动加10积分
   - `POST /api/review/{id}/reject` → 驳回（需audit_comment）+ 不积分
   - `GET /api/review/history` → 审核历史

2. `backend/routers/knowledge.py` 补充：
   - `POST /api/knowledge/submit-experience` → status='pending', +1积分

3. `frontend/src/views/ReviewCenter.vue`：左右分栏审核界面，使用 `helpContent['ReviewCenter']`

4. `frontend/src/views/ExperienceSubmit.vue`：经验表单 + 提交，使用 `helpContent['ExperienceSubmit']`

**验收标准**：完整审核流程 + 积分联动正确

**输出物**：backend/routers/review.py, frontend/ReviewCenter.vue, ExperienceSubmit.vue

---

### Day 8 · 个人知识能力图表

**前置条件**：Day 7 完成

**任务内容**：

1. `backend/routers/learning.py`：
   - `POST /api/learning/record` → 记录学习行为
   - `GET /api/learning/history` → 学习历史

2. `backend/routers/dashboard.py`：
   - `GET /api/dashboard/personal` → 个人掌握度 + 雷达图数据 + 薄弱领域 + 积分排名
     （返回格式见PRD 7.1节的计算逻辑）

3. `frontend/src/components/RadarChart.vue`：ECharts雷达图（双线：掌握度+期望值）

4. `frontend/src/views/PersonalDashboard.vue`：总掌握度环形进度 + 雷达图 + 薄弱领域
   - 使用 `helpContent['PersonalDashboard']`

**验收标准**：雷达图数据正确反映学习记录

**输出物**：backend/routers/learning.py, dashboard.py, frontend/RadarChart.vue, PersonalDashboard.vue

---

### Day 9 · 团队看板 + 集团BI大屏

**前置条件**：Day 8 完成

**任务内容**：

1. `backend/routers/dashboard.py` 补充：
   - `GET /api/dashboard/team` → 部门数据（返回格式见PRD）
   - `GET /api/dashboard/global` → 集团全局数据（老板专属）
   - `GET /api/dashboard/flywheel` → 飞轮运转数据

2. `frontend/src/components/HeatMap.vue`：ECharts热力图

3. `frontend/src/views/TeamDashboard.vue`：部门排行 + 部门雷达 + 薄弱领域
   - 使用 `helpContent['TeamDashboard']`

4. `frontend/src/views/BIBoard.vue`：全屏大屏（知识总量/趋势/饼图/热力图/排行榜/预警）
   - 使用 `helpContent['BIBoard']`

**验收标准**：三种看板各角色可见范围正确，数据正确

**输出物**：dashboard.py(补充), HeatMap.vue, TeamDashboard.vue, BIBoard.vue

---

### Day 10 · 学习中心 + 每日一题 + 题库运营

**前置条件**：Day 9 完成

**任务内容**：

1. `backend/routers/questions.py`：
   - `GET /api/questions/today` → 今日题目（按岗位+去重+难度递增推送）
   - `POST /api/questions/{id}/answer` → 答题（对+1分，错入错题本）
   - `GET /api/questions/history` → 答题历史
   - `POST /api/questions` → 新增题目（管理员）
   - `PUT /api/questions/{id}` → 修改题目（管理员）
   - `PUT /api/questions/{id}/status` → 作废/恢复（管理员，status: active/retired）
   - `GET /api/questions/list` → 题库管理列表（管理员，支持按岗位/难度/状态/来源筛选）
   - `GET /api/questions/stats` → 题库健康度统计（各岗位题目数、平均难度、近期新增趋势）
   - `POST /api/questions/batch-import` → Excel批量导入
   - `POST /api/questions/ai-generate` → **AI自动出题**（管理员选择知识条目，调LLM生成题目草稿，人工确认后入库）

2. `frontend/src/views/LearningCenter.vue`：必修课进度 + 学习日历 + 错题本
   - 使用 `helpContent['LearningCenter']`

3. `frontend/src/views/QuestionAnswer.vue`：每日一题卡片 + 四种题型 + 解析
   - 使用 `helpContent['QuestionAnswer']`

4. `frontend/src/views/ExamManage.vue`：**完整题库运营管理界面**（详见附录G）
   - 题库列表：支持搜索/筛选/排序
   - 新增/编辑/作废操作
   - AI自动出题入口
   - 题库健康度看板
   - 批量导入（Excel模板下载+上传）
   - 使用 `helpContent['ExamManage']`

5. seed_data.py 补充各岗位初始题目（销售10道、技术10道、客服10道、公共5道，共35道）

**验收标准**：答题流程完整；管理员可完成题目新增/修改/作废；AI出题可生成草稿并确认入库；题库健康度数据正确

> **🔴 测试门B（Day 10 必须通过）**：运行 `./tests/run_gate.sh B`，全部 PASSED 后方可进入 Day 11。
> 覆盖：经验提交→审核→积分完整流程 / 个人看板数据 / 答题与错题本。

**输出物**：backend/routers/questions.py, frontend/LearningCenter.vue, QuestionAnswer.vue, ExamManage.vue

---

### Day 11 · 个人中心 + 用户管理

**前置条件**：Day 10 完成

**任务内容**：

1. `backend/routers/users.py` 补充：
   - `GET /api/users/ranking` → 积分排行榜

2. `frontend/src/views/Profile.vue`：完整个人中心（积分/排名/提交记录/收藏/皮肤入口）
   - 使用 `helpContent['Profile']`

3. `frontend/src/views/UserManage.vue`：用户表格 + 新增/编辑 + 状态开关
   - 使用 `helpContent['UserManage']`

**验收标准**：个人数据正确，用户管理功能完整

**输出物**：users.py(补充), frontend/Profile.vue, UserManage.vue

---

### Day 12 · 数字老师"阿能"对话

**前置条件**：Day 11 完成

**任务内容**：

1. `backend/routers/chat.py`：
   - `POST /api/chat/ask` → 核心对话接口（**完整实现见附录E**）
     - 步骤1：**混合检索**（见附录E.3）
       - 关键词检索：PostgreSQL tsvector 全文搜索 → Top-20，得分归一化
       - 语义检索：对用户问题调 embedding API → 向量 → pgvector cosine 相似度 → Top-20
       - RRF 融合：两路结果按 RRF 公式合并排序 → 取 Top-5
     - 步骤2：组装阿能Prompt（角色扮演 + 岗位注入 + 上下文）
     - 步骤3：读取 llm_providers WHERE is_default=true → 调用 /chat/completions（**stream=True**，SSE流式输出）
     - 步骤4：写入 chat_logs
     - 返回：SSE 流式文本 + references: [...]
   - 插件分发：根据用户意图识别触发对应插件（见附录F）
   - `POST /api/chat/feedback` → 满意/不满意评价
   - `POST /api/chat/feedback` → 满意/不满意评价

2. `frontend/src/stores/chat.ts`：对话历史管理

3. `frontend/src/components/ANengChat.vue`：
   - 右下角悬浮阿能按钮 + 对话面板
   - 四种教学模式切换 + 岗位欢迎语
   - 引用卡片（知识标题，可点击跳转详情）
   - 每条回复末尾"还有什么不清楚的地方？"

4. Home.vue补充"召唤阿能"入口

**验收标准**：
- 至少一个LLM模型配置好API Key后，对话返回正确答案
- 引用来源可点击跳转
- 对话日志写入正确

**输出物**：backend/routers/chat.py, frontend/stores/chat.ts, ANengChat.vue

---

### Day 13 · LLM模型配置页面

**前置条件**：Day 12 完成

**任务内容**：

1. `backend/routers/llm.py`：
   - `GET /api/llm/providers` → 全部模型列表
   - `PUT /api/llm/providers/{id}` → 更新配置
   - `POST /api/llm/providers/{id}/test` → 测试连接
   - `PUT /api/llm/providers/{id}/set-default` → 设为默认
   - `POST /api/llm/providers` → 新增自定义模型
   - API Key加密存储（cryptography Fernet）

2. `frontend/src/views/LLMSettings.vue`：
   - 8个预设模型卡片/表格 + 自定义模型
   - 编辑弹窗（Base URL / API Key / Model Name / Temperature / MaxTokens）
   - 启用开关 + 设为默认 + 测试连接按钮
   - 测试结果弹窗（绿色成功/红色失败+错误信息）
   - 使用 `helpContent['LLMSettings']`

3. SideMenu管理员菜单增加"LLM模型配置"项

**验收标准**：
- 可编辑任意模型配置并保存
- 测试连接返回正确结果
- 设为默认后，阿能对话使用新模型
- API Key加密存储，API返回脱敏显示（只显示前4后4位）

**输出物**：backend/routers/llm.py, frontend/LLMSettings.vue

---

### Day 14 · 系统设置 + 飞轮规则 + 审计日志

**前置条件**：Day 13 完成

**任务内容**：

1. `backend/routers/settings.py`：
   - `GET /api/settings` → 全部配置
   - `PUT /api/settings` → 批量更新配置（积分/飞轮/提醒）

2. `backend/routers/logs.py`：
   - `GET /api/logs/audit` → 审计日志列表（分页/筛选）
   - 在所有业务操作中埋点写 audit_logs

3. `frontend/src/views/SystemSettings.vue`：
   - 4个页签：积分规则 / 飞轮阈值 / 审计日志 / 数据导出
   - 使用 `helpContent['SystemSettings']`

**验收标准**：
- 配置读写正确
- 审计日志记录完整
- 数据导出CSV可用

**输出物**：backend/routers/settings.py, logs.py, frontend/SystemSettings.vue

---

### Day 15 · 音频处理 + 语音留言

**前置条件**：Day 14 完成

**任务内容**：

1. `backend/routers/voice.py`：
   - `POST /api/voice/upload` → 音频上传 + 转写
   - `GET /api/voice/status/{id}` → 查询转写状态
   - `POST /api/voice/{id}/to-experience` → 转经验草稿

   转写方案：调用当前激活的Dify API（如果配置了Dify模型）→ Dify内置音频转写接口；否则调用通义千问Paraformer语音识别API

2. `frontend/src/views/ExperienceSubmit.vue` 补充语音录入（MediaRecorder → 上传 → 转写 → 编辑 → 提交）

3. `ANengChat.vue` 补充语音输入按钮

**验收标准**：录音 → 转写 → 草稿 → 提交审核 全链路通

> **🔴 测试门C（Day 15 必须通过）**：运行 `./tests/run_gate.sh C`，全部 PASSED 后方可进入 Day 16。
> 覆盖：阿能对话（mock LLM）/ LLM配置CRUD / RLHF反馈写入 / 异步任务提交与状态查询。

**输出物**：backend/routers/voice.py, 更新 ExperienceSubmit.vue, ANengChat.vue

---

### Day 16 · 视频知识处理 + 批量导入

**前置条件**：Day 15 完成

**任务内容**：

1. `backend/video_processor.py`：视频上传 → 提取音频 → 转写 → 带时间戳分段 → 写入 knowledge_entries

2. `backend/routers/knowledge.py` 补充视频片段查询

3. `frontend/src/views/KnowledgeDetail.vue` 补充 `<video>` 播放器 + 时间戳定位

4. `backend/import_data.py`：批量导入 `D:\合群集团资料\` 全部内容
   - 按PRD 4.3的映射表逐一处理
   - 处理日志 + 统计报告

**验收标准**：
- 视频上传后自动分段入库，时间戳正确
- 批量导入17个文件全部成功
- 导入后知识库可搜索

**输出物**：backend/video_processor.py, import_data.py, 更新 KnowledgeDetail.vue

---

### Day 17 · 首页仪表盘 + 个性化推荐引擎

**前置条件**：Day 16 完成

**任务内容**：

1. `backend/routers/dashboard.py` 补充：
   - `GET /api/dashboard/home` → 按角色返回聚合首页数据，**职员端"今日推送"调用个性化推荐引擎**（见附录H）

2. `backend/recommendation.py`：个性化推荐引擎（详见附录H）
   - 输入：user_id, position, top_k=5
   - 输出：推荐知识条目列表 + 推荐原因标签

3. `frontend/src/views/Home.vue`：三种角色的三套首页布局
   - **职员**：今日个性化推荐（含推荐原因标签） + 每日一题入口 + 召唤阿能 + 学习进度 + 积分排名
   - 管理员：待审核红点 + 本周沉淀 + 团队达标率 + 知识健康度 + 题库预警卡片
   - 老板：四大数字卡 + 小雷达图 + 经验精华 + 预警区
   - 使用 `helpContent['Home']`

4. 系统预埋告警逻辑（首页接口中计算）

**验收标准**：
- 职员首页"今日推送"内容因人而异，薄弱领域知识优先出现
- 推荐卡片显示推荐原因（"你的技术服务知识掌握度较低"/"你上周学过相关内容"）
- 三种角色首页内容差异化，数据正确

**输出物**：backend/recommendation.py, dashboard.py(补充), frontend/Home.vue

---

### Day 18 · 全端响应式适配

**前置条件**：Day 17 完成

**任务内容**：

逐页检查修复适配：
- 手机(≤768px)：BottomTab留白、分类树改抽屉、表格横滚、ANengChat全屏
- Pad(768-1024px)：SideNav 160px宽、图表中等尺寸
- PC(≥1025px)：完整布局
- BIBoard `requestFullscreen` 支持

**验收标准**：全部19个页面在三端显示正常

**输出物**：更新 global.css + 各组件响应式调整

---

### Day 19 · 性能优化 + 缓存 + 限流

**前置条件**：Day 18 完成

**任务内容**：

1. 数据库索引执行（附录A.16，确认全部生效）

2. `backend/cache.py`：Redis缓存层
   - 热门知识：10min / 首页数据：5min / 排行榜：30min / 分类树：1h

3. `backend/rate_limit.py`：Redis滑动窗口限流
   - 全局：100次/min/IP / 登录：10次/min/IP / AI对话：30次/min/用户

4. 前端：路由懒加载 + ECharts按需引入

**验收标准**：知识列表<200ms，首页<500ms

**输出物**：backend/cache.py, rate_limit.py

---

### Day 20 · 系统日志 + 全局异常处理

**前置条件**：Day 19 完成

**任务内容**：

1. `backend/logger.py`：Python logging，INFO→控制台，ERROR→文件

2. `main.py` 补充全局异常处理器：401/403/404/422/500统一格式

3. `backend/routers/logs.py`：审计日志查询接口

**验收标准**：异常返回统一格式，关键操作有日志

> **🔴 测试门D（Day 20 必须通过）**：运行 `./tests/run_gate.sh D`，全部 PASSED 后方可进入 Day 21。
> 覆盖：全量接口回归（0 FAILED）/ 知识列表 p95 < 500ms / 异步任务完整生命周期 / 覆盖率报告生成。

**输出物**：backend/logger.py, routers/logs.py, 更新 main.py

---

### Day 21 · Docker Compose 生产部署

**前置条件**：Day 20 完成

**任务内容**：

1. `backend/Dockerfile`：Python 3.12-slim，安装依赖，启动 uvicorn

2. `.env` 完整环境变量

3. `docker-compose.yml` 完善：volume持久化 + healthcheck + Nginx（可选）

4. 前端构建集成到FastAPI（`npm run build` → dist/ → mount）

5. `README.md`：部署说明

**验收标准**：`docker compose up -d` 一键启动，浏览器访问可用

**输出物**：Dockerfile, .env, docker-compose.yml(完善), README.md

---

### Day 22 · LLM模型全部测试 + 端到端验证

**前置条件**：Day 21 完成

**任务内容**：

1. 对8个预设LLM模型逐一测试连接（用 `POST /api/llm/providers/{id}/test`），记录哪些模型可用

2. 端到端手动测试清单（全部19个页面 + 帮助系统）：
   - [ ] 登录与三级权限正确
   - [ ] 全部页面"?"按钮可用，帮助内容正确
   - [ ] 知识浏览/搜索/详情
   - [ ] 知识管理CRUD/上传
   - [ ] 经验提交→审核→积分全流程
   - [ ] 个人看板雷达图
   - [ ] 团队看板
   - [ ] BI大屏
   - [ ] 学习中心+每日一题
   - [ ] 个人中心+用户管理
   - [ ] LLM配置+测试+切换
   - [ ] 阿能对话（文本+语音）
   - [ ] 系统设置+飞轮规则
   - [ ] 8个皮肤逐个切换
   - [ ] 批量导入数据验证
   - [ ] 手机端/Pad端/PC端响应式
   - [ ] 性能：列表<500ms，对话<2s

3. 输出 `交付检查清单.md`

**验收标准**：全部测试项通过

> **🔴 测试门E（Day 22 交付验收）**：运行 `./tests/run_gate.sh E`，生成 HTML 覆盖率报告；同步完成三端冒烟清单所有勾选；`交付检查清单.md` 全部打勾后方可进入 Day 23 收尾。

**输出物**：交付检查清单.md

---

### Day 23 · 交付收尾

**前置条件**：Day 22 完成

**任务内容**：

1. 修复Day 22发现的所有问题
2. 最终docker compose测试（全新环境从头启动）
3. `D:\HqEvoAI\交付检查清单.md` 全部打勾

---

## 三、总结

| 维度 | 设计决策 |
|------|---------|
| 总工期 | 23个工作日 |
| 代码文件 | Python ~26个 + Vue ~32个 + 配置5个，约63个文件 |
| 数据库表 | **19张表**（含 regions、aneng_plugins、async_tasks、schema_migrations，完整DDL见附录A+各附录） |
| 容器数量 | 3个（PostgreSQL + Redis + FastAPI含Vue静态文件） |
| 前端框架 | Vue 3 一套代码响应式适配PC/Pad/手机三端 |
| 后端框架 | FastAPI 异步 |
| 检索引擎 | **混合检索**：tsvector关键词 + pgvector语义向量 + RRF融合排序（附录E） |
| LLM接入 | **8个预设模型 + 自定义 + Embedding模型**，全面支持国内主流大模型（附录B） |
| 语音转写 | **腾讯云ASR首选**，支持自定义热词表（车型/专业词汇），短音频同步/长音频异步（附录K） |
| 异步队列 | **Redis List轻量队列**，处理视频转写/批量导入/embedding生成等长耗时任务，前端进度条轮询（附录I） |
| 数据库迁移 | **版本化SQL文件 + 启动自动执行**，无Alembic依赖，schema_migrations表追踪版本（附录J） |
| 角色体系 | **6级真实人事层级**：集团老板/区域总监/门店总经理/部门经理/系统管理员/一线员工，数据范围隔离（附录L） |
| 阿能插件 | **插件式架构**：P1知识问答 / P2经验录入 / P3管理汇报，可扩展（附录F） |
| 题库运营 | AI自动出题 + 手工录入 + Excel导入，完整运营策略和健康度看板（附录G） |
| 个性化推荐 | 基于掌握度+学习记录的差异化首页推荐引擎（附录H） |
| 知情同意 | 登录页知情同意协议，首次必须勾选，数据归属条款明确，审计记录留存（附录M） |
| **RLHF闭环** | **四环闭环**：员工即时反馈+专家精标注+自动标记（环1）→聚合分析+LLM周报（环2）→Prompt优化+知识补丁+检索调参+微调数据导出（环3）→A/B灰度+效果监控+一键回滚（环4），3张专用表（附录N） |
| **节点测试** | **五道测试门**（A/B/C/D/E）：pytest自动化 + 冒烟清单 + 性能基线，Day 5/10/15/20/22各设卡，不通过不进下一阶段（附录O） |
| 皮肤系统 | 8套宋式美学CSS变量皮肤（附录D） |
| BI看板 | ECharts 雷达图/柱状图/热力图/饼图/折线图，按角色权限异构展示 |
| 页面帮助 | **全部19个页面**的"?"帮助系统，统一规范（附录C） |
| 开发原则 | 最简设计、SQL先行、每日有可验收产出、清晰不加班 |

---

## 附录E：混合检索设计（Hybrid RAG）

### E.1 设计原理

纯关键词检索（tsvector）的缺陷：用户说"这辆车抖动"，知识库存的是"发动机怠速异常振动"，关键词不重合导致召回失败。

纯语义向量检索的缺陷：专业零件编号、车型代码（如"BYD汉EV DM-i"）语义相近但字面不同，向量检索反而混淆。

**混合检索 = 关键词 + 语义向量 + RRF融合**，两路互补，召回质量显著高于单路。全部在 PostgreSQL + pgvector 内完成，不引入独立向量数据库。

### E.2 数据库扩展

```sql
-- 安装 pgvector 扩展（PostgreSQL 16 官方支持）
CREATE EXTENSION IF NOT EXISTS vector;

-- 在 knowledge_entries 增加向量字段
ALTER TABLE knowledge_entries ADD COLUMN IF NOT EXISTS
    embedding vector(1536);  -- 适配 text-embedding-3-small / qwen-text-embedding

-- 向量检索索引（HNSW，适合中等规模，<100万条）
CREATE INDEX IF NOT EXISTS idx_ke_embedding
    ON knowledge_entries USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
```

> `vector_index_map` 表保留用于大规模分块场景（单条知识>500字时拆分存储）。初期直接在 `knowledge_entries` 存整条向量即可。

### E.3 检索流程实现（backend/retrieval.py）

```python
async def hybrid_search(
    query: str,
    knowledge_base: str,
    user_position: str,
    top_k: int = 5,
    db: AsyncSession = None,
    embedding_client = None
) -> list[dict]:

    # --- 1. 关键词检索（tsvector） ---
    kw_sql = """
        SELECT id, title, content,
               ts_rank(
                   to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(content,'')),
                   plainto_tsquery('simple', :query)
               ) AS kw_score,
               ROW_NUMBER() OVER (
                   ORDER BY ts_rank(...) DESC
               ) AS kw_rank
        FROM knowledge_entries
        WHERE status = 'approved'
          AND knowledge_base = ANY(:kb_filter)
          AND to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(content,''))
              @@ plainto_tsquery('simple', :query)
        LIMIT 20
    """

    # --- 2. 语义向量检索（pgvector cosine） ---
    query_vec = await embedding_client.embed(query)  # 调 embedding API
    vec_sql = """
        SELECT id, title, content,
               1 - (embedding <=> :query_vec::vector) AS vec_score,
               ROW_NUMBER() OVER (
                   ORDER BY embedding <=> :query_vec::vector
               ) AS vec_rank
        FROM knowledge_entries
        WHERE status = 'approved'
          AND knowledge_base = ANY(:kb_filter)
          AND embedding IS NOT NULL
        ORDER BY embedding <=> :query_vec::vector
        LIMIT 20
    """

    # --- 3. RRF 融合排序 ---
    # RRF(d) = Σ 1/(k + rank_i(d))，k=60 为标准值
    # 合并两路结果，按 id 聚合，计算 RRF 得分，取 Top-5
    k = 60
    scores = {}
    for row in kw_results:
        scores.setdefault(row.id, {"data": row, "rrf": 0})
        scores[row.id]["rrf"] += 1 / (k + row.kw_rank)
    for row in vec_results:
        scores.setdefault(row.id, {"data": row, "rrf": 0})
        scores[row.id]["rrf"] += 1 / (k + row.vec_rank)

    ranked = sorted(scores.values(), key=lambda x: x["rrf"], reverse=True)
    return [r["data"] for r in ranked[:top_k]]
```

### E.4 Embedding 接入

Embedding API 统一在 `llm_providers` 表新增一类 `provider_type = 'embedding'`，或在现有模型记录中增加 `is_embedding BOOLEAN DEFAULT false` 字段。

| 推荐模型 | provider | 维度 | 备注 |
|---------|----------|------|------|
| text-embedding-3-small | custom(OpenAI兼容) | 1536 | 效果好，按token计费 |
| qwen-text-embedding-v3 | tongyi | 1024 | 国内访问稳定 |
| embedding-3 | zhipu | 2048 | 免费额度大 |

**Embedding 写入时机**：
1. 知识条目 `status` 变为 `approved` 时，异步任务调 embedding API，结果写入 `embedding` 字段
2. 知识内容编辑后（`version+1`），重新生成 embedding
3. `backend/routers/knowledge.py` 的 approve 动作触发 background task

```python
# 示例：审核通过时异步写向量
from fastapi import BackgroundTasks

@router.post("/review/{id}/approve")
async def approve_knowledge(id: int, bg: BackgroundTasks, ...):
    # 更新 status
    await db.execute(update_status_sql)
    # 异步生成 embedding，不阻塞审核响应
    bg.add_task(generate_and_save_embedding, knowledge_id=id)
    return ok()
```

### E.5 Day 任务影响

| 受影响 Day | 新增工作 |
|-----------|---------|
| Day 2 | init.sql 增加 `CREATE EXTENSION vector`；knowledge_entries 增加 embedding 字段和 HNSW 索引 |
| Day 12 | chat.py 调用 `hybrid_search()` 替换原 tsvector 单路检索；新增 `backend/retrieval.py` |
| Day 13 | llm.py 增加 embedding 模型配置支持（`is_embedding` 字段）；LLMSettings.vue 展示 embedding 模型 |
| Day 19 | 性能验收目标：混合检索 <300ms（含 embedding API 调用缓存） |

---

## 附录F：阿能插件架构设计

### F.1 设计原理

阿能不是单一的问答机器人，而是一个**插件式 AI 助手平台**。用户输入（文字或语音）经意图识别路由到对应插件，每个插件有独立的 Prompt 模板、数据源和输出格式。新业务能力通过新增插件扩展，不改动核心对话流程。

```
用户输入（文字/语音）
       ↓
  意图识别（LLM分类 or 关键词规则）
       ↓
  ┌────────────────────────────────┐
  │         插件路由器              │
  └────────────────────────────────┘
   ↓            ↓             ↓
[P1:知识问答] [P2:经验录入] [P3:管理汇报]  ... [未来插件]
```

### F.2 数据库：插件配置表

```sql
CREATE TABLE IF NOT EXISTS aneng_plugins (
    id SERIAL PRIMARY KEY,
    plugin_code VARCHAR(50) UNIQUE NOT NULL,  -- 'knowledge_qa' / 'experience_input' / 'mgmt_report'
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    allowed_roles VARCHAR(200) NOT NULL DEFAULT 'boss,admin,staff',  -- 逗号分隔
    system_prompt TEXT,           -- 该插件的系统Prompt模板
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

插件启用/停用由管理员在系统设置中控制，灰度上线新插件时只需插入一条记录。

### F.3 当前三个插件详细设计

---

#### 插件 P1：24小时知识问答与学习指导

**plugin_code**: `knowledge_qa`
**触发条件**: 默认插件，其他插件未匹配时兜底
**允许角色**: boss / admin / staff（全员）

**流程**:
```
用户提问 → 混合检索(附录E) → Top-5知识片段 → 组装Prompt → LLM流式回答 → 返回答案+引用来源
```

**系统Prompt模板**:
```
你是合群汽车集团的数字老师"阿能"。你的任务是基于企业知识库内容，用简洁专业的语言回答员工问题。
当前员工岗位：{position}，所在部门：{dept_name}，门店：{store_name}。

以下是从知识库中检索到的相关内容：
{context}

请基于以上内容回答员工的问题。如果知识库中没有相关信息，请如实告知并建议员工联系对应部门。
每次回答结束后加上："还有什么不清楚的地方？"
```

**前端展示**: 回答正文 + 引用知识卡片（标题可点击跳转详情）

---

#### 插件 P2：24小时语音工作经验录入

**plugin_code**: `experience_input`
**触发条件**: 意图识别为"我想记录/分享一个经验"，或用户点击阿能面板的"录入经验"按钮
**允许角色**: staff（一线员工）

**流程**:
```
员工语音/文字输入经验内容
       ↓
ASR转写（如为语音）
       ↓
LLM结构化整理：提取标题、正文、建议标签、建议分类
       ↓
展示预览草稿，员工确认/修改
       ↓
一键提交 → knowledge_entries(status='pending') → 进入审核队列
       ↓
experience_points +1（提交积分）
```

**结构化整理Prompt**:
```
员工提交了以下工作经验内容，请帮助整理为标准知识条目格式：

原文：{raw_content}
员工岗位：{position}

请输出JSON格式：
{
  "title": "简洁的经验标题（15字以内）",
  "content": "整理后的完整内容（保留细节，补充逻辑）",
  "suggested_tags": ["标签1", "标签2", "标签3"],
  "suggested_category": "建议的知识分类名称",
  "car_brand": "涉及的车型品牌（无则留空）",
  "car_model": "具体车型（无则留空）"
}
```

**前端展示**: ANengChat内嵌草稿预览卡片，含"修改"和"直接提交"按钮

---

#### 插件 P3：管理层语音工作汇报

**plugin_code**: `mgmt_report`
**触发条件**: 意图识别包含"汇报"/"报告"/"情况"，且用户角色为 boss/admin
**允许角色**: boss / admin（老板、总经理、部门经理、店长）

**触发示例**:
- "阿能，给我汇报一下前天到今天的员工知识库使用情况"
- "昨天各部门知识学习怎么样"
- "最近三天经验沉淀情况如何"

**时间解析**: LLM从语音中提取时间范围，转为 `start_date` / `end_date`，传入数据查询层

**数据查询层** (`backend/routers/chat.py` → `report_plugin.py`):

```python
async def generate_mgmt_report(
    start_date: date, end_date: date,
    requester_role: str, requester_dept_id: int
) -> dict:
    # a. 知识库使用情况
    usage = await db.execute("""
        SELECT
            d.name AS dept_name,
            s.name AS store_name,
            COUNT(DISTINCT lr.user_id) AS active_users,
            COUNT(lr.id) AS total_views,
            SUM(lr.duration_sec)/60 AS total_minutes
        FROM learning_records lr
        JOIN users u ON u.id = lr.user_id
        LEFT JOIN departments d ON d.id = u.dept_id
        LEFT JOIN stores s ON s.id = u.store_id
        WHERE lr.created_at BETWEEN :start AND :end
          AND (:dept_filter OR u.dept_id = :dept_id)
        GROUP BY d.name, s.name
        ORDER BY active_users DESC
    """, {...})

    # b. 经验沉淀情况
    contributions = await db.execute("""
        SELECT
            d.name AS dept_name,
            u.position,
            COUNT(*) AS submitted,
            SUM(CASE WHEN ke.status='approved' THEN 1 ELSE 0 END) AS approved
        FROM knowledge_entries ke
        JOIN users u ON u.real_name = ke.source_person
        LEFT JOIN departments d ON d.id = u.dept_id
        WHERE ke.created_at BETWEEN :start AND :end
          AND ke.source_type = 'experience'
        GROUP BY d.name, u.position
    """, {...})

    # c. 各岗位知识掌握情况（复用 personal_dashboard 计算逻辑）
    mastery = await calc_dept_mastery_matrix(start_date, end_date)

    return {"usage": usage, "contributions": contributions, "mastery": mastery}
```

**LLM汇报生成Prompt**:
```
你是合群汽车集团的数字助理"阿能"。请根据以下数据，以汇报口吻向{role_name}做工作汇报。

汇报时间范围：{start_date} 至 {end_date}

【知识库使用数据】
{usage_table}

【经验沉淀数据】
{contribution_table}

【各岗位掌握情况】
{mastery_matrix}

要求：
1. 先说总体情况（人数、活跃率）
2. 分部门/门店点评亮点和薄弱项
3. 对经验贡献排名靠前的部门/个人给予肯定
4. 结尾给出1-2条具体建议
5. 语气专业但不生硬，适合对话式汇报
```

**前端展示**:
- ANengChat 面板内流式输出汇报文字
- 同时渲染数据表格（部门×指标）和柱状图（ECharts）
- 支持"导出PDF汇报"按钮（Day 22 实现）

### F.4 意图识别实现

```python
# backend/intent_classifier.py
INTENT_RULES = [
    {
        "plugin": "mgmt_report",
        "keywords": ["汇报", "报告", "情况", "使用情况", "学习情况", "沉淀情况"],
        "required_roles": ["boss", "admin"]
    },
    {
        "plugin": "experience_input",
        "keywords": ["记录经验", "分享经验", "我想录入", "帮我整理"],
        "required_roles": ["staff", "admin"]
    }
    # 未匹配则路由到 knowledge_qa
]

async def classify_intent(text: str, user_role: str) -> str:
    for rule in INTENT_RULES:
        if user_role in rule["required_roles"]:
            if any(kw in text for kw in rule["keywords"]):
                return rule["plugin"]
    return "knowledge_qa"  # 默认
```

> 初期用关键词规则，V2 升级为 LLM 意图分类（few-shot prompt）。

### F.5 未来插件扩展预留

| 插件代码 | 名称 | 依赖系统 | 优先级 |
|---------|------|---------|-------|
| `dms_query` | 库存与销售数据查询 | DMS系统API | V2 |
| `crm_followup` | 客户跟进提醒与记录 | CRM系统API | V2 |
| `repair_guide` | 维修工单辅助创建 | 维修保养系统 | V2 |
| `finance_calc` | 金融方案计算与推荐 | 金融业务系统 | V3 |

扩展方式：`aneng_plugins` 表插入新记录 + `backend/plugins/` 目录新增对应插件模块，核心路由代码无需修改。

### F.6 Day 任务影响

| 受影响 Day | 新增工作 |
|-----------|---------|
| Day 2 | init.sql 增加 aneng_plugins 表；种子数据写入3个初始插件记录 |
| Day 12 | chat.py 增加意图识别路由；新增 `backend/intent_classifier.py`；新增 `backend/plugins/knowledge_qa.py`、`experience_input.py`、`mgmt_report.py` |
| Day 14 | SystemSettings.vue 增加"阿能插件"页签，管理员可启用/停用插件 |
| Day 17 | Home.vue 阿能入口按岗位显示不同欢迎语（staff显示"问我学习"，admin/boss显示"听我汇报"）|

---

## 附录G：题库运营策略设计

### G.1 题库来源（三条渠道）

| 来源 | 方式 | 责任人 | 预计占比 |
|------|------|-------|---------|
| **AI自动出题** | 管理员选择已审核知识条目，点击"AI出题"，LLM生成题目草稿，人工审核确认后入库 | 知识管理员 | 60% |
| **手工录入** | 管理员在题库管理页面手动填写，支持四种题型 | 各岗位主管 | 30% |
| **Excel批量导入** | 下载标准模板，填充题目后上传，系统解析入库 | 知识管理员 | 10% |

### G.2 数据库字段扩展

在 `daily_questions` 表补充运营字段：

```sql
ALTER TABLE daily_questions
    ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'retired', 'draft')),
    ADD COLUMN IF NOT EXISTS source_type VARCHAR(20) NOT NULL DEFAULT 'manual'
        CHECK (source_type IN ('manual', 'ai_generated', 'imported')),
    ADD COLUMN IF NOT EXISTS answer_count INT DEFAULT 0,    -- 被答题次数
    ADD COLUMN IF NOT EXISTS correct_count INT DEFAULT 0,  -- 答对次数
    ADD COLUMN IF NOT EXISTS retired_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS retired_reason VARCHAR(200),
    ADD COLUMN IF NOT EXISTS created_by INT REFERENCES users(id);
```

正确率 = `correct_count / answer_count`，低于30%的题目系统自动标记"建议审查"。

### G.3 维护操作界面（ExamManage.vue）

**页面布局：三个页签**

**页签1：题库列表**
- 筛选条件：岗位(全部/销售/技术/客服) / 难度(1-5) / 状态(active/retired/draft) / 来源(手工/AI/导入)
- 列表列：题目摘要 / 岗位 / 难度 / 答题次数 / 正确率 / 状态 / 创建时间 / 操作
- 操作按钮：编辑 / 作废 / 预览
- 批量操作：选中多条后批量作废

**新增/编辑弹窗字段**：
```
题型（单选/多选/判断/填空）
题目内容（文本域）
选项A/B/C/D（单选/多选题显示）
正确答案
解析（必填，答错后展示给员工）
目标岗位（销售/技术/客服/全员）
难度等级（1-5星）
关联知识条目（可选，答错时推荐学习）
```

**作废操作**：需填写作废原因（如"内容过期"/"已有更新版本"），作废后题目 status='retired'，不再推送但历史答题记录保留。

**页签2：AI自动出题**

```
步骤1：从知识库选择1-5条已审核知识条目（搜索/筛选选择）
步骤2：选择生成题型（单选/判断/多选，可多选）
步骤3：选择目标岗位和难度
步骤4：点击"AI生成"→ 调 POST /api/questions/ai-generate
步骤5：展示生成的题目草稿列表（可逐条编辑/删除）
步骤6：点击"全部确认入库" → 批量写入，status='active'
```

**AI出题Prompt**：
```
请基于以下知识内容，生成{count}道{question_types}题目。

知识内容：
{knowledge_content}

要求：
- 题目考核知识的核心要点，避免考察细节数字
- 选项设计要有干扰性，但正确答案唯一明确
- 解析要说明正确答案的依据
- 难度：{difficulty_level}（1=基础识记，5=综合应用）
- 目标岗位：{position}

输出JSON数组格式：
[{
  "question_type": "single_choice",
  "question_content": "...",
  "options": {"A":"...","B":"...","C":"...","D":"..."},
  "answer": "A",
  "explanation": "..."
}]
```

**页签3：题库健康度看板**

```
各岗位题目总数（柱状图）：销售N道 / 技术N道 / 客服N道 / 公共N道
题目难度分布（饼图）：难度1-5各占比
近30天新增趋势（折线图）
正确率分布：
  - 正确率>80%：考虑提升难度
  - 正确率<30%：建议重新出题
预警：
  - 某岗位题目不足20道 → 橙色预警
  - 连续30天无新题 → 红色预警
```

### G.4 推送规则（升级版）

```python
async def get_today_question(user_id: int, position: str) -> dict:
    # 1. 候选池：该岗位(+ 全员) active题目
    # 2. 排除：该用户14天内已答过的题目
    # 3. 优先推送：用户错题本中，关联知识已学习但题目未重答的（强化复习）
    # 4. 次优先：用户薄弱分类关联的题目（从 personal_dashboard 掌握度数据取）
    # 5. 兜底：按难度递增顺序
    # 6. 如所有题目14天内均已答过，重置排除窗口为7天
```

### G.5 更新频率建议（运营规范，写入系统帮助文档）

| 岗位 | 最低题目数 | 建议每月新增 | 检查频率 |
|------|---------|-----------|---------|
| 销售 | 50道 | 10道 | 每月1日 |
| 技术 | 80道 | 15道 | 每月1日 |
| 客服 | 40道 | 8道 | 每月1日 |
| 公共 | 30道 | 5道 | 每季度 |

管理员首页在题库不足最低数量时，显示红色预警卡片，直接链接到 ExamManage AI出题页签。

---

## 附录H：个性化推荐引擎设计

### H.1 设计原理

首页"今日推送"不是按岗位统一推送，而是基于每个员工的**个人学习记录**和**知识掌握薄弱领域**做差异化推荐。所有原始数据（learning_records、knowledge_entries、personal_dashboard 掌握度）已存在，推荐引擎是对现有数据的二次计算，无需新表，无需外部推荐服务。

### H.2 推荐算法（backend/recommendation.py）

```python
async def get_personalized_recommendations(
    user_id: int,
    position: str,
    top_k: int = 5,
    db: AsyncSession = None
) -> list[dict]:
    """
    返回格式：[{knowledge_id, title, reason_tag, reason_text, score}, ...]
    reason_tag: 'weak_area' | 'not_started' | 'popular' | 'new_arrival'
    """

    # --- 步骤1：计算该用户各分类掌握度 ---
    # 复用 personal_dashboard 的掌握度计算逻辑
    mastery = await calc_user_mastery_by_category(user_id, position, db)
    # mastery = {category_id: mastery_ratio, ...}

    # --- 步骤2：找出薄弱分类（掌握度最低的3个） ---
    weak_categories = sorted(mastery.items(), key=lambda x: x[1])[:3]
    weak_cat_ids = [cat_id for cat_id, _ in weak_categories]

    # --- 步骤3：从薄弱分类中找未学知识（高权重，+3分） ---
    weak_unlearned = await db.execute("""
        SELECT ke.id, ke.title, ke.category_id, ke.view_count,
               3.0 AS score,
               'weak_area' AS reason_tag
        FROM knowledge_entries ke
        WHERE ke.status = 'approved'
          AND ke.knowledge_base = ANY(:kb_filter)
          AND ke.category_id = ANY(:weak_cats)
          AND ke.id NOT IN (
              SELECT knowledge_id FROM learning_records
              WHERE user_id = :uid
          )
        ORDER BY ke.view_count DESC
        LIMIT 10
    """, {"uid": user_id, "kb_filter": get_kb_filter(position),
          "weak_cats": weak_cat_ids})

    # --- 步骤4：找完全未开始的分类知识（中权重，+2分） ---
    not_started = await db.execute("""
        SELECT ke.id, ke.title, ke.category_id, ke.view_count,
               2.0 AS score,
               'not_started' AS reason_tag
        FROM knowledge_entries ke
        WHERE ke.status = 'approved'
          AND ke.knowledge_base = ANY(:kb_filter)
          AND ke.category_id NOT IN (
              SELECT DISTINCT ke2.category_id
              FROM learning_records lr
              JOIN knowledge_entries ke2 ON ke2.id = lr.knowledge_id
              WHERE lr.user_id = :uid
          )
          AND ke.id NOT IN (
              SELECT knowledge_id FROM learning_records WHERE user_id = :uid
          )
        ORDER BY ke.useful_count DESC
        LIMIT 10
    """, {"uid": user_id, "kb_filter": get_kb_filter(position)})

    # --- 步骤5：近7天新入库的热门知识（低权重，+1分） ---
    new_popular = await db.execute("""
        SELECT ke.id, ke.title, ke.category_id, ke.view_count,
               1.0 AS score,
               'new_arrival' AS reason_tag
        FROM knowledge_entries ke
        WHERE ke.status = 'approved'
          AND ke.knowledge_base = ANY(:kb_filter)
          AND ke.created_at >= NOW() - INTERVAL '7 days'
          AND ke.id NOT IN (
              SELECT knowledge_id FROM learning_records WHERE user_id = :uid
          )
        ORDER BY ke.view_count DESC
        LIMIT 5
    """, {"uid": user_id, "kb_filter": get_kb_filter(position)})

    # --- 步骤6：合并去重，按 score 降序取 top_k ---
    all_candidates = {}
    for row in [*weak_unlearned, *not_started, *new_popular]:
        if row.id not in all_candidates:
            all_candidates[row.id] = row
        else:
            # 同一知识取最高分
            if row.score > all_candidates[row.id].score:
                all_candidates[row.id] = row

    ranked = sorted(all_candidates.values(), key=lambda x: x.score, reverse=True)

    # --- 步骤7：构造推荐原因文案 ---
    reason_texts = {
        'weak_area': lambda r: f"你的{get_category_name(r.category_id)}掌握度较低，建议补强",
        'not_started': lambda r: f"该分类你尚未开始学习",
        'new_arrival': lambda r: f"本周新上架，同岗位{r.view_count}人已学",
    }

    return [
        {
            "knowledge_id": r.id,
            "title": r.title,
            "reason_tag": r.reason_tag,
            "reason_text": reason_texts[r.reason_tag](r),
            "score": r.score
        }
        for r in ranked[:top_k]
    ]
```

### H.3 前端展示（Home.vue 职员首页）

**今日推送卡片组**：

```vue
<!-- 每张卡片 -->
<div class="recommend-card" @click="goto(item.knowledge_id)">
  <div class="card-title">{{ item.title }}</div>
  <div class="reason-tag" :class="item.reason_tag">
    {{ item.reason_text }}
  </div>
</div>
```

原因标签样式：
- `weak_area` → 橙色标签"补强推荐"
- `not_started` → 蓝色标签"新领域"
- `new_arrival` → 绿色标签"本周新知"

### H.4 缓存策略

个性化推荐计算有一定开销，缓存 key = `recommend:{user_id}`，TTL = **2小时**（Redis）。

以下情况清除缓存，触发重新计算：
- 用户完成一次学习（POST /api/learning/record）
- 用户答题（POST /api/questions/answer）
- 知识库新增 approved 条目（approve 动作）

```python
# 在上述三个接口的写操作完成后：
await redis.delete(f"recommend:{user_id}")
```

### H.5 帮助文案更新（helpContent.ts 首页节）

将首页帮助文案中"今日推送"说明更新为：

```
今日推送：系统根据你的学习记录和岗位知识掌握情况，为你个性化推荐。
掌握度低的分类优先出现，每次学完一条后推荐会随之更新。
```

### H.6 Day 任务影响

| 受影响 Day | 新增工作 |
|-----------|---------|
| Day 8 | personal_dashboard 的掌握度计算逻辑抽取为独立函数 `calc_user_mastery_by_category()`，供推荐引擎复用 |
| Day 17 | 新增 `backend/recommendation.py`；dashboard/home 接口调用推荐引擎；Home.vue 推荐卡片含 reason_tag 样式 |
| Day 19 | 推荐结果 Redis 缓存 2小时；三个写操作埋点清缓存 |

---

## 附录I：异步任务队列设计

### I.1 需要异步处理的场景

| 场景 | 预估耗时 | 不异步的后果 |
|------|---------|------------|
| 视频上传后提取音频+ASR转写 | 30s-5min | 上传界面卡死，超时报错 |
| PDF/DOCX/XLSX批量导入解析 | 5-60s | 管理员等待无响应 |
| 知识条目审核通过后生成 embedding | 1-3s | 审核操作响应慢 |
| 管理汇报生成（P3插件，大数据量） | 3-10s | 阿能对话界面假死 |
| 语音录音转写（ASR） | 2-10s | 经验录入界面卡顿 |

### I.2 技术选型：Redis List 轻量队列

不引入 Celery/RabbitMQ/Kafka，用 **Redis List + FastAPI BackgroundTasks + 轮询状态** 实现，3个容器不变。

```
任务提交接口 → 写入 Redis List（任务队列）→ 立即返回 task_id
Worker协程（FastAPI startup启动）→ 消费队列 → 更新任务状态
前端 → 轮询 GET /api/tasks/{task_id}/status → 完成后刷新结果
```

### I.3 数据库：异步任务状态表

```sql
CREATE TYPE async_task_status_enum AS ENUM ('pending', 'running', 'done', 'failed');
CREATE TYPE async_task_type_enum AS ENUM (
    'video_transcribe', 'audio_transcribe', 'batch_import',
    'generate_embedding', 'mgmt_report'
);

CREATE TABLE IF NOT EXISTS async_tasks (
    id BIGSERIAL PRIMARY KEY,
    task_type async_task_type_enum NOT NULL,
    status async_task_status_enum NOT NULL DEFAULT 'pending',
    payload JSONB NOT NULL,           -- 任务参数（如 knowledge_id, file_path）
    result JSONB,                     -- 任务结果（成功时）
    error_message TEXT,               -- 失败原因
    progress SMALLINT DEFAULT 0,      -- 0-100，进度百分比
    created_by INT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_at_status ON async_tasks(status);
CREATE INDEX IF NOT EXISTS idx_at_user ON async_tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_at_created ON async_tasks(created_at DESC);
```

### I.4 后端实现（backend/task_queue.py）

```python
import asyncio, json
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

QUEUE_KEY = "hqevoai:task_queue"

async def enqueue_task(
    redis: Redis, db: AsyncSession,
    task_type: str, payload: dict, user_id: int
) -> int:
    # 1. 写数据库，获取 task_id
    result = await db.execute(
        "INSERT INTO async_tasks(task_type, payload, created_by) "
        "VALUES (:t, :p, :u) RETURNING id",
        {"t": task_type, "p": json.dumps(payload), "u": user_id}
    )
    task_id = result.scalar()
    await db.commit()

    # 2. 推入 Redis List
    await redis.rpush(QUEUE_KEY, json.dumps({"task_id": task_id, "task_type": task_type}))
    return task_id


async def worker_loop(redis: Redis, db_factory):
    """在 FastAPI startup 启动的后台协程"""
    while True:
        # 阻塞等待，最多5秒（BLPOP）
        item = await redis.blpop(QUEUE_KEY, timeout=5)
        if not item:
            continue
        msg = json.loads(item[1])
        async with db_factory() as db:
            await dispatch_task(msg["task_id"], msg["task_type"], db)


async def dispatch_task(task_id: int, task_type: str, db: AsyncSession):
    await db.execute(
        "UPDATE async_tasks SET status='running', started_at=NOW() WHERE id=:id",
        {"id": task_id}
    )
    await db.commit()
    try:
        task = await db.execute(
            "SELECT payload FROM async_tasks WHERE id=:id", {"id": task_id}
        )
        payload = task.scalar()

        if task_type == "video_transcribe":
            result = await handle_video_transcribe(payload, task_id, db)
        elif task_type == "audio_transcribe":
            result = await handle_audio_transcribe(payload, db)
        elif task_type == "batch_import":
            result = await handle_batch_import(payload, task_id, db)
        elif task_type == "generate_embedding":
            result = await handle_generate_embedding(payload, db)
        elif task_type == "mgmt_report":
            result = await handle_mgmt_report(payload, db)

        await db.execute(
            "UPDATE async_tasks SET status='done', result=:r, "
            "progress=100, finished_at=NOW() WHERE id=:id",
            {"r": json.dumps(result), "id": task_id}
        )
    except Exception as e:
        await db.execute(
            "UPDATE async_tasks SET status='failed', error_message=:e, "
            "finished_at=NOW() WHERE id=:id",
            {"e": str(e), "id": task_id}
        )
    await db.commit()
```

### I.5 API 接口

```
POST /api/tasks/submit        → 提交任务，返回 {task_id}
GET  /api/tasks/{id}/status   → 查询状态 {status, progress, result, error_message}
GET  /api/tasks/my            → 我的任务历史列表（最近20条）
```

### I.6 前端进度展示（通用 TaskProgress 组件）

```vue
<!-- components/TaskProgress.vue -->
<!-- 提交任务后展示进度条，done时回调刷新 -->
<template>
  <div v-if="visible" class="task-progress">
    <div class="task-name">{{ label }}</div>
    <div class="progress-bar">
      <div :style="{ width: progress + '%' }" :class="statusClass" />
    </div>
    <div class="task-status">{{ statusText }}</div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
const props = defineProps({ taskId: Number, label: String })
const emit = defineEmits(['done', 'failed'])

const progress = ref(0)
const statusClass = ref('running')
const statusText = ref('处理中...')
let timer = null

onMounted(() => {
  timer = setInterval(async () => {
    const res = await api.get(`/api/tasks/${props.taskId}/status`)
    progress.value = res.data.progress
    if (res.data.status === 'done') {
      statusClass.value = 'done'
      statusText.value = '处理完成'
      clearInterval(timer)
      emit('done', res.data.result)
    } else if (res.data.status === 'failed') {
      statusClass.value = 'failed'
      statusText.value = '处理失败：' + res.data.error_message
      clearInterval(timer)
      emit('failed')
    }
  }, 2000)  // 每2秒轮询
})
onUnmounted(() => clearInterval(timer))
</script>
```

各场景接入方式：
- **视频上传**（KnowledgeManage.vue）：上传完成后显示 TaskProgress，done 时刷新知识列表
- **批量导入**（KnowledgeManage.vue）：导入提交后显示 TaskProgress + 进度百分比
- **语音转写**（ExperienceSubmit.vue / ANengChat.vue）：录音上传后显示"转写中..."，done 时填充文本框
- **管理汇报**（ANengChat P3插件）：提交汇报请求后显示"阿能正在整理数据..."，done 时展示汇报内容

### I.7 Day 任务影响

| 受影响 Day | 新增工作 |
|-----------|---------|
| Day 2 | init.sql 增加 async_tasks 表 |
| Day 1 | `backend/task_queue.py` 新建；`main.py` startup 启动 `worker_loop` 协程 |
| Day 15 | voice.py 语音转写改为 enqueue_task，返回 task_id；前端用 TaskProgress 组件 |
| Day 16 | video_processor.py 视频转写改为 enqueue_task；批量导入 import_data.py 同步改为队列 |
| Day 12 | P3管理汇报数据量大时走队列；ANengChat 汇报请求返回 task_id + 进度条 |

---

## 附录J：数据库迁移方案（无Alembic）

### J.1 设计原则

不引入 Alembic，用**版本化 SQL 文件 + 启动时自动执行**的方式管理数据库变更。规则简单、开发者可直接读懂迁移历史、无额外依赖。

### J.2 目录结构

```
backend/
└── sql/
    ├── init.sql              # 初始建表（Day 2，仅首次建库执行）
    └── migrations/
        ├── 001_add_embedding_field.sql
        ├── 002_add_async_tasks_table.sql
        ├── 003_add_aneng_plugins_table.sql
        ├── 004_add_question_ops_fields.sql
        └── ...（后续版本持续追加）
```

### J.3 迁移版本追踪表

```sql
-- 在 init.sql 末尾追加，首次建库时一并创建
CREATE TABLE IF NOT EXISTS schema_migrations (
    version INT PRIMARY KEY,
    filename VARCHAR(200) NOT NULL,
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    checksum VARCHAR(64)   -- SHA256前16位，防止文件被篡改
);
```

### J.4 自动执行逻辑（backend/migrate.py）

```python
import os, hashlib
from pathlib import Path
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

MIGRATIONS_DIR = Path(__file__).parent / "sql" / "migrations"

async def run_migrations(db: AsyncSession):
    """FastAPI startup 时调用，自动执行未应用的迁移"""

    # 确保追踪表存在
    await db.execute(text("""
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version INT PRIMARY KEY,
            filename VARCHAR(200) NOT NULL,
            applied_at TIMESTAMPTZ DEFAULT NOW(),
            checksum VARCHAR(64)
        )
    """))
    await db.commit()

    # 读取已应用的版本号
    result = await db.execute(text("SELECT version FROM schema_migrations ORDER BY version"))
    applied = {row[0] for row in result.fetchall()}

    # 扫描 migrations/ 目录，按版本号排序
    migration_files = sorted(
        MIGRATIONS_DIR.glob("*.sql"),
        key=lambda f: int(f.stem.split("_")[0])
    )

    for f in migration_files:
        version = int(f.stem.split("_")[0])
        if version in applied:
            continue

        sql_content = f.read_text(encoding="utf-8")
        checksum = hashlib.sha256(sql_content.encode()).hexdigest()[:16]

        try:
            # 执行迁移 SQL（支持多条语句）
            for statement in sql_content.split(";"):
                stmt = statement.strip()
                if stmt:
                    await db.execute(text(stmt))

            # 记录已应用
            await db.execute(text("""
                INSERT INTO schema_migrations(version, filename, checksum)
                VALUES (:v, :f, :c)
            """), {"v": version, "f": f.name, "c": checksum})
            await db.commit()
            print(f"[Migration] Applied: {f.name}")

        except Exception as e:
            await db.rollback()
            print(f"[Migration] FAILED: {f.name} — {e}")
            raise  # 启动失败，阻止服务启动，强制修复

# 在 main.py 的 startup 事件中调用：
# @app.on_event("startup")
# async def startup():
#     async with async_session() as db:
#         await run_migrations(db)
#     await run_seed_data()
#     asyncio.create_task(worker_loop(...))
```

### J.5 迁移文件编写规范

每个迁移文件：
- 文件名格式：`{三位序号}_{描述}.sql`，如 `005_add_store_region_field.sql`
- 内容只写**增量变更**，全部使用 `IF NOT EXISTS` / `IF EXISTS` 保证幂等
- 禁止修改历史迁移文件（checksum 校验会报错）
- 允许在同一文件包含多条 SQL，用 `;` 分隔

**示例：001_add_embedding_field.sql**
```sql
ALTER TABLE knowledge_entries
    ADD COLUMN IF NOT EXISTS embedding vector(1536);

CREATE INDEX IF NOT EXISTS idx_ke_embedding
    ON knowledge_entries USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64)
```

**示例：002_add_async_tasks_table.sql**
```sql
CREATE TYPE IF NOT EXISTS async_task_status_enum
    AS ENUM ('pending', 'running', 'done', 'failed');

CREATE TABLE IF NOT EXISTS async_tasks (
    id BIGSERIAL PRIMARY KEY,
    task_type VARCHAR(50) NOT NULL,
    status async_task_status_enum NOT NULL DEFAULT 'pending',
    payload JSONB NOT NULL,
    result JSONB,
    error_message TEXT,
    progress SMALLINT DEFAULT 0,
    created_by INT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ
)
```

### J.6 回滚策略

本方案**不提供自动回滚**（与 Alembic 的 downgrade 不同）。理由：生产环境自动回滚风险高于风险本身。

回滚方式：
1. **数据不受影响的变更**（新增字段/表）：直接写一条新迁移 `DROP COLUMN` 即可
2. **数据受影响的变更**：在执行迁移前手工备份，`pg_dump -t table_name > backup.sql`

### J.7 Day 任务影响

| 受影响 Day | 新增工作 |
|-----------|---------|
| Day 1 | 新建 `backend/sql/migrations/` 目录；新建 `backend/migrate.py` |
| Day 2 | `init.sql` 末尾追加 schema_migrations 表；main.py startup 调用 `run_migrations()` |
| Day 2+ | 每次数据库结构变更，新增对应序号的 .sql 文件，不修改 init.sql 和 models.py 外的已有文件 |

---

## 附录K：语音转写方案（腾讯云ASR）

### K.1 选型说明

| 方案 | 优势 | 劣势 |
|------|------|------|
| **腾讯云ASR（首选）** | 中文识别准确率高、汽车行业词汇支持好、国内延迟低、价格合理（0.0007元/秒） | 需腾讯云账号和鉴权 |
| 通义千问Paraformer | 阿里生态，与tongyi LLM同账号 | 中文方言支持弱于腾讯 |
| Dify内置转写 | 接入简单 | 依赖Dify部署，不稳定 |

选腾讯云ASR原因：4S集团员工语音包含大量汽车专业词汇（车型名、零件编号、故障代码），腾讯ASR支持**自定义热词**，可将常用车型名/品牌名加入热词表，显著提升识别准确率。

### K.2 腾讯云ASR接入

**使用接口**：腾讯云「一句话识别」（录音文件识别）

- 短音频（≤60秒，适合经验录入）：`POST https://asr.tencentcloudapi.com` Action=`SentenceRecognition`
- 长音频（>60秒，适合视频转写）：`POST https://asr.tencentcloudapi.com` Action=`CreateRecTask`（异步，需轮询结果）

**鉴权方式**：TC3-HMAC-SHA256 签名，SecretId + SecretKey 存入 `.env`

```python
# backend/asr_client.py
import hmac, hashlib, json, time
from datetime import datetime, timezone
import httpx

class TencentASRClient:
    def __init__(self, secret_id: str, secret_key: str):
        self.secret_id = secret_id
        self.secret_key = secret_key
        self.endpoint = "asr.tencentcloudapi.com"
        self.region = "ap-guangzhou"   # 就近选广州节点

    def _sign(self, payload: dict, action: str) -> dict:
        """TC3-HMAC-SHA256 签名（腾讯云标准）"""
        timestamp = int(time.time())
        date = datetime.fromtimestamp(timestamp, tz=timezone.utc).strftime("%Y-%m-%d")
        body = json.dumps(payload)

        # 规范请求串
        canonical = (
            f"POST\n/\n\n"
            f"content-type:application/json\n"
            f"host:{self.endpoint}\n\n"
            f"content-type;host\n"
            f"{hashlib.sha256(body.encode()).hexdigest()}"
        )
        credential_scope = f"{date}/asr/tc3_request"
        str_to_sign = (
            f"TC3-HMAC-SHA256\n{timestamp}\n{credential_scope}\n"
            f"{hashlib.sha256(canonical.encode()).hexdigest()}"
        )

        # 派生签名密钥
        def hmac_sha256(key, msg):
            return hmac.new(key if isinstance(key, bytes) else key.encode(),
                             msg.encode(), hashlib.sha256).digest()

        secret_date = hmac_sha256(f"TC3{self.secret_key}", date)
        secret_service = hmac_sha256(secret_date, "asr")
        secret_signing = hmac_sha256(secret_service, "tc3_request")
        signature = hmac.new(secret_signing, str_to_sign.encode(), hashlib.sha256).hexdigest()

        auth = (
            f"TC3-HMAC-SHA256 Credential={self.secret_id}/{credential_scope}, "
            f"SignedHeaders=content-type;host, Signature={signature}"
        )
        return {
            "Authorization": auth,
            "Content-Type": "application/json",
            "Host": self.endpoint,
            "X-TC-Action": action,
            "X-TC-Version": "2019-06-14",
            "X-TC-Timestamp": str(timestamp),
            "X-TC-Region": self.region,
        }

    async def transcribe_short(self, audio_data: bytes, audio_format: str = "wav") -> str:
        """短音频（≤60s）一句话识别，同步返回文字"""
        import base64
        payload = {
            "EngSerViceType": "16k_zh",   # 16kHz中文通用模型
            "SourceType": 1,               # 1=音频数据（base64）
            "VoiceFormat": audio_format,
            "Data": base64.b64encode(audio_data).decode(),
            "HotwordId": "汽车行业热词表ID",  # 管理员在腾讯云控制台配置后填入
        }
        headers = self._sign(payload, "SentenceRecognition")
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"https://{self.endpoint}",
                headers=headers,
                json=payload,
                timeout=30.0
            )
        result = resp.json()
        if result.get("Response", {}).get("Result"):
            return result["Response"]["Result"]
        raise Exception(result.get("Response", {}).get("Error", {}).get("Message", "ASR失败"))

    async def transcribe_long_submit(self, audio_url: str) -> str:
        """长音频提交任务，返回 TaskId"""
        payload = {
            "EngModelType": "16k_zh",
            "ChannelNum": 1,
            "ResTextFormat": 0,
            "SourceType": 0,   # 0=URL
            "Url": audio_url,
        }
        headers = self._sign(payload, "CreateRecTask")
        async with httpx.AsyncClient() as client:
            resp = await client.post(f"https://{self.endpoint}", headers=headers, json=payload)
        result = resp.json()
        return str(result["Response"]["Data"]["TaskId"])

    async def transcribe_long_query(self, task_id: str) -> dict:
        """查询长音频转写结果"""
        payload = {"TaskId": int(task_id)}
        headers = self._sign(payload, "DescribeTaskStatus")
        async with httpx.AsyncClient() as client:
            resp = await client.post(f"https://{self.endpoint}", headers=headers, json=payload)
        data = resp.json()["Response"]["Data"]
        return {"status": data["Status"], "result": data.get("Result", "")}
        # Status: 0=等待 1=执行 2=成功 3=失败
```

### K.3 热词表配置（提升行业准确率）

在腾讯云 ASR 控制台创建热词表，写入合群集团常用词汇：

```
比亚迪 汉EV 宋PLUS 海豹 仰望
DM-i DM-p 刀片电池
故障码 P0300 P0420
PDI 预交检 大保养 小保养
置换 金融 首付 月供
```

热词表ID（`HotwordId`）写入 `system_config` 表，key = `tencent_asr_hotword_id`，管理员在系统设置中填写。

### K.4 配置项（.env 补充）

```env
TENCENT_ASR_SECRET_ID=AKIDxxxxxxxxxx
TENCENT_ASR_SECRET_KEY=xxxxxxxxxx
TENCENT_ASR_REGION=ap-guangzhou
```

### K.5 语音处理流程（整合异步队列）

```
短音频（录音≤60s）：
  MediaRecorder录音 → 上传 → POST /api/voice/upload
  → asr_client.transcribe_short() 同步调用（约2-5s）
  → 直接返回文字，无需队列

长音频（视频音轨/长录音>60s）：
  文件上传 → enqueue_task('audio_transcribe') → 返回 task_id
  → worker调用 transcribe_long_submit() 获取腾讯TaskId
  → 轮询 transcribe_long_query() 直到 Status=2
  → 更新 async_tasks.result → 前端 TaskProgress 展示完成
```

### K.6 Day 任务影响

| 受影响 Day | 变更内容 |
|-----------|---------|
| Day 1 | `.env` 增加 TENCENT_ASR_* 配置项；`config.py` 读取 |
| Day 15 | `voice.py` 引入 `TencentASRClient`；短音频同步转写，长音频走异步队列（附录I）；`system_config` 种子数据增加 `tencent_asr_hotword_id` 空值占位 |
| Day 14 | SystemSettings.vue 增加"语音识别"配置项：SecretId（脱敏显示）/ SecretKey / Region / 热词表ID |

---

## 附录L：4S集团角色权限体系设计

### L.1 真实人事层级

```
集团层
  └── 集团老板 / 董事长（group_boss）
        └── 区域总监（region_director）—— 管辖多家门店
              └── 门店总经理（store_gm）—— 管辖一家门店
                    ├── 销售经理（dept_manager, position=sales）
                    ├── 技术服务经理（dept_manager, position=tech）
                    └── 客服经理（dept_manager, position=service）
                          └── 一线员工（staff）
                                销售顾问 / 技师 / 客服专员

系统层（横切，不对应业务层级）
  └── 系统管理员（sys_admin）—— 负责知识库维护、用户管理、系统配置
```

### L.2 数据库调整：用户表角色枚举扩展

替换原 `user_role_enum`，重建为：

```sql
-- 先删除旧枚举（Day 2 init.sql 中替换）
-- 新角色枚举
CREATE TYPE user_role_enum AS ENUM (
    'group_boss',       -- 集团老板/董事长
    'region_director',  -- 区域总监
    'store_gm',         -- 门店总经理
    'dept_manager',     -- 部门经理（销售/技术/客服）
    'sys_admin',        -- 系统管理员
    'staff'             -- 一线员工
);

CREATE TYPE user_position_enum AS ENUM ('sales', 'tech', 'service');

-- 用户表增加 region_id 字段（区域总监管辖区域）
ALTER TABLE users ADD COLUMN IF NOT EXISTS region_id INT;

-- 区域表（新增）
CREATE TABLE IF NOT EXISTS regions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- stores 表增加 region_id
ALTER TABLE stores ADD COLUMN IF NOT EXISTS region_id INT REFERENCES regions(id) ON DELETE SET NULL;
```

完整用户表字段（替换附录A.3）：

```sql
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    real_name VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role_enum NOT NULL DEFAULT 'staff',
    position user_position_enum,
    dept_id INT,
    store_id INT,
    region_id INT,
    phone VARCHAR(20),
    avatar_url VARCHAR(200),
    status SMALLINT NOT NULL DEFAULT 1,
    last_login_at TIMESTAMPTZ,
    consent_agreed BOOLEAN NOT NULL DEFAULT false,   -- 知情同意（附录M）
    consent_agreed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE SET NULL,
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE SET NULL,
    FOREIGN KEY (region_id) REFERENCES regions(id) ON DELETE SET NULL
);
```

### L.3 各角色权限矩阵

| 功能模块 | group_boss | region_director | store_gm | dept_manager | sys_admin | staff |
|---------|-----------|----------------|---------|-------------|----------|-------|
| **知识库浏览** | 全部4库 | 全部4库 | 全部4库 | 本岗位库+公共 | 全部4库 | 本岗位库+公共 |
| **知识管理（CRUD）** | 只读 | 只读 | 只读 | 只读 | ✅ | ✗ |
| **经验提交** | ✗ | ✗ | ✗ | ✅（提交部门经验）| ✅ | ✅ |
| **审核中心** | 只读 | 只读 | 只读 | ✗ | ✅ | ✗ |
| **个人看板** | ✗ | ✗ | ✗ | ✅（看自己）| ✅ | ✅ |
| **部门/门店看板** | 全集团 | 管辖区域内 | 本门店 | 本部门 | 全集团 | ✗ |
| **BI大屏** | 全集团 | 管辖区域内 | 本门店 | 本部门 | 全集团 | ✗ |
| **阿能P3汇报** | ✅全集团 | ✅区域 | ✅门店 | ✅部门 | ✗ | ✗ |
| **每日一题** | ✗ | ✗ | ✗ | ✗ | ✅ | ✅ |
| **用户管理** | 只读 | 只读（本区域） | 只读（本门店）| ✗ | ✅ | ✗ |
| **系统设置** | ✗ | ✗ | ✗ | ✗ | ✅ | ✗ |
| **LLM配置** | ✗ | ✗ | ✗ | ✗ | ✅ | ✗ |

### L.4 数据可见范围规则（后端统一实现）

```python
# backend/auth.py — 数据范围过滤器
def get_data_scope(user) -> dict:
    """返回该用户可见的 store_ids / dept_ids / region_ids"""
    if user.role in ('group_boss', 'sys_admin'):
        return {"scope": "all"}
    elif user.role == 'region_director':
        return {"scope": "region", "region_id": user.region_id}
    elif user.role == 'store_gm':
        return {"scope": "store", "store_id": user.store_id}
    elif user.role == 'dept_manager':
        return {"scope": "dept", "dept_id": user.dept_id, "store_id": user.store_id}
    else:  # staff
        return {"scope": "self", "user_id": user.id}
```

所有 dashboard、用户列表、审计日志查询接口，调用 `get_data_scope()` 过滤结果，不在业务逻辑中硬编码角色判断。

### L.5 导航菜单按角色渲染

```javascript
// frontend/src/router.ts — 菜单可见性规则
const MENU_RULES = {
    '知识库':       ['group_boss','region_director','store_gm','dept_manager','sys_admin','staff'],
    '经验提交':     ['dept_manager','sys_admin','staff'],
    '学习中心':     ['sys_admin','staff'],
    '每日一题':     ['sys_admin','staff'],
    '审核中心':     ['sys_admin'],
    '知识管理':     ['sys_admin'],
    '个人看板':     ['sys_admin','staff'],
    '团队看板':     ['group_boss','region_director','store_gm','dept_manager','sys_admin'],
    'BI大屏':       ['group_boss','region_director','store_gm','dept_manager','sys_admin'],
    '用户管理':     ['sys_admin'],
    '系统设置':     ['sys_admin'],
    'LLM配置':      ['sys_admin'],
}
```

### L.6 种子数据扩展（Day 2）

```python
# 新增区域
regions = [{"name": "海口区域"}]

# 新增测试用户（覆盖全角色）
test_users = [
    {"username": "boss",        "role": "group_boss",     "real_name": "集团老板"},
    {"username": "region01",    "role": "region_director","real_name": "区域总监", "region_id": 1},
    {"username": "gm01",        "role": "store_gm",       "real_name": "旗舰店总经理", "store_id": 1},
    {"username": "sales_mgr01", "role": "dept_manager",   "real_name": "销售经理",
     "position": "sales", "dept_id": 1, "store_id": 1},
    {"username": "admin",       "role": "sys_admin",      "real_name": "系统管理员"},
    {"username": "sales01",     "role": "staff", "position": "sales",   "dept_id": 1, "store_id": 1},
    {"username": "tech01",      "role": "staff", "position": "tech",    "dept_id": 2, "store_id": 1},
    {"username": "service01",   "role": "staff", "position": "service", "dept_id": 3, "store_id": 1},
]
# 所有用户默认密码 hequn123
```

### L.7 Day 任务影响

| 受影响 Day | 变更内容 |
|-----------|---------|
| Day 2 | init.sql 替换 user_role_enum 为6级枚举；新增 regions 表；users 表增加 region_id、consent_agreed 字段；种子数据覆盖全角色 |
| Day 3 | auth.py JWT payload 增加 region_id；新增 `get_data_scope()` 函数；权限函数扩展为 `require_role(*roles)` 支持新枚举值 |
| Day 4 | SideMenu.vue 按新 MENU_RULES 渲染导航 |
| Day 9 | dashboard/team 和 dashboard/global 接口应用 `get_data_scope()` 过滤 |

---

## 附录M：员工行为数据知情同意设计

### M.1 知情同意协议正文

以下协议文本在登录页展示，员工首次登录时必须勾选同意。

---

**合群汽车集团 · 员工业务数据使用知情同意书**

尊敬的员工：

在您使用"合群汽车集团AI+业务能力知识库系统"（以下简称"本系统"）前，请仔细阅读以下说明。

**一、数据采集范围**

您在本系统中产生的以下行为数据，将被系统自动记录：

1. 知识查阅记录：您浏览、搜索、收藏的知识条目及时长；
2. 学习行为数据：您的学习进度、答题记录、知识掌握评估结果；
3. 经验贡献内容：您主动提交的工作经验、话术、技术总结等文字及语音内容；
4. 系统使用记录：登录时间、操作日志、与数字助理"阿能"的对话内容；
5. 其他在本系统内产生的业务相关行为数据。

**二、数据归属与使用目的**

上述数据系您在履行职务行为过程中产生，依据劳动合同及公司制度，**数据所有权归合群汽车集团所有**。公司将使用上述数据用于：

- 员工能力评估与培训改进；
- 企业知识库的建设与持续优化；
- 业务运营分析与管理决策支持；
- 人工智能模型训练与知识推荐优化。

**三、数据保护承诺**

1. 您的行为数据仅在公司内部及授权系统范围内使用，不向任何第三方出售或转让；
2. 管理人员查看员工数据须经系统权限控制，遵循最小必要原则；
3. 员工离职后，其历史贡献数据（经验内容、知识条目）保留在知识库中，个人身份信息按相关法规要求处理。

**四、您的权利**

您有权通过系统管理员查询本人的数据记录。如对数据使用有疑问，请联系系统管理员或人力资源部门。

**五、同意声明**

勾选"我已阅读并同意"，即表示您已知晓上述内容，同意在本系统中产生的业务数据归公司所有，并授权公司按上述目的使用。

本知情同意书自您首次登录系统时生效，适用于您在职期间使用本系统的全部行为。

**合群汽车集团 人力资源部 / 信息技术部**

---

### M.2 前端实现（Login.vue）

```vue
<!-- 登录表单底部，提交按钮上方 -->
<div class="consent-area">
  <div class="consent-text-preview">
    <!-- 显示协议前3行摘要 + 展开按钮 -->
    <span class="preview">使用本系统即表示您同意公司数据政策...</span>
    <button class="link-btn" @click="showConsentModal = true">查看完整协议</button>
  </div>
  <label class="consent-checkbox">
    <input type="checkbox" v-model="consentChecked" />
    <span>我已阅读并同意《员工业务数据使用知情同意书》</span>
  </label>
</div>

<!-- 完整协议弹窗 -->
<Teleport to="body">
  <div v-if="showConsentModal" class="modal-overlay" @click.self="showConsentModal = false">
    <div class="consent-modal">
      <div class="modal-header">
        <h3>员工业务数据使用知情同意书</h3>
        <button @click="showConsentModal = false">×</button>
      </div>
      <div class="modal-body consent-content">
        <!-- 附录M.1全文，渲染为格式化文本 -->
      </div>
      <div class="modal-footer">
        <button class="btn-primary" @click="consentChecked = true; showConsentModal = false">
          我已阅读，同意
        </button>
      </div>
    </div>
  </div>
</Teleport>

<!-- 登录按钮，未同意时禁用 -->
<button
  class="btn-login"
  :disabled="!consentChecked"
  :title="consentChecked ? '' : '请先阅读并同意知情同意书'"
  @click="handleLogin"
>
  登录
</button>
```

**登录逻辑补充**：

```typescript
// stores/auth.ts — login 函数
async function login(username: string, password: string, consentAgreed: boolean) {
  const res = await api.post('/api/auth/login', {
    username, password, consent_agreed: consentAgreed
  })
  // ...
}
```

```python
# backend/routers/users.py — POST /api/auth/login
class LoginRequest(BaseModel):
    username: str
    password: str
    consent_agreed: bool = False

async def login(req: LoginRequest, db: AsyncSession):
    user = await verify_user(req.username, req.password, db)
    # 首次同意时写入数据库
    if req.consent_agreed and not user.consent_agreed:
        await db.execute(
            "UPDATE users SET consent_agreed=true, consent_agreed_at=NOW() WHERE id=:id",
            {"id": user.id}
        )
        await db.commit()
    # 已同意用户无需重复传 consent_agreed=true
    return generate_token(user)
```

### M.3 首次登录强制同意逻辑

```
用户输入账号密码
  ↓
后端验证通过（但先不返回token）
  ↓
如果 user.consent_agreed = false：
  前端：checkbox未勾选 → 登录按钮禁用，无法登录
  用户必须勾选后才能点击"登录"
  ↓
提交时带 consent_agreed=true → 后端写入 consent_agreed_at
  ↓
返回JWT token，正常进入系统

已同意用户（consent_agreed = true）：
  正常显示checkbox但默认勾选（只读），无需重复操作
```

### M.4 审计记录

同意动作写入 audit_logs：

```python
action = "consent_agreed"
target_type = "user"
target_id = user.id
detail = f"用户首次登录同意数据知情同意书，IP: {client_ip}"
```

### M.5 Day 任务影响

| 受影响 Day | 变更内容 |
|-----------|---------|
| Day 2 | users 表增加 `consent_agreed BOOLEAN DEFAULT false` 和 `consent_agreed_at TIMESTAMPTZ` 字段（已在附录L.2的DDL中包含） |
| Day 3 | Login.vue 增加知情同意区域和弹窗；LoginRequest schema 增加 consent_agreed 字段；登录接口写入同意记录；审计日志埋点 |

---

## 附录N：RLHF专家反馈闭环设计

### N.1 设计概述

**现状诊断**

当前系统已有基础反馈采集（`chat_logs.is_satisfied`、`useful_count`、`POST /api/chat/feedback`），但这些数据仅用于统计展示，**未形成改进AI行为的闭环**。在汽车销售集团场景中，阿能回答质量直接影响员工销售能力和客户体验，必须通过持续专家反馈迭代提升。

**RLHF四环闭环架构**

```
环1：人类反馈收集
  员工实时点赞/踩 + 领域专家精标注 + 管理层抽查评分
        ↓
环2：反馈聚合与分析
  数据清洗 → 问题归因 → 优先级排序 → 改进周报自动生成
        ↓
环3：依据反馈改进模型/策略
  Prompt优化 + 知识库修补 + 检索调参 + 微调数据集生成
        ↓
环4：改进后重新部署，形成闭环
  A/B测试 → 灰度上线 → 效果监控 → 版本管理与回滚
        ↓（返回环1，持续迭代）
```

**三层渐进改进策略**（不依赖算力直接改LLM权重）

| 层级 | 改进手段 | 响应周期 |
|------|---------|---------|
| 即时层 | Prompt工程优化、系统指令调整 | 当天可部署 |
| 策略层 | 检索参数调优、知识库补充纠错 | 1-3天 |
| 模型层 | 生成微调训练数据集，提交LLM服务商微调 | 1-4周 |

---

### N.2 数据库：RLHF专用表（migrations/010_rlhf_tables.sql）

#### N.2.1 详细反馈表

```sql
CREATE TYPE feedback_source_enum AS ENUM (
    'user_thumb',     -- 员工点赞/踩
    'expert_review',  -- 领域专家精标注
    'mgmt_audit',     -- 管理层抽查
    'auto_flag'       -- 系统自动标记（触发预警规则）
);

CREATE TABLE IF NOT EXISTS rlhf_feedback (
    id BIGSERIAL PRIMARY KEY,
    chat_log_id BIGINT NOT NULL REFERENCES chat_logs(id) ON DELETE CASCADE,
    feedback_source feedback_source_enum NOT NULL DEFAULT 'user_thumb',
    overall_score SMALLINT CHECK (overall_score BETWEEN 1 AND 5),
    is_helpful BOOLEAN,
    dimension_scores JSONB,
    -- {"factual_accuracy":4,"relevance":5,"completeness":3,
    --  "tone":4,"citation_quality":2,"practical_value":3}
    preferred_answer TEXT,        -- 专家填写的理想回答
    rejection_reason TEXT,        -- 问题原因描述
    improvement_suggestion TEXT,  -- 改进建议
    tags VARCHAR(500),            -- "幻觉/引用错误/话术不当/信息过时"
    reviewer_id INT REFERENCES users(id) ON DELETE SET NULL,
    is_used_for_training BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rf_chat     ON rlhf_feedback(chat_log_id);
CREATE INDEX IF NOT EXISTS idx_rf_score    ON rlhf_feedback(overall_score);
CREATE INDEX IF NOT EXISTS idx_rf_source   ON rlhf_feedback(feedback_source);
CREATE INDEX IF NOT EXISTS idx_rf_training ON rlhf_feedback(is_used_for_training);
CREATE INDEX IF NOT EXISTS idx_rf_created  ON rlhf_feedback(created_at DESC);
```

#### N.2.2 改进任务追踪表

```sql
CREATE TYPE improvement_type_enum AS ENUM (
    'prompt_update',    -- Prompt模板修改
    'knowledge_patch',  -- 知识库内容补充/纠错
    'retrieval_tuning', -- 检索参数调优（RRF权重/topK）
    'plugin_update',    -- 插件Prompt更新
    'llm_switch',       -- 切换LLM模型
    'finetune_dataset'  -- 导出微调数据集
);

CREATE TYPE improvement_status_enum AS ENUM (
    'identified',   -- 已识别问题
    'in_progress',  -- 改进中
    'testing',      -- A/B测试中
    'deployed',     -- 已上线
    'reverted'      -- 已回滚
);

CREATE TABLE IF NOT EXISTS rlhf_improvement_tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    improvement_type improvement_type_enum NOT NULL,
    status improvement_status_enum NOT NULL DEFAULT 'identified',
    problem_description TEXT NOT NULL,
    solution_description TEXT,
    before_config JSONB,        -- 改进前配置快照
    after_config JSONB,         -- 改进后配置快照
    feedback_count INT DEFAULT 0,
    baseline_score DECIMAL(4,2),
    improved_score DECIMAL(4,2),
    deployed_at TIMESTAMPTZ,
    created_by INT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### N.2.3 模型版本快照表

```sql
CREATE TABLE IF NOT EXISTS rlhf_model_versions (
    id SERIAL PRIMARY KEY,
    version_tag VARCHAR(50) NOT NULL,     -- 如 "v1.2-20260610"
    description TEXT,
    prompt_snapshot JSONB,                -- 全插件系统Prompt快照
    retrieval_config JSONB,               -- 检索参数快照（topK、RRF k值等）
    llm_provider_id INT REFERENCES llm_providers(id),
    is_active BOOLEAN DEFAULT false,      -- 当前生效版本
    is_ab_candidate BOOLEAN DEFAULT false,
    ab_traffic_ratio SMALLINT DEFAULT 0,  -- A/B流量比例（0-100）
    avg_score DECIMAL(4,2),
    total_conversations INT DEFAULT 0,
    deployed_at TIMESTAMPTZ,
    retired_at TIMESTAMPTZ,
    created_by INT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

> 以上3张表在 `migrations/010_rlhf_tables.sql` 中完整定义，Day 2随其他迁移文件一并执行。

---

### N.3 环1：人类反馈收集

#### N.3.1 三类反馈渠道

**渠道A — 员工即时反馈（低门槛，高数量）**

在 `ANengChat.vue` 每条阿能回复末尾追加反馈条：

```vue
<!-- ANengChat.vue — 每条AI回复末尾 -->
<div class="answer-feedback">
  <span class="feedback-hint">这个回答对你有帮助吗？</span>
  <button :class="{'active': rated === 1}" @click="rate(1)">👍 有用</button>
  <button :class="{'active': rated === -1}" @click="rate(-1)">👎 没用</button>
  <button v-if="rated === -1" class="report-detail" @click="showDetailFeedback = true">
    说说哪里不对
  </button>
</div>

<!-- 踩后展开快速原因选择 -->
<div v-if="showDetailFeedback" class="quick-tags">
  <span>问题类型：</span>
  <label v-for="tag in FEEDBACK_TAGS" :key="tag">
    <input type="checkbox" v-model="selectedTags" :value="tag" />{{ tag }}
  </label>
  <textarea v-model="extraComment" placeholder="补充说明（可选）" rows="2" />
  <button @click="submitDetail">提交</button>
</div>
```

```typescript
// 快速标签选项（对应汽车销售场景）
const FEEDBACK_TAGS = [
  '引用的知识有误', '回答不完整', '话术不适合当前场景',
  '车型信息不准确', '价格/政策已过期', '回答跑题了', '其他'
]
```

后端接口扩展：

```python
# POST /api/chat/feedback（原有接口升级）
class FeedbackRequest(BaseModel):
    chat_log_id: int
    is_helpful: bool
    tags: list[str] = []
    extra_comment: str = ""

@router.post("/chat/feedback")
async def submit_feedback(req: FeedbackRequest, current_user=Depends(...), db=Depends(...)):
    # 更新 chat_logs.is_satisfied
    await db.execute(
        "UPDATE chat_logs SET is_satisfied=:v WHERE id=:id",
        {"v": 1 if req.is_helpful else 0, "id": req.chat_log_id}
    )
    # 同时写 rlhf_feedback 详细记录
    tag_str = "/".join(req.tags)
    await db.execute("""
        INSERT INTO rlhf_feedback
            (chat_log_id, feedback_source, is_helpful, tags,
             rejection_reason, reviewer_id)
        VALUES (:cid, 'user_thumb', :helpful, :tags, :reason, :uid)
    """, {"cid": req.chat_log_id, "helpful": req.is_helpful,
          "tags": tag_str, "reason": req.extra_comment,
          "uid": current_user.id})
    await db.commit()
    return ok()
```

**渠道B — 领域专家精标注（高质量，低数量）**

管理员在系统设置新增"对话质量审查"页签，支持：

- 筛选低分对话（`is_satisfied=0` 或 `overall_score ≤ 2`）
- 筛选高频未命中问题（`is_hit=0`）
- 随机抽取N条对话（用于抽检）
- 每条对话展示：原始问题 + 阿能回答 + 检索引用的知识片段

专家标注界面字段：
```
总体评分（1-5星）
六维评分：事实准确性 / 相关性 / 完整性 / 语气 / 引用质量 / 实用价值（各1-5）
理想回答（专家手写标准答案）
问题原因（自由文本）
改进建议（自由文本）
标记"用于训练数据"（checkbox）
```

后端接口：
```
POST /api/rlhf/expert-review        → 提交专家标注
GET  /api/rlhf/review-queue         → 待审对话队列（筛选/分页）
GET  /api/rlhf/review-queue/random  → 随机抽取N条
```

**渠道C — 系统自动标记（0人工成本）**

在 `chat.py` 对话写入逻辑中，对以下情况自动插入 `rlhf_feedback(feedback_source='auto_flag')`：

```python
# 自动标记规则（backend/rlhf_autoflag.py）
AUTO_FLAG_RULES = [
    {
        "name": "检索未命中",
        "condition": lambda log: log.is_hit == 0,
        "tags": "检索未命中",
        "score": 1
    },
    {
        "name": "回答超时",
        "condition": lambda log: log.response_time_ms > 8000,
        "tags": "响应过慢",
        "score": 2
    },
    {
        "name": "答案极短（可能拒答）",
        "condition": lambda log: len(log.answer) < 30,
        "tags": "回答过短/拒答",
        "score": 2
    },
]

async def auto_flag_if_needed(chat_log, db):
    for rule in AUTO_FLAG_RULES:
        if rule["condition"](chat_log):
            await db.execute("""
                INSERT INTO rlhf_feedback
                    (chat_log_id, feedback_source, overall_score, tags, is_helpful)
                VALUES (:cid, 'auto_flag', :score, :tags, false)
            """, {"cid": chat_log.id, "score": rule["score"],
                  "tags": rule["tags"]})
```

---

### N.4 环2：反馈聚合与分析

#### N.4.1 聚合分析接口（backend/routers/rlhf.py）

```python
# GET /api/rlhf/analytics?days=7&source=all
async def get_rlhf_analytics(days: int = 7, source: str = "all", db=Depends(...)):

    # 1. 满意度趋势（按天）
    satisfaction_trend = await db.execute("""
        SELECT DATE(cl.created_at) AS day,
               COUNT(*) AS total,
               SUM(CASE WHEN cl.is_satisfied=1 THEN 1 ELSE 0 END) AS satisfied,
               AVG(rf.overall_score) AS avg_score
        FROM chat_logs cl
        LEFT JOIN rlhf_feedback rf ON rf.chat_log_id = cl.id
        WHERE cl.created_at >= NOW() - INTERVAL ':days days'
        GROUP BY DATE(cl.created_at)
        ORDER BY day
    """, {"days": days})

    # 2. 问题标签分布（TOP10）
    tag_distribution = await db.execute("""
        SELECT unnest(string_to_array(tags, '/')) AS tag,
               COUNT(*) AS cnt
        FROM rlhf_feedback
        WHERE created_at >= NOW() - INTERVAL ':days days'
          AND is_helpful = false
        GROUP BY tag
        ORDER BY cnt DESC
        LIMIT 10
    """, {"days": days})

    # 3. 高频低分问题（需要优先改进）
    problem_questions = await db.execute("""
        SELECT cl.question,
               COUNT(*) AS complaint_count,
               AVG(rf.overall_score) AS avg_score,
               STRING_AGG(DISTINCT rf.tags, ' | ') AS all_tags
        FROM chat_logs cl
        JOIN rlhf_feedback rf ON rf.chat_log_id = cl.id
        WHERE rf.is_helpful = false
          AND cl.created_at >= NOW() - INTERVAL ':days days'
        GROUP BY cl.question
        HAVING COUNT(*) >= 2
        ORDER BY complaint_count DESC, avg_score ASC
        LIMIT 20
    """, {"days": days})

    # 4. 六维平均分（仅含专家标注数据）
    dimension_scores = await db.execute("""
        SELECT
            AVG((dimension_scores->>'factual_accuracy')::numeric) AS factual_accuracy,
            AVG((dimension_scores->>'relevance')::numeric)        AS relevance,
            AVG((dimension_scores->>'completeness')::numeric)     AS completeness,
            AVG((dimension_scores->>'tone')::numeric)             AS tone,
            AVG((dimension_scores->>'citation_quality')::numeric) AS citation_quality,
            AVG((dimension_scores->>'practical_value')::numeric)  AS practical_value
        FROM rlhf_feedback
        WHERE feedback_source = 'expert_review'
          AND created_at >= NOW() - INTERVAL ':days days'
    """, {"days": days})

    return ok({
        "satisfaction_trend": satisfaction_trend,
        "tag_distribution": tag_distribution,
        "problem_questions": problem_questions,
        "dimension_scores": dimension_scores,
    })
```

#### N.4.2 自动周报生成

每周一0点，后台任务调LLM生成改进周报，推送到管理员首页：

```python
# backend/rlhf_report.py
async def generate_weekly_report(db, llm_client):
    analytics = await get_rlhf_analytics(days=7, db=db)
    prompt = f"""
你是合群汽车集团AI系统的质量分析专家。
请基于以下过去7天的AI对话质量数据，生成一份简洁的改进周报：

满意度趋势：{analytics['satisfaction_trend']}
问题标签TOP5：{analytics['tag_distribution'][:5]}
高频投诉问题：{analytics['problem_questions'][:5]}
六维评分：{analytics['dimension_scores']}

请输出：
1. 本周质量总结（2句话）
2. 最紧迫的3个改进点（各一行，说明原因）
3. 建议的改进优先级排序
"""
    report_text = await llm_client.chat(prompt)
    # 存入 system_config，key = 'rlhf_weekly_report'
    await save_config("rlhf_weekly_report", report_text, db)
    await save_config("rlhf_report_updated_at", str(datetime.now()), db)

---

### N.5 环3：依据反馈改进模型/策略

#### N.5.1 三条改进路径

**路径一：Prompt工程优化（最快，当天生效）**

管理员在 SystemSettings.vue"阿能配置"页签中直接编辑各插件的系统Prompt，修改后系统自动拍快照：

```python
# PUT /api/rlhf/prompt-config
class PromptUpdateRequest(BaseModel):
    plugin_code: str         # 'knowledge_qa' / 'experience_input' / 'mgmt_report'
    new_system_prompt: str
    change_reason: str       # 必填，说明此次修改针对什么反馈问题

@router.put("/rlhf/prompt-config")
async def update_prompt(req: PromptUpdateRequest,
                        current_user=Depends(require_role('sys_admin')),
                        db=Depends(...)):
    # 1. 读取当前 prompt，写入改进任务记录
    old_prompt = await get_plugin_prompt(req.plugin_code, db)
    task_id = await create_improvement_task(
        title=f"Prompt优化：{req.plugin_code}",
        improvement_type="prompt_update",
        problem_description=req.change_reason,
        before_config={"prompt": old_prompt},
        after_config={"prompt": req.new_system_prompt},
        db=db, creator=current_user.id
    )
    # 2. 更新 aneng_plugins 表的 system_prompt
    await db.execute(
        "UPDATE aneng_plugins SET system_prompt=:p WHERE plugin_code=:c",
        {"p": req.new_system_prompt, "c": req.plugin_code}
    )
    # 3. 拍版本快照
    await snapshot_model_version(task_id=task_id, db=db, creator=current_user.id)
    await db.commit()
    return ok({"task_id": task_id})
```

**路径二：知识库定向修补（1-3天）**

基于高频投诉问题，系统辅助管理员定向补充或纠错知识：

```python
# GET /api/rlhf/knowledge-gaps?limit=10
# 返回：被投诉"信息不准确/过期"但知识库无对应条目的问题
async def get_knowledge_gaps(limit: int = 10, db=Depends(...)):
    gaps = await db.execute("""
        SELECT cl.question,
               COUNT(*) AS complaint_count,
               STRING_AGG(rf.preferred_answer, ' || ') AS expert_answers
        FROM chat_logs cl
        JOIN rlhf_feedback rf ON rf.chat_log_id = cl.id
        WHERE rf.tags LIKE '%车型信息不准确%'
           OR rf.tags LIKE '%价格/政策已过期%'
           OR rf.tags LIKE '%引用的知识有误%'
          AND cl.is_hit = 0  -- 检索未命中
        GROUP BY cl.question
        ORDER BY complaint_count DESC
        LIMIT :lim
    """, {"lim": limit})
    return ok(gaps)
```

管理员查看知识缺口后，直接跳转"经验提交"页面补录，或在"知识管理"页面纠错并重新审核通过。审核通过后自动触发 embedding 重建（已有机制，附录E.4）。

**路径三：检索参数调优（配置化，无需重启）**

将 RRF 融合参数、topK 值存入 `system_config` 表，管理员可在后台动态调整：

```
system_config keys:
  rlhf_retrieval_topk         = 5     （最终返回的知识片段数，可调2-10）
  rlhf_rrf_k                  = 60    （RRF公式中的k值，可调20-100）
  rlhf_kw_weight              = 0.5   （关键词检索权重，可调0-1）
  rlhf_vec_weight             = 0.5   （向量检索权重，可调0-1）
  rlhf_min_score_threshold    = 0.1   （低于此分数的结果丢弃）
```

检索层每次请求时从 Redis 缓存读取这些配置（TTL=5min），无需重启服务。

#### N.5.2 微调数据集生成（路径四，长期）

将专家标注的高质量反馈导出为标准微调格式：

```python
# GET /api/rlhf/export-training-data?format=jsonl
async def export_training_data(format: str = "jsonl", db=Depends(...)):
    # 只导出：专家标注 + 有理想答案 + 标记了"用于训练" 的记录
    rows = await db.execute("""
        SELECT
            cl.question AS prompt,
            rf.preferred_answer AS chosen,
            cl.answer AS rejected,
            rf.dimension_scores,
            rf.overall_score
        FROM rlhf_feedback rf
        JOIN chat_logs cl ON cl.id = rf.chat_log_id
        WHERE rf.feedback_source = 'expert_review'
          AND rf.preferred_answer IS NOT NULL
          AND rf.is_used_for_training = true
          AND rf.overall_score <= 3  -- 原回答差，有改进价值
        ORDER BY rf.created_at DESC
    """)
    # 组装为 OpenAI fine-tuning JSONL 格式
    lines = []
    for row in rows:
        lines.append(json.dumps({
            "messages": [
                {"role": "system", "content": ANENG_SYSTEM_PROMPT},
                {"role": "user",   "content": row.prompt},
                {"role": "assistant", "content": row.chosen}
            ]
        }, ensure_ascii=False))
    # 返回文件下载
    content = "\n".join(lines)
    return Response(content=content,
                    media_type="application/jsonlines",
                    headers={"Content-Disposition": "attachment; filename=finetune_data.jsonl"})
```

> 导出的数据集可提交给通义千问/DeepSeek/智谱等支持自定义微调的服务商，形成专属于合群汽车场景的小模型。

---

### N.6 环4：改进后重新部署，形成闭环

#### N.6.1 模型版本管理

每次 Prompt 修改或检索参数调整，系统自动拍快照：

```python
# backend/rlhf_versioning.py
async def snapshot_model_version(task_id: int, db: AsyncSession, creator: int):
    # 读取当前全部插件 Prompt
    plugins = await db.execute("SELECT plugin_code, system_prompt FROM aneng_plugins WHERE is_active=true")
    prompt_snapshot = {row.plugin_code: row.system_prompt for row in plugins}

    # 读取当前检索配置
    retrieval_config = {
        "topk":          await get_config("rlhf_retrieval_topk", db),
        "rrf_k":         await get_config("rlhf_rrf_k", db),
        "kw_weight":     await get_config("rlhf_kw_weight", db),
        "vec_weight":    await get_config("rlhf_vec_weight", db),
    }

    # 获取当前默认 LLM
    provider = await db.execute("SELECT id FROM llm_providers WHERE is_default=true LIMIT 1")

    version_tag = f"v{datetime.now().strftime('%Y%m%d-%H%M')}"
    await db.execute("""
        INSERT INTO rlhf_model_versions
            (version_tag, prompt_snapshot, retrieval_config,
             llm_provider_id, is_active, created_by)
        VALUES (:tag, :prompt, :retrieval, :llm, true, :uid)
    """, {"tag": version_tag, "prompt": json.dumps(prompt_snapshot),
          "retrieval": json.dumps(retrieval_config),
          "llm": provider.id, "uid": creator})
    await db.commit()
    return version_tag
```

#### N.6.2 A/B测试灰度上线

```python
# backend/routers/chat.py — 对话路由时的A/B分流
async def get_active_config(user_id: int, db, redis) -> dict:
    # 检查是否有A/B候选版本
    ab_version = await db.execute("""
        SELECT * FROM rlhf_model_versions
        WHERE is_ab_candidate = true
        LIMIT 1
    """)

    if ab_version:
        # 按 user_id 哈希稳定分流，避免同一用户在不同对话中跳版本
        bucket = hash(str(user_id)) % 100
        if bucket < ab_version.ab_traffic_ratio:
            # 走候选版本
            return {
                "prompts": ab_version.prompt_snapshot,
                "retrieval": ab_version.retrieval_config,
                "version_id": ab_version.id
            }

    # 走当前稳定版本（从 aneng_plugins + system_config 读取）
    return await get_current_active_config(db, redis)
```

A/B 测试管理接口：
```
POST /api/rlhf/ab-test/start      → 启动A/B测试（指定候选版本ID + 流量比例）
GET  /api/rlhf/ab-test/result     → 查看A/B对比数据（满意度/平均分/样本量）
POST /api/rlhf/ab-test/conclude   → 结束测试（选择全量切换or回滚）
```

#### N.6.3 效果监控仪表盘（RLHFDashboard.vue）

管理员在 SystemSettings.vue 新增"AI质量监控"页签，展示：

```
顶部指标卡（4个）：
  本周满意度 / 环比变化 | 专家平均分 | 投诉率 | 未命中率

左侧：满意度7天趋势折线图（ECharts）
中间：问题标签分布饼图（TOP8标签）
右侧：六维雷达图（事实准确性/相关性/完整性/语气/引用质量/实用价值）

下方：高频投诉问题TOP10表格
  列：问题 / 投诉次数 / 平均分 / 主要标签 / 操作（→跳转知识管理补录）

底部：改进任务看板（kanban）
  已识别 | 改进中 | 测试中 | 已上线
  每张卡片显示：标题/类型/关联反馈数/基线分→改进分

右上角：
  "查看本周AI质量周报"按钮（展示LLM自动生成的改进周报）
  "导出训练数据"按钮（调 GET /api/rlhf/export-training-data）
  "版本历史"按钮（展示 rlhf_model_versions 列表，支持一键回滚）
```

#### N.6.4 快速回滚

```python
# POST /api/rlhf/rollback/{version_id}
async def rollback_to_version(version_id: int,
                               current_user=Depends(require_role('sys_admin')),
                               db=Depends(...)):
    version = await db.execute(
        "SELECT * FROM rlhf_model_versions WHERE id=:id", {"id": version_id}
    )
    if not version:
        raise HTTPException(404, "版本不存在")

    # 将快照中的 prompt 写回 aneng_plugins
    for plugin_code, prompt in version.prompt_snapshot.items():
        await db.execute(
            "UPDATE aneng_plugins SET system_prompt=:p WHERE plugin_code=:c",
            {"p": prompt, "c": plugin_code}
        )

    # 将检索配置写回 system_config
    for key, value in version.retrieval_config.items():
        await db.execute(
            "UPDATE system_config SET config_value=:v WHERE config_key=:k",
            {"v": str(value), "k": f"rlhf_{key}"}
        )

    # 清 Redis 缓存，立即生效
    await redis.delete("rlhf:active_config")

    # 审计日志
    await write_audit_log(action="rlhf_rollback", target_id=version_id,
                          detail=f"回滚到版本 {version.version_tag}", user=current_user)
    await db.commit()
    return ok({"rolled_back_to": version.version_tag})
```

---

### N.7 RLHF模块Day任务影响

| 受影响 Day | 新增工作 |
|-----------|---------|
| Day 2 | `migrations/010_rlhf_tables.sql`：新增 `rlhf_feedback`、`rlhf_improvement_tasks`、`rlhf_model_versions` 三张表；`system_config` 种子数据写入检索调参默认值 |
| Day 12 | `chat.py` 对话写入后调用 `auto_flag_if_needed()`；`POST /api/chat/feedback` 接口升级为写 `rlhf_feedback`；`ANengChat.vue` 回复末尾增加👍👎反馈条和快速标签弹窗 |
| Day 14 | `backend/routers/rlhf.py` 新建：聚合分析/专家标注队列/Prompt配置/训练数据导出/A/B测试/回滚接口；`SystemSettings.vue` 新增"AI质量监控"页签（满意度趋势+问题标签+改进看板+周报+版本历史） |
| Day 17 | `backend/rlhf_report.py`：每周一0点触发LLM自动生成改进周报（接入异步队列附录I）；管理员首页增加"AI质量周报"入口卡片 |
| Day 19 | 检索调参配置项加入 Redis 缓存（TTL=5min）；A/B分流在 `chat.py` 中实现；确认 `rlhf_feedback` 相关索引生效 |
| Day 22 | 端到端验收：提交5条带标签的差评 → 专家标注2条 → 查看聚合分析数据正确 → 执行一次Prompt修改 → 确认版本快照生成 → 执行回滚 → 验证配置还原 |

---

### N.8 帮助文案补充（helpContent.ts）

在 `helpContent['SystemSettings']` 的 how 步骤中追加：

```
AI质量监控页签：
  - 查看阿能对话的满意度趋势、问题标签分布、六维评分雷达图
  - 高频投诉问题表格可直接跳转知识管理补录知识
  - 改进任务看板跟踪每项改进的进展状态
  - 每周一自动生成"AI质量周报"，点击右上角"查看周报"获取改进建议
  - "导出训练数据"可下载专家标注的高质量对话，用于提交LLM服务商微调
  - "版本历史"记录每次Prompt修改，支持一键回滚到任意历史版本
```

---

## 附录O：节点测试设计

### O.1 测试策略总览

**现状问题**：原任务卡每日仅有"验收标准"手工检查项，Day 22 才进行统一人工测试。这导致：
- 前期 bug 积压，Day 22 发现问题修复成本极高
- 接口变更破坏已有功能无法及时感知
- 无法量化每个节点的质量状态

**解决方案：四道节点测试门 + 自动化测试基线**

```
Day 1-5   →  [测试门A] 基础设施 + 认证 + 知识浏览
Day 6-10  →  [测试门B] 核心业务 + 看板 + 题库
Day 11-15 →  [测试门C] AI对话 + LLM配置 + 语音
Day 16-20 →  [测试门D] 全链路 + 性能 + 异步任务
Day 21-23 →  [测试门E] 端到端交付验收（原Day 22升级版）
```

**测试分层**

| 层级 | 工具 | 覆盖范围 | 运行时机 |
|------|------|---------|---------|
| 接口自动化测试 | pytest + httpx | 后端全部 API | 每个测试门前运行 |
| 冒烟测试 | 手工执行检查清单 | 前端关键路径 | 每个测试门 |
| 性能基线测试 | `ab` / `wrk` 命令 | 核心接口响应时间 | 测试门D |
| 回归测试 | pytest（全量） | 全部已有接口 | 测试门E |

---

### O.2 自动化测试框架搭建（Day 1 一并创建）

#### O.2.1 目录结构

```
backend/
└── tests/
    ├── conftest.py          # pytest fixtures：测试客户端、测试DB、JWT token
    ├── test_auth.py         # 认证与权限测试
    ├── test_knowledge.py    # 知识库CRUD测试
    ├── test_review.py       # 审核流程测试
    ├── test_dashboard.py    # 看板数据测试
    ├── test_chat.py         # 阿能对话测试（mock LLM）
    ├── test_questions.py    # 题库与答题测试
    ├── test_llm.py          # LLM配置测试
    ├── test_rlhf.py         # RLHF反馈闭环测试
    └── run_gate.sh          # 节点测试门一键执行脚本
```

#### O.2.2 conftest.py

```python
# backend/tests/conftest.py
import pytest
import asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from main import app
from database import get_db
from config import settings

TEST_DB_URL = "postgresql+asyncpg://hqevoai:hqevoai@localhost:5432/hqevoai_test"

@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="session")
async def test_db():
    engine = create_async_engine(TEST_DB_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    yield async_session
    await engine.dispose()

@pytest.fixture
async def client(test_db):
    async def override_get_db():
        async with test_db() as session:
            yield session
    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()

@pytest.fixture
async def staff_token(client):
    res = await client.post("/api/auth/login",
        json={"username": "sales01", "password": "hequn123", "consent_agreed": True})
    return res.json()["data"]["token"]

@pytest.fixture
async def admin_token(client):
    res = await client.post("/api/auth/login",
        json={"username": "admin", "password": "hequn123", "consent_agreed": True})
    return res.json()["data"]["token"]

@pytest.fixture
async def boss_token(client):
    res = await client.post("/api/auth/login",
        json={"username": "boss", "password": "hequn123", "consent_agreed": True})
    return res.json()["data"]["token"]
```

#### O.2.3 requirements 补充

在 `backend/requirements.txt` 追加：
```
pytest==8.3.0
pytest-asyncio==0.24.0
httpx==0.28.0          # 已有，确认版本
pytest-cov==5.0.0
```

---

### O.3 测试门A（Day 5 完成后执行）

**覆盖范围**：基础设施 + 认证 + 知识浏览

```python
# backend/tests/test_auth.py
import pytest

@pytest.mark.asyncio
async def test_login_success(client):
    res = await client.post("/api/auth/login",
        json={"username": "sales01", "password": "hequn123", "consent_agreed": True})
    assert res.status_code == 200
    assert res.json()["data"]["token"] is not None

@pytest.mark.asyncio
async def test_login_wrong_password(client):
    res = await client.post("/api/auth/login",
        json={"username": "sales01", "password": "wrong", "consent_agreed": False})
    assert res.json()["code"] != 0

@pytest.mark.asyncio
async def test_unauthorized_access(client):
    # 无token访问受保护接口，应返回401
    res = await client.get("/api/knowledge")
    assert res.status_code == 401

@pytest.mark.asyncio
async def test_role_isolation_knowledge(client, staff_token):
    # sales01 只能看 public + sales 知识库，不能看 tech
    headers = {"Authorization": f"Bearer {staff_token}"}
    res = await client.get("/api/knowledge?knowledge_base=tech", headers=headers)
    assert res.json()["code"] != 0 or len(res.json()["data"]["items"]) == 0

@pytest.mark.asyncio
async def test_knowledge_list(client, staff_token):
    headers = {"Authorization": f"Bearer {staff_token}"}
    res = await client.get("/api/knowledge?page=1&page_size=10", headers=headers)
    assert res.status_code == 200
    assert "items" in res.json()["data"]

@pytest.mark.asyncio
async def test_health_check(client):
    res = await client.get("/api/health")
    assert res.json()["data"] == "ok"
```

**执行命令**：
```bash
cd backend && pytest tests/test_auth.py tests/test_knowledge.py -v --tb=short
```

**通过标准**：全部用例 PASSED，0 FAILED。不通过则当日不进入 Day 6。

---

### O.4 测试门B（Day 10 完成后执行）

**覆盖范围**：核心业务流程（经验提交→审核→积分）+ 看板 + 题库

```python
# backend/tests/test_review.py
@pytest.mark.asyncio
async def test_experience_submit_to_approve_flow(client, staff_token, admin_token):
    staff_h  = {"Authorization": f"Bearer {staff_token}"}
    admin_h  = {"Authorization": f"Bearer {admin_token}"}

    # 1. 员工提交经验
    res = await client.post("/api/knowledge/submit-experience", headers=staff_h, json={
        "title": "测试经验-自动化用例",
        "content": "这是一条自动化测试用的经验内容，超过30个字符才有效。",
        "category_id": 1,
        "knowledge_base": "sales",
        "tags": "测试/自动化"
    })
    assert res.json()["code"] == 0
    kid = res.json()["data"]["id"]

    # 2. 管理员看到待审核列表
    res = await client.get("/api/review/pending", headers=admin_h)
    ids = [item["id"] for item in res.json()["data"]["items"]]
    assert kid in ids

    # 3. 管理员审核通过
    res = await client.post(f"/api/review/{kid}/approve", headers=admin_h)
    assert res.json()["code"] == 0

    # 4. 积分自动 +10（提交+1 + 审核通过+10 - 已有+1 = 确认approved积分）
    res = await client.get("/api/users/ranking", headers=staff_h)
    assert res.status_code == 200


# backend/tests/test_questions.py
@pytest.mark.asyncio
async def test_today_question_and_answer(client, staff_token):
    headers = {"Authorization": f"Bearer {staff_token}"}

    # 获取今日题目
    res = await client.get("/api/questions/today", headers=headers)
    assert res.json()["code"] == 0
    question = res.json()["data"]
    qid = question["id"]

    # 答题（答对）
    res = await client.post(f"/api/questions/{qid}/answer", headers=headers,
        json={"answer": question["answer"]})
    assert res.json()["data"]["is_correct"] == True

@pytest.mark.asyncio
async def test_dashboard_personal(client, staff_token):
    headers = {"Authorization": f"Bearer {staff_token}"}
    res = await client.get("/api/dashboard/personal", headers=headers)
    data = res.json()["data"]
    assert "radar_data" in data
    assert "mastery_rate" in data
    assert "weak_categories" in data
```

**执行命令**：
```bash
cd backend && pytest tests/test_auth.py tests/test_knowledge.py \
  tests/test_review.py tests/test_questions.py tests/test_dashboard.py -v
```

**通过标准**：全部 PASSED。积分联动数值正确，看板数据格式完整。

---

### O.5 测试门C（Day 15 完成后执行）

**覆盖范围**：阿能对话 + LLM配置 + RLHF反馈 + 语音转写

```python
# backend/tests/test_chat.py
from unittest.mock import AsyncMock, patch

@pytest.mark.asyncio
async def test_chat_ask_with_mock_llm(client, staff_token):
    """用 mock LLM 验证对话流程，不消耗真实 API 配额"""
    headers = {"Authorization": f"Bearer {staff_token}"}

    mock_response = "根据知识库内容，建议您采用三步法介绍车型。还有什么不清楚的地方？"
    with patch("routers.chat.call_llm", new_callable=AsyncMock) as mock_llm:
        mock_llm.return_value = mock_response
        res = await client.post("/api/chat/ask", headers=headers,
            json={"question": "如何介绍星瑞车型"})
    assert res.status_code == 200
    # SSE 流式，验证 chat_logs 写入
    logs_res = await client.get("/api/logs/audit?action=chat", headers=headers)
    assert logs_res.status_code == 200

@pytest.mark.asyncio
async def test_chat_feedback(client, staff_token):
    headers = {"Authorization": f"Bearer {staff_token}"}
    # 先获取最近一条对话日志
    res = await client.get("/api/chat/history?limit=1", headers=headers)
    if res.json()["data"]["items"]:
        log_id = res.json()["data"]["items"][0]["id"]
        # 提交差评+标签
        fb_res = await client.post("/api/chat/feedback", headers=headers, json={
            "chat_log_id": log_id,
            "is_helpful": False,
            "tags": ["引用的知识有误"],
            "extra_comment": "自动化测试"
        })
        assert fb_res.json()["code"] == 0

@pytest.mark.asyncio
async def test_llm_provider_list(client, admin_token):
    headers = {"Authorization": f"Bearer {admin_token}"}
    res = await client.get("/api/llm/providers", headers=headers)
    providers = res.json()["data"]
    assert len(providers) == 8  # 8个预设模型
    assert any(p["provider_type"] == "deepseek" for p in providers)
```

**执行命令**：
```bash
cd backend && pytest tests/ -v --ignore=tests/test_rlhf.py -k "not perf"
```

**通过标准**：全部 PASSED（chat 测试用 mock，不依赖真实LLM key）。

---

### O.6 测试门D（Day 20 完成后执行）

**覆盖范围**：全链路回归 + 性能基线 + 异步任务

**全量回归**：
```bash
cd backend && pytest tests/ -v --cov=. --cov-report=term-missing
# 要求：通过率 100%，主要业务模块覆盖率 ≥ 60%
```

**性能基线测试**（需安装 `ab` 或 `wrk`）：
```bash
# 知识列表接口，100并发，1000请求
ab -n 1000 -c 100 -H "Authorization: Bearer $TOKEN" \
   http://localhost:8000/api/knowledge?page=1&page_size=10

# 验收标准：p95 < 500ms，p99 < 1000ms，错误率 < 0.1%
```

**异步任务验证**：
```python
# backend/tests/test_async_tasks.py
@pytest.mark.asyncio
async def test_async_task_lifecycle(client, admin_token):
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 提交一个测试任务（generate_embedding，payload用已有知识ID）
    res = await client.post("/api/tasks/submit", headers=headers,
        json={"task_type": "generate_embedding", "payload": {"knowledge_id": 1}})
    assert res.json()["code"] == 0
    task_id = res.json()["data"]["task_id"]

    # 轮询直到完成（最多等10秒）
    import asyncio
    for _ in range(10):
        await asyncio.sleep(1)
        status_res = await client.get(f"/api/tasks/{task_id}/status", headers=headers)
        status = status_res.json()["data"]["status"]
        if status in ("done", "failed"):
            break
    assert status == "done"
```

**通过标准**：
- 全量回归 0 FAILED
- 知识列表 p95 < 500ms
- 异步任务正常流转

---

### O.7 测试门E（Day 22 升级版，原端到端验收）

在原 Day 22 手动测试清单基础上，补充以下结构化验收：

**自动化回归（完整版）**：
```bash
cd backend
pytest tests/ -v --cov=. --cov-report=html:coverage_report/
# 生成 HTML 覆盖率报告，存入 D:\HqEvoAI\coverage_report\
```

**RLHF 闭环端到端验收**：
```bash
pytest tests/test_rlhf.py -v
# 验证：差评→rlhf_feedback写入 → 聚合分析数据正确 → Prompt修改→版本快照 → 回滚成功
```

**三端冒烟清单**（手工，每端各执行一遍）：

| 测试场景 | PC端 | Pad端(768px) | 手机端(375px) |
|---------|------|-------------|-------------|
| 登录并通过知情同意 | □ | □ | □ |
| 知识搜索并查看详情 | □ | □ | □ |
| 阿能对话（👍👎反馈） | □ | □ | □ |
| 每日一题答题 | □ | □ | □ |
| 皮肤切换（8套） | □ | □ | □ |
| 管理员审核经验 | □ | — | — |
| BI大屏全屏展示 | □ | — | — |

全部□打勾后，`交付检查清单.md` 方可标记"测试完成"。

---

### O.8 节点测试门快速执行脚本

`backend/tests/run_gate.sh`：

```bash
#!/bin/bash
# 用法: ./run_gate.sh A|B|C|D|E
GATE=$1

case $GATE in
  A)
    echo "=== 测试门A：基础设施 + 认证 + 知识浏览 ==="
    pytest tests/test_auth.py tests/test_knowledge.py -v --tb=short
    ;;
  B)
    echo "=== 测试门B：核心业务流程 + 看板 + 题库 ==="
    pytest tests/test_auth.py tests/test_knowledge.py \
           tests/test_review.py tests/test_questions.py tests/test_dashboard.py -v
    ;;
  C)
    echo "=== 测试门C：AI对话 + LLM配置 + 反馈 ==="
    pytest tests/ --ignore=tests/test_rlhf.py -k "not perf" -v
    ;;
  D)
    echo "=== 测试门D：全量回归 + 性能基线 ==="
    pytest tests/ -v --cov=. --cov-report=term-missing
    ;;
  E)
    echo "=== 测试门E：交付验收（全量 + RLHF）==="
    pytest tests/ -v --cov=. --cov-report=html:coverage_report/
    ;;
  *)
    echo "用法: ./run_gate.sh A|B|C|D|E"
    exit 1
    ;;
esac
```

---

### O.9 节点测试门 Day 任务影响

| Day | 新增工作 |
|-----|---------|
| Day 1 | 创建 `backend/tests/` 目录及 `conftest.py`；requirements.txt 追加 pytest/pytest-asyncio/pytest-cov；`run_gate.sh` 建立 |
| Day 3 | 新增 `tests/test_auth.py`（登录/权限/知情同意用例） |
| Day 5 | 新增 `tests/test_knowledge.py`；**执行测试门A**，全部通过后方可进入 Day 6 |
| Day 7 | 新增 `tests/test_review.py` |
| Day 8 | 新增 `tests/test_dashboard.py` |
| Day 10 | 新增 `tests/test_questions.py`；**执行测试门B**，全部通过后方可进入 Day 11 |
| Day 12 | 新增 `tests/test_chat.py`（mock LLM，不消耗API配额） |
| Day 13 | 新增 `tests/test_llm.py` |
| Day 15 | 新增 `tests/test_async_tasks.py`；**执行测试门C**，全部通过后方可进入 Day 16 |
| Day 19 | 新增 `tests/test_rlhf.py`（RLHF闭环测试） |
| Day 20 | **执行测试门D**（全量回归 + 性能基线），生成覆盖率报告 |
| Day 22 | **执行测试门E**（交付验收），输出最终覆盖率报告 + 三端冒烟清单 |
```
