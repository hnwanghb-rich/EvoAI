--
-- PostgreSQL database dump
--

\restrict m7ZzhfYKN2ttYMkpGipzfLJYeooPNvn6AMcPQZbUx54eMy8UWjjVLIM9jEGQr4w

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: content_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.content_type_enum AS ENUM (
    'text',
    'video',
    'audio',
    'image'
);


--
-- Name: entry_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.entry_status_enum AS ENUM (
    'draft',
    'pending',
    'approved',
    'rejected',
    'archived'
);


--
-- Name: knowledge_base_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.knowledge_base_enum AS ENUM (
    'public',
    'sales',
    'tech',
    'service'
);


--
-- Name: llm_provider_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.llm_provider_type_enum AS ENUM (
    'tongyi',
    'deepseek',
    'zhipu',
    'kimi',
    'baichuan',
    'xfyun',
    'siliconflow',
    'dify',
    'custom'
);


--
-- Name: point_action_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.point_action_enum AS ENUM (
    'submit',
    'approved',
    'used'
);


--
-- Name: question_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.question_type_enum AS ENUM (
    'single_choice',
    'multi_choice',
    'true_false',
    'fill_blank'
);


--
-- Name: source_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.source_type_enum AS ENUM (
    'manual',
    'experience',
    'exam',
    'policy',
    'video',
    'audio'
);


--
-- Name: transcript_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.transcript_status_enum AS ENUM (
    'pending',
    'done',
    'failed'
);


--
-- Name: user_position_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_position_enum AS ENUM (
    'sales',
    'tech',
    'service',
    'clerk'
);


