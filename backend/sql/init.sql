-- =====================================================
-- 合群汽车集团 AI+业务能力知识库 —— 数据库初始化
-- 适用：PostgreSQL 16+
-- 执行方式：容器首次启动，挂载到 /docker-entrypoint-initdb.d/
-- =====================================================

-- 1. pgvector 扩展（混合检索用，不可用时跳过不影响其他表）
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS vector;
    RAISE NOTICE 'pgvector 扩展已启用';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pgvector 扩展不可用，跳过向量功能（不影响基本使用）';
END $$;

-- 2. 枚举类型
DO $$ BEGIN
    CREATE TYPE user_role_enum AS ENUM ('boss', 'admin', 'staff');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE user_position_enum AS ENUM ('sales', 'tech', 'service', 'clerk');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE knowledge_base_enum AS ENUM ('public', 'sales', 'tech', 'service');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE content_type_enum AS ENUM ('text', 'video', 'audio', 'image');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE source_type_enum AS ENUM ('manual', 'experience', 'exam', 'policy', 'video', 'audio');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE entry_status_enum AS ENUM ('draft', 'pending', 'approved', 'rejected', 'archived');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE point_action_enum AS ENUM ('submit', 'approved', 'used');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE transcript_status_enum AS ENUM ('pending', 'done', 'failed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE question_type_enum AS ENUM ('single_choice', 'multi_choice', 'true_false', 'fill_blank');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE llm_provider_type_enum AS ENUM (
        'tongyi', 'deepseek', 'zhipu', 'kimi', 'baichuan',
        'xfyun', 'siliconflow', 'dify', 'custom'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =====================================================
-- 3. 建表（15张）
-- =====================================================

-- A.1 部门表
CREATE TABLE IF NOT EXISTS departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    parent_id INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (parent_id) REFERENCES departments(id) ON DELETE SET NULL
);

-- A.2 门店表
CREATE TABLE IF NOT EXISTS stores (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(300),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- A.3 用户表
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

-- A.4 知识分类表
CREATE TABLE IF NOT EXISTS knowledge_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    parent_id INT,
    knowledge_base knowledge_base_enum NOT NULL,
    sort_order INT DEFAULT 0,
    icon VARCHAR(50),
    description VARCHAR(200),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (parent_id) REFERENCES knowledge_categories(id) ON DELETE SET NULL
);

-- A.5 知识条目主表（不含 vector 字段，避免 pgvector 不可用时建表失败）
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

-- A.6 经验积分表
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

-- A.7 学习记录表
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

-- A.8 语音留言表
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

-- A.9 向量索引映射表
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

-- A.10 每日一题表
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
    category_id INT,
    tags VARCHAR(500),
    push_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (related_knowledge_id) REFERENCES knowledge_entries(id) ON DELETE SET NULL,
    FOREIGN KEY (category_id) REFERENCES knowledge_categories(id) ON DELETE SET NULL
);

-- A.11 对话日志表
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

-- A.12 皮肤偏好表
CREATE TABLE IF NOT EXISTS skin_preferences (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,
    skin_id SMALLINT NOT NULL DEFAULT 1 CHECK (skin_id BETWEEN 1 AND 8),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- A.13 LLM模型配置表
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

-- A.14 系统配置表
CREATE TABLE IF NOT EXISTS system_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    config_type VARCHAR(20) NOT NULL DEFAULT 'string',
    description VARCHAR(200),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- A.15 审计日志表
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

-- =====================================================
-- 4. pgvector 扩展字段（仅在扩展可用时添加）
-- =====================================================
DO $$
DECLARE
    vec_available boolean;
BEGIN
    SELECT count(*) > 0 INTO vec_available FROM pg_available_extensions WHERE name = 'vector';
    IF vec_available THEN
        ALTER TABLE knowledge_entries ADD COLUMN IF NOT EXISTS embedding vector(1536);
        CREATE INDEX IF NOT EXISTS idx_ke_embedding
            ON knowledge_entries USING hnsw (embedding vector_cosine_ops)
            WITH (m = 16, ef_construction = 64);
        RAISE NOTICE 'pgvector 向量字段和索引已创建';
    ELSE
        RAISE NOTICE 'pgvector 不可用，跳过 embedding 字段（混合检索功能需安装 pgvector）';
    END IF;
END $$;

-- =====================================================
-- 5. 索引（附录 A.16）
-- =====================================================

-- knowledge_entries 核心索引
CREATE INDEX IF NOT EXISTS idx_ke_category ON knowledge_entries(category_id);
CREATE INDEX IF NOT EXISTS idx_ke_status ON knowledge_entries(status);
CREATE INDEX IF NOT EXISTS idx_ke_kb ON knowledge_entries(knowledge_base);
CREATE INDEX IF NOT EXISTS idx_ke_brand ON knowledge_entries(car_brand);
CREATE INDEX IF NOT EXISTS idx_ke_created ON knowledge_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ke_source_person ON knowledge_entries(source_person);
CREATE INDEX IF NOT EXISTS idx_ke_view ON knowledge_entries(view_count DESC);

-- 全文搜索（中文用 simple 词典）
CREATE INDEX IF NOT EXISTS idx_ke_fulltext ON knowledge_entries
    USING gin(to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(content,'')));

-- 学习记录
CREATE INDEX IF NOT EXISTS idx_lr_user ON learning_records(user_id);
CREATE INDEX IF NOT EXISTS idx_lr_knowledge ON learning_records(knowledge_id);
CREATE INDEX IF NOT EXISTS idx_lr_created ON learning_records(created_at DESC);

-- 积分
CREATE INDEX IF NOT EXISTS idx_ep_user ON experience_points(user_id);
CREATE INDEX IF NOT EXISTS idx_ep_created ON experience_points(created_at DESC);

-- 对话日志
CREATE INDEX IF NOT EXISTS idx_cl_user ON chat_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_cl_created ON chat_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cl_hit ON chat_logs(is_hit);

-- 审计日志
CREATE INDEX IF NOT EXISTS idx_al_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_al_created ON audit_logs(created_at DESC);