--
-- Name: user_role_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role_enum AS ENUM (
    'boss',
    'admin',
    'staff'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    user_id integer,
    username character varying(50),
    action character varying(50) NOT NULL,
    target_type character varying(50),
    target_id bigint,
    detail text,
    ip_address character varying(50),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: chat_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_logs (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    question text NOT NULL,
    answer text DEFAULT ''::text NOT NULL,
    references_json jsonb,
    is_satisfied smallint,
    is_hit smallint DEFAULT 1,
    response_time_ms integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: chat_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_logs_id_seq OWNED BY public.chat_logs.id;


--
-- Name: daily_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_questions (
    id integer NOT NULL,
    question_type public.question_type_enum DEFAULT 'single_choice'::public.question_type_enum NOT NULL,
    question_content text NOT NULL,
    options jsonb,
    answer text NOT NULL,
    explanation text,
    target_position public.user_position_enum,
    difficulty_level smallint DEFAULT 1,
    related_knowledge_id bigint,
    push_date date,
    created_at timestamp with time zone DEFAULT now(),
    tags character varying(500),
    category_id integer,
    CONSTRAINT daily_questions_difficulty_level_check CHECK (((difficulty_level >= 1) AND (difficulty_level <= 5)))
);


--
-- Name: daily_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_questions_id_seq OWNED BY public.daily_questions.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    parent_id integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: exam_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_attempts (
    id integer NOT NULL,
    user_id integer,
    paper_id integer,
    answers jsonb DEFAULT '{}'::jsonb,
    score integer DEFAULT 0,
    total_questions integer DEFAULT 0,
    correct_count integer DEFAULT 0,
    started_at timestamp with time zone DEFAULT now(),
    submitted_at timestamp with time zone,
    status character varying(20) DEFAULT 'started'::character varying
);


--
-- Name: exam_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exam_attempts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exam_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exam_attempts_id_seq OWNED BY public.exam_attempts.id;


--
-- Name: exam_papers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_papers (
    id integer NOT NULL,
    title character varying(200) NOT NULL,
    target_type character varying(20) DEFAULT 'all'::character varying,
    target_value character varying(50),
    time_mode character varying(20) DEFAULT 'anytime'::character varying,
    start_time timestamp with time zone,
    end_time timestamp with time zone,
    duration_minutes integer DEFAULT 60,
    total_questions integer DEFAULT 0,
    status character varying(20) DEFAULT 'active'::character varying,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: exam_papers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exam_papers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exam_papers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exam_papers_id_seq OWNED BY public.exam_papers.id;


--
-- Name: exam_papers_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_papers_questions (
    id integer NOT NULL,
    paper_id integer,
    question_id integer,
    sort_order integer DEFAULT 0
);


--
-- Name: exam_papers_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exam_papers_questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exam_papers_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exam_papers_questions_id_seq OWNED BY public.exam_papers_questions.id;


--
-- Name: experience_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experience_points (
    id integer NOT NULL,
    user_id integer NOT NULL,
    knowledge_id integer,
    points integer DEFAULT 0 NOT NULL,
    action_type public.point_action_enum NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: experience_points_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.experience_points_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: experience_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.experience_points_id_seq OWNED BY public.experience_points.id;


--
-- Name: knowledge_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_categories (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    parent_id integer,
    knowledge_base public.knowledge_base_enum NOT NULL,
    sort_order integer DEFAULT 0,
    icon character varying(50),
    created_at timestamp with time zone DEFAULT now(),
    description character varying(200),
    is_active boolean DEFAULT true
);


--
-- Name: knowledge_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_categories_id_seq OWNED BY public.knowledge_categories.id;


--
-- Name: knowledge_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_entries (
    id bigint NOT NULL,
    title character varying(200) NOT NULL,
    content text DEFAULT ''::text NOT NULL,
    content_type public.content_type_enum DEFAULT 'text'::public.content_type_enum NOT NULL,
    category_id integer NOT NULL,
    sub_category character varying(50),
    knowledge_base public.knowledge_base_enum NOT NULL,
    source_type public.source_type_enum DEFAULT 'manual'::public.source_type_enum NOT NULL,
    source_file_path character varying(500),
    source_person character varying(50),
    source_dept character varying(50),
    media_url character varying(500),
    media_start_sec real DEFAULT 0,
    media_end_sec real DEFAULT 0,
    tags character varying(500),
    car_brand character varying(50),
    car_model character varying(100),
    difficulty_level smallint DEFAULT 1,
    view_count integer DEFAULT 0,
    useful_count integer DEFAULT 0,
    status public.entry_status_enum DEFAULT 'draft'::public.entry_status_enum NOT NULL,
    auditor_id integer,
    audit_comment character varying(500),
    version integer DEFAULT 1,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT knowledge_entries_difficulty_level_check CHECK (((difficulty_level >= 1) AND (difficulty_level <= 5)))
);


--
-- Name: knowledge_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_entries_id_seq OWNED BY public.knowledge_entries.id;


--
-- Name: learning_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.learning_records (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    knowledge_id integer NOT NULL,
    learn_type character varying(20) DEFAULT 'view'::character varying NOT NULL,
    duration_sec integer DEFAULT 0,
    score numeric(5,2),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: learning_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.learning_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: learning_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.learning_records_id_seq OWNED BY public.learning_records.id;


--
-- Name: llm_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.llm_providers (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    provider_type public.llm_provider_type_enum NOT NULL,
    base_url character varying(500) NOT NULL,
    api_key character varying(500) DEFAULT ''::character varying NOT NULL,
    model_name character varying(100) NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    max_tokens integer DEFAULT 2048,
    temperature real DEFAULT 0.7,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: llm_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.llm_providers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: llm_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.llm_providers_id_seq OWNED BY public.llm_providers.id;


--
-- Name: position_capabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.position_capabilities (
    id integer NOT NULL,
    "position" character varying(20) NOT NULL,
    category_id integer NOT NULL
);


--
-- Name: position_capabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.position_capabilities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: position_capabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.position_capabilities_id_seq OWNED BY public.position_capabilities.id;


--
-- Name: skin_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skin_preferences (
    id integer NOT NULL,
    user_id integer NOT NULL,
    skin_id smallint DEFAULT 1 NOT NULL,
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT skin_preferences_skin_id_check CHECK (((skin_id >= 1) AND (skin_id <= 8)))
);


--
-- Name: skin_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.skin_preferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: skin_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.skin_preferences_id_seq OWNED BY public.skin_preferences.id;


--
-- Name: stores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stores (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    address character varying(300),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: stores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stores_id_seq OWNED BY public.stores.id;


--
-- Name: system_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_config (
    id integer NOT NULL,
    config_key character varying(100) NOT NULL,
    config_value text NOT NULL,
    config_type character varying(20) DEFAULT 'string'::character varying NOT NULL,
    description character varying(200),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: system_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.system_config_id_seq OWNED BY public.system_config.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    real_name character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role public.user_role_enum DEFAULT 'staff'::public.user_role_enum NOT NULL,
    "position" public.user_position_enum,
    dept_id integer,
    store_id integer,
    phone character varying(20),
    avatar_url character varying(200),
    status smallint DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: vector_index_map; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vector_index_map (
    id bigint NOT NULL,
    knowledge_id bigint NOT NULL,
    chunk_index integer DEFAULT 0 NOT NULL,
    chunk_text text NOT NULL,
    embedding_model character varying(50),
    vector_store_id character varying(200),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: vector_index_map_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vector_index_map_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vector_index_map_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vector_index_map_id_seq OWNED BY public.vector_index_map.id;


--
-- Name: voice_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.voice_messages (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    audio_path character varying(500) NOT NULL,
    transcript text,
    transcript_status public.transcript_status_enum DEFAULT 'pending'::public.transcript_status_enum NOT NULL,
    related_knowledge_id bigint,
    tags character varying(200),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: voice_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.voice_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: voice_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.voice_messages_id_seq OWNED BY public.voice_messages.id;


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: chat_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_logs ALTER COLUMN id SET DEFAULT nextval('public.chat_logs_id_seq'::regclass);


--
-- Name: daily_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_questions ALTER COLUMN id SET DEFAULT nextval('public.daily_questions_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: exam_attempts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts ALTER COLUMN id SET DEFAULT nextval('public.exam_attempts_id_seq'::regclass);


--
-- Name: exam_papers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_papers ALTER COLUMN id SET DEFAULT nextval('public.exam_papers_id_seq'::regclass);


--
-- Name: exam_papers_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_papers_questions ALTER COLUMN id SET DEFAULT nextval('public.exam_papers_questions_id_seq'::regclass);


--
-- Name: experience_points id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experience_points ALTER COLUMN id SET DEFAULT nextval('public.experience_points_id_seq'::regclass);


--
-- Name: knowledge_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_categories ALTER COLUMN id SET DEFAULT nextval('public.knowledge_categories_id_seq'::regclass);


--
-- Name: knowledge_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_entries ALTER COLUMN id SET DEFAULT nextval('public.knowledge_entries_id_seq'::regclass);


--
-- Name: learning_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_records ALTER COLUMN id SET DEFAULT nextval('public.learning_records_id_seq'::regclass);


--
-- Name: llm_providers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.llm_providers ALTER COLUMN id SET DEFAULT nextval('public.llm_providers_id_seq'::regclass);


--
-- Name: position_capabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.position_capabilities ALTER COLUMN id SET DEFAULT nextval('public.position_capabilities_id_seq'::regclass);


--
-- Name: skin_preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skin_preferences ALTER COLUMN id SET DEFAULT nextval('public.skin_preferences_id_seq'::regclass);


--
-- Name: stores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stores ALTER COLUMN id SET DEFAULT nextval('public.stores_id_seq'::regclass);


--
-- Name: system_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_config ALTER COLUMN id SET DEFAULT nextval('public.system_config_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: vector_index_map id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vector_index_map ALTER COLUMN id SET DEFAULT nextval('public.vector_index_map_id_seq'::regclass);


--
-- Name: voice_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_messages ALTER COLUMN id SET DEFAULT nextval('public.voice_messages_id_seq'::regclass);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: chat_logs chat_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_logs
    ADD CONSTRAINT chat_logs_pkey PRIMARY KEY (id);


--
-- Name: daily_questions daily_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_questions
    ADD CONSTRAINT daily_questions_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: exam_attempts exam_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts
    ADD CONSTRAINT exam_attempts_pkey PRIMARY KEY (id);


--
-- Name: exam_papers exam_papers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_papers
    ADD CONSTRAINT exam_papers_pkey PRIMARY KEY (id);


--
-- Name: exam_papers_questions exam_papers_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_papers_questions
    ADD CONSTRAINT exam_papers_questions_pkey PRIMARY KEY (id);


--
-- Name: experience_points experience_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experience_points
    ADD CONSTRAINT experience_points_pkey PRIMARY KEY (id);


--
-- Name: knowledge_categories knowledge_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_categories
    ADD CONSTRAINT knowledge_categories_pkey PRIMARY KEY (id);


--
-- Name: knowledge_entries knowledge_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_entries
    ADD CONSTRAINT knowledge_entries_pkey PRIMARY KEY (id);


--
-- Name: learning_records learning_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_records
    ADD CONSTRAINT learning_records_pkey PRIMARY KEY (id);


--
-- Name: llm_providers llm_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.llm_providers
    ADD CONSTRAINT llm_providers_pkey PRIMARY KEY (id);


--
-- Name: position_capabilities position_capabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.position_capabilities
    ADD CONSTRAINT position_capabilities_pkey PRIMARY KEY (id);


--
-- Name: position_capabilities position_capabilities_position_category_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.position_capabilities
    ADD CONSTRAINT position_capabilities_position_category_id_key UNIQUE ("position", category_id);


--
-- Name: skin_preferences skin_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skin_preferences
    ADD CONSTRAINT skin_preferences_pkey PRIMARY KEY (id);


--
-- Name: skin_preferences skin_preferences_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skin_preferences
    ADD CONSTRAINT skin_preferences_user_id_key UNIQUE (user_id);


--
-- Name: stores stores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stores
    ADD CONSTRAINT stores_pkey PRIMARY KEY (id);


--
-- Name: system_config system_config_config_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_config_key_key UNIQUE (config_key);


--
-- Name: system_config system_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: vector_index_map vector_index_map_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vector_index_map
    ADD CONSTRAINT vector_index_map_pkey PRIMARY KEY (id);


--
-- Name: voice_messages voice_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_messages
    ADD CONSTRAINT voice_messages_pkey PRIMARY KEY (id);


--
-- Name: idx_al_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_al_created ON public.audit_logs USING btree (created_at DESC);


--
-- Name: idx_al_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_al_user ON public.audit_logs USING btree (user_id);


--
-- Name: idx_cl_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cl_created ON public.chat_logs USING btree (created_at DESC);


--
-- Name: idx_cl_hit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cl_hit ON public.chat_logs USING btree (is_hit);


--
-- Name: idx_cl_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cl_user ON public.chat_logs USING btree (user_id);


--
-- Name: idx_ep_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ep_created ON public.experience_points USING btree (created_at DESC);


--
-- Name: idx_ep_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ep_user ON public.experience_points USING btree (user_id);


--
-- Name: idx_ke_brand; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ke_brand ON public.knowledge_entries USING btree (car_brand);


--
-- Name: idx_ke_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ke_category ON public.knowledge_entries USING btree (category_id);


--
-- Name: idx_ke_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ke_created ON public.knowledge_entries USING btree (created_at DESC);


--
-- Name: idx_ke_fulltext; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ke_fulltext ON public.knowledge_entries USING gin (to_tsvector('simple'::regconfig, (((COALESCE(title, ''::character varying))::text || ' '::text) || COALESCE(content, ''::text))));


--
-- Name: idx_ke_kb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ke_kb ON public.knowledge_entries USING btree (knowledge_base);


--
-- Name: idx_ke_source_person; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ke_source_person ON public.knowledge_entries USING btree (source_person);


--
-- Name: idx_ke_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ke_status ON public.knowledge_entries USING btree (status);


--
-- Name: idx_ke_view; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ke_view ON public.knowledge_entries USING btree (view_count DESC);


--
-- Name: idx_lr_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lr_created ON public.learning_records USING btree (created_at DESC);


--
-- Name: idx_lr_knowledge; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lr_knowledge ON public.learning_records USING btree (knowledge_id);


--
-- Name: idx_lr_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lr_user ON public.learning_records USING btree (user_id);


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: chat_logs chat_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_logs
    ADD CONSTRAINT chat_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: daily_questions daily_questions_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_questions
    ADD CONSTRAINT daily_questions_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.knowledge_categories(id) ON DELETE SET NULL;


--
-- Name: daily_questions daily_questions_related_knowledge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_questions
    ADD CONSTRAINT daily_questions_related_knowledge_id_fkey FOREIGN KEY (related_knowledge_id) REFERENCES public.knowledge_entries(id) ON DELETE SET NULL;


--
-- Name: departments departments_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: exam_attempts exam_attempts_paper_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts
    ADD CONSTRAINT exam_attempts_paper_id_fkey FOREIGN KEY (paper_id) REFERENCES public.exam_papers(id) ON DELETE CASCADE;


--
-- Name: exam_attempts exam_attempts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts
    ADD CONSTRAINT exam_attempts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: exam_papers exam_papers_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_papers
    ADD CONSTRAINT exam_papers_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: exam_papers_questions exam_papers_questions_paper_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_papers_questions
    ADD CONSTRAINT exam_papers_questions_paper_id_fkey FOREIGN KEY (paper_id) REFERENCES public.exam_papers(id) ON DELETE CASCADE;


--
-- Name: exam_papers_questions exam_papers_questions_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_papers_questions
    ADD CONSTRAINT exam_papers_questions_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.daily_questions(id) ON DELETE CASCADE;


--
-- Name: experience_points experience_points_knowledge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experience_points
    ADD CONSTRAINT experience_points_knowledge_id_fkey FOREIGN KEY (knowledge_id) REFERENCES public.knowledge_entries(id) ON DELETE SET NULL;


--
-- Name: experience_points experience_points_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experience_points
    ADD CONSTRAINT experience_points_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: daily_questions fk_dq_category; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_questions
    ADD CONSTRAINT fk_dq_category FOREIGN KEY (category_id) REFERENCES public.knowledge_categories(id) ON DELETE SET NULL;


--
-- Name: knowledge_categories knowledge_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_categories
    ADD CONSTRAINT knowledge_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.knowledge_categories(id) ON DELETE SET NULL;


--
-- Name: knowledge_entries knowledge_entries_auditor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_entries
    ADD CONSTRAINT knowledge_entries_auditor_id_fkey FOREIGN KEY (auditor_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: knowledge_entries knowledge_entries_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_entries
    ADD CONSTRAINT knowledge_entries_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.knowledge_categories(id) ON DELETE RESTRICT;


--
-- Name: learning_records learning_records_knowledge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_records
    ADD CONSTRAINT learning_records_knowledge_id_fkey FOREIGN KEY (knowledge_id) REFERENCES public.knowledge_entries(id) ON DELETE CASCADE;


--
-- Name: learning_records learning_records_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_records
    ADD CONSTRAINT learning_records_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: position_capabilities position_capabilities_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.position_capabilities
    ADD CONSTRAINT position_capabilities_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.knowledge_categories(id) ON DELETE CASCADE;


--
-- Name: skin_preferences skin_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skin_preferences
    ADD CONSTRAINT skin_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users users_dept_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_dept_id_fkey FOREIGN KEY (dept_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: users users_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE SET NULL;


--
-- Name: vector_index_map vector_index_map_knowledge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vector_index_map
    ADD CONSTRAINT vector_index_map_knowledge_id_fkey FOREIGN KEY (knowledge_id) REFERENCES public.knowledge_entries(id) ON DELETE CASCADE;


--
-- Name: voice_messages voice_messages_related_knowledge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_messages
    ADD CONSTRAINT voice_messages_related_knowledge_id_fkey FOREIGN KEY (related_knowledge_id) REFERENCES public.knowledge_entries(id) ON DELETE SET NULL;


--
-- Name: voice_messages voice_messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_messages
    ADD CONSTRAINT voice_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: TABLE audit_logs; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.audit_logs TO hqevoai;


--
-- Name: SEQUENCE audit_logs_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.audit_logs_id_seq TO hqevoai;


--
-- Name: TABLE chat_logs; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.chat_logs TO hqevoai;


--
-- Name: SEQUENCE chat_logs_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.chat_logs_id_seq TO hqevoai;


--
-- Name: TABLE daily_questions; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.daily_questions TO hqevoai;


--
-- Name: SEQUENCE daily_questions_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.daily_questions_id_seq TO hqevoai;


--
-- Name: TABLE departments; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.departments TO hqevoai;


--
-- Name: SEQUENCE departments_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.departments_id_seq TO hqevoai;


--
-- Name: TABLE exam_attempts; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.exam_attempts TO hqevoai;


--
-- Name: SEQUENCE exam_attempts_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT USAGE ON SEQUENCE public.exam_attempts_id_seq TO hqevoai;


--
-- Name: TABLE exam_papers; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.exam_papers TO hqevoai;


--
-- Name: SEQUENCE exam_papers_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT USAGE ON SEQUENCE public.exam_papers_id_seq TO hqevoai;


--
-- Name: TABLE exam_papers_questions; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.exam_papers_questions TO hqevoai;


--
-- Name: SEQUENCE exam_papers_questions_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT USAGE ON SEQUENCE public.exam_papers_questions_id_seq TO hqevoai;


--
-- Name: TABLE experience_points; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.experience_points TO hqevoai;


--
-- Name: SEQUENCE experience_points_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.experience_points_id_seq TO hqevoai;


--
-- Name: TABLE knowledge_categories; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.knowledge_categories TO hqevoai;


--
-- Name: SEQUENCE knowledge_categories_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.knowledge_categories_id_seq TO hqevoai;


--
-- Name: TABLE knowledge_entries; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.knowledge_entries TO hqevoai;


--
-- Name: SEQUENCE knowledge_entries_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.knowledge_entries_id_seq TO hqevoai;


--
-- Name: TABLE learning_records; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.learning_records TO hqevoai;


--
-- Name: SEQUENCE learning_records_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.learning_records_id_seq TO hqevoai;


--
-- Name: TABLE llm_providers; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.llm_providers TO hqevoai;


--
-- Name: SEQUENCE llm_providers_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.llm_providers_id_seq TO hqevoai;


--
-- Name: TABLE position_capabilities; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.position_capabilities TO hqevoai;


--
-- Name: SEQUENCE position_capabilities_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT USAGE ON SEQUENCE public.position_capabilities_id_seq TO hqevoai;


--
-- Name: TABLE skin_preferences; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.skin_preferences TO hqevoai;


--
-- Name: SEQUENCE skin_preferences_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.skin_preferences_id_seq TO hqevoai;


--
-- Name: TABLE stores; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.stores TO hqevoai;


--
-- Name: SEQUENCE stores_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.stores_id_seq TO hqevoai;


--
-- Name: TABLE system_config; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.system_config TO hqevoai;


--
-- Name: SEQUENCE system_config_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.system_config_id_seq TO hqevoai;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.users TO hqevoai;


--
-- Name: SEQUENCE users_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.users_id_seq TO hqevoai;


--
-- Name: TABLE vector_index_map; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.vector_index_map TO hqevoai;


--
-- Name: SEQUENCE vector_index_map_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.vector_index_map_id_seq TO hqevoai;


--
-- Name: TABLE voice_messages; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.voice_messages TO hqevoai;


--
-- Name: SEQUENCE voice_messages_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.voice_messages_id_seq TO hqevoai;


--
-- PostgreSQL database dump complete
--

\unrestrict m7ZzhfYKN2ttYMkpGipzfLJYeooPNvn6AMcPQZbUx54eMy8UWjjVLIM9jEGQr4w

