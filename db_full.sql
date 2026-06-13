--
-- PostgreSQL database dump
--

\restrict UenSeeLQ9d7vD1H3Ua3tWdvGj517L1Q8fEwbgHXB9jWGZztZeNgDyB5OAPOHixg

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
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_logs (id, user_id, username, action, target_type, target_id, detail, ip_address, created_at) FROM stdin;
1	1	admin	update_settings	system_config	1	修改 points_submit 为5	127.0.0.1	2026-06-09 13:32:16.015788+08
2	1	admin	update_settings	system_config	1	测试修改配置	127.0.0.1	2026-06-09 13:33:30.467626+08
3	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:01:35.446254+08
4	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-09 14:01:35.973512+08
5	2	admin	test_audit	system	0	测试审计日志写入	127.0.0.1	2026-06-09 14:01:37.582462+08
6	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-09 14:01:38.254245+08
7	1	admin	final_test	system	0	Day20最终验证	127.0.0.1	2026-06-09 14:02:35.470107+08
8	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-09 14:02:48.341314+08
9	1	boss	login	user	1	张总裁 登录系统	127.0.0.1	2026-06-09 14:09:14.466078+08
10	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:09:15.681797+08
11	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-09 14:09:15.072749+08
12	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-09 14:09:16.263539+08
13	5	service01	login	user	5	陈客服 登录系统	127.0.0.1	2026-06-09 14:09:16.84279+08
14	2	admin	review_approve	knowledge_entry	210	通过审核: E2E经验	127.0.0.1	2026-06-09 14:09:17.646806+08
15	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-09 14:23:22.887583+08
16	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:25:45.579653+08
17	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:29:47.655966+08
18	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:29:55.838468+08
19	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:30:06.141643+08
20	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:30:22.924479+08
21	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:32:59.878861+08
22	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:33:20.304733+08
23	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:33:39.005115+08
24	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:35:48.012939+08
25	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:36:49.565163+08
26	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:36:59.603593+08
27	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-09 14:42:54.436028+08
28	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:49:32.786458+08
29	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:51:06.787092+08
30	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-09 14:54:38.103314+08
31	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-10 14:57:28.317268+08
32	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-10 15:07:11.730015+08
33	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-10 15:13:22.415053+08
34	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-10 15:52:27.535182+08
35	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-10 15:52:40.883012+08
36	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-10 15:53:37.530034+08
37	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-10 15:57:03.702466+08
38	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-10 16:09:07.834329+08
39	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 11:38:56.723867+08
40	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 11:53:18.251834+08
41	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 11:54:13.894154+08
42	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 11:54:28.248166+08
43	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 12:11:41.367269+08
44	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 12:38:48.255954+08
45	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 12:44:27.003304+08
46	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-11 13:23:14.907751+08
47	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-11 13:28:17.645649+08
48	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-11 13:28:34.049184+08
49	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 13:42:03.363531+08
50	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 13:42:15.328954+08
51	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 13:42:39.350939+08
52	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 13:43:17.901392+08
53	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-11 13:44:30.742786+08
54	5	service01	login	user	5	陈客服 登录系统	127.0.0.1	2026-06-11 13:57:25.520992+08
55	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 13:58:37.545525+08
56	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 14:31:21.945305+08
57	5	service01	login	user	5	陈客服 登录系统	127.0.0.1	2026-06-11 14:32:14.919159+08
58	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 12:32:59.249243+08
59	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 12:42:08.938518+08
60	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 12:42:34.998914+08
61	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 13:11:02.591892+08
62	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 13:34:21.229715+08
63	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 13:59:07.265769+08
64	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 14:29:12.989702+08
65	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 14:38:55.730177+08
66	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 14:39:08.103008+08
67	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 14:41:25.658828+08
68	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 14:42:21.794345+08
69	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 14:46:25.161382+08
70	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 14:46:59.847939+08
71	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 14:57:34.463265+08
72	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 14:58:54.444749+08
73	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 15:03:32.937066+08
74	2	admin	review_approve	knowledge_entry	233	通过审核: 销售经理驾驶仓数据分析看板 - 片段2 (01:00)	127.0.0.1	2026-06-12 15:19:53.149498+08
75	2	admin	review_approve	knowledge_entry	272	通过审核: 销售经理驾驶仓数据分析看板 - 片段1 (00:00)	127.0.0.1	2026-06-12 15:20:56.351092+08
76	2	admin	review_approve	knowledge_entry	275	通过审核: 销售经理驾驶仓数据分析看板 - 片段1 (00:00)	127.0.0.1	2026-06-12 15:22:10.691854+08
77	2	admin	review_approve	knowledge_entry	5	通过审核: 语音经验	127.0.0.1	2026-06-12 15:22:18.112899+08
78	2	admin	review_approve	knowledge_entry	231	通过审核: 销售经理驾驶仓数据分析看板	127.0.0.1	2026-06-12 15:22:26.018285+08
79	2	admin	review_approve	knowledge_entry	273	通过审核: 销售经理驾驶仓数据分析看板 - 片段2 (01:00)	127.0.0.1	2026-06-12 15:24:35.889121+08
112	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 03:05:45.232567+08
113	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 05:29:21.405587+08
114	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 05:29:26.333283+08
115	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 05:29:43.314516+08
116	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 05:29:47.758602+08
117	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 05:29:55.725733+08
118	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-13 05:29:56.952246+08
119	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 08:03:27.74492+08
120	5	service01	login	user	5	陈客服 登录系统	127.0.0.1	2026-06-13 10:40:56.736631+08
121	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-13 10:47:01.367382+08
122	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 10:48:37.160303+08
123	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 10:52:44.704413+08
124	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 10:53:18.776465+08
125	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-13 11:11:15.806439+08
126	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-13 11:11:50.600509+08
127	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-13 11:12:53.783002+08
128	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 11:33:05.635155+08
129	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-13 11:34:18.403041+08
130	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-13 11:36:25.145009+08
131	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-13 11:39:03.101744+08
132	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-13 11:42:22.3229+08
133	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-13 11:47:32.956683+08
134	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-13 11:51:05.635568+08
135	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-13 11:51:27.310072+08
136	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-13 11:55:58.360681+08
137	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 12:10:24.842139+08
138	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 14:04:24.420258+08
139	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 14:04:47.125972+08
140	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 14:09:29.450733+08
141	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-13 14:22:32.684263+08
142	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 14:38:01.375222+08
143	5	service01	login	user	5	陈客服 登录系统	127.0.0.1	2026-06-13 14:38:21.316866+08
144	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 14:45:05.703839+08
145	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-13 14:49:54.266756+08
146	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-13 14:56:28.813313+08
147	5	service01	login	user	5	陈客服 登录系统	127.0.0.1	2026-06-13 14:56:52.539776+08
148	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-13 15:12:30.825327+08
\.


--
-- Data for Name: daily_questions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_questions (id, question_type, question_content, options, answer, explanation, target_position, difficulty_level, related_knowledge_id, push_date, created_at, tags, category_id) FROM stdin;
2	single_choice	星瑞L6的整车质保政策是？	{"A": "3年/10万公里", "B": "4年/12万公里", "C": "5年/15万公里", "D": "6年/20万公里"}	C	整车5年/15万公里，三电系统终身质保（首任车主）。	sales	2	\N	\N	2026-06-09 13:11:57.42903+08	\N	7
3	true_false	销售顾问可以对客户承诺三电系统终身质保适用于所有车主。	null	false	三电系统终身质保仅适用于首任车主。	sales	1	\N	2026-06-10	2026-06-09 13:11:57.429032+08	\N	7
31	single_choice	合群汽车集团的消防器材点检频率是？	{"A": "每月15日", "B": "每季度一次", "C": "每年一次", "D": "不定期"}	A	每月15日进行消防器材点检，填写检查记录。	\N	1	\N	2026-06-11	2026-06-09 13:11:57.42931+08	\N	1
30	single_choice	客户回访的最佳频次是？	{"A": "每天一次", "B": "保养后7-15天", "C": "每年一次", "D": "从不回访"}	B	保养后7-15天回访可有效了解客户满意度和发现潜在问题。	service	2	\N	\N	2026-06-09 13:11:57.429306+08	\N	23
1	single_choice	星瑞L6的CLTC综合续航里程是多少？	{"A": "800km", "B": "1000km", "C": "1200km", "D": "1500km"}	C	星瑞L6 CLTC综合续航1200km，纯电续航200km。	sales	1	\N	2026-06-09	2026-06-09 13:11:57.429023+08	\N	7
37	single_choice	星瑞L6作为合群汽车集团的旗舰新能源轿车，其CLTC综合续航里程是多少？	{"A": "1000km", "B": "1200km", "C": "1500km", "D": "800km"}	B	根据文档，星瑞L6的CLTC综合续航为1200km，这是其核心续航指标。选项A、C、D均为干扰项，分别接近或偏离实际值。	sales	1	\N	\N	2026-06-10 15:53:43.922789+08	\N	7
46	single_choice	帝豪向上系列采用什么涂装工艺？	{"A": "传统溶剂型喷涂", "B": "环保水性B1B2涂装工艺", "C": "静电粉末喷涂", "D": "电泳涂装工艺"}	B	文档提到采用“环保水性B1B2涂装工艺喷涂”，并搭配德国巴斯夫高耐候涂料，使漆面更炫彩、高亮、耐久、环保。	\N	3	\N	\N	2026-06-10 16:01:19.857907+08	\N	1
48	single_choice	帝豪向上系列的车身扭转刚度达到什么水平？	{"A": "15000N·m/deg", "B": "20000N·m/deg", "C": "25000N·m/deg", "D": "18000N·m/deg"}	B	文档明确指出“同级最强20000N·m/deg车身扭转刚度”，这是其超低用车成本卖点的一部分。	\N	3	\N	\N	2026-06-10 16:01:19.857912+08	\N	1
32	true_false	车间内可以吸烟，但需在指定区域。	null	false	严禁在车间内吸烟或使用明火，这是消防安全强制规定。	\N	1	\N	2026-06-11	2026-06-09 13:11:57.429312+08	\N	1
33	single_choice	安全事故发生后，应在多长时间内向安全主管报告？	{"A": "15分钟内", "B": "1小时内", "C": "24小时内", "D": "72小时内"}	A	发生安全事故后，15分钟内向安全主管报告。	\N	1	\N	2026-06-11	2026-06-09 13:11:57.429314+08	\N	1
34	single_choice	合群汽车集团的企业愿景核心是？	{"A": "利润第一", "B": "知识驱动、全员成长", "C": "快速发展", "D": "削减成本"}	B	合群汽车集团以知识驱动飞轮、全员能力提升为企业成长的核心战略。	\N	1	\N	2026-06-11	2026-06-09 13:11:57.429315+08	\N	1
35	true_false	全员消防演练应每季度进行一次。	null	true	每季度进行一次全员消防演练是集团安全管理制度的要求。	\N	1	\N	2026-06-11	2026-06-09 13:11:57.429317+08	\N	1
43	single_choice	帝豪向上系列的核心产品定位是什么？	{"A": "全球品质冠军家轿", "B": "自主品牌智能先锋", "C": "国民轿车性价比之王", "D": "高端运动轿车标杆"}	A	根据文档，帝豪向上系列的产品定位是“全球品质冠军家轿”，强调其全球化的品质和冠军级表现。	\N	1	\N	2026-06-11	2026-06-10 16:01:19.857891+08	\N	1
45	single_choice	帝豪向上系列的目标人群特征是什么？	{"A": "20-30岁单身女性，追求时尚", "B": "30-40岁已婚已育首购男性用户，本地居住家庭稳定", "C": "25-35岁职场新人，注重科技配置", "D": "40-50岁换购用户，偏好豪华品牌"}	B	文档明确说明目标人群为“本地居住，家庭稳定的30-40岁已婚已育首购男性用户为主”。	\N	1	\N	2026-06-11	2026-06-10 16:01:19.857905+08	\N	1
50	single_choice	帝豪向上系列的全新外观车色叫什么？	{"A": "星尘金", "B": "荣耀金", "C": "暖阳金", "D": "璀璨金"}	B	文档中“全新外观车色-荣耀金”明确标出，该颜色采用银元型铝粉，呈现暖金色泽。	\N	1	\N	2026-06-11	2026-06-10 16:01:19.857916+08	\N	1
55	single_choice	星瑞L6的动力系统综合功率是多少？	{"A": "200kW", "B": "230kW", "C": "250kW", "D": "210kW"}	B	文档指出1.5T混动发动机+前置电机综合功率为230kW，体现了车辆的动力性能。	\N	3	\N	\N	2026-06-10 16:09:12.019438+08	\N	1
53	single_choice	星瑞L6在CLTC工况下的续航里程是多少？	{"A": "1000km", "B": "1200km", "C": "1500km", "D": "1100km"}	C	根据文档，星瑞L6 CLTC续航为1200km，这是其关键卖点之一。	\N	1	\N	2026-06-11	2026-06-10 16:09:12.019432+08	\N	1
89	single_choice	GS3影速的指导价是多少？	{"A": "9.8万", "B": "10.8万", "C": "12.58万", "D": "11.8万"}	B	根据文档，GS3影速的指导价为10.8万。	sales	1	222	\N	2026-06-11 12:38:58.651007+08	金融按揭方案	12
90	single_choice	GS3影速的限时价相比指导价优惠了多少？	{"A": "0.5万", "B": "1万", "C": "1.5万", "D": "2万"}	B	指导价10.8万，限时价9.8万，优惠1万元。	sales	1	222	\N	2026-06-11 12:38:58.662859+08	金融按揭方案	12
91	single_choice	下列哪项是GS3影速的金融方案特点？	{"A": "0首付8万3年0息", "B": "至高置换补贴20000", "C": "金融礼+置换礼", "D": "0首付10万5年0息"}	A	文档显示GS3影速的金融方案为0首付8万3年0息。	sales	2	222	\N	2026-06-11 12:38:58.664049+08	金融按揭方案	12
92	single_choice	GS4 MAX的限时价是多少？	{"A": "12.58万", "B": "10.28万", "C": "9.8万", "D": "11.28万"}	B	文档写明GS4 MAX限时价为10.28万。	sales	1	222	\N	2026-06-11 12:38:58.664892+08	金融按揭方案	12
93	single_choice	GS4 MAX的金融方案中，至高置换补贴金额是多少？	{"A": "10000", "B": "15000", "C": "20000", "D": "25000"}	C	文档指出GS4 MAX至高置换补贴20000。	sales	2	222	\N	2026-06-11 12:38:58.665626+08	金融按揭方案	12
94	single_choice	旗舰版的指导价与哪款车相同？	{"A": "GS3影速", "B": "GS4 MAX", "C": "GS5", "D": "GS8"}	B	旗舰版和GS4 MAX的指导价均为12.58万。	sales	2	222	\N	2026-06-11 12:38:58.666483+08	金融按揭方案	12
95	single_choice	旗舰版的限时优惠是什么？	{"A": "直降1万", "B": "优惠至高6888红包", "C": "置换补贴20000", "D": "0首付方案"}	B	文档显示旗舰版限时价优惠至高6888红包。	sales	2	222	\N	2026-06-11 12:38:58.667501+08	金融按揭方案	12
96	single_choice	旗舰版提供的金融方案包括哪些？	{"A": "仅金融礼", "B": "仅置换礼", "C": "金融礼+置换礼", "D": "0首付方案"}	C	文档写明旗舰版金融方案为金融礼+置换礼。	sales	3	222	\N	2026-06-11 12:38:58.668452+08	金融按揭方案	12
97	single_choice	客户想用0首付购车，应推荐哪款车型？	{"A": "GS3影速", "B": "GS4 MAX", "C": "旗舰版", "D": "以上均可"}	A	只有GS3影速提供0首付8万3年0息的金融方案。	sales	3	222	\N	2026-06-11 12:38:58.669389+08	金融按揭方案	12
76	single_choice	题目1	{"A": "x", "B": "y", "C": "z", "D": "w"}	B	解析1	sales	1	\N	\N	2026-06-11 11:54:13.914485+08	\N	7
77	single_choice	题目2	{"A": "a", "B": "b", "C": "c", "D": "d"}	C	解析2	sales	2	\N	\N	2026-06-11 11:54:13.914491+08	\N	7
78	single_choice	题目3	{"A": "p", "B": "q", "C": "r", "D": "s"}	A	解析3	sales	3	\N	\N	2026-06-11 11:54:13.914494+08	\N	7
74	single_choice	优惠券取消抵扣后，工单必须先做什么才能做质检反完工？	{"A": "重新核销", "B": "取消优惠券抵扣", "C": "删除工单", "D": "更新收费类型"}	B	文档说明工单使用优惠券抵扣后，必须先取消抵扣才能做质检反完工。	\N	3	\N	\N	2026-06-11 11:51:24.642142+08	\N	1
98	single_choice	若客户有旧车置换，最可能获得较高补贴的车型是？	{"A": "GS3影速", "B": "GS4 MAX", "C": "旗舰版", "D": "补贴金额相同"}	B	GS4 MAX至高置换补贴20000，而旗舰版是金融礼+置换礼，未明确金额，GS3影速无置换补贴信息。	sales	3	222	\N	2026-06-11 12:38:58.67031+08	金融按揭方案	12
6	single_choice	试驾过程中，销售顾问首先应该做什么？	{"A": "直接让客户上高速", "B": "讲解试驾路线和安全注意事项", "C": "让客户自行驾驶", "D": "播放音乐"}	B	试驾前必须先讲解路线和安全注意事项，确保客户了解操作。	sales	1	\N	2026-06-11	2026-06-09 13:11:57.429037+08	\N	7
99	single_choice	2025年12月，2026款GS3影速的提车折扣是多少？	{"A": "8000元", "B": "10000元", "C": "12000元", "D": "18000元"}	C	根据文档第5页，2026款GS3影速的提车折扣为12000元。	\N	2	\N	\N	2026-06-11 13:13:41.679675+08	\N	1
56	single_choice	在工单的新增与修改操作中，带有红点的项目代表什么含义？	{"A": "高风险项目", "B": "必填项", "C": "可选项目", "D": "收费项目"}	B	根据文档中‘注：有红点的项目是必填项’的说明，红点标识表示必填内容，确保工单录入的完整性。	\N	1	\N	2026-06-11	2026-06-10 16:16:52.252436+08	\N	1
120	single_choice	员工入职后，住房公积金从什么时候开始提供？	{"A": "入职当月", "B": "转正当月", "C": "入职转正1年后", "D": "入职满两年"}	C	制度明确说明：员工自入职转正1年后公司提供住房公积金。	\N	2	\N	\N	2026-06-11 13:48:27.596648+08	\N	1
147	single_choice	销售顾问排行榜中包含了哪些关键数据？	{"A": "仅包含目标完成率", "B": "包含目标、客户转化率、贡献率等数据", "C": "仅包含订单与交织目标", "D": "包含毛利结构和品牌排名"}	B	文档明确指出销售顾问排行榜包含了目标、客户转化率、贡献率等数据，因此B选项正确。A、C选项过于片面，D选项与排行榜无关。	\N	2	233	\N	2026-06-12 15:19:52.909674+08	\N	7
148	single_choice	以下哪个功能可以帮助管理层快速识别主力车型与短板车型？	{"A": "毛利历史注重图", "B": "业绩趋势图", "C": "排行榜通过核心指标排序", "D": "全车系目标完成情况"}	C	文档提到排行榜通过核心指标进行排序，可快速识别主力车型与短板车型，因此C选项正确。A选项关于毛利历史，B选项关于趋势，D选项关于目标对比，均未直接指向车型识别。	\N	3	233	\N	2026-06-12 15:19:52.909676+08	\N	7
149	single_choice	在销售经理驾驶舱数据看板中，以下哪项功能允许用户按不同时间周期查看数据？	{"A": "点击右上角选择日报、月报、年报", "B": "通过快捷按钮选择周期", "C": "直接查看默认数据", "D": "点击关键数据指标穿透"}	A	文档明确指出，点击右上角可选择查看日报、月报、年报，这是查看不同时间周期数据的主要方式。选项B的快捷按钮是补充功能，但非主要方式。	\N	2	272	\N	2026-06-12 15:20:57.782051+08	\N	7
150	single_choice	销售顾问排行榜中，以下哪项数据不包含在内？	{"A": "目标", "B": "客户转化率", "C": "贡献率", "D": "毛利结构"}	D	文档中列出销售顾问排行榜包含目标、客户转化率、贡献率等数据，毛利结构是独立的模块，不包含在排行榜中。	\N	3	272	\N	2026-06-12 15:20:57.782057+08	\N	7
151	single_choice	销售经理驾驶舱数据看板中，以下哪个功能可以实现对关键数据指标的深入查看？	{"A": "点击右上角选择查看周期", "B": "通过快捷按钮选择周期", "C": "关键数据指标可点击穿透", "D": "查看日、月、年报"}	C	文档中明确提到'关键数据指标可点击穿透'，这是查看深层数据的功能，而其他选项涉及周期选择或报表查看，不直接实现数据穿透。	\N	2	275	\N	2026-06-12 15:22:10.417104+08	\N	7
152	single_choice	在销售经理驾驶舱中，要快速识别主力车型与短板车型，应使用哪个功能模块？	{"A": "毛利历史柱状图", "B": "销售顾问排行榜", "C": "业绩趋势图", "D": "全车系目标完成情况"}	B	文档指出'排行榜通过核心指标进行排序，可快速识别主力车型与短板车型'，而其他模块主要用于查看毛利、趋势或完成率。	\N	2	275	\N	2026-06-12 15:22:10.417109+08	\N	7
153	single_choice	关于销售经理驾驶舱中的毛利结构功能，以下描述正确的是？	{"A": "只能查看总毛利数据", "B": "毛利结构已拆分到具体业务模块", "C": "毛利历史柱状图显示目标完成率", "D": "可通过排行榜查看毛利分布"}	B	文档明确说明'毛利结构已拆分到具体业务模块'，而其他选项与事实不符：A错误因为可查看总毛利和单周毛利；C错误因为柱状图显示历史毛利；D错误因为排行榜不涉及毛利分布。	\N	3	275	\N	2026-06-12 15:22:10.417112+08	\N	7
154	single_choice	在销售经理驾驶舱数据看板中，用户可以通过哪种方式选择查看日报、月报或年报？	{"A": "点击右上角的按钮后选择周期", "B": "通过快捷按钮选择周期", "C": "直接在主界面滑动切换", "D": "点击关键数据指标穿透"}	A	文档中明确提到：点击右上角后，可选择查看日报、月报、年报；同时也提到可以通过快捷按钮选择周期，但题目问的是查看日报、月报、年报的具体方式，对应点击右上角操作。	\N	2	273	\N	2026-06-12 15:24:35.619812+08	\N	7
155	single_choice	销售顾问排行榜中不包含以下哪项数据？	{"A": "目标", "B": "客户转化率", "C": "贡献率", "D": "订单数量"}	D	文档指出销售顾问排行榜包含了目标、客户转化率、贡献率等数据，但未提及订单数量。订单数量属于销售顾问个人业绩穿透后可查看的细节，而非排行榜直接展示的数据。	\N	3	273	\N	2026-06-12 15:24:35.619815+08	\N	7
137	single_choice	通过什么图表可以对比你在各指标上的表现，并直观看出强弱项？	{"A": "柱状图", "B": "折线图", "C": "雷达图", "D": "饼图"}	C	文档提到：这张雷达图可以对比你在各项指标上的表现，强弱项更为直观。	\N	2	\N	\N	2026-06-12 14:55:58.486866+08	\N	1
138	single_choice	二季趋势图主要用于展示什么？	{"A": "每年四季度的业绩变化", "B": "每个月的业绩变化", "C": "每周的业绩变化", "D": "每天的业绩变化"}	B	文档中说明：二季趋势图清晰呈现每个月的业绩变化。	\N	2	\N	\N	2026-06-12 14:55:58.486869+08	\N	1
156	single_choice	在销售经理驾驶舱中，哪个功能可用于快速识别主力车型与短板车型？	{"A": "毛利结构模块", "B": "业绩趋势图", "C": "排行榜", "D": "毛利历史柱状图"}	C	文档明确说明：排行榜通过核心指标进行排序，可快速识别主力车型与短板车型。其他选项虽涉及毛利或趋势分析，但非直接用于车型识别。	\N	3	273	\N	2026-06-12 15:24:35.619817+08	\N	7
146	single_choice	销售经理驾驶舱数据看板支持哪些查看周期？	{"A": "仅支持日报", "B": "日报、月报、年报", "C": "周报、月报、年报", "D": "日报、周报、月报"}	B	根据文档内容，点击右上角可选择查看日报、月报、年报，同时也可以通过快捷按钮选择周期，因此B选项正确。其他选项未提及或与文档不符。	\N	1	233	2026-06-13	2026-06-12 15:19:52.909669+08	\N	7
4	single_choice	销售过程中，遇到客户提出超出权限的价格折扣要求，应该？	{"A": "直接拒绝", "B": "请示销售经理", "C": "自行降价", "D": "忽略客户"}	B	超出权限的价格折扣应请示销售经理，由管理层决策。	sales	2	\N	\N	2026-06-09 13:11:57.429034+08	\N	7
5	single_choice	下列哪项属于合群汽车集团金融按揭方案的特色？	{"A": "仅合作一家银行", "B": "支持多渠道银行按揭", "C": "不提供金融服务", "D": "仅支持全款购车"}	B	集团支持多渠道银行按揭方案，为客户提供灵活金融选择。	sales	2	\N	\N	2026-06-09 13:11:57.429036+08	\N	7
7	multi_choice	以下哪些是星瑞L6的智能座舱功能？（多选）	{"A": "15.6英寸中控屏", "B": "语音控制", "C": "手势识别", "D": "全自动驾驶"}	ABC	星瑞L6支持15.6英寸中控屏、语音控制、手势识别，但无全自动驾驶。	sales	3	\N	\N	2026-06-09 13:11:57.429038+08	\N	7
8	single_choice	客户跟进管理中，首次接触后应在多长时间内进行回访？	{"A": "1小时内", "B": "24小时内", "C": "3天内", "D": "1周内"}	B	客户首次接触后建议24小时内回访，保持沟通热度。	sales	2	\N	\N	2026-06-09 13:11:57.42904+08	\N	7
10	single_choice	与比亚迪汉DM-i对比，星瑞L6的差异化优势是什么？	{"A": "更低功率", "B": "更高功率和更长整车质保", "C": "更低续航", "D": "更少安全气囊"}	B	星瑞L6综合功率230kW，高于汉DM-i；整车质保5年/15万公里也更长。	sales	3	\N	\N	2026-06-09 13:11:57.429043+08	\N	7
11	single_choice	国六B发动机怠速抖动时，常见的故障码是什么？	{"A": "P0101", "B": "P0300", "C": "P0500", "D": "P0700"}	B	P0300(随机失火)和P0171(混合气过稀)是国六B怠速抖动常见故障码。	tech	3	\N	\N	2026-06-09 13:11:57.429044+08	\N	15
13	single_choice	发动机怠速时燃油压力应为多少？	{"A": "200-250kPa", "B": "350-400kPa", "C": "500-600kPa", "D": "700-800kPa"}	B	怠速时燃油压力应为350-400kPa。	tech	3	\N	\N	2026-06-09 13:11:57.429047+08	\N	15
15	single_choice	国六B车型碳罐电磁阀常见故障是什么？	{"A": "完全堵塞", "B": "卡滞在常开位置", "C": "电路短路", "D": "物理断裂"}	B	国六B车型碳罐电磁阀容易卡滞在常开位置，导致混合气过稀。	tech	4	\N	\N	2026-06-09 13:11:57.429051+08	\N	15
16	single_choice	新能源车维修中，高压系统断电后需等待多久才能操作？	{"A": "1分钟", "B": "5分钟", "C": "至少10分钟", "D": "立即操作"}	C	高压系统断电后需等待至少10分钟，确保电容放电完毕，方可操作。	tech	3	\N	\N	2026-06-09 13:11:57.429053+08	\N	15
26	single_choice	保险理赔服务中，客服需要协助客户准备哪些材料？	{"A": "仅驾驶证", "B": "事故证明+定损单+驾驶证+行驶证", "C": "仅发票", "D": "仅身份证"}	B	保险理赔需要事故证明、定损单、驾驶证、行驶证等全套材料。	service	2	\N	\N	2026-06-09 13:11:57.429288+08	\N	23
27	single_choice	续保业务技巧中，最佳续保时机是什么时候？	{"A": "保险到期后", "B": "保险到期前30天", "C": "保险到期前1天", "D": "任意时间"}	B	保险到期前30天是最佳续保时机，给客户充足的比较和考虑时间。	service	2	\N	\N	2026-06-09 13:11:57.429289+08	\N	23
28	multi_choice	以下哪些属于会员服务的权益？（多选）	{"A": "优先预约", "B": "消费积分兑换", "C": "免费年度检测", "D": "免费购车"}	ABC	会员通常享有优先预约、消费积分兑换和免费年度检测等权益。	service	2	\N	\N	2026-06-09 13:11:57.429291+08	\N	23
14	true_false	举升机操作可以单人完成，无需两人协作。	null	false	举升机操作必须两人协作，严禁单人操作，这是安全生产规范要求。	tech	1	\N	2026-06-11	2026-06-09 13:11:57.42905+08	\N	15
9	true_false	二手车评估只看外观和里程数即可定价。	null	false	二手车评估需综合考虑品牌、车型、车龄、里程、事故维修记录等多维因素。	sales	1	\N	2026-06-11	2026-06-09 13:11:57.429041+08	\N	7
18	true_false	电气设备检修前不需要断开电源，只需告知同事即可。	null	false	电气设备检修前必须断开电源并挂警示牌，这是安全生产强制要求。	tech	1	\N	2026-06-11	2026-06-09 13:11:57.429056+08	\N	15
20	single_choice	废机油应如何处理？	{"A": "倒入下水道", "B": "卖给废品站", "C": "交由合规危废处置单位", "D": "混入生活垃圾"}	C	废机油属于危险废物，必须交由合规处置单位处理。	tech	1	\N	2026-06-11	2026-06-09 13:11:57.429059+08	\N	15
12	single_choice	国六B发动机火花塞的标准间隙是多少？	{"A": "0.5-0.6mm", "B": "0.7-0.8mm", "C": "1.0-1.2mm", "D": "1.5mm以上"}	B	国六B发动机对火花塞间隙要求更严，标准0.7-0.8mm。	tech	2	\N	2026-06-11	2026-06-09 13:11:57.429046+08	\N	15
17	single_choice	钣金喷漆工艺中，底漆的主要作用是什么？	{"A": "美观", "B": "防锈和增加面漆附着力", "C": "遮瑕", "D": "增加重量"}	B	底漆主要起防锈作用并为面漆提供良好的附着基础。	tech	2	\N	2026-06-11	2026-06-09 13:11:57.429054+08	\N	15
19	multi_choice	以下哪些是故障诊断的基本步骤？（多选）	{"A": "读取故障码", "B": "目视检查", "C": "直接更换全部零件", "D": "使用诊断仪检查数据流"}	ABD	故障诊断步骤包括读取故障码、目视检查和数据流分析，不应盲目更换零件。	tech	2	\N	2026-06-11	2026-06-09 13:11:57.429057+08	\N	15
21	single_choice	客户投诉'听-认-行'三步法中，第一步是什么？	{"A": "行动解决", "B": "耐心倾听", "C": "马上解释", "D": "直接拒绝"}	B	三步法第一步是耐心倾听，让客户完整表达不满。	service	1	\N	2026-06-11	2026-06-09 13:11:57.429061+08	\N	23
22	single_choice	处理客户投诉时，以下哪种话术是共情式表达的体现？	{"A": "这是你的问题", "B": "我完全理解您现在的心情", "C": "您说得不对", "D": "您去找我们领导"}	B	共情话术如'我完全理解您现在的心情'能有效缓解客户情绪。	service	1	\N	2026-06-11	2026-06-09 13:11:57.429063+08	\N	23
24	true_false	客户投诉处理时，应该先解释原因，再倾听客户诉求。	null	false	应先倾听客户诉求，认可情绪后再解释和处理，不可急于解释。	service	1	\N	2026-06-11	2026-06-09 13:11:57.429233+08	\N	23
25	single_choice	预约保养接待流程中，客户到店后首先应？	{"A": "让客户自己找车位", "B": "引导停车并接待登记", "C": "让客户等待", "D": "直接开进车间"}	B	客户到店后首先应引导停车并完成接待登记。	service	1	\N	2026-06-11	2026-06-09 13:11:57.429286+08	\N	23
23	single_choice	客户投诉后，客服应在多长时间内给予回复？	{"A": "24小时内", "B": "30分钟内", "C": "3天内", "D": "1周内"}	B	应给出明确时间承诺：'我会在30分钟内给您回复'。	service	2	\N	2026-06-11	2026-06-09 13:11:57.429064+08	\N	23
38	single_choice	星瑞L6的整车质保和三电系统终身质保分别适用于哪些条件？	{"A": "整车质保5年/15万公里，三电系统终身质保适用于所有车主", "B": "整车质保3年/10万公里，三电系统终身质保仅限首任车主", "C": "整车质保5年/15万公里，三电系统终身质保仅限首任车主", "D": "整车质保5年/10万公里，三电系统终身质保适用于首任及二手车主"}	C	文档明确说明整车质保为5年/15万公里，三电系统终身质保仅限首任车主。选项A错误在于三电系统并非所有车主适用；B错误在于整车质保条款不符；D错误在于三电系统不包含二手车主。	sales	2	\N	\N	2026-06-10 15:53:43.922793+08	\N	7
39	single_choice	星瑞L6搭载的智能驾驶辅助系统级别和动力系统综合功率分别是多少？	{"A": "L2级智能驾驶辅助，综合功率200kW", "B": "L2+级智能驾驶辅助，综合功率230kW", "C": "L3级智能驾驶辅助，综合功率250kW", "D": "L2级智能驾驶辅助，综合功率230kW"}	B	文档指出星瑞L6配备L2+级智能驾驶辅助，动力系统综合功率为230kW。选项A和D的L2级不准确，C的L3级过高且功率不符。	sales	3	\N	\N	2026-06-10 15:53:43.922794+08	\N	7
40	single_choice	星瑞L6是哪家汽车集团的旗舰新能源轿车？	{"A": "合群汽车集团", "B": "恒驰汽车集团", "C": "群星汽车集团", "D": "合众汽车集团"}	A	文档明确指出星瑞L6是合群汽车集团的旗舰新能源轿车，其他选项名称相似但不正确。	sales	1	\N	\N	2026-06-10 15:57:08.324961+08	\N	7
41	single_choice	星瑞L6在CLTC工况下的续航里程是多少？	{"A": "800km", "B": "1000km", "C": "1200km", "D": "1500km"}	C	文档中写明星瑞L6的CLTC续航为1200km，其他选项为常见干扰数字。	sales	1	\N	\N	2026-06-10 15:57:08.324965+08	\N	7
42	single_choice	星瑞L6配备的智能驾驶系统级别是？	{"A": "L1", "B": "L2", "C": "L2+", "D": "L3"}	C	文档中明确星瑞L6搭载L2+智能驾驶，比基础L2更先进，但未达到L3。	sales	2	\N	\N	2026-06-10 15:57:08.324966+08	\N	7
29	true_false	配件仓储管理可以采用先进先出原则降低库存损耗。	null	true	先进先出(FIFO)原则可有效降低配件库存损耗和管理成本。	service	1	\N	2026-06-11	2026-06-09 13:11:57.429293+08	\N	23
44	single_choice	第4代帝豪主要向上突破了哪个方面的天花板？	{"A": "自主品牌价格天花板", "B": "自主品牌健康安全天花板", "C": "自主品牌科技天花板", "D": "自主品牌品质天花板"}	D	文档中明确指出，第4代帝豪通过BMA全球模块化架构，向上突破了自主品牌品质天花板。	\N	2	\N	2026-06-13	2026-06-10 16:01:19.857901+08	\N	1
47	single_choice	帝豪向上系列搭载的1.5L直列四缸发动机最大功率和扭矩分别是多少？	{"A": "85kW，145N·m", "B": "88kW，150N·m", "C": "90kW，155N·m", "D": "92kW，160N·m"}	B	文档中写明1.5L直列四缸发动机具有“88kW同级最大功率”和“150N·m同级最大扭矩”。	\N	2	\N	2026-06-13	2026-06-10 16:01:19.85791+08	\N	1
59	single_choice	关于套餐卡的使用，以下哪项说法是正确的？	{"A": "零件核销可在工单未完工时进行", "B": "工时核销要求所有工时项目完成派工", "C": "套餐卡项目剩余次数必须大于等于核销次数", "D": "套餐卡车系为空时不能使用"}	B	文档要求工时核销只允许在在修工单中核销，并确保所有工时项目完成派工；零件核销需工单已完工；剩余次数要大于核销次数；车系为空表示所有车系可用。	\N	3	\N	\N	2026-06-10 16:16:52.252451+08	\N	1
63	single_choice	优惠券核销后，若要取消抵扣，在什么条件下可以操作？	{"A": "工单质检反完工前", "B": "工单质检反完工后", "C": "任何时间均可", "D": "仅限收银员操作"}	A	文档强调工单使用优惠券抵扣后，必须先取消抵扣才能做质检反完工，因此取消抵扣必须在质检反完工前进行。	\N	3	\N	\N	2026-06-10 16:16:52.25246+08	\N	1
64	single_choice	套餐卡中零件核销时，如何更新套餐卡中该零件的剩余次数？	{"A": "减少一次", "B": "更新为原剩余次数减工单对应零件出库数", "C": "保持不变", "D": "重置为零"}	B	文档说明零件核销后，套餐卡中该零件的剩余次数更新为原剩余次数-工单对应零件出库数。	\N	3	\N	\N	2026-06-10 16:16:52.252462+08	\N	1
52	single_choice	截至文档编写时，帝豪系列累计全球用户数是多少？	{"A": "300万+", "B": "420万+", "C": "500万+", "D": "350万+"}	B	文档提到“十六载向上历程，收获全球420万+用户信赖”，并以此为基础冲刺500万销量。	\N	1	\N	2026-06-11	2026-06-10 16:01:19.85792+08	\N	1
57	single_choice	维修零件出库操作由谁执行？	{"A": "维修技师", "B": "服务顾问", "C": "仓管员", "D": "收银员"}	C	文档明确标明‘维修零件出库（仓管员操作）’，仓管员负责录入工单耗材零件。	\N	1	\N	2026-06-11	2026-06-10 16:16:52.252445+08	\N	1
66	single_choice	在工单录入中，带有红点的项目表示什么？	{"A": "可选填项", "B": "必填项", "C": "重要提示", "D": "错误标记"}	B	文档中明确指出，有红点的项目是必填项，这是工单录入的基本规则。	\N	1	\N	2026-06-11	2026-06-11 11:51:24.642128+08	\N	1
71	single_choice	优惠券使用条件中，工单必须已处于什么状态？	{"A": "已派工", "B": "已质检完工", "C": "已结算", "D": "已出库"}	B	文档明确优惠券使用条件之一是工单已质检完工。	\N	1	\N	2026-06-11	2026-06-11 11:51:24.642139+08	\N	1
51	single_choice	帝豪向上系列的核心竞品包括哪些车型？	{"A": "长安逸动、轩逸经典、朗逸新锐", "B": "比亚迪秦PLUS、丰田卡罗拉、本田思域", "C": "大众速腾、日产轩逸、丰田雷凌", "D": "吉利星瑞、长安UNI-V、本田凌派"}	A	文档中明确列出核心竞品为“自主：长安第二代*动（应为长安逸动）合资：轩*经典、朗逸 *锐”，对应长安逸动、轩逸经典、朗逸新锐。	\N	2	\N	2026-06-13	2026-06-10 16:01:19.857918+08	\N	1
54	single_choice	星瑞L6的整车质保政策是？	{"A": "3年/10万公里", "B": "5年/15万公里", "C": "8年/20万公里", "D": "4年/12万公里"}	B	文档明确说明整车5年/15万公里质保，这是销售中需强调的售后保障。	\N	2	\N	2026-06-13	2026-06-10 16:09:12.019436+08	\N	1
58	single_choice	优惠券核销后，工单中会新增一条编号前缀为什么的记录？	{"A": "Fac", "B": "Vou", "C": "Dis", "D": "Pro"}	B	文档指出优惠券核销后，在工时或零件项目中新增一条编号前缀为‘Vou’的记录，金额为负数用于冲减客户付费。	\N	2	\N	2026-06-13	2026-06-10 16:16:52.252449+08	\N	1
60	single_choice	延保车辆首次来店保养时，系统会有什么特殊操作？	{"A": "自动生成优惠券", "B": "弹出起保窗口要求起保操作", "C": "要求重新购买延保", "D": "自动折扣10%"}	B	文档说明如果客户是购买延保后首次来店保养，系统会弹出起保窗口，要求进行起保操作。	\N	2	\N	2026-06-13	2026-06-10 16:16:52.252454+08	\N	1
61	single_choice	厂家优惠券核销时，在工时项目中会新增几条记录？	{"A": "一条", "B": "两条", "C": "三条", "D": "四条"}	B	文档明确指出厂家优惠券核销时，在工时项目中增加编号为‘Fac’的两条记录，金额一正一负。	\N	2	\N	2026-06-13	2026-06-10 16:16:52.252456+08	\N	1
62	single_choice	推结算单时，如果付款方显示为空，应如何处理？	{"A": "忽略该问题继续操作", "B": "在工单备注中手动填写", "C": "在基础数据中设置付款方名称", "D": "重新创建工单"}	C	文档注明‘如付款方显示为空，需在【01.03基础数据】中设置付款方名称’。	\N	2	\N	2026-06-13	2026-06-10 16:16:52.252458+08	\N	1
65	single_choice	以下哪个操作不是在05售后管理→05.01维修服务接待模块中进行的？	{"A": "优惠券核销", "B": "延保起保", "C": "维修财务结账", "D": "质检完工"}	C	维修财务结账的操作入口是08财务管理→08.01.03维修财务结账，由收银员操作，而其他选项均在05售后管理模块内。	\N	2	\N	2026-06-13	2026-06-10 16:16:52.252464+08	\N	1
67	single_choice	优惠券核销后，在工时或零件项目中新增一条编号前缀为什么的记录？	{"A": "Fac", "B": "Vou", "C": "Dis", "D": "Cou"}	B	文档说明优惠券核销后新增编号前缀为'Vou'的记录，金额为负数，用于冲减客户付费金额。	\N	2	\N	2026-06-13	2026-06-11 11:51:24.642133+08	\N	1
68	single_choice	套餐卡中工时核销的前提条件是什么？	{"A": "工单已完工", "B": "所有工时项目完成派工", "C": "零件已出库", "D": "客户已付费"}	B	文档指出工时核销只允许在在修工单中核销，且需确保所有工时项目都完成派工。	\N	2	\N	2026-06-13	2026-06-11 11:51:24.642136+08	\N	1
69	single_choice	延保销售录入时，客户车辆的车系必须满足什么条件？	{"A": "车系必须为空", "B": "车系必须与延保方案设置的车名一致", "C": "车系必须为所有车系", "D": "车系无限制"}	B	文档强调销售录入的客户车所属车系必须是延保方案设置的车名（车系），否则无法录入。	\N	2	\N	2026-06-13	2026-06-11 11:51:24.642137+08	\N	1
70	single_choice	厂家优惠券核销时，在工时项目中增加几条记录？	{"A": "一条", "B": "两条", "C": "三条", "D": "四条"}	B	文档说明厂家优惠券核销时增加编号为'Fac'的两条记录，金额一正一负。	\N	2	\N	2026-06-13	2026-06-11 11:51:24.642138+08	\N	1
72	single_choice	套餐卡零件核销时，需在什么状态下进行？	{"A": "工单派工后", "B": "套餐零件已出库且工单已完工", "C": "工单质检前", "D": "客户付费后"}	B	文档指出零件核销须在要核销的套餐零件已出库且工单已完工后进行，以确保出库件不变。	\N	2	\N	2026-06-13	2026-06-11 11:51:24.64214+08	\N	1
82	single_choice	关于套餐卡的使用条件，以下哪项描述正确？	{"A": "工时核销时，工单必须已完成质检完工", "B": "零件核销时，零件已出库且工单已完工", "C": "套餐卡中项目剩余次数可以小于要核销的次数", "D": "套餐卡使用时不限制车系"}	B	文档规定，零件核销须在要核销的套餐零件已出库，且工单已完工后，确保核销后出库件不变。	\N	3	\N	\N	2026-06-11 12:30:15.040394+08	\N	1
84	single_choice	厂家优惠券核销时，在工时项目中增加的两条记录金额和编号有什么特点？	{"A": "两条记录编号均为Fac，金额一正一负", "B": "两条记录编号均为Vou，金额相同", "C": "两条记录编号不同，金额均为正", "D": "一条记录编号Fac，另一条为Vou"}	A	文档指出，厂家优惠券核销在工时项目中增加编号为“Fac”的两条记录，金额是券面值的一正一负。	\N	3	\N	\N	2026-06-11 12:30:15.040395+08	\N	1
86	single_choice	在套餐卡使用中，工时核销的时机是什么？	{"A": "工单已质检完工后", "B": "工单在修且所有工时项目完成派工", "C": "零件出库后", "D": "结算后"}	B	文档规定，工时核销只允许在在修工单中核销，确保所有工时项目都完成派工。	\N	3	\N	\N	2026-06-11 12:30:15.040397+08	\N	1
75	single_choice	厂家优惠券主要用于核销哪类项目的费用？	{"A": "零件项目费用", "B": "工时项目费用", "C": "延保费用", "D": "套餐费用"}	B	文档明确指出厂家优惠券用于核销工时项目费用。	\N	1	\N	2026-06-11	2026-06-11 11:51:24.642143+08	\N	1
79	single_choice	在维修服务接待操作中，工单录入的整体操作步骤入口在哪里？	{"A": "05售后管理→05.01维修服务接待", "B": "05售后管理→05.02维修服务接待", "C": "08财务管理→08.01.03维修财务结账", "D": "02.07优惠券方案"}	A	文档明确指出，工单录入的整体操作步骤入口是“05售后管理→05.01维修服务接待”。	\N	1	\N	2026-06-11	2026-06-11 12:30:15.040388+08	\N	1
80	single_choice	在工单新增与修改中，带有红点的项目表示什么？	{"A": "可选填项", "B": "必填项", "C": "系统默认项", "D": "高级选项"}	B	文档中注明“有红点的项目是必填项”，这是工单录入的基本规则。	\N	1	\N	2026-06-11	2026-06-11 12:30:15.040392+08	\N	1
87	single_choice	推结算单时，如果付款方显示为空，应如何处理？	{"A": "忽略此问题，继续操作", "B": "在基础数据中设置付款方名称", "C": "手动输入付款方", "D": "联系客服"}	B	文档提示，如付款方显示为空，需在【01.03基础数据】中设置付款方名称。	\N	1	\N	2026-06-11	2026-06-11 12:30:15.040397+08	\N	1
88	single_choice	维修财务结账的操作入口在哪里？	{"A": "05售后管理→05.01维修服务接待", "B": "08财务管理→08.01.03维修财务结账", "C": "02.07优惠券方案", "D": "09.07优惠券管理"}	B	文档指出，维修财务结账功能入口是08财务管理→08.01.03维修财务结账。	\N	1	\N	2026-06-11	2026-06-11 12:30:15.040398+08	\N	1
81	single_choice	优惠券核销后，在工时或零件项目中新增的记录编号前缀是什么？	{"A": "Fac", "B": "Vou", "C": "Dis", "D": "Pro"}	B	文档说明，优惠券核销后新增记录编号前缀为“Vou”，用于冲减客户付费金额。	\N	2	\N	2026-06-13	2026-06-11 12:30:15.040393+08	\N	1
83	single_choice	延保销售录入时，客户车辆的车系必须满足什么条件？	{"A": "必须是延保方案设置的车名（车系）", "B": "可以是任意车系", "C": "必须与延保类型一致", "D": "必须为新车"}	A	文档说明，销售录入的客户车所属车系必须是延保方案设置的车名（车系），否则无法录入。	\N	2	\N	2026-06-13	2026-06-11 12:30:15.040395+08	\N	1
85	single_choice	当工单使用优惠券抵扣后，若要取消抵扣，应执行什么操作？	{"A": "直接删除优惠券记录", "B": "在核销窗口选择要取消的券，点击取消抵扣按钮", "C": "修改工单收费类型", "D": "重新录入工单"}	B	文档明确，取消优惠券核销抵扣需在优惠券核销窗口选择要取消的券，点击“取消抵扣”按钮。	\N	2	\N	2026-06-13	2026-06-11 12:30:15.040396+08	\N	1
100	single_choice	2025年12月，以下哪个车型的限时红包礼时间为12月1日至12月25日？	{"A": "向往S7 PRO+", "B": "E8 PHEV", "C": "M6系列", "D": "GS3影速（2026款）"}	D	根据文档第1页，GS3影速（2026款）有限时红包礼：12月1日-12月25日限时抢至高6888元购车红包。其他选项车型的限时红包礼时间可能不同。	\N	2	\N	\N	2026-06-11 13:13:41.679683+08	\N	1
102	single_choice	2025年12月，以下哪个车型的置换补贴最高？	{"A": "向往M8乾昆、鸿蒙座舱版", "B": "E8 MAX+", "C": "M8系列（不含宗师）", "D": "M6系列"}	A	根据文档第8页，向往M8乾昆、鸿蒙座舱版的全品牌置换补贴为30000元，是选项中最高。	\N	3	\N	\N	2026-06-11 13:13:41.679692+08	\N	1
104	single_choice	2025年12月，向往S7激光雷达版提供的全场景智行保障最高是多少？	{"A": "100万元", "B": "200万元", "C": "250万元", "D": "300万元"}	D	根据文档第2页，向往S7激光雷达版提供300万元全场景智行保障。	\N	2	\N	\N	2026-06-11 13:13:41.679699+08	\N	1
105	single_choice	2025年12月，以下哪个车型提供了0首付的金融礼？	{"A": "GS4 MAX", "B": "影豹1.5T", "C": "M6系列", "D": "E8荣耀系列"}	A	根据文档第1页，GS4 MAX有金融礼：可享0首付，至高8万3年0息。	\N	2	\N	\N	2026-06-11 13:13:41.679703+08	\N	1
106	single_choice	2025年12月，以下哪个车型的提车折扣为55000元？	{"A": "E9超级快充宗师版", "B": "向往M8宗师", "C": "E8 PHEV系列", "D": "GS8系列"}	A	根据文档第5页，E9超级快充宗师版的提车折扣为55000元。	\N	3	\N	\N	2026-06-11 13:13:41.679706+08	\N	1
107	single_choice	2025年12月，库存融资贴息核销利率上限为4%适用于以下哪些车型？	{"A": "E8", "B": "向往S7", "C": "ES9", "D": "GS3影速"}	D	根据文档第9页，E8、E9、ES9、向往S7、向往S9、向往M8乾及鸿蒙座舱版车型贴息核销利率上限为3%，其余车型上限为4%，GS3影速属于其余车型。	\N	4	\N	\N	2026-06-11 13:13:41.67971+08	\N	1
108	single_choice	2025年12月，以下哪个车型提供价值20000元的华为乾昆智驾ADS高阶功能包补贴？	{"A": "向往S7 PRO+", "B": "向往S9", "C": "向往M8宗师", "D": "E8 PHEV"}	B	根据文档第3页，向往S9有限时享20000元华为乾昆智驾ADS高阶功能包补贴权益。	\N	3	\N	\N	2026-06-11 13:13:41.679745+08	\N	1
111	single_choice	当台风风力等级为8-9级时，售后服务部应如何应对？	{"A": "成立2辆车和4人的救援小组值班", "B": "准备加满油电的SUV车辆随时待命", "C": "撤离车间的维修车", "D": "安排所有员工放假"}	A	文档中台风8-9级响应措施明确要求售后服务部成立2辆车和4人的救援小组值班。	\N	2	\N	\N	2026-06-11 13:21:00.936473+08	\N	1
112	single_choice	在台风11-12级响应措施中，除部分必要的照明电外，应如何处理电源？	{"A": "保持所有电源开启以备应急", "B": "全部下闸断电", "C": "只关闭空调电源", "D": "增加备用发电机"}	B	文档指出，在11-12级台风响应中，除部分必要照明电外，应全部下闸断电。	\N	2	\N	\N	2026-06-11 13:21:00.936476+08	\N	1
113	single_choice	对于13-18级台风，无混凝土结构的门店应如何安排值班人员？	{"A": "安排所有员工在门店内值班", "B": "不安排值班人员，统一集中到有混凝土结构的场所", "C": "只安排男性员工值班", "D": "安排值班人员在车内待命"}	B	文档规定，13-18级台风时，无混凝土结构的门店不安排值班人员，值班人员统一集中到有混凝土结构的场所。	\N	3	\N	\N	2026-06-11 13:21:00.93648+08	\N	1
114	single_choice	台风期间，人事行政部负责准备防风物资，以下哪项不属于防风物资？	{"A": "沙袋和木板", "B": "食品和饮用水", "C": "汽车轮胎", "D": "手电筒和铁丝"}	C	文档中列出的防风物资包括沙袋、木板、铁丝、手电筒、食品、饮用水等，汽车轮胎不在此列。	\N	2	\N	\N	2026-06-11 13:21:00.936483+08	\N	1
116	single_choice	合群汽车集团防台风应急演练的频率要求是什么？	{"A": "每季度一次", "B": "每年至少一次", "C": "每月一次", "D": "每两年一次"}	B	文档培训与演练部分明确每年至少组织一次防台风应急演练。	\N	2	\N	\N	2026-06-11 13:21:00.93649+08	\N	1
117	single_choice	在13-18级台风响应中，关于电脑主机应如何防护？	{"A": "将电脑主机放在窗边通风", "B": "将电脑主机放到垫高的地上，并加电脑套防水袋", "C": "将电脑主机转移到室外", "D": "保持原状不动"}	B	文档中13-18级台风响应措施要求将电脑主机放到垫高的地上，并加电脑套防水袋。	\N	3	\N	\N	2026-06-11 13:21:00.936493+08	\N	1
118	single_choice	台风期间，值班人员原则上应待在什么位置？	{"A": "高层办公室", "B": "室外开阔地", "C": "水泥结构的一楼", "D": "停车场内"}	C	文档规定台风期间值班人员原则上待在水泥结构的一楼，避免坠物砸伤。	\N	2	\N	\N	2026-06-11 13:21:00.936496+08	\N	1
101	single_choice	2025年12月，影豹R-style版限时价是多少？	{"A": "9.28万元", "B": "9.8万元", "C": "10.8万元", "D": "12.8万元"}	C	根据文档第1页，影豹R-style版指导价12.8万元，限时价10.8万元。	\N	1	\N	2026-06-11	2026-06-11 13:13:41.679688+08	\N	1
103	single_choice	2025年12月限时抽奖活动中，特等奖的红包金额是多少？	{"A": "1688元", "B": "2088元", "C": "3088元", "D": "6888元"}	D	根据文档第4页，特等奖为6888元红包。	\N	1	\N	2026-06-11	2026-06-11 13:13:41.679696+08	\N	1
110	single_choice	合群汽车集团防台委员会的会长是谁？	{"A": "陈文群", "B": "黄兴军", "C": "邢益宝", "D": "各店总经理"}	C	文档中明确列出防台委员会会长为邢益宝。	\N	1	\N	2026-06-11	2026-06-11 13:21:00.936468+08	\N	1
115	single_choice	台风过后，各部门应如何处理受损设施设备？	{"A": "直接报废处理", "B": "及时修复受损设施设备，恢复正常运营秩序", "C": "等待集团统一安排", "D": "忽略轻微损坏"}	B	文档后期处置部分要求台风过后及时修复受损设施设备，恢复正常运营秩序。	\N	1	\N	2026-06-11	2026-06-11 13:21:00.936486+08	\N	1
136	multi_choice	在销售顾问看板中，以下哪项不属于关键数据？	{"A": "客户总数", "B": "订单数", "C": "交车数", "D": "客户满意度评分"}	D,A	文档中列出的关键数据包括客户总数、订单数、交车数、转化率、总毛利、单车毛利，不包括客户满意度评分。	\N	1	\N	2026-06-13	2026-06-12 14:55:58.486863+08	\N	1
73	single_choice	推结算单时，如果付款方显示为空，应如何处理？	{"A": "忽略该字段", "B": "在【01.03基础数据】中设置付款方名称", "C": "手动输入付款方", "D": "重新生成工单"}	B	文档注明如付款方显示为空，需在【01.03基础数据】中设置付款方名称。	\N	1	\N	2026-06-11	2026-06-11 11:51:24.642141+08	\N	1
109	single_choice	合群汽车集团防台风应急管理制度的目的是什么？	{"A": "确保所有员工在台风期间正常上班", "B": "防范台风灾害，减少人员伤亡和财产损失，保障运营秩序", "C": "提高集团各品牌的市场竞争力", "D": "加强汽车销售业绩"}	B	根据文档总则部分，制度目的是有效防范台风灾害，最大程度减少人员伤亡和财产损失，保障公司正常运营秩序。	\N	1	\N	2026-06-11	2026-06-11 13:21:00.93646+08	\N	1
121	single_choice	关于住房补助，以下哪一项描述是正确的？	{"A": "适用于所有新入职员工，补助金额为每月800元", "B": "补助期限为12个月，从入职当月开始计算", "C": "如果员工月到手工资超过3000元，补助自动取消", "D": "补助以现金形式单独发放，不包含在工资中"}	B	制度规定：住房补助期限为12个月，从入职当月开始计算；补贴标准为每月500元；当月到手工资大于等于2000元时取消补助；补助以工资形式发放。	\N	2	\N	\N	2026-06-11 13:48:27.59665+08	\N	1
124	single_choice	员工个人使用的车辆，享受维修优惠时，工费按什么标准结算？	{"A": "按配件成本价，工费5折", "B": "按配件成本价，工费7折", "C": "按配件市场价，工费8折", "D": "按配件成本价，工费全价"}	B	制度规定：员工个人使用的车辆（上限2台）维修时，配件按成本价，工费按7折结算优惠。	\N	2	\N	\N	2026-06-11 13:48:27.596657+08	\N	1
125	single_choice	直系亲属购车时，如果弄虚作假，将面临什么处罚？	{"A": "1000元经济处罚并记小过一次", "B": "3000元经济处罚并记大过一次", "C": "5000元经济处罚并记大过一次", "D": "直接辞退"}	C	制度明确：直系亲属购车须提供关系证明材料，如有弄虚作假者给予5000元的经济处罚并记大过一次。	\N	2	\N	\N	2026-06-11 13:48:27.596658+08	\N	1
126	single_choice	员工享受优惠购车后，对购车价格信息负有保密义务，违反者将受到什么处罚？	{"A": "2000元经济处罚并记小过一次", "B": "3000元经济处罚并记大过一次", "C": "4000元经济处罚并记大过一次", "D": "5000元经济处罚并记大过一次"}	C	制度规定：享受优惠购车者，本人、家属及亲朋好友对购车相关价格信息负有保密义务，违背者给予4000元的经济处罚并记大过一次。	\N	2	\N	\N	2026-06-11 13:48:27.59666+08	\N	1
127	single_choice	员工购车福利中，员工个人购车是否享受转介绍奖励？	{"A": "享受，但仅限一次", "B": "不享受，销售员只发放交车奖励", "C": "享受，与正常销售相同", "D": "不享受，且销售员无任何奖励"}	B	制度明确：员工个人购车不享受转介绍奖励，销售员仅发放交车奖励，不纳入销售员当期销量目标。	\N	3	\N	\N	2026-06-11 13:48:27.596662+08	\N	1
128	single_choice	员工福利管理制度中，关于假期福利，哪一项描述是正确的？	{"A": "员工所享有的假期包括年假、婚假、产假、陪产假、病假等", "B": "正式员工凭子女学校通知，每学期可享受1天带薪家长会假", "C": "双职工家庭，夫妻双方可各享受半天家长会假", "D": "员工子女入学时，每年3月、9月初给予半天带薪假期，仅限双职工"}	B	制度规定：正式员工凭子女学校通知，每学期每个员工子女可享受1次半天带薪家长会假；双职工仅可一人享受；子女入学时，每年3月、9月初给予半天带薪假期，适用于所有正式员工。	\N	3	\N	\N	2026-06-11 13:48:27.596663+08	\N	1
119	single_choice	根据合群汽车集团的员工福利管理制度，以下哪一项不属于公司统一为正式员工缴纳的社会统筹保险？	{"A": "基本养老保险", "B": "基本医疗保险", "C": "住房公积金", "D": "失业保险"}	C	根据制度，社会统筹保险包括基本养老保险、基本医疗保险、失业保险、工伤保险、生育保险；住房公积金被列为公司根据自身经营条件设置的福利项目，不属于社会统筹保险的一部分。	\N	1	\N	2026-06-11	2026-06-11 13:48:27.596643+08	\N	1
122	single_choice	员工级和主管级以上的通讯补贴标准分别是多少？	{"A": "员工级50元/月，主管级以上80元/月", "B": "员工级80元/月，主管级以上100元/月", "C": "员工级100元/月，主管级以上150元/月", "D": "员工级60元/月，主管级以上90元/月"}	B	制度明确：通讯补贴标准为员工级80元/月/项，主管级以上100元/月/项。	\N	1	\N	2026-06-11	2026-06-11 13:48:27.596653+08	\N	1
123	single_choice	员工每年可享受几次集团旗下品牌按厂家标准成本价的购车机会？	{"A": "两次", "B": "三次", "C": "一次", "D": "无限制"}	C	制度规定：员工每年享受一次集团旗下所有品牌按厂家标准成本价的购车机会，仅限本人及配偶使用。	\N	1	\N	2026-06-11	2026-06-11 13:48:27.596655+08	\N	1
131	single_choice	毛利結構在看板中是如何呈現的？	{"A": "僅顯示總毛利", "B": "拆分到具體業務模塊", "C": "只顯示單周毛利", "D": "不顯示毛利"}	B	文檔指出毛利結構已拆分到具體業務模塊。	\N	2	\N	\N	2026-06-12 14:31:39.276283+08	\N	1
132	single_choice	業績趨勢圖的主要功能是什麼？	{"A": "展示當前業績排名", "B": "動態呈現關鍵指標的時間走勢", "C": "顯示銷售顧問個人信息", "D": "展示車型配置"}	B	文檔說明業績趨勢圖動態呈現關鍵指標的時間走勢，幫助把握業績起落規律。	\N	2	\N	\N	2026-06-12 14:31:39.276287+08	\N	1
133	single_choice	銷售顧問排行榜包含了哪些核心數據？	{"A": "目標、客戶轉化率、貢獻率", "B": "姓名、年齡、工齡", "C": "學歷、培訓次數", "D": "考勤、請假天數"}	A	文檔明確列出排行榜包含了目標、客戶轉化率、貢獻率等數據。	\N	2	\N	\N	2026-06-12 14:31:39.276289+08	\N	1
134	single_choice	进入数据可视化平台后，如何登录？	{"A": "输入账号密码并点击登录", "B": "直接使用微信扫码", "C": "通过指纹识别", "D": "输入手机号验证码"}	A	文档明确指出：输入账号密码点击登录。	\N	1	\N	2026-06-13	2026-06-12 14:55:58.486855+08	\N	1
139	single_choice	毛利历史图可以查看哪些数据？	{"A": "总毛利和单车毛利", "B": "总毛利和净利润", "C": "单车毛利和毛利率", "D": "总毛利和毛利率"}	A	文档指出：毛利历史图可查看总毛利和单车毛利。	\N	2	\N	\N	2026-06-12 14:55:58.486871+08	\N	1
140	single_choice	要图展示的主要是什么？	{"A": "客户转化率", "B": "目标完成率", "C": "订单增长率", "D": "交车成功率"}	B	文档明确：要图展示的是目标完成率。	\N	2	\N	\N	2026-06-12 14:55:58.486874+08	\N	1
141	single_choice	车系排行榜的作用是什么？	{"A": "展示所有车系的销量排名", "B": "按车系拆开客户、订单、交车和转化率，帮助识别主力车系", "C": "比较不同门店的业绩", "D": "展示车系的利润排名"}	B	文档提到：车系排行榜把你自己的客户、订单、交车和转化率按车系拆开，让你清楚看到哪些车系是业绩主力，哪些还有挖掘空间。	\N	2	\N	\N	2026-06-12 14:55:58.486876+08	\N	1
143	single_choice	以下哪个图表可以帮助你看清成长轨迹和把握节奏？	{"A": "雷达图", "B": "毛利历史图", "C": "二季趋势图", "D": "要图"}	C	文档指出：二季趋势图清晰呈现每个月的业绩变化，让你看清成长轨迹，即时把握节奏。	\N	3	\N	\N	2026-06-12 14:55:58.486881+08	\N	1
144	single_choice	排名举证从哪些层级进行排名？	{"A": "集团、区域、品牌到本店", "B": "集团、城市、门店到个人", "C": "品牌、车型、颜色到配置", "D": "全国、区域、省份到城市"}	A	文档说明：排名举证从集团、区域、品牌到本店进行排名。	\N	2	\N	\N	2026-06-12 14:55:58.486883+08	\N	1
145	single_choice	在销售顾问看板中，查看毛利结构的主要目的是什么？	{"A": "了解总利润来源", "B": "查看每个订单的明细利润", "C": "对比不同车型的利润", "D": "预测未来利润"}	A	文档提到：在这个界面可以看到自己的毛利结构，一眼看出利润具体来自哪里。	\N	2	\N	\N	2026-06-12 14:55:58.486886+08	\N	1
187	single_choice	在进行优惠券核销时，以下哪项条件不是必须满足的？	{"A": "工单已质检完工", "B": "工单中必须有客户付费类的收费类型", "C": "工单的工时项目和零件项目必须符合优惠券使用的限定范围", "D": "优惠券方案已经过总经理和财务审核生效"}	D	优惠券方案生效是在设置阶段，而优惠券核销是使用已生效的优惠券，因此方案生效不是核销时的条件。核销条件包括工单已质检完工、符合限定范围以及工单有客户付费类收费类型。	\N	3	\N	\N	2026-06-13 10:37:57.716955+08	\N	1
188	single_choice	关于套餐卡中零件核销的操作，以下描述正确的是？	{"A": "零件核销可以在工时项目未派工时进行", "B": "零件核销时，工单中要核销零件的收费类型改为套餐收费类型", "C": "零件核销后，套餐卡中该零件的剩余次数减少一次", "D": "零件核销后，需先取消核销才能做质检反完工"}	B	根据手册，零件核销时需把工单中要核销零件的收费类型改为套餐的收费类型。A错误，零件核销需在零件已出库且工单已完工后；C错误，剩余次数更新为原剩余次数减去工单对应零件出库数，不一定是减少一次；D错误，取消核销针对优惠券，非套餐卡。	\N	3	\N	\N	2026-06-13 10:37:57.716961+08	\N	1
189	single_choice	厂家优惠券核销时，在工时项目中增加记录的要求是？	{"A": "增加一条编号为'Fac'的记录，金额为券面值的负数", "B": "增加两条编号为'Fac'的记录，金额一正一负，收费类型分别为券定义的和工单的", "C": "增加两条编号为'Vou'的记录，金额均为券面值的一半", "D": "增加一条记录，编号为'Fac'，金额为正，收费类型为工单收费类型"}	B	手册明确说明：厂家优惠券核销时，在工时项目中增加编号为'Fac'的两条记录，两条记录的金额是券面值的一正一负，收费类型分别是券定义的收费类型和工单的收费类型。	\N	4	\N	\N	2026-06-13 10:37:57.716965+08	\N	1
190	single_choice	在合群汽车集团系统中，套餐卡方案的制定需要在哪个功能模块下进行？	{"A": "市场管理→套餐卡销售管理", "B": "业务基础资料→套餐方案", "C": "财务结算管理", "D": "工时及材料定义"}	B	根据文档，套餐卡方案制定位于'业务基础资料→套餐方案'路径下，而销售管理则在市场管理模块。	\N	2	\N	\N	2026-06-13 10:38:21.622775+08	\N	1
191	single_choice	套餐卡在哪个环节之后才会生效？	{"A": "方案制定完成后", "B": "工时项目定义完成后", "C": "材料项目定义完成后", "D": "财务结算之后"}	D	文档明确指出'财务结算之后生效'，其他选项均为前置准备步骤。	\N	2	\N	\N	2026-06-13 10:38:21.622782+08	\N	1
193	single_choice	帝豪向上系列车型中，哪项关于全新荣耀金车色的描述是正确的？	{"A": "采用单一银元型铝粉，光线下呈现冷白色泽", "B": "采用12~25μm粒径的多种银元型铝粉，光线下泛暖金色泽", "C": "每层色漆厚度误差控制在头发丝直径的1/10", "D": "采用普通水性漆喷涂，不使用高耐候涂料"}	B	文档明确说明：采用12~25μm粒径的多种银元型铝粉，光线下泛着暖金色泽，金属微粒随角度流转，宛如星尘闪烁。其它选项与文档不符。	\N	2	\N	\N	2026-06-13 10:39:29.701401+08	\N	1
135	multi_choice	销售顾问看板中提供哪三种查看方式？	{"A": "日报、周报、月报", "B": "日报、夜报、年报", "C": "周报、月报、季报", "D": "日报、季报、年报"}	B,C	文档中明确提到：可以选择日报、夜报、年报三种查看方式。	\N	1	\N	2026-06-13	2026-06-12 14:55:58.48686+08	\N	1
129	single_choice	銷售經理駕駛艙數據看板支持哪些週期報表查看？	{"A": "日報、月報、年報", "B": "週報、月報、年報", "C": "日報、週報、月報", "D": "日報、季報、年報"}	A	文檔明確說明可選擇查看日報、月報、年報。	\N	1	\N	2026-06-13	2026-06-12 14:31:39.276273+08	\N	1
130	single_choice	在銷售經理看板中，如何查看不同時間週期的數據？	{"A": "點擊數據指標", "B": "點擊右上角選擇週期或使用快捷按鈕", "C": "刷新頁面", "D": "聯繫IT部門"}	B	文檔提到點擊右上角可選擇查看日報、月報、年報，也可通過快捷按鈕選擇週期。	\N	1	\N	2026-06-13	2026-06-12 14:31:39.27628+08	\N	1
142	single_choice	销售顾问驾驶舱支持哪些终端？	{"A": "仅手机端", "B": "仅电脑端", "C": "手机端和电脑端双端覆盖", "D": "平板端和电脑端"}	C	文档明确：销售顾问驾驶舱分手手机端和电脑端，双端覆盖。	\N	1	\N	2026-06-13	2026-06-12 14:55:58.486879+08	\N	1
192	single_choice	帝豪向上系列车型的第4代主要突破了哪个方面的天花板？	{"A": "智能天花板", "B": "品质天花板", "C": "安全天花板", "D": "科技天花板"}	B	根据文档，第4代帝豪凭借BMA全球模块化架构加持，向上突破自主品牌品质天花板。	\N	1	\N	2026-06-13	2026-06-13 10:39:29.701394+08	\N	1
194	single_choice	关于帝豪向上系列车型的“超低用车成本”卖点，以下哪项描述正确？	{"A": "搭载1.5L直列四缸发动机，动力足，油耗低", "B": "搭载1.5L直列三缸发动机，动力足，油耗低", "C": "搭载2.0L直列四缸发动机，动力足，油耗低", "D": "搭载1.4L直列四缸发动机，动力足，油耗低"}	A	文档中“超低用车成本”部分明确提到：搭载1.5L直列四缸发动机，动力足，油耗低。	\N	1	\N	2026-06-13	2026-06-13 10:39:29.701404+08	\N	1
49	single_choice	帝豪向上系列中“2宽2低”设计具体指什么？	{"A": "宽车体和宽轮胎，低底盘和低油耗", "B": "宽车身和宽高比，低重心和低风阻", "C": "宽座椅和宽后备箱，低噪音和低排放", "D": "宽视野和宽轮距，低价格和低维护"}	B	文档提到“2宽2低”包括1820mm同级最宽车身、1.24同级最大宽高比、低重心设计和低风阻设计（0.27Cd）。	\N	2	\N	2026-06-13	2026-06-10 16:01:19.857914+08	\N	1
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.departments (id, name, parent_id, created_at) FROM stdin;
1	销售部	\N	2026-06-09 13:11:54.909014+08
2	技术部	\N	2026-06-09 13:11:54.909021+08
3	客服部	\N	2026-06-09 13:11:54.909024+08
\.


--
-- Data for Name: exam_attempts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.exam_attempts (id, user_id, paper_id, answers, score, total_questions, correct_count, started_at, submitted_at, status) FROM stdin;
1	2	2	{"2": "D", "3": "true", "10": "C", "16": "C", "18": "true", "20": "C", "27": "B", "34": "C", "45": "A", "51": "A", "71": "A", "74": "A", "76": "C", "79": "B", "82": "B", "85": "D", "101": "C", "107": "C", "120": "C", "130": "D", "137": "C", "146": "B", "148": "D", "149": "D", "154": "D"}	36	25	9	2026-06-13 08:06:59.015831+08	2026-06-13 16:07:39.61241+08	submitted
2	5	3	{"146": "C", "147": "D", "148": "D", "149": "C", "150": "B", "151": "A", "153": "B", "154": "D", "155": "C", "156": "B"}	9	11	1	2026-06-13 10:41:06.410366+08	2026-06-13 18:41:28.334721+08	submitted
3	5	2	{"2": "C", "3": "true", "10": "C", "16": "D", "20": "A", "27": "C", "34": "B", "51": "B", "71": "C", "74": "A", "76": "D", "79": "B", "85": "A", "101": "B", "107": "C", "120": "C", "130": "D", "137": "B", "146": "C", "148": "C", "154": "D"}	16	25	4	2026-06-13 10:41:33.135235+08	2026-06-13 18:42:10.133386+08	submitted
4	4	1	{"4": "B", "8": "B", "20": "B", "21": "B", "37": "B", "54": "B", "63": "B", "75": "B", "77": "B", "85": "B", "87": "B", "89": "B", "97": "B", "99": "B", "107": "B", "115": "B", "116": "B", "119": "B", "149": "B", "154": "B"}	55	20	11	2026-06-13 10:47:20.386498+08	2026-06-13 18:47:54.968958+08	submitted
5	4	3	{"146": "C", "147": "D", "148": "D", "149": "B", "150": "C", "151": "C", "152": "C", "153": "B", "154": "B", "155": "B", "156": "C"}	27	11	3	2026-06-13 11:43:38.364732+08	2026-06-13 19:43:55.192705+08	submitted
\.


--
-- Data for Name: exam_papers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.exam_papers (id, title, target_type, target_value, time_mode, start_time, end_time, duration_minutes, total_questions, status, created_by, created_at, updated_at) FROM stdin;
1	公司基础知识考试	all	\N	anytime	\N	\N	60	20	active	2	2026-06-13 05:31:19.798914+08	2026-06-13 05:31:19.798919+08
2	公司销售基础	all	\N	scheduled	2026-06-13 15:15:00+08	2026-06-14 15:15:00+08	60	25	active	2	2026-06-13 05:45:33.889375+08	2026-06-13 05:45:33.889381+08
3	产品知识考试-1	all	\N	anytime	\N	\N	60	11	active	2	2026-06-13 10:40:33.413886+08	2026-06-13 10:40:33.413892+08
\.


--
-- Data for Name: exam_papers_questions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.exam_papers_questions (id, paper_id, question_id, sort_order) FROM stdin;
1	1	107	1
2	1	21	2
3	1	87	3
4	1	99	4
5	1	149	5
6	1	63	6
7	1	77	7
8	1	37	8
9	1	97	9
10	1	8	10
11	1	75	11
12	1	115	12
13	1	85	13
14	1	4	14
15	1	119	15
16	1	154	16
17	1	116	17
18	1	20	18
19	1	54	19
20	1	89	20
21	2	51	1
22	2	149	2
23	2	45	3
24	2	85	4
25	2	18	5
26	2	76	6
27	2	82	7
28	2	137	8
29	2	79	9
30	2	20	10
31	2	2	11
32	2	71	12
33	2	107	13
34	2	146	14
35	2	120	15
36	2	10	16
37	2	101	17
38	2	74	18
39	2	154	19
40	2	16	20
41	2	130	21
42	2	27	22
43	2	148	23
44	2	34	24
45	2	3	25
46	3	155	1
47	3	154	2
48	3	151	3
49	3	152	4
50	3	147	5
51	3	148	6
52	3	150	7
53	3	153	8
54	3	156	9
55	3	146	10
56	3	149	11
\.


--
-- Data for Name: experience_points; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.experience_points (id, user_id, knowledge_id, points, action_type, created_at) FROM stdin;
1	3	5	1	submit	2026-06-09 13:37:14.963535+08
2	3	210	1	submit	2026-06-09 14:09:17.596947+08
3	3	210	10	approved	2026-06-09 14:09:17.641812+08
4	3	210	2	used	2026-06-09 14:09:17.672548+08
5	3	\N	1	submit	2026-06-09 14:31:05.451291+08
6	3	\N	1	submit	2026-06-09 14:42:22.049913+08
7	4	\N	1	submit	2026-06-11 13:23:33.826259+08
8	4	\N	1	submit	2026-06-11 13:31:54.129992+08
9	4	\N	1	submit	2026-06-11 13:32:31.474259+08
10	4	\N	1	submit	2026-06-11 13:32:40.769478+08
11	4	\N	1	submit	2026-06-11 13:32:45.799032+08
12	4	\N	1	submit	2026-06-11 13:34:05.279736+08
13	4	\N	1	submit	2026-06-11 13:34:29.544161+08
14	4	\N	1	submit	2026-06-11 13:34:33.646051+08
15	4	\N	1	submit	2026-06-11 13:34:51.468164+08
16	5	\N	1	submit	2026-06-11 13:57:47.660358+08
17	5	\N	1	submit	2026-06-11 13:57:56.276263+08
18	5	\N	1	submit	2026-06-11 13:58:06.104964+08
19	5	\N	1	submit	2026-06-11 13:58:09.676918+08
20	5	\N	1	submit	2026-06-11 13:58:12.844994+08
21	5	\N	1	submit	2026-06-11 13:58:15.436619+08
22	2	233	10	approved	2026-06-12 15:19:53.135972+08
23	2	272	10	approved	2026-06-12 15:20:56.337709+08
24	2	275	10	approved	2026-06-12 15:22:10.68884+08
25	3	5	10	approved	2026-06-12 15:22:18.108012+08
26	2	231	10	approved	2026-06-12 15:22:26.014313+08
27	2	273	10	approved	2026-06-12 15:24:35.886416+08
60	4	\N	1	submit	2026-06-13 10:48:19.08739+08
61	4	\N	1	submit	2026-06-13 11:49:18.005802+08
62	4	\N	1	submit	2026-06-13 11:49:21.74255+08
63	4	\N	1	submit	2026-06-13 11:52:02.438653+08
64	4	\N	1	submit	2026-06-13 11:52:12.72771+08
65	4	\N	1	submit	2026-06-13 11:52:30.014682+08
66	4	444	1	submit	2026-06-13 14:56:16.17548+08
67	5	445	1	submit	2026-06-13 14:59:02.286285+08
\.


--
-- Data for Name: knowledge_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_categories (id, name, parent_id, knowledge_base, sort_order, icon, created_at, description, is_active) FROM stdin;
2	企业文化与价值观	\N	public	2	🏢	2026-06-09 13:11:54.924116+08	集团使命愿景、核心价值观、服务理念与企业文化宣导	t
3	安全生产与消防	\N	public	3	🧯	2026-06-09 13:11:54.924118+08	车间安全操作、消防应急、危化品管理、职业病防护等安全知识	t
4	通用商务礼仪	\N	public	4	🤝	2026-06-09 13:11:54.924119+08	客户接待礼仪、电话沟通规范、职业形象与行为准则	t
5	IT系统操作指南	\N	public	5	💻	2026-06-09 13:11:54.92412+08	DMS系统、OA办公、企业微信、邮件等信息化工具使用教程	t
6	法律法规合规	\N	public	6	⚖️	2026-06-09 13:11:54.924122+08	汽车三包法、消费者权益保护、个人信息保护、反商业贿赂等法规	t
7	产品知识库	\N	sales	1	🚗	2026-06-09 13:11:54.924123+08	在售车型参数配置、核心卖点、产品定位及目标客群分析	t
8	竞品对比分析	\N	sales	2	📊	2026-06-09 13:11:54.924124+08	同级别竞品车型优劣势对比、攻防话术与差异化卖点提炼	t
9	销售话术技巧	\N	sales	3	💬	2026-06-09 13:11:54.924125+08	展厅接待、需求挖掘、试驾引导、异议处理及逼单成交的实战话术	t
10	价格谈判策略	\N	sales	4	💰	2026-06-09 13:11:54.924126+08	报价策略、优惠政策组合、金融方案推荐、赠品谈判与价格异议化解	t
11	客户跟进管理	\N	sales	5	📝	2026-06-09 13:11:54.924127+08	潜客分级跟进、战败客户分析、老客户转介绍及客户生命周期管理	t
12	金融按揭方案	\N	sales	6	🏦	2026-06-09 13:11:54.924129+08	银行/厂家金融产品对比、按揭计算、征信预审及放款流程指导	t
13	二手车评估	\N	sales	7	🔄	2026-06-09 13:11:54.92413+08	二手车检测评估方法、置换话术、残值预估与二手车销售策略	t
14	试驾流程标准	\N	sales	8	🛣️	2026-06-09 13:11:54.924131+08	试驾路线规划、动态体验引导、安全注意事项及试驾后促单流程	t
15	发动机系统维修	\N	tech	1	⚙️	2026-06-09 13:11:54.924132+08	涵盖发动机机械、燃油供给、进排气、冷却润滑系统的诊断与维修技术	t
16	变速箱维修技术	\N	tech	2	🔧	2026-06-09 13:11:54.924133+08	MT/AT/CVT/DCT各类型变速箱的工作原理、常见故障与维修工艺	t
17	电气电子系统	\N	tech	3	⚡	2026-06-09 13:11:54.924134+08	车载网络、灯光仪表、舒适电子、ADAS辅助驾驶系统的诊断与编程	t
18	空调暖风系统	\N	tech	4	❄️	2026-06-09 13:11:54.924136+08	制冷循环原理、压缩机/蒸发器检修、自动空调控制逻辑及故障排查	t
19	底盘悬挂转向	\N	tech	5	🛞	2026-06-09 13:11:54.924137+08	悬挂系统、转向机、制动系统、轮胎四轮定位的检查调整与维修	t
20	新能源车维修	\N	tech	6	🔋	2026-06-09 13:11:54.924138+08	三电系统维修、高压安全操作、充电系统诊断与均衡维护	t
21	钣金喷漆工艺	\N	tech	7	🎨	2026-06-09 13:11:54.924139+08	车身钣金修复、漆面处理、涂装工艺流程及色彩调配技术	t
22	故障诊断方法	\N	tech	8	🔍	2026-06-09 13:11:54.92414+08	故障码读取分析、数据流判断、示波器使用、异响定位及疑难故障排查思路	t
23	预约接待流程	\N	service	1	📅	2026-06-09 13:11:54.924141+08	客户预约管理、到店接待、环车检查、工单开单及交车流程标准	t
24	保养服务标准	\N	service	2	🛠️	2026-06-09 13:11:54.924142+08	各车型保养周期、保养项目标准、油液规格及保养提醒话术	t
25	客户投诉处理	\N	service	3	😟	2026-06-09 13:11:54.924143+08	投诉分类分级、情绪安抚技巧、快速响应机制及投诉闭环处理流程	t
26	保险理赔服务	\N	service	4	📄	2026-06-09 13:11:54.924144+08	车险定损流程、理赔资料指导、保险公司对接及事故车维修跟进	t
27	续保业务技巧	\N	service	5	♻️	2026-06-09 13:11:54.924146+08	续保客户筛选、保险产品对比推荐、续保话术及套餐组合策略	t
28	客户回访规范	\N	service	6	📞	2026-06-09 13:11:54.924147+08	售后三日回访、保养到期提醒、满意度调研及客户关怀活动标准	t
29	会员服务管理	\N	service	7	⭐	2026-06-09 13:11:54.924148+08	会员权益体系、积分规则、会员日活动策划及VIP客户专属服务标准	t
30	配件仓储管理	\N	service	8	📦	2026-06-09 13:11:54.924149+08	配件入库出库流程、库存预警、常用件备货策略及呆滞件处理规范	t
1	公司制度与规范	\N	public	1	📋	2026-06-09 13:11:54.924112+08	考勤、报销、用车、办公等公司内部管理制度与流程规范	t
\.


--
-- Data for Name: knowledge_entries; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_entries (id, title, content, content_type, category_id, sub_category, knowledge_base, source_type, source_file_path, source_person, source_dept, media_url, media_start_sec, media_end_sec, tags, car_brand, car_model, difficulty_level, view_count, useful_count, status, auditor_id, audit_comment, version, created_at, updated_at) FROM stdin;
2	国六B排放发动机怠速抖动故障诊断	故障现象：国六B排放标准车辆，冷启动后怠速不稳，转速波动±150rpm，伴随轻微抖动。\n\n诊断步骤：\n1. **读取故障码**：使用诊断仪读取ECU，常见故障码P0300(随机失火)、P0171(混合气过稀)\n2. **检查火花塞**：国六B发动机对火花塞间隙要求更严，标准0.7-0.8mm，超过0.9mm需更换\n3. **检查燃油系统**：测量燃油压力，怠速时应为350-400kPa\n4. **检查碳罐电磁阀**：国六B车型碳罐电磁阀容易卡滞在常开位置，导致混合气过稀\n5. **检查进气系统**：曲轴箱通风PCV阀、进气歧管密封\n\n典型维修案例：星瑞X5 SUV，行驶3万公里，怠速抖动。最终确认碳罐电磁阀故障，更换后问题解决。维修时间约1.5小时，材料费240元。	text	22	\N	tech	experience	\N	赵技师	技术部	\N	0	0	怠速抖动,国六B,碳罐电磁阀,故障诊断	星瑞	X5	4	89	23	approved	\N	\N	1	2026-06-09 13:11:57.396052+08	2026-06-09 13:11:57.396054+08
3	客户投诉三步骤化解法	面对客户投诉，客服人员应遵循"听-认-行"三步法：\n\n**第一步：倾听（2-3分钟）**\n- 保持耐心，不打岔，让客户完整表达不满\n- 使用积极倾听话术："嗯，我明白了""请您继续说"\n- 注意记录关键信息：订单号、车牌号、投诉核心问题\n\n**第二步：认可情绪（1分钟）**\n- 共情话术："我完全理解您现在的心情，换作是我也会很着急"\n- 不要急于解释或推卸，先让客户感受到被重视\n- 确认问题："让我确认一下，您的主要问题是……对吗？"\n\n**第三步：行动承诺（1分钟）**\n- 给出明确时间承诺："我会在30分钟内给您回复"\n- 告知具体处理方案："我们会安排技师重新检查"\n- 留下联系方式，确保客户能找到您\n\n典型案例：客户因保养时间过长投诉，客服使用三步法，从最初要求退款的对抗转为接受补偿方案（免费下次保养），客户后续续保率达85%。	text	25	\N	service	experience	\N	陈客服	客服部	\N	0	0	投诉处理,客服话术,客户关系	\N	\N	2	156	31	approved	\N	\N	1	2026-06-09 13:11:57.396057+08	2026-06-09 13:11:57.396059+08
4	合群汽车集团安全生产规范（2025版）	**合群汽车集团安全生产管理制度（2025年修订版）**\n\n一、车间安全\n1. 维修作业必须佩戴防护用具（安全帽、防护手套、护目镜）\n2. 举升机操作必须两人协作，严禁单人操作\n3. 电气设备检修前必须断开电源并挂警示牌\n4. 油品、涂料等易燃物品存放于专用防爆柜\n\n二、消防管理\n1. 每月15日进行消防器材点检，填写检查记录\n2. 严禁在车间内吸烟或使用明火\n3. 消防通道时刻保持畅通，禁止堆放杂物\n4. 每季度进行一次全员消防演练\n\n三、事故报告\n1. 发生安全事故后，15分钟内向安全主管报告\n2. 事故现场保护，不得擅自破坏\n3. 72小时内提交书面事故分析报告\n4. 隐瞒不报者按集团纪律处分条例处理\n\n四、环保要求\n1. 废机油、废电池等危废交由合规处置单位处理\n2. 烤漆房废气处理设备每月维护一次\n3. 噪音超标区域必须佩戴耳塞	text	3	\N	public	policy	\N	李管理	销售部	\N	0	0	安全生产,消防,管理制度,2025版	\N	\N	1	312	8	approved	\N	\N	1	2026-06-09 13:11:57.396062+08	2026-06-09 13:11:57.396064+08
7	新车交付流程-片段1	第1段内容...	video	7	\N	sales	video	/uploads/demo-delivery.mp4	系统导入	\N	/uploads/demo-delivery.mp4	0	60	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:42:56.654777+08	2026-06-09 13:42:56.654785+08
8	新车交付流程-片段2	第2段内容...	video	7	\N	sales	video	/uploads/demo-delivery.mp4	系统导入	\N	/uploads/demo-delivery.mp4	60	120	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:42:56.654788+08	2026-06-09 13:42:56.65479+08
9	新车交付流程-片段3	第3段内容...	video	7	\N	sales	video	/uploads/demo-delivery.mp4	系统导入	\N	/uploads/demo-delivery.mp4	120	180	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:42:56.654793+08	2026-06-09 13:42:56.654795+08
10	董办【2025年】001号关于全员提升服务意识倡议书的通知（第1段）	[2025]合群总部-日常-董办-001号 密级：重要普通\n1/2主题词：关于全员服务意识倡议书通知\n文件发送：董办、各子公司、各直营店、各部门 文件抄送:无\n发文单位：集团总经理办公室 发文日期：2025年02月28日\n存档部门：集团总经理办公室人事行政部\n关于全员提升服务意识倡议书的通知\n集团各品牌、各直营店、各部门：\n在近期的巡店检查工作中，我们发现集团旗下各店的整体服务意识与服务质\n量存在诸多问题。用户投诉频发，不接听用户电话、服务态度恶劣等现象频繁出\n现，这不仅严重损害了用户的利益，也对集团的品牌形象造成了负面影响。\n服务是企业立足市场的根本，为了重塑集团及各品牌的服务口碑，提升客户\n满意度，现向全体员工发出以下倡议：\n1、全员必须重视并提升服务意识：从董事长到每一位基层员工，都要深刻认\n识到服务的重要性，主动提升服务态度与服务效率；\n2、加强内部监督：全体员工以及中层管理干部需相互监督，一旦发现服务意\n识淡薄、服务质量未达标的行为，要及时指出并督促整改；\n3、落实责任追究：针对服务态度恶劣、效率低下等不符合服务标准的行为，\n无论涉及基层员工还是中层干部，集团将严肃追究个人及其直属领导责任。	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\董办【2025年】001号关于全员提升服务意识倡议书的通知.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:07.006762+08	2026-06-09 13:43:07.006769+08
97	操作手册-套餐卡	套餐卡操作手册\n\n套餐卡管理功能流程说明\n\n套餐卡方案制定\n业务基础资料→套餐方案\n\n套餐卡方案制定\n业务基础资料→套餐方案\n工时项目及材料材料定义。材料项目定义与工时项目的方案一致\n套餐卡销售管理\n市场管理→套餐卡销售管理\n\n套餐卡销售管理\n市场管理→套餐卡销售管理\n财务结算之后生效	text	1	\N	tech	manual	D:\\合群集团资料\\维修知识\\操作手册-套餐卡.pdf	系统导入	\N	\N	0	0	批量导入,维修知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:12.615614+08	2026-06-09 13:43:12.615624+08
6	测试视频-新车交付流程	视频转写内容：新车交付流程分为五个步骤...	video	7	\N	sales	video	\N	李管理	\N	\N	0	0	\N	\N	\N	1	2	0	approved	\N	\N	1	2026-06-09 13:42:55.643227+08	2026-06-09 14:26:09.347269+08
5	语音经验	这是测试转写内容：在销售过程中要注意倾听客户需求。	text	7	\N	sales	experience	\N	王销售	\N	\N	0	0	\N	\N	\N	1	0	0	approved	2	\N	1	2026-06-09 13:37:14.934892+08	2026-06-12 15:22:18.104353+08
11	董办【2025年】001号关于全员提升服务意识倡议书的通知（第2段）	对于\n情节特别严重、造成恶劣影响的，除追究责任外还将予以辞退处理。\n现再次公布“集团董事长办公室投诉监督组”联系方式，欢迎全体员工进行\n监督投诉，并提出批评与建议。同时，要求各品牌、各店务必在早会或夕会时，\n向全体员工进行宣贯。让我们齐心协力，为用户提供最优质的产品和服务。\n特此通知！\n[2025]合群总部-日常-董办-001号 密级：重要普通\n2/2附：集团董事长办公室投诉监督组联系方式\n组长：邢益宝13907640169（微信同号）\n组员：黄兴军13907558401（微信同号）\n向海霞18689860279（微信同号）\n邓铭洲15109875321（微信同号）\n王诗葵13807636392（微信同号）\n签发：	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\董办【2025年】001号关于全员提升服务意识倡议书的通知.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:07.021719+08	2026-06-09 13:43:07.021723+08
12	董办【2025年】004号 附件1：防台风应急管理制度（修订版）（第1段）	1/4防台风应急管理制度（修订版）\n一、总则\n（一）目的：为有效防范台风灾害，最大程度减少集团各品牌、各店人员伤\n亡和财产损失，保障公司正常运营秩序，特制定本制度。\n（二）适用范围：本制度适用于海南合群集团旗下各品牌、各门店及相关设\n施在台风侵袭期间的应急防范与处置工作。\n（三）工作原则：坚持以人为本、预防为主、快速反应、协同应对的原则，\n各部门密切配合，确保各项防风措施落实到位。\n二、组织指挥体系及职责\n（一）成立防台委员会：成立以集团董事长为组长，各部门负责人为成员的\n防台委员会。负责全面指挥和协调公司的防台风工作，制定决策，下达指令，\n调配资源。\n会长：邢益宝​\n副会长：陈文群、黄兴军​​\n（二）成立防台应急小组：防台应急小组组长及组员均为防台委员会委员。\n防台委员会负责统筹协调公司整体防台工作，制定防台策略与应急预案，监\n督各部门防台措施的执行情况。\n组长：各店总经理或门店负责人\n副组长：各店销售经理/售后经理/客服经理/市场经理/财务经理\n/人事行政经理​\n组员：主管级（含）以上所有员工\n（三）各部门职责\n1.总经办：各店总经理作为本门店防风第一责任人，按照台风级别组织落\n实防风措施，安排值班人员，及时汇报防风工作进展及遇到的困难。	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\董办【2025年】004号 附件1：防台风应急管理制度（修订版）.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:07.134878+08	2026-06-09 13:43:07.134883+08
13	董办【2025年】004号 附件1：防台风应急管理制度（修订版）（第2段）	2.各部门经理：负责组建和管理部门员工，确保部门员工能在台风期间随\n时待命，协调内部及社会救援力量。并组织销售、售后救援小组开展救援\n工作。\n2/43.人事行政部\n（1）负责准备和管理防风物资，如沙袋、木板、铁丝、手电筒、食品、\n饮用水等，保障物资的充足供应和合理调配；对办公设备、门店设施进行\n防护和加固，确保设备安全。\n（2）负责对公司场所进行安全检查，排查安全隐患，指导各部门落实防\n风安全措施，监督防风工作执行情况。\n（3）根据台风情况合理安排员工上班、下班和放假时间，确保员工安全。\n三、台风预警及响应措施\n根据台风风力等级，制定以下响应措施：\n台风风力等级 响应措施\n8-9级1.各店总经理安排部门中干及有车男性员工值班，做好值班记录；\n2.玻璃门内外各用4袋沙袋顶紧，台风过后将沙袋用纸箱装好存\n放以便反复使用；\n3.关闭并锁紧窗户、卷闸门；\n4.保安室准备4个大功率手电筒；\n5.手机和充电宝充满电；\n6.售后服务部成立2辆车和4人的救援小组值班，随时准备应对\n突发情况。\n10级1.执行8-9级响应措施的基础上，玻璃门内外拉手之间用木板\n夹紧并用铁丝绑紧，台风过后将木板整齐存放以便反复使用；	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\董办【2025年】004号 附件1：防台风应急管理制度（修订版）.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:07.136876+08	2026-06-09 13:43:07.136881+08
14	董办【2025年】004号 附件1：防台风应急管理制度（修订版）（第3段）	2.各部门上报值班人员名单，确保信息畅通。\n11-12级1.执行10级响应措施的基础上，卷闸门里面焊接对角圆孔插入钢\n管加固。\n2.台风来前，除部分必要的照明电外，全部下闸断电。\n3.每个部门准备一辆加满油电的防风车辆（SUV），随时待命。\n3/4台风风力等级 响应措施\n13-18级1.执行11-12级响应措施的基础上，无混凝土结构的门店不安\n排值班人员，值班人员统一集中到有混凝土结构的场所；\n2.调整商品车停放位置，远离可能积水、倒塌树木及围墙的地方，\n尽量放在空旷高地；重大台风前，撤离车间的维修车；\n3.部门根据台风大小准备必要值班食品（方便面、矿泉水等），\n原则上按一天的量准备。\n4.将电脑主机放到垫高的地上，并加电脑套防水袋；对平时漏水\n的地方，在办公设备上加防水油布。\n5.公司根据台风情况安排放假，以微信群通知为准；非值班人员\n早晨上班时若风大、雨大、路面积水，允许晚到或不上班，各部门\n可上报后安排员工提前下班。\n6.台风期间，值班人员原则上待在水泥结构的一楼，非重要情况\n不允许外出，避免坠物砸伤。\n四、应急救援与处置\n（一）救援行动：当发生因台风引发的紧急情况时，销售和售后救援小组应	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\董办【2025年】004号 附件1：防台风应急管理制度（修订版）.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:07.139199+08	2026-06-09 13:43:07.139203+08
30	附件1 合群汽车集团员工手册（第15段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n8/20\n（五）签订文件：\n签订劳动合同、廉洁承诺书、保密承诺书、安全承诺书等文件。同时在企业微信\n学习电子版员工手册，并在各品牌人事行政处统一签字。劳动合同等相关协议由员工\n本人签字并按手印、公司盖章后生效。\n（六）领用相关用品：笔、笔记本、工牌、领用工服，必要岗位申请印刷名片。\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.554147+08	2026-06-09 13:43:09.554153+08
15	董办【2025年】004号 附件1：防台风应急管理制度（修订版）（第4段）	立即开展救援工作，采取有效措施救助受伤人员，转移受灾物资，降低损失。\n（二）信息报告：在台风期间，各部门应及时向防台委员会报告防风工作情\n况、受灾情况及救援进展，确保信息畅通。\n（三）后期处置：台风过后，各部门组织人员对公司场所进行清理和检查，\n统计损失情况，及时修复受损设施设备，恢复正常运营秩序。\n五、培训与演练\n（一）培训：定期组织员工进行防台风知识培训，增强员工的防范意识和应\n急处置能力。培训内容包括台风危害、防风措施、应急救援知识等。\n（二）演练：每年至少组织一次防台风应急演练，模拟台风来袭场景，检验\n和提升各部门的应急响应能力、协同配合能力和实际操作能力。演练结束后，\n对演练效果进行评估和总结，针对存在的问题及时进行整改。\n4/4六、附则\n（一）本制度应根据国家法律法规、政策变化及集团实际情况适时进行修订，\n确保制度的有效性和适应性。\n（二）本制度由海南合群集团防台委员会负责解释。\n（三）本制度自发布之日起实施。\n签发：	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\董办【2025年】004号 附件1：防台风应急管理制度（修订版）.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:07.140514+08	2026-06-09 13:43:07.140517+08
16	附件1 合群汽车集团员工手册（第1段）	1/20合群汽车集团\n员工手册\n目录\n第一章董事长致辞\n第二章公司概述\n第三章企业文化\n第四章人事管理制度\n第五章考勤、休假制度\n第六章薪酬\n第七章公司福利\n第八章职业发展\n第九章奖惩\n第十章员工守则\n第十一章财务管理制度\n第十二章安全手册\n第十三章附则\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.521314+08	2026-06-09 13:43:09.521324+08
17	附件1 合群汽车集团员工手册（第2段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n2/20合群汽车集团\n员工手册\n董事长致辞：\n亲爱的同事，我是合群汽车集团董事长邢益宝，我谨代表公司董事会，欢迎您加\n入海南合群汽车集团大家庭！\n同时，我也向已经在海南合群汽车集团工作的广大员工表示感谢，正是由于众多\n合群员工的团结进取、忘我付出、艰苦拼搏，集团才得以在十几年的时间内发展到今\n天这样的规模，成为在海南省内汽车行业享有一定声誉的企业。\n公司是以贡献定报酬，凭责任定待遇。对于新员工，工作业绩要在一定时期才能\n真实的体现出来，晋升和调薪会有一个过程，这一过程的长短取决于个人努力程度和\n工作状态。	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.524847+08	2026-06-09 13:43:09.524854+08
18	附件1 合群汽车集团员工手册（第3段）	如果你善于消化他人的经验，善于与人合作，能有效借助公司提供的平台，\n进步就会很快。如果你封闭自己，缺乏必要的沟通和团队合作的意识，那你的晋升会\n很慢，但只要你肯吃苦，能够及时并能保质保量完成本职工作，你的工作报酬和公司\n福利是绝对可以保证的。当然您如果表现得够优秀，我认为随着集团发展，您也会有\n更多的机会。\n如果我们把企业比作一艘远航的船，这艘船最根本的驱动力就是我们的全体员工。\n从公司层面来讲，我们一直强调以人为本的管理理念，强调为员工的发展提供机会，\n通过建立和完善公司的各种管理机制，达到人性化管理和制度化管理的完美结合。从\n另一个层面来讲，企业与员工的关系是相互依存的，没有全体员工的努力，企业就不\n可能持续发展；企业若不能持续发展，就不可能为员工提供发展的机会。我们将努力\n让企业进一步发展，让每一位员工都感到自己作为一个合群员工的骄傲和自豪。同时，\n我们也希望合群的每一位员工都要时刻牢记自己是一个合群的员工，你的一举一动，\n一言一行，都代表着合群的形象，你的每一项工作都直接关系着企业的信誉和发展。\n每一个合群员工都应该积极维护我们合群那种充满活力、积极进取、富有使命感和责\n任感的企业形象。	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.528211+08	2026-06-09 13:43:09.528218+08
19	附件1 合群汽车集团员工手册（第4段）	公司业务正在飞速扩张，并进行相应的系统性管理变革，完善我们的企业文化。\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.530736+08	2026-06-09 13:43:09.530742+08
227	附件8 员工福利管理制度	1/5员工福利管理制度\n一、目的\n为提升企业员工归属感，体现人文关怀，推动企业文化建设，形成良好的企业向心\n力和凝聚力，特制定本制度。\n二、名词解释\n福利：福利特指除公司正常发放的工资和奖金等劳动报酬之外增加给予员工的其他\n福利报酬，包括现金形式和非现金形式两种。\n正式员工：特指已提交转正申请，并经审核通过的在职员工。\n三、适用范围：\n本规定适用于集团所有正式员工，其中部分福利不适用于试用期及实习期员工。\n福建、广东区域如存在特殊福利需求，可单独向集团总经理/董事长申请。\n四、福利待遇的种类：\n（一）公司提供的福利待遇包括按国家规定执行的福利待遇，以及根据公司自身条件\n设置的各项福利待遇。\n（二）按照国家政策和规定，提供的统筹五险（包括：基本养老保险、基本医疗保险、\n失业保险、工伤保险、生育保险；）\n（三）根据公司自身经营条件设置的福利项目包括：住房公积金、节庆福利、假期福\n利、生活福利、培训福利、意外伤害保险、重大疾病险及其他福利。\n（四）员工购车及维修享有员工价格优惠等福利\n五、福利待遇：\n（一）社会统筹保险\n1.公司负责为所有正式员工缴纳国家规定的养老保险、医疗保险、生育保险、工伤保\n险、失业保险；\n2.员工转正后，社会保险由人事行政部负责为员工办理；\n3.社会保险的缴费基数根据公司上年度经营状况，结合海口市上年度工资水平、根据\n政府当期发布的最低缴费基数由人事行政部每年统一进行调整缴纳；\n4.员工办理社保需按时提交规定资料，不能按时提交资料的员工，属于个人原因，所\n带来的所有法律责任由个人承担；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n2/55.社会统筹保险由公司统一缴纳，个人应缴纳部分在工资中扣除；\n（二）住房公积金\n1.员工自入职转正1年后公司提供住房公积金。\n2.住房公积金的缴费基数根据公司上年度经营状况，结合海口市及各省、市上年度工\n资水平由人事行政部每年统一进行调整。\n（三）补贴福利\n1.节庆福利\n（1）每逢元旦、五一劳动节、端午节、十一国庆节、中秋节等等法定假日根据公司\n的经营情况决定是否给全体员工发放节日福利；\n（2）三八妇女节：女性员工放假半天并发放节日福利。\n2.假期福利\n员工所享有的假期有：年假、婚假、陪产假（男员工）、孕检假、哺乳假、丧假、\n事假、病假、工伤假、家长会假等。\n3.生活福利\n（1）工作餐：\n①公司为员工提供免费工作午餐，加班员工应提前报备方可提供免费工作晚餐；\n无厨房门店提供餐费补助，补助标准按照集团财务制度相关规定执行，由各店统一管\n理及支出；\n②二级直营店人员按25元/天/人补助，每月餐费补助次月按实际出勤天数核定发\n放。\n（2）住房补助\n①适用对象条件：入职一年以内的员工并月度领取到手的工资总额低于2000元。\n（到手工资总额是指扣除个人承担部分的社保及个人所得税后的总额）\n②补贴标准：每人每月按照500元标准补助。\n③补贴期限：12个月，从入职当月开始计算；满一年12个月后自动取消。领取租\n房补贴的员工在领取补贴期限内，如月领取到手工资总额大于等于2000元时，则取消\n当月租房补贴；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n3/5④发放方式：当月的租房补贴以工资的形式（包含在工资中）于次月28日在员工\n工资卡中发放。\n⑤人事行政部对上月人员工资进行核对，将符合租房补贴人员发放名单，递交给\n工资制作人员，由工资制作人员计入工资中一并发放。\n4.交通补贴\n（1）当月的交通补贴以工资的形式（包含在工资中）于次月8日发到员工工资卡中。\n（2）其他特殊情况产生的交通费用凭票实销实报（油票、停车票、出租车票等），不\n允许跨月累积报销。\n5.通讯补贴\n（1）当月的通讯补贴以工资的形式（包含在工资中）发到员工工资卡中，补贴标准为：\n员工级：80元/月/项，主管级以上100元月/项，于次月8日在员工工资卡中发放。\n（2）其他特殊情况产生的通讯费用凭票实销实报（电话单、通话记录，通话录音等），\n不允许跨月累积报销。\n6.工装福利\n具体享受内容见各品牌厂商要求着装，费用按照集团财务管理制度相关内容执行。\n7.常规体检\n（1）公司每两年组织员工集体体检一次。\n（2）公司每年组织一次特殊岗位的职业病体检。\n8.文化生活\n为了丰富员工文化生活而设立以下福利：\n（1）为促进员工的身心健康，丰富员工的精神和文化生活、业余生活，培养员工积极\n向上的道德情操而提供以下福利：\n①在不影响工作的情况下，公司不定期组织员工参加羽毛球、篮球、足球等体育活\n动。\n②聚餐：各部门可向集团申请部门经费用于部门间聚餐（部门活动基金为申请制）。\n③员工旅游：公司每年组织全体员工省内旅游1次；组织优秀员工岛外旅游1次，\n星级员工国外旅游1次。（因特殊情况不能组织旅游时，以现金形式发放补助，补助标\n准以集团当期公布的补贴标准为准）。\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n4/5（2）其他文化活动：具体实施根据公司实际情况而定，由发起部门进行组织。\n9.培训福利\n公司根据各部门的培训需求，由各品牌组织实施，提升员工的知识、技能、态度\n等方面与不断变动的技术、外部环境相适应。\n培训福利包括：员工在职或短期脱产培训等。具体规定见公司《培训管理制度》。\n10.其他额外商业保险（公司有权根据当期实际经营情况选择是否购买）\n（1）意外伤害险：充分考虑员工的安全，避免因意外伤害给员工和家属带来的负担，\n为正式员工额外购买意外伤害险。\n（2）重大医疗险：确保员工因个人和家庭成员发生重大疾病给员工带来的负担，享受\n条件为在实施购买时当年前转正的员工，否则在下一年购买\n11.家长会假\n（1）正式员工凭子女学校或幼儿园的通知家长会通知单，享受半天带薪假期，每学期\n每个员工子女可享受1次，双职工仅可一人享受。\n（2）正式员工且有子女在适龄阶段开学的，每年3月、9月初子女入学时，给予半天\n入学入园报名的带薪假期。\n12.员工购车及维修优惠政策\n（1）员工购车福利：\n①员工每年享受一次集团旗下所有品牌按厂家标准成本价的购车机会，仅限本人及\n配偶使用；\n②亲友购车可凭申请享受相应的优惠，特殊情况各品牌总经理根据市场实际情况一\n车一议。\n③员工购买集团各品牌的试驾车新车指标、二手试驾车必须报集团董事长审核批准；\n（2）员工车辆维修及续保福利：\n①员工个人使用并在公司相关管理部门报备过的车辆（上限2台），方可享受维修按\n配件成本，工费按7折结算优惠，续保按当期续保政策执行。\n②鼓励员工推荐亲戚朋友到各品牌维修，各品牌应给予适当优惠，但折扣不得高于\n各品牌总经理和直营店部门领导的权限范围。\n（3）直系亲属购车，须提供关系证明材料，如有弄虚作假者给予5000元的经济处罚\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n5/5并记大过一次。\n（4）享受优惠购车者，本人、家属及亲朋好友对购车相关价格信息负有保密义务，不\n得擅自对外传播相关价格信息，违背者给予4000元的经济处罚并记大过一次。\n（5）员工个人购车，销售人员严格执行销售流程，为购车者办理相关手续，该车不享\n受转介绍奖励，销售员仅发放交车奖励，不纳入销售员当期销量目标。该车不享受公\n司及销售部其他优惠政策。\n（6）任何员工不得利用公司福利政策弄虚作假，谋取个人利益，有违者公司将纳入信\n用不良记录，给予处罚、通报批评乃至辞退的处理。\n（7）申请福利流程：由员工本人向各品牌总经理书面或电话申请，经各环节负责人审\n定后实施.\n六、附则\n一、如本制度条款中有与国家政策相冲突或未涉及内容，均以国家政策为准；\n二、本制度经董事会授权董事长邢益宝先生签发；\n三、本制度解释权归人事行政部所有，人事行政部有权根据需要修改、增加或更新员\n工手册的内容，如有修改内容将在企业微信中通告全体员工；\n四、本制度正式发布后，如出现重大与实际情况不相符的，可上报集团总经理/董事长\n审定，一事一议裁定，并可组织编委会修订条例；\n五、本制度在企业微信－合群云档－规章制度中发布，集团全体员工均可自行阅览，\n不得下载；\n六、公布实施后新入职的新员工，需在入职前详细阅读本手册，并签字确认认同本手\n册的全部内容，如不认同本手册内容，可选择自动放弃入职；\n七、本制度正式发布后，如与前期发布的制度相违处，以本制度为准，后续所有制度\n调整，均以最新发布为准；\n八、本制度自2022年01月01日开始执行。\n签发人：\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\HqEvoAI\\uploads\\9a2133a96008457f8eb0c5b781516266.pdf	王销售	\N	\N	0	0	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-11 13:44:31.131212+08	2026-06-11 13:44:31.131217+08
20	附件1 合群汽车集团员工手册（第5段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n3/20期望每位合群员工都能积极参与，只有参与才能更好理解，只有理解才能达成共识。\n希望每位合群员工能自觉遵守公司制度，并在全体员工的努力推动下，我们坚信合群\n汽车集团将一步步实现自己的奋斗目标。而合群的每一位员工，都会在合群这个朝气\n蓬勃、不断进取的企业中，逐步体现自己的人生价值。我希望大家充分的了解合群的\n文化与制度，并充分执行；还希望大家能够在工作中找出合群的问题，我们一起解决\n问题，共同进步；并衷心希望每一位员工能够在这里工作愉快、身体健康、平平安安！\n希望大家以此手册为指导，自我管理，不断进取。\n董事长：\n第二章公司概述\n海南合群汽车销售有限公司成立于2007年，是一家经营多品牌汽车销售、售后服\n务、汽车配件、汽车租赁、汽车精品、二手车销售、汽车美容、金融按揭、车辆保险、\n新能源电池维保等汽车相关综合服务的本土企业。	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.532755+08	2026-06-09 13:43:09.532761+08
21	附件1 合群汽车集团员工手册（第6段）	集团从郑州日产品牌发展起步，正\n逐步转型成为多品牌经营为主，多种业态模式共同发展的企业，力争成为海南省汽车\n行业的实力标杆企业。截止2021年12月集团旗下有超过20个汽车品牌，33个一级授\n权店，20个直营店。全岛网络布局覆盖达100%。集团旗下经营品牌有：郑州日产、长\n安汽车、上汽大通、吉利汽车、上汽大众、上汽名爵、领克汽车、上汽跃进、几何新\n能源、北汽福田、比亚迪新能源、枫叶新能源、广汽三菱、捷途汽车、远程汽车、英\n伦汽车、零跑汽车、南京依维柯等。2020年集团实现新车总量12212台，约占海南汽\n车销售份额9.5%，实现售后总产值1.3亿，2021年销量超过17000台，售后产值超过\n1.5亿元，集团总营业规模达20亿元左右，年纳税额接近3000万，集团员工规模达\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.535015+08	2026-06-09 13:43:09.535021+08
22	附件1 合群汽车集团员工手册（第7段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n4/201100余人。\n公司奉行“以人为本、诚信经营、真实合理”的经营理念，作为国内多家知名汽	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.536969+08	2026-06-09 13:43:09.536975+08
23	附件1 合群汽车集团员工手册（第8段）	车品牌的经销商,我们以优异的产品质量及良好的售后服务，赢得广大客户的信赖和支\n持，让公司在海南汽车流通行业占有了重要地位。在全体员工的共同努力下，公司连\n续多年获得各汽车品牌“优秀经销商”“十佳经销商”“全球优秀经销商”等嘉誉。\n同时，我们也获得社会各界的肯定，连续多年获得全国汽车维修行业诚信企业，海口\n市“守合同重信用”单位，海南银行诚信合作企业单位等荣誉称号。\n公司秉承“安全第一、客户至上、高效执行、科学创新”的管理理念，通过卓越\n的人力资源管理促进员工职业化素质的提高，着力打造一个极具活力和凝聚力的优秀\n团队，为客户创造更完善更优质的服务。\n第三章企业文化\n【企业使命】：\n为用户提供最优质的产品和服务，践行社会责任、推动共同富裕\n【核心价值观】：公平、公正、团结、互助\n【经营理念】：以人为本、诚信经营、真实合理\n【管理理念】：安全第一、客户至上、高效执行、科学创新\n【大家庭文化】\n互助、互爱、共享、批评与自我批评\n【问题文化】\n发现问题是好事\n解决问题是大事\n逃避问题是蠢事\n没有问题是坏事\n【公司的发展历史】\n序号 时间 标志性事件 意义\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.539331+08	2026-06-09 13:43:09.539337+08
24	附件1 合群汽车集团员工手册（第9段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.541421+08	2026-06-09 13:43:09.541428+08
228	附件8 员工福利管理制度	1/5员工福利管理制度\n一、目的\n为提升企业员工归属感，体现人文关怀，推动企业文化建设，形成良好的企业向心\n力和凝聚力，特制定本制度。\n二、名词解释\n福利：福利特指除公司正常发放的工资和奖金等劳动报酬之外增加给予员工的其他\n福利报酬，包括现金形式和非现金形式两种。\n正式员工：特指已提交转正申请，并经审核通过的在职员工。\n三、适用范围：\n本规定适用于集团所有正式员工，其中部分福利不适用于试用期及实习期员工。\n福建、广东区域如存在特殊福利需求，可单独向集团总经理/董事长申请。\n四、福利待遇的种类：\n（一）公司提供的福利待遇包括按国家规定执行的福利待遇，以及根据公司自身条件\n设置的各项福利待遇。\n（二）按照国家政策和规定，提供的统筹五险（包括：基本养老保险、基本医疗保险、\n失业保险、工伤保险、生育保险；）\n（三）根据公司自身经营条件设置的福利项目包括：住房公积金、节庆福利、假期福\n利、生活福利、培训福利、意外伤害保险、重大疾病险及其他福利。\n（四）员工购车及维修享有员工价格优惠等福利\n五、福利待遇：\n（一）社会统筹保险\n1.公司负责为所有正式员工缴纳国家规定的养老保险、医疗保险、生育保险、工伤保\n险、失业保险；\n2.员工转正后，社会保险由人事行政部负责为员工办理；\n3.社会保险的缴费基数根据公司上年度经营状况，结合海口市上年度工资水平、根据\n政府当期发布的最低缴费基数由人事行政部每年统一进行调整缴纳；\n4.员工办理社保需按时提交规定资料，不能按时提交资料的员工，属于个人原因，所\n带来的所有法律责任由个人承担；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n2/55.社会统筹保险由公司统一缴纳，个人应缴纳部分在工资中扣除；\n（二）住房公积金\n1.员工自入职转正1年后公司提供住房公积金。\n2.住房公积金的缴费基数根据公司上年度经营状况，结合海口市及各省、市上年度工\n资水平由人事行政部每年统一进行调整。\n（三）补贴福利\n1.节庆福利\n（1）每逢元旦、五一劳动节、端午节、十一国庆节、中秋节等等法定假日根据公司\n的经营情况决定是否给全体员工发放节日福利；\n（2）三八妇女节：女性员工放假半天并发放节日福利。\n2.假期福利\n员工所享有的假期有：年假、婚假、陪产假（男员工）、孕检假、哺乳假、丧假、\n事假、病假、工伤假、家长会假等。\n3.生活福利\n（1）工作餐：\n①公司为员工提供免费工作午餐，加班员工应提前报备方可提供免费工作晚餐；\n无厨房门店提供餐费补助，补助标准按照集团财务制度相关规定执行，由各店统一管\n理及支出；\n②二级直营店人员按25元/天/人补助，每月餐费补助次月按实际出勤天数核定发\n放。\n（2）住房补助\n①适用对象条件：入职一年以内的员工并月度领取到手的工资总额低于2000元。\n（到手工资总额是指扣除个人承担部分的社保及个人所得税后的总额）\n②补贴标准：每人每月按照500元标准补助。\n③补贴期限：12个月，从入职当月开始计算；满一年12个月后自动取消。领取租\n房补贴的员工在领取补贴期限内，如月领取到手工资总额大于等于2000元时，则取消\n当月租房补贴；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n3/5④发放方式：当月的租房补贴以工资的形式（包含在工资中）于次月28日在员工\n工资卡中发放。\n⑤人事行政部对上月人员工资进行核对，将符合租房补贴人员发放名单，递交给\n工资制作人员，由工资制作人员计入工资中一并发放。\n4.交通补贴\n（1）当月的交通补贴以工资的形式（包含在工资中）于次月8日发到员工工资卡中。\n（2）其他特殊情况产生的交通费用凭票实销实报（油票、停车票、出租车票等），不\n允许跨月累积报销。\n5.通讯补贴\n（1）当月的通讯补贴以工资的形式（包含在工资中）发到员工工资卡中，补贴标准为：\n员工级：80元/月/项，主管级以上100元月/项，于次月8日在员工工资卡中发放。\n（2）其他特殊情况产生的通讯费用凭票实销实报（电话单、通话记录，通话录音等），\n不允许跨月累积报销。\n6.工装福利\n具体享受内容见各品牌厂商要求着装，费用按照集团财务管理制度相关内容执行。\n7.常规体检\n（1）公司每两年组织员工集体体检一次。\n（2）公司每年组织一次特殊岗位的职业病体检。\n8.文化生活\n为了丰富员工文化生活而设立以下福利：\n（1）为促进员工的身心健康，丰富员工的精神和文化生活、业余生活，培养员工积极\n向上的道德情操而提供以下福利：\n①在不影响工作的情况下，公司不定期组织员工参加羽毛球、篮球、足球等体育活\n动。\n②聚餐：各部门可向集团申请部门经费用于部门间聚餐（部门活动基金为申请制）。\n③员工旅游：公司每年组织全体员工省内旅游1次；组织优秀员工岛外旅游1次，\n星级员工国外旅游1次。（因特殊情况不能组织旅游时，以现金形式发放补助，补助标\n准以集团当期公布的补贴标准为准）。\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n4/5（2）其他文化活动：具体实施根据公司实际情况而定，由发起部门进行组织。\n9.培训福利\n公司根据各部门的培训需求，由各品牌组织实施，提升员工的知识、技能、态度\n等方面与不断变动的技术、外部环境相适应。\n培训福利包括：员工在职或短期脱产培训等。具体规定见公司《培训管理制度》。\n10.其他额外商业保险（公司有权根据当期实际经营情况选择是否购买）\n（1）意外伤害险：充分考虑员工的安全，避免因意外伤害给员工和家属带来的负担，\n为正式员工额外购买意外伤害险。\n（2）重大医疗险：确保员工因个人和家庭成员发生重大疾病给员工带来的负担，享受\n条件为在实施购买时当年前转正的员工，否则在下一年购买\n11.家长会假\n（1）正式员工凭子女学校或幼儿园的通知家长会通知单，享受半天带薪假期，每学期\n每个员工子女可享受1次，双职工仅可一人享受。\n（2）正式员工且有子女在适龄阶段开学的，每年3月、9月初子女入学时，给予半天\n入学入园报名的带薪假期。\n12.员工购车及维修优惠政策\n（1）员工购车福利：\n①员工每年享受一次集团旗下所有品牌按厂家标准成本价的购车机会，仅限本人及\n配偶使用；\n②亲友购车可凭申请享受相应的优惠，特殊情况各品牌总经理根据市场实际情况一\n车一议。\n③员工购买集团各品牌的试驾车新车指标、二手试驾车必须报集团董事长审核批准；\n（2）员工车辆维修及续保福利：\n①员工个人使用并在公司相关管理部门报备过的车辆（上限2台），方可享受维修按\n配件成本，工费按7折结算优惠，续保按当期续保政策执行。\n②鼓励员工推荐亲戚朋友到各品牌维修，各品牌应给予适当优惠，但折扣不得高于\n各品牌总经理和直营店部门领导的权限范围。\n（3）直系亲属购车，须提供关系证明材料，如有弄虚作假者给予5000元的经济处罚\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n5/5并记大过一次。\n（4）享受优惠购车者，本人、家属及亲朋好友对购车相关价格信息负有保密义务，不\n得擅自对外传播相关价格信息，违背者给予4000元的经济处罚并记大过一次。\n（5）员工个人购车，销售人员严格执行销售流程，为购车者办理相关手续，该车不享\n受转介绍奖励，销售员仅发放交车奖励，不纳入销售员当期销量目标。该车不享受公\n司及销售部其他优惠政策。\n（6）任何员工不得利用公司福利政策弄虚作假，谋取个人利益，有违者公司将纳入信\n用不良记录，给予处罚、通报批评乃至辞退的处理。\n（7）申请福利流程：由员工本人向各品牌总经理书面或电话申请，经各环节负责人审\n定后实施.\n六、附则\n一、如本制度条款中有与国家政策相冲突或未涉及内容，均以国家政策为准；\n二、本制度经董事会授权董事长邢益宝先生签发；\n三、本制度解释权归人事行政部所有，人事行政部有权根据需要修改、增加或更新员\n工手册的内容，如有修改内容将在企业微信中通告全体员工；\n四、本制度正式发布后，如出现重大与实际情况不相符的，可上报集团总经理/董事长\n审定，一事一议裁定，并可组织编委会修订条例；\n五、本制度在企业微信－合群云档－规章制度中发布，集团全体员工均可自行阅览，\n不得下载；\n六、公布实施后新入职的新员工，需在入职前详细阅读本手册，并签字确认认同本手\n册的全部内容，如不认同本手册内容，可选择自动放弃入职；\n七、本制度正式发布后，如与前期发布的制度相违处，以本制度为准，后续所有制度\n调整，均以最新发布为准；\n八、本制度自2022年01月01日开始执行。\n签发人：\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\HqEvoAI\\uploads\\ee37a20949204ffc977caf301f5e799b.pdf	赵技师	\N	\N	0	0	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-11 13:45:27.81077+08	2026-06-11 13:45:27.810775+08
25	附件1 合群汽车集团员工手册（第10段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n5/2012006年12月郑州日产品牌成立合众公司成立，开始进入汽车行\n业\n22009年1月合众升级为4S店、文昌直\n营店成立成立第一家汽车4S店，第一家\n直营二网，并开始走向全岛化布\n局\n32012年7月海南合群成立、御风品牌\n授权经营成立第二家汽车4S店\n42014年初众泰、长安、上汽大通品\n牌成立公司走向多品牌经营发展\n52015年4月收购三亚郑州日产成为郑州日产厂家在海南地区\n唯一授权经销商\n62016年三亚吉利、琼海上汽大众、\n比速品牌成立开启以合群集团形象对外展示，\n逐步向集团化管理迈进\n72017年 上汽名爵、领克品牌成立多品牌落地，加快品牌发展的步\n伐\n82018年海南合众收购海口吉利品\n牌G网成为吉利汽车海南独家G网代理\n品牌商\n92019年上汽跃进、几何、福田、\n三亚比亚迪开启进军新能源汽车市场，开始\n扩张商用车市场\n102020年1.枫叶、广汽蔚来、广汽\n三菱品牌成立\n2.与宁德时代合作成立\n海南合润，负责宁德时代\n动力电池维保1.全岛年销量突破1万台	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.543401+08	2026-06-09 13:43:09.543408+08
26	附件1 合群汽车集团员工手册（第11段）	2.开始布局新能源汽车后市场\n112021年1、新增品牌：捷途、远程、\n英伦、零跑汽车、南京依\n维柯\n2、走出岛内市场，布局广走出岛内市场，开拓进军岛外市\n场，挖掘汽车后市场\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.546182+08	2026-06-09 13:43:09.546189+08
27	附件1 合群汽车集团员工手册（第12段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n6/20东佛山吉利、广东阳江领\n克、福建泉州吉利\n3、邦普能源回收合作新能\n源电池回收\n【现行管理架构】\n第四章人事管理制度\n一、新员工入职指引\n（一）对接岗位：人事行政部在新员工入职前人事需对其进行个人背景调查。调查\n内容包括：学历、原公司的工作状况、个人征信等。\n（二）新员工入职时须提交以下资料：\n1.毕业证和学位证原件及复印件、身份证复印件、驾驶证复印件；\n2.所取得的相关资质认证机构的认证证书复印件；\n3.三张近期1寸免冠彩色照片；\n4.六个月内体检报告（特殊岗位入职后需进行职业病体检）;\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.548239+08	2026-06-09 13:43:09.548246+08
28	附件1 合群汽车集团员工手册（第13段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.550179+08	2026-06-09 13:43:09.550186+08
29	附件1 合群汽车集团员工手册（第14段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n7/205.实习生需提供三方协议；\n6.加盖原公司公章的离职证明原件（有从业经验者）；\n7.以本人为户主开户银行卡用于发放工资（具体以各品牌店要求为准）;\n8.个人征信报告（到人民银行窗口打印或各银行手机APP下载）。\n（三）报到流程：\n提交入职资料→签订文件→领用办公用品→参观公司、部门引见。\n（四）员工入职手续办理流程图：\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.55203+08	2026-06-09 13:43:09.552036+08
87	关于颁布吉利银河跨年购置税补贴执行细则的通知（第3段）	吉利汽车销售有限公司  \n                                    佛山合悦汽车销售有限公司_何志才                                                                                                                                             \n                                    佛山合悦汽车销售有限公司_何志才                                                                                                                                             \n                                    佛山合悦汽车销售有限公司_何志才	text	1	\N	public	manual	D:\\合群集团资料\\商务政策\\关于颁布吉利银河跨年购置税补贴执行细则的通知.pdf	系统导入	\N	\N	0	0	批量导入,商务政策	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.820575+08	2026-06-09 13:43:11.820582+08
31	附件1 合群汽车集团员工手册（第16段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.556396+08	2026-06-09 13:43:09.556403+08
32	附件1 合群汽车集团员工手册（第17段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n9/20（七）加入公司企业微信：公司采用“企业微信”的方式对员工的日常进行管理，\n相关人事流程、考勤、各项申请、费用报销、规章制度及文件发布等均在企业微信\n内进行审批。\n（八）人事行政部向集团董办报备，统一制作个人电子名片。\n（九）由员工入职的部门领导负责安排相关岗位师傅对新员工进行代培。\n二、试用及转正管理\n（一）员工入职后，公司将会安排入职的相关培训，包括不限于：工作职责与工\n作内容、工作目标、公司的规章制度等，要求转正前参加“企业微信”规章制度\n学习培训，考试合格方可转正。\n（二）按合同期签订期限的不同，试用期为1-3个月，特殊岗位，特殊情况除外，\n但最长不得超过6个月；\n（三）试用期结束后，员工满足岗位考核要求的可给予转正；\n（四）其他未尽事宜参考《员工试用转正制度》。\n三、异动管理\n（一）晋升、调岗管理\n1.公司岗位晋升采用择优培养，竞聘上岗的原则；\n2.公司临时出现岗位空缺而产生需求，根据过往业绩和综合表现给予参加岗位评\n聘的机会；\n3.人事行政部根据公司战略规划及人员需求，定期发布岗位需求及具体要求，员	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.55869+08	2026-06-09 13:43:09.558696+08
33	附件1 合群汽车集团员工手册（第18段）	工可关注“企业微信”公布的相关通知；\n4.其他未尽事宜参考《员工异动管理制度》。\n（二）降职、辞退管理\n1.当员工工作能力不能胜任本职岗位要求，从而影响到工作质量、效率和完成情\n况将给予降职或辞退处理；\n2.月度绩效考核连续不合格者，将给予降职或辞退处理；\n3.违反公司制度，造成较严重负面影响者给予降职处理直至辞退；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.5609+08	2026-06-09 13:43:09.560907+08
34	附件1 合群汽车集团员工手册（第19段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n10/204.违反企业红线等严重违法乱纪甚至触犯法律者，公司将做开除处理，同时集团\n内部公示，并保留追究法律责任的权利；\n5.其他未尽事宜参考《员工异动管理制度》。\n四、离职管理\n（一）辞职申请：员工辞职应填写《离职申请表》，并发起离职审批流程报与相关\n领导审批；\n（二）离职时间：试用期员工离职须提前3天提出书面申请，已转正员工离职须提\n前30天提出书面申请，获得直属上级领导同意后，在“企业微信”发起申请，完\n成工作相关交接，待离职申请流程审批完成后方可离职；	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.563068+08	2026-06-09 13:43:09.563074+08
35	附件1 合群汽车集团员工手册（第20段）	（三）总经理、财务经理及门店第一负责人的离职事项必须通过集团财务部门相关\n审计，审计报告副本上报集团人事行政部存档备案，审计报告为办理离职交接手续\n的必要步骤。无审计报告视为交接工作未完成。试用期员工离职须提前3天提出书\n面申请，待批准后方可办理离职；\n（四）其他未尽事宜参考《员工离职管理制度》。\n（五）离职办理流程图：\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.565385+08	2026-06-09 13:43:09.565392+08
229	附件8 员工福利管理制度	1/5员工福利管理制度\n一、目的\n为提升企业员工归属感，体现人文关怀，推动企业文化建设，形成良好的企业向心\n力和凝聚力，特制定本制度。\n二、名词解释\n福利：福利特指除公司正常发放的工资和奖金等劳动报酬之外增加给予员工的其他\n福利报酬，包括现金形式和非现金形式两种。\n正式员工：特指已提交转正申请，并经审核通过的在职员工。\n三、适用范围：\n本规定适用于集团所有正式员工，其中部分福利不适用于试用期及实习期员工。\n福建、广东区域如存在特殊福利需求，可单独向集团总经理/董事长申请。\n四、福利待遇的种类：\n（一）公司提供的福利待遇包括按国家规定执行的福利待遇，以及根据公司自身条件\n设置的各项福利待遇。\n（二）按照国家政策和规定，提供的统筹五险（包括：基本养老保险、基本医疗保险、\n失业保险、工伤保险、生育保险；）\n（三）根据公司自身经营条件设置的福利项目包括：住房公积金、节庆福利、假期福\n利、生活福利、培训福利、意外伤害保险、重大疾病险及其他福利。\n（四）员工购车及维修享有员工价格优惠等福利\n五、福利待遇：\n（一）社会统筹保险\n1.公司负责为所有正式员工缴纳国家规定的养老保险、医疗保险、生育保险、工伤保\n险、失业保险；\n2.员工转正后，社会保险由人事行政部负责为员工办理；\n3.社会保险的缴费基数根据公司上年度经营状况，结合海口市上年度工资水平、根据\n政府当期发布的最低缴费基数由人事行政部每年统一进行调整缴纳；\n4.员工办理社保需按时提交规定资料，不能按时提交资料的员工，属于个人原因，所\n带来的所有法律责任由个人承担；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n2/55.社会统筹保险由公司统一缴纳，个人应缴纳部分在工资中扣除；\n（二）住房公积金\n1.员工自入职转正1年后公司提供住房公积金。\n2.住房公积金的缴费基数根据公司上年度经营状况，结合海口市及各省、市上年度工\n资水平由人事行政部每年统一进行调整。\n（三）补贴福利\n1.节庆福利\n（1）每逢元旦、五一劳动节、端午节、十一国庆节、中秋节等等法定假日根据公司\n的经营情况决定是否给全体员工发放节日福利；\n（2）三八妇女节：女性员工放假半天并发放节日福利。\n2.假期福利\n员工所享有的假期有：年假、婚假、陪产假（男员工）、孕检假、哺乳假、丧假、\n事假、病假、工伤假、家长会假等。\n3.生活福利\n（1）工作餐：\n①公司为员工提供免费工作午餐，加班员工应提前报备方可提供免费工作晚餐；\n无厨房门店提供餐费补助，补助标准按照集团财务制度相关规定执行，由各店统一管\n理及支出；\n②二级直营店人员按25元/天/人补助，每月餐费补助次月按实际出勤天数核定发\n放。\n（2）住房补助\n①适用对象条件：入职一年以内的员工并月度领取到手的工资总额低于2000元。\n（到手工资总额是指扣除个人承担部分的社保及个人所得税后的总额）\n②补贴标准：每人每月按照500元标准补助。\n③补贴期限：12个月，从入职当月开始计算；满一年12个月后自动取消。领取租\n房补贴的员工在领取补贴期限内，如月领取到手工资总额大于等于2000元时，则取消\n当月租房补贴；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n3/5④发放方式：当月的租房补贴以工资的形式（包含在工资中）于次月28日在员工\n工资卡中发放。\n⑤人事行政部对上月人员工资进行核对，将符合租房补贴人员发放名单，递交给\n工资制作人员，由工资制作人员计入工资中一并发放。\n4.交通补贴\n（1）当月的交通补贴以工资的形式（包含在工资中）于次月8日发到员工工资卡中。\n（2）其他特殊情况产生的交通费用凭票实销实报（油票、停车票、出租车票等），不\n允许跨月累积报销。\n5.通讯补贴\n（1）当月的通讯补贴以工资的形式（包含在工资中）发到员工工资卡中，补贴标准为：\n员工级：80元/月/项，主管级以上100元月/项，于次月8日在员工工资卡中发放。\n（2）其他特殊情况产生的通讯费用凭票实销实报（电话单、通话记录，通话录音等），\n不允许跨月累积报销。\n6.工装福利\n具体享受内容见各品牌厂商要求着装，费用按照集团财务管理制度相关内容执行。\n7.常规体检\n（1）公司每两年组织员工集体体检一次。\n（2）公司每年组织一次特殊岗位的职业病体检。\n8.文化生活\n为了丰富员工文化生活而设立以下福利：\n（1）为促进员工的身心健康，丰富员工的精神和文化生活、业余生活，培养员工积极\n向上的道德情操而提供以下福利：\n①在不影响工作的情况下，公司不定期组织员工参加羽毛球、篮球、足球等体育活\n动。\n②聚餐：各部门可向集团申请部门经费用于部门间聚餐（部门活动基金为申请制）。\n③员工旅游：公司每年组织全体员工省内旅游1次；组织优秀员工岛外旅游1次，\n星级员工国外旅游1次。（因特殊情况不能组织旅游时，以现金形式发放补助，补助标\n准以集团当期公布的补贴标准为准）。\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n4/5（2）其他文化活动：具体实施根据公司实际情况而定，由发起部门进行组织。\n9.培训福利\n公司根据各部门的培训需求，由各品牌组织实施，提升员工的知识、技能、态度\n等方面与不断变动的技术、外部环境相适应。\n培训福利包括：员工在职或短期脱产培训等。具体规定见公司《培训管理制度》。\n10.其他额外商业保险（公司有权根据当期实际经营情况选择是否购买）\n（1）意外伤害险：充分考虑员工的安全，避免因意外伤害给员工和家属带来的负担，\n为正式员工额外购买意外伤害险。\n（2）重大医疗险：确保员工因个人和家庭成员发生重大疾病给员工带来的负担，享受\n条件为在实施购买时当年前转正的员工，否则在下一年购买\n11.家长会假\n（1）正式员工凭子女学校或幼儿园的通知家长会通知单，享受半天带薪假期，每学期\n每个员工子女可享受1次，双职工仅可一人享受。\n（2）正式员工且有子女在适龄阶段开学的，每年3月、9月初子女入学时，给予半天\n入学入园报名的带薪假期。\n12.员工购车及维修优惠政策\n（1）员工购车福利：\n①员工每年享受一次集团旗下所有品牌按厂家标准成本价的购车机会，仅限本人及\n配偶使用；\n②亲友购车可凭申请享受相应的优惠，特殊情况各品牌总经理根据市场实际情况一\n车一议。\n③员工购买集团各品牌的试驾车新车指标、二手试驾车必须报集团董事长审核批准；\n（2）员工车辆维修及续保福利：\n①员工个人使用并在公司相关管理部门报备过的车辆（上限2台），方可享受维修按\n配件成本，工费按7折结算优惠，续保按当期续保政策执行。\n②鼓励员工推荐亲戚朋友到各品牌维修，各品牌应给予适当优惠，但折扣不得高于\n各品牌总经理和直营店部门领导的权限范围。\n（3）直系亲属购车，须提供关系证明材料，如有弄虚作假者给予5000元的经济处罚\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n5/5并记大过一次。\n（4）享受优惠购车者，本人、家属及亲朋好友对购车相关价格信息负有保密义务，不\n得擅自对外传播相关价格信息，违背者给予4000元的经济处罚并记大过一次。\n（5）员工个人购车，销售人员严格执行销售流程，为购车者办理相关手续，该车不享\n受转介绍奖励，销售员仅发放交车奖励，不纳入销售员当期销量目标。该车不享受公\n司及销售部其他优惠政策。\n（6）任何员工不得利用公司福利政策弄虚作假，谋取个人利益，有违者公司将纳入信\n用不良记录，给予处罚、通报批评乃至辞退的处理。\n（7）申请福利流程：由员工本人向各品牌总经理书面或电话申请，经各环节负责人审\n定后实施.\n六、附则\n一、如本制度条款中有与国家政策相冲突或未涉及内容，均以国家政策为准；\n二、本制度经董事会授权董事长邢益宝先生签发；\n三、本制度解释权归人事行政部所有，人事行政部有权根据需要修改、增加或更新员\n工手册的内容，如有修改内容将在企业微信中通告全体员工；\n四、本制度正式发布后，如出现重大与实际情况不相符的，可上报集团总经理/董事长\n审定，一事一议裁定，并可组织编委会修订条例；\n五、本制度在企业微信－合群云档－规章制度中发布，集团全体员工均可自行阅览，\n不得下载；\n六、公布实施后新入职的新员工，需在入职前详细阅读本手册，并签字确认认同本手\n册的全部内容，如不认同本手册内容，可选择自动放弃入职；\n七、本制度正式发布后，如与前期发布的制度相违处，以本制度为准，后续所有制度\n调整，均以最新发布为准；\n八、本制度自2022年01月01日开始执行。\n签发人：\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\HqEvoAI\\uploads\\bf6174220ad04096b124a110414dbe26.pdf	赵技师	\N	\N	0	0	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-11 13:47:39.91239+08	2026-06-11 13:47:39.912393+08
243	销售经理驾驶仓数据分析看板 - 片段5 (00:18)	可選擇查看日報、月報、年報。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	18.07	21.67	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.498386+08	2026-06-12 14:31:07.49839+08
36	附件1 合群汽车集团员工手册（第21段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n11/20\n第五章考勤、休假制度\n一、考勤\n（一）公司员工各类考勤打卡采用“企业微信”管理方式完成；\n（二）公司工作时间如下：\n工作时间：8:30-18:00，午饭午休时间为12：30-14：00，根据公司岗位的\n实际工作需求，保安及厨房岗位采用不定时工时制；\n（三）各区域可根据地域实际情况提报调整上下班计划，上报集团审批后执行；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.567444+08	2026-06-09 13:43:09.567451+08
37	附件1 合群汽车集团员工手册（第22段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.56952+08	2026-06-09 13:43:09.569526+08
38	附件1 合群汽车集团员工手册（第23段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n12/20（四）其他未尽事宜参考《员工考勤管理制度》。\n二、假期\n（一）公司假期分为：公休、法定假日、福利假、年假、婚假、产假、丧假、病假、\n事假；\n（二）公休假期：每周一天；\n（三）公司福利假：2天/月（详见假期管理制度）；\n（四）法定假日：元旦、春节、五一劳动节、清明节、端午节、十一国庆节、中秋\n节等国家法定假日。放假时间原则按国家标准执行，具体安排由人事行政部另行通\n知；\n（五）年假：\n1.以自然年为计算单位，每满一个自然年方可享受5天年假；\n2.新员工入职满一年，当年度剩余时间的年假计算规则按下表计算：\n年假天数\n上年度到岗月份可休年假天数 次年年休假月份\n满一个自然年 5天 次年1月-12月\n1月－3月 4天 次年4月－12月\n4月－6月 3天 次年7月－12月\n7月－9月 2天 次年10月－12月\n10月 1天 次年11月－12月\n11月－12月 0天 无\n（六）婚假：加入公司后领取结婚证的员工可凭结婚证享受公司提供的带薪婚假。\n（七）产假：转正后员工在我司工作期间可享受国家标准产假政策。\n（八）丧假：员工直系亲属，祖父母、外祖父母过世享有2天带薪丧假，父母、配	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.571591+08	2026-06-09 13:43:09.571598+08
39	附件1 合群汽车集团员工手册（第24段）	偶、子女过世，享有3天带薪丧假。\n（九）病假：因病不能正常出勤者的员工可申请病假。病假员工须提供二级（含）\n资质以上医院开具的休假证明。\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.574255+08	2026-06-09 13:43:09.574262+08
40	附件1 合群汽车集团员工手册（第25段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n13/20（十）事假：员工事假须提前一天在系统内进行申请，经批准确认后方可休假；临\n时事假以调休方式向部门领导申请。\n（十一）其他未尽事宜参考《员工假管理制度》。\n第六章薪酬\n一、薪资标准及结构\n（一）员工薪酬分为固定薪酬和绩效薪酬。\n（二）固定薪酬：\n类\n别基准工资 年终奖金\n构\n成岗位工资级别工资企业工龄工资通讯补贴交通补贴\n（三）绩效薪酬：\n类\n别基准工资 绩效工资年终奖金\n构\n成岗位工资级别工资企业工龄工资通讯补贴交通补贴个人业绩\n二、薪资发放及查询\n（一）员工工资实行月薪制。基本工资支付时间为每月确定日，以法定货币（人民币）\n支付，若遇支薪日为节假日时，则延期至最近工作日支付；\n（二）基本工资发放日为每月8日，绩效工资发放日为每月28日；	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.57627+08	2026-06-09 13:43:09.576278+08
230	BI汽车经销商集团管理系统V1.0说明书20260108	BI汽车经销商集团管理系统\n版本号：V1.0\n操\n作\n手\n册\n系统登录：\n根据页面提示信息，以用户名、密码方式登录系统，点击界面【登录】按钮，即可进入，如下图所示：\n如果是新用户第一次登陆，需要自行修改密码\n系统功能板块：\n0.集团组织信息管理\n0.1基本组织信息填报\n 填报公司基本信息。如下图所示：\n0.2公司基本情况\n可筛选查询各公司的基本情况。如下图所示：\n0.5数据清单\n0.5.1固定资产清单\n可筛选查询各公司的固定资产情况。如下图所示：\n0.5.2实物资产\n0.5.3代理品牌查询\n可筛选查询代理品牌情况。如下图所示：\n0.5.6公司财产险统计查询\n页面可筛选查询具体公司财产险投保情况，如下图所示：\n当前页面同步显示脱保公司清单、有效保单分布、公司财产险详细信息。如下图所示：\n0.5.10内部车辆清单\n筛选查询公司车辆详细信息，如下图所示：\n0.3人员情况\n0.3.1人员情况\n筛选查询公司人员情况，实时数据，每2小时后台自动同步一次。如下图所示：\n0.3.2人员情况（历史）\n筛选查询公司人员情况历史数据\n0.3.3人员情况月度分析\n筛选查询人员月度情况，如下图所示：0.3.4人员架构\n筛选查询各店人员架构情况，如下图所示：\n0.4人效分析\n销售部人效分析\n筛选查询公司销售部的人效情况，如下图所示：\n售后部人效分析\n筛选查询公司售后部的人效情况，如下图所示：\n整车管理\n1.1库存分析\n1.1.1门店实时库存结构\n页面显示各公司实时库存情况，系统实时同步，实时更新，可筛选查询，蓝色字体代表可穿透，能直接穿透进入具体公司的库存结构。如下图所示：\n该页面可查询库存成本结构，分包含已配车和不含已配车资金占用情况，集团库存深度（在库，含在途）、150天以上长库车型。\n如下图所示：\n1.1.3品牌实时库存结构\n可查看各品牌实时库存结构，可分区域筛选具体公司实时库存情况。如下图所示：\n1.1.5门店历史库存结构\n筛选查询公司历史库存情况，蓝色区域可穿透进入查询具体公司历史库存数据情况。如下图所示：\n1.1.6车辆采购计划参考\n输入目标数量后，会自动生成建议计划，如：销售提车目标100台。\n1.2订单台数\n月-订单台数\n(1).筛选查询当月订单情况，分品牌展示，蓝色区域可以渗透，进一步查询当前品牌的不同门店月订单情况。\n如下图所示：\n(2).筛选查询当月订单情况，分公司展示，蓝色区域可以渗透查询单店情况。\n如下图所示：\n(3).订单达成柱状图。如下图所示：\n(4).每日订单情况，红色代表周末。如下图所示：\n(5).订单来源大类和小类分类。如下图所示：\n(6).自然进店订单类型分布。如下图所示：\n1.2订单台数\n年-订单台数\n筛选查询年订单情况，分品牌展示数据，蓝色区域可以渗透。进一步查询当前品牌的各店年订单数据，细化到具体车型订单、具体销售顾问订单数。\n如下图所示：\n1.2订单台数\n新车小订汇总：筛选查询品牌新车小订订单、小订转大订等情况\n如下图所示：\n新车小订分公司展示\n如下图所示：\n1.2订单台数\n全员开发贡献订单，蓝色渗透查询具体开发人员\n如下图所示：\n1.2订单台数\n未交车明细，如下图所示：\n1.3交车台数\n1.3.1月-交车台车\n分品牌查询集团月交车台数，蓝色区域可以渗透进入品牌交车明细。如下图所示：\n分公司查询集团月交车台数，蓝色区域可以渗透公司交车明细。如下图所示：\n每日交车分布，红色区域为周末，如下图所示：\n集团各店交车达成情况，柱状图分布，如下图所示：\n集团未交订单天数分布，如下图所示：1.4交车毛利\n1.4.3整车业务毛利汇总按品牌汇总整车业务毛利，可以渗透进入同品牌交车毛利情况、销售顾问交车毛利情况。\n如下图所示：\n1.4.4毛利汇总（含水平业务）\n含水平业务毛利汇总，分品牌、分区域、分公司展示，蓝色区域为可渗透内容，从当前界面进入下一层数据查看。\n如下图所示：\n1.5客流分析\n筛选查询各品牌客流情况，如下图所示：集团新增客流数，分公司查询。蓝色区域可以渗透进入下一界面详细查看。如下图所示：\n集团新增客流来源分布。如下图所示：1.6销售顾问\n销售顾问每日战报，按公司筛选查询销售顾问个人战报。渗透查询具体车型零售与集团整体价格情况。如下图所示：\n1.8排名管理\n1.8.1订单排名\n集团订单排名看板，当日新增订单、当月订单、年度累计订单排名。如下图所示：\n1.8.2交车排名：集团交车排名看板，当日交车、当月交车、年度累计交车排名。如下图所示：\n1.8.3交车达成排名\n集团各店交车达成情况，本月达成排名，年度达成排名。如下图所示：\n1.9交付中心\n1.9.1交付中心毛利汇总\n分品牌、分公司展示交付中心毛利情况。蓝色区域可以渗透进入查询同品牌毛利，交付专员毛利。如下图所示：\n1.11厂家任务管理\n1.1.4厂家接车进度\n筛选查询集团各公司接车进度，渗透查询各车型任务达成情况。如下图所示：\n1.1.5厂家终端任务进度\n筛选查询集团各公司厂家终端任务进度，渗透查询各车型任务达成情况。如下图所示：\n1.12直营集客店\n筛选查询直营集客数据，渗透各直营店的集客输送情况。如下图所示。\n2.售后管理\n2.1维修产值\n2.1.1月-维修产值\n筛选查询集团各公司月维修产值情况，蓝色区域可渗透进下一界面，详细查询公司具体产值情况。如下图所示：集团产值柱状分析图、产值日分布，红色代表周末情况。\n如下图所示：\n产值收入类型分布，蓝色区域可渗透查询各公司同一分类情况。\n如下图所示：\n保险理赔结算台次、不同公司保险赔付率情况。如下图所示：集团待结算工单情况，分天数节点统计。如下图所示：不同驱动方式结算台次占比统计，如下图所示：\n2.1.2月-售后衍生业务\n筛选查询各公司衍生业务情况，蓝色区域渗透进一步筛查\n2.1.3年-维修产值及毛利\n（1）筛选查询集团总维修产值及毛利情况，各公司情况查询，蓝色区域渗透具体明细项目。如下图所示：\n集团毛利汇总、各公司毛利汇总。如下图所示：（3）集团毛利率汇总、各公司毛利率汇总情况。如下图所示：\n2.1.4服务顾问每日战报\n筛选查询服务顾问战报情况，如下图所示：\n2.2维修台数\n2.2.1月-进厂数量\n筛选查询集团月进厂数量，渗透查询进厂类型及数量情况。\n2.2.2年-维修结算台数\n筛选查询维修台数，集团整体结算分析、各公司每月终结算情况。\n如下图所示：\n渗透查询具体公司情况。如下图所示：\n2.3维修零件\n2.3.1维修零件-产值及毛利\n筛选查询零件收入、毛利、毛利率情况，集团汇总和各公司情况，蓝色区域可以渗透进入明细。如下图所示：\n2.4工时收入\n2.4.1维修工时收入\n筛选查询维修工时收入情况，如下图所示：维修工时收入占比情况，如下图所示：\n维修工时客单价情况，如下图所示：\n2.5售后业务汇总\n查询各公司售后业务汇总，渗透公司具体明细。如下图所示：查询各公司售后业务汇总，渗透公司具体明细。如下图所示：\n4.水平业务\n4.1延保业务 \n延保分析-交车口径。可筛选查询当月交车中有购买延保的数据。\n如下图所示：\n延保分析-销售口径。可筛选查询当月提车购买+提车后跨月来购买延保的数据。\n如下图所示：\n延保分析-按日分析\n筛选查询各品牌、各公司延保日进度数据分析，如下图所示：延保分析-按月分析\n筛选查询各品牌、各公司延保月进度数据分析，如下图所示：\n延保销售顾问排名（交车口径），如下图所示：\n延保销售顾问排名（销售口径），如下图所示：\n4.2用车无忧业务\n用车无忧分析（交车口径）：可筛选分析当月交车中有购买用车无忧的数据。从品牌维度、公司维度，按收入、渗透率排序。如下图所示：\n产品分类饼图：\n用车无忧分析-销售口径。可筛选查询当月提车购买+提车后跨月来购买用车无忧的数据。从品牌、公司维度的收入、渗透率数据。\n如下图所示：\n用车无忧分析-按日分析\n筛选查询各品牌、各公司无忧业务，日进度数据分析\n如下图所示：\n销售第三方产品排名：筛选查询除店内自营数据外，第三方的销售情况。如下图所示：无忧销售顾问排名（交车口径），如下图所示：\n无忧销售顾问排名（销售口径），如下图所示：\n太阳膜升级\n太阳膜升级分析，各品牌渗透率、收入、毛利率分析。如下图所示：\n精品业务-精品管理\n筛选查询各门店精品数据分析。蓝色区域渗透公司具体销售顾问数据。如下图所示：\n目标填报\n用车无忧目标数据填报。如下图所示：\n延保目标数据填报。如下图所示：\n水平汇总\n台次目标达成进表表。各区域和公司水平台次进度分析。如下图所示：\n水平业务汇总，如下图所示：\n水平业务年度汇总，如下图所示：\n保险管理\n5.1保单情况。筛选查询集团保单台数、保费金额、情况，各区域和公司保单数据分析，蓝色区域可以渗透进入查询公司具体销售顾问保单数据。如下图所示：\n集团每日总保单、集团各店部保单数据柱状分析。如下图所示：\n集团新保续保台数、新保续保保费分析。如下图所示：\n5.2保费战报。\n分区域分公司的新保续保每日战报分析 ，目标达成率。\n如下图所示：5.3保险月度\n保险月度报告，台数、各公司保费收入。\n如下图所示：\n各保险公司产值、保费占比，如下图所示：5.4保险公司维修工单毛利情况\n各保险公司维修工单分析。如下图所示：\n5.5延保情况\n各公司保险延保情况分析，蓝色区域渗透延保详细信息，包含销售顾问销售详细信息，渗透查询对应客户信息和车型信息。如下图所示：\n5.6目标管理\n5.6.1月度目标管理，各区域公司月度目标。如下图所示：\n客户管理\n6.1基盘客户分析\n客户基盘信息，集团汇总，到各店汇总情况。如下图所示：\n6.2客户公里数情况\n按结算日期，取区间最后一次进厂的公里数。如下图所示：\n返利管理\n7.1集团返利\n筛选查询集团及各店返利情况。如下图所示：\n各店各项返利汇总，蓝色区域可以渗透。如下图所示：\n蓝色区域渗透进入详细明细。如下图所示：\nMP5预估其他返利汇总，可以渗透查询具体返利内容情况。如下图所示：\n9.零件管理\n9.1零件库龄\n筛选查询各公司零件库存情况，包括库龄天数和库存金额。如下图所示：\n呆滞库存分析报表\n配件呆滞库存数量和金额分析报表，如下图所示：\n10.总经理\n10.1整车排名\n10.1.1集团订单排名，当日订单、月订单、年订单排名。如下图所示：\n10.1.2集团交车排名。当日交车、月交车、年交车排名。如下图所示：\n10.1.3集团交车达成排名。月交车排名、年交车排名。如下图所示：\n10.2售后排名\n10.2.1集团售后产值排名\n当日产值、月产值、年产值排名。如下图所示：\n10.2.2集团售后产值达成排名。如下图所示：\n10.3业务数据总览\n销售、售后业务数据总览。如下图所示：\n行业数据管理\n10.4乘用车销量\n筛选查询乘用车销量数据。如下图所示：\n筛选查询全国皮卡月度销量数据。如下图所示：\n筛选查询全国皮卡年度销量数据。如下图所示：\n11.金融管理\n11.1集团按揭水平分析表\n筛选查询集团按揭渗透率、收入、金融按揭分类类型分析。\n如下图所示：\n11.2集团按揭水平年度分析表\n筛选查询集团按揭年渗透率、收入、各店按揭详细数据分析。\n如下图所示：\n金融渠道分析，渗透查询各渠道、各公司详细台账。如下图所示：\n11.3排名管理\n11.3.1按揭台数月度排名、年度排名。如下图所示：\n11.3.2按揭渗透率月度排名、年度排名。如下图所示：\n11.3.3金融按揭收入月度排名、年度排名。如下图所示：\n11.3.4金融单台收入月度排名、年度排名。如下图所示：11.3.5金融除返后收入月度排名、年度排名。如下图所示：11.3.6金融除返后单台收入月度排名、年度排名。如下图所示：11.3.7按揭返佣系统月度排名、年度排名。如下图所示：\n11.3.8按揭除返后返佣系数月度排名、年度排名。如下图所示：\n12.营销管理\n12.1.1节点活动\n1.活动查询。查询各品牌门店活动信息情况。如下图所示：\n2.活动创建。创建活动信息。如下图所示：\n3.目标填报。填报活动目标。如下图所示：\n4.活动汇总。填写活动汇总情况。如下图所示：\n12.2预算管理。\n预算计划。各公司市场预算明细表。如下图所示：2.执行总结。各公司市场实际执行情况明细表。如下图所示：\n可以渗透进入当前公司详细数据分析。如下图所示：\n3.预算与实际对比。各公司市场预算与实际执行对比表。如下图所示：4.计划项目一览。筛选查询各区域各公司月度计划。如下图所示：\n12.3排名管理\n1.费用排名\n2.订单排名：网销月度订单、年度订单排名。如下图所示：3.线索排名：当期线索、年度线索排名。如下图所示：\n4.线索成本排名：当期线索单价、年度线索单价排名。如下图所示：\n5.订单成本排名：当期订单单价、年度订单单价排名。如下图所示：\n总结报告\n13.1集团总览\n集团数据总览看板，如下图所示。\n13.2销售报告：销售版块看板。如下图所示：13.3售后报告：售后版块看板。如下图所示：\n14.盘点管理\n盘点汇总填报，如下图所示：集团盘点汇总表，如下图所示：\n资金管理\n在途资金管理\n筛选查询刷卡在途金额，蓝色区域渗透进入明细查询。如下图所示：清算金额商户统计\n清算对账商户资金汇总。渗透查询清算金额详细列表。如下图所示：\n在途与清算对比。如下图所示：银行账户资金。\n筛选查询各公司银行资金交易情况，渗透查询每个账户交易情况。如下图所示：\n厂家账户管理\n筛选查询各公司销售、配件厂家账户余额情况，如下图所示：\n19.综合管理\n建店管理	text	15	\N	tech	manual	D:\\HqEvoAI\\uploads\\08318190ec67469992d61885d9289a52.docx	李管理	\N	\N	0	0	批量导入,发动机系统维修	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 12:37:15.694641+08	2026-06-12 12:37:15.694649+08
41	附件1 合群汽车集团员工手册（第26段）	（三）如员工对工资发放金额有异议时，可先到直属部门经理处查询应发金额，如无\n问题再至财务处查询实发金额；\n（四）员工绩效工资由部门确定的绩效方案进行核算，并经由员工确认后上报总经理\n审核，总经理审核无误后上报集团审定后发放；\n（五）其他未尽事宜参考《员工薪酬管理制度》。\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.578271+08	2026-06-09 13:43:09.578277+08
42	附件1 合群汽车集团员工手册（第27段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n14/20第七章公司福利\n公司提供的福利待遇包括按国家规定执行的福利待遇，以及根据公司自身条件设\n置的内部福利。\n一、按照国家政策和规定的福利有养老保险、基本医疗保险、失业保险、工伤保险、\n生育保险及住房公积金。\n二、根据公司自身经营情况，由集团决定是否实施以下福利项目：\n（一）员工体检：\n1.公司每两年组织员工集体体检一次；\n2.公司每年组织一次特殊岗位员工的职业病体检。\n（二）节庆福利：元旦、五一劳动节、端午节、十一国庆节、中秋节等法定假日根据\n公司的经营情况决定是否给全体员工发放节日福利；三八妇女节：女性员工放假半天	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.580367+08	2026-06-09 13:43:09.580373+08
43	附件1 合群汽车集团员工手册（第28段）	并发放节日福利；\n（三）通讯及交通补贴：当月的通讯补贴以工资的形式（包含在工资中）发到员工工\n资卡中，补贴标准为：员工级：80元/月/项，主管级以上100元月/项；\n（四）生活福利\n1.工作餐：公司为员工提供免费工作午餐，加班员工或提前报备的员工可提供免费工\n作晚餐；无厨房门店提供餐费补助，补助标准按照集团财务制度相关规定执行，由各\n店统一管理及支出；\n2.住房补贴：入职一年以内的员工并月度领取到手的工资总额低于2000元。（到手工\n资总额是指扣除个人承担部分的社保及个人所得税后的总额）可申请住房补贴，补贴\n标准：每人每月补贴500元。补贴期限：12个月，从入职当月开始计算；满一年12\n个月后自动取消。领取租房补贴的员工在领取补贴期限内，如月领取到手工资总额大\n于等于2000元时，则取消当月租房补贴；\n（五）额外商业保险（公司根据实际经营情况选择是否购买）\n1.意外伤害险：公司充分考虑员工的安全，避免意外伤害给员工与家属造成负担，特\n为正式员工额外购买意外伤害险；\n2.重大医疗险：在购买期当年前转正的员工，否则将在下一个年度购买。\n（六）爱心基金会：\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.582316+08	2026-06-09 13:43:09.582322+08
44	附件1 合群汽车集团员工手册（第29段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.584921+08	2026-06-09 13:43:09.584928+08
45	附件1 合群汽车集团员工手册（第30段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n15/201.爱心基金会是公司员工之间互助互爱和团队协作的平台，员工自愿加入。加入爱心\n基金会的员工在遇急病、重大疾病，以及遭遇意外所发生的车祸、火灾等本人无法抗\n拒的突发事件时，由于医疗费用负担较重，家庭经济损失惨重，给家庭带来影响较大\n时可申请使用；\n2.详尽事宜参考《爱心基金会管理办法》。\n（七）文化生活福利\n1.娱乐活动：不定期的羽毛球、篮球、踢足球等娱乐活动；\n2.聚餐：各部门可申请部门经费用于部门间聚餐，详见财务管理制度中报销相关规定；\n3.旅游：每年全体员工省内出游，优秀员工岛外旅游，星级员工国外旅游（因特殊情\n况不能组织旅游时，以现金形式发放）；\n4.其他文化活动：具体实施根据公司实际情况而定，由发起部门进行组织。\n（八）员工购车及维修优惠福利：\n1.员工每年享受一次集团全部品牌按厂家标准成本价购车机会，仅限本人及配偶使用；\n2.亲友购车可凭申请享受相应的优惠，特殊情况各品牌根据市场实际情况一车一议；\n3.员工购买试驾车新车、二手试驾车必须报集团董事长审核批准；	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.58677+08	2026-06-09 13:43:09.586776+08
46	附件1 合群汽车集团员工手册（第31段）	4.员工个人使用并报备过的车辆（上限2台），维修按配件成本，工费标准按照7折\n结算，续保按当期续保政策执行；\n5.鼓励员工推荐亲戚朋友到各品牌维修，各品牌应给予适当优惠，但折扣不得高于职\n能部门领导的权限；\n6.详尽事宜参考《员工福利管理制度》。\n第八章职业发展\n一、考评原则：择优培养，竞聘上岗\n二、考评方式：考试+个人业绩+日常表现\n三、培训体系：\n（一）员工培训按组织方式不同，分为内部培训和外派培训两种：\n1.内部培训类型：新入职员工培训、岗位技能培训、晋升培训、转岗培训、职业发展\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.588608+08	2026-06-09 13:43:09.588614+08
47	附件1 合群汽车集团员工手册（第32段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n16/20培训；\n2.外派培训类型：厂家培训、知识培训、拓展培训。\n（二）员工培训按类别不同，分为技能培训和管理培训两种：\n1.技能培训：岗位技能培训、转岗培训\n2.管理培训：晋升培训、职业发展培训\n3.详尽事宜参考《员工培训管理制度》\n第九章奖惩\n规范公司的日常管理，保障公司的各项业务井然有序，做到奖罚分明，轻重有别，	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.590681+08	2026-06-09 13:43:09.590688+08
48	附件1 合群汽车集团员工手册（第33段）	在公司内形成公正、公平、公开的良好风气。\n一、奖励形式：通告表扬、实物奖励、经济奖励、职位晋升；\n二、惩罚方式：通告批评、经济处罚、降职降薪、开除辞退；\n三、详尽事宜参考《员工奖惩管理规定》。\n第十章员工守则\n一、员工着装的整体要求：整洁、得体、大方，工作时间统一穿着职业装或工装，保\n持服装整洁得体，衣扣整齐；\n二、注意在不同的场合使用不同的文明语言以及称谓，尊重他人，不随意取笑和评论\n对方的口音或方言；\n三、公司执行首问责任制，即每一个员工都有接待职责，须用主动热情的态度做好接\n待或解释工作，无论何种原因，都不得与客户大声争吵，影响工作秩序及在企业办公\n场所喧哗；\n四、忠于职守，尊重与服从领导，不得有敷衍塞责的行为；\n五、不得经营与本公司类似或岗位上相关联的业务，不得兼任其他公司的任何职务；\n六、全体员工必须不断提升个人的工作技能水平，强化品质意识，完成各级领导交付\n的工作任务。\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.592919+08	2026-06-09 13:43:09.592926+08
49	附件1 合群汽车集团员工手册（第34段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.596167+08	2026-06-09 13:43:09.596174+08
50	附件1 合群汽车集团员工手册（第35段）	17/20七、不得携带违禁品、危险品或公司规定其他不得带入生产、工作场所的物品进入公\n司工作场所；员工电瓶车充电需在公司指定场所内进行；\n八、爱护公共财物，未经许可不得私自将公司财物带出公司；\n九、工作时间不得中途随意离开岗位、如需离开应向上级主管人员请准后方可离岗，\n中干员工在工作时间离开工作岗位，须在中干去向群内报备；\n十、员工应随时注意保持作业地点、宿舍及公司其他场所的环境卫生；\n十一、提倡员工团结协作，同舟共济，不得有吵闹、斗殴、搭讪攀谈、搬弄是非或其\n他扰乱公共秩序的行为出现；\n十二、严禁员工过度饮酒、酗酒、嗜赌、吸毒及其他违反治安管理行为出现，如明知\n故犯企业有权做出相应的处罚；\n十三、任何员工、任何岗位不得利用职权贪污舞弊，收受贿赂，或以公司名义在外招\n摇撞骗；\n十四、严守公司机密，不得擅自传送未公开的或未授权的公司内部资料、文件，不传\n送具有威胁性、不友好的或有损公司声誉的信息；\n十五、严禁员工之间互相打听工资、相互攀比。\n第十一章财务管理制度\n财务部门的人事任免权及业务管理权归集团董事长办公室，业务归口直接上级管\n理责任人为集团财务总监。各公司总经理协助董事长办公室对财务部的日常管理工作。	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.598398+08	2026-06-09 13:43:09.598404+08
244	销售经理驾驶仓数据分析看板 - 片段6 (00:21)	也可以通過快捷按鈕選擇週期。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	21.67	24.77	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.499666+08	2026-06-12 14:31:07.499671+08
51	附件1 合群汽车集团员工手册（第36段）	一、费用报销管理制度\n（一）所有费用报销均实行预算制管理，各项费用报销需遵循在预算额度内报销的基\n本原则；\n（二）所有费用报销需经过审批后方能支付，预算外经费需经过专项审批后方能报销；\n（三）所有签字人对所签字事项了解并对签字负责；\n（四）所有报销都必须提供合法、真实、有效的发票。报销人对发票的真伪负责，财\n务部门对发票的真实性起审查监督作用；\n（五）详尽事宜参考《财务管理制度》。\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.600451+08	2026-06-09 13:43:09.600457+08
52	附件1 合群汽车集团员工手册（第37段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n18/20\n二、费用报销的基本流程：\n三、差旅管理制度\n（一）员工出差前需提前在系统中发起差旅申请，经系统审批通过方可出行；\n（二）报销差旅住宿费用时须同时提供酒店出具的明细单作为报销依据；\n（三）按照厂商会议（含培训）规定标准执行的差旅费用，报销时须同时附上由厂家\n发出的会议通知或相关文件作为报销依据；\n（四）厂家指定培训或会议住宿，按厂家标准执行\n（五）若为同性员工级别二人同时出差，按一个房间标准报销，品牌副总经理以上人	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.602713+08	2026-06-09 13:43:09.602719+08
53	附件1 合群汽车集团员工手册（第38段）	员出差，可单独住宿；员工与主管、经理、总监级别以上中干一同出差，按最高中干\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.604696+08	2026-06-09 13:43:09.604702+08
54	附件1 合群汽车集团员工手册（第39段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n19/20级别的标准报销。特殊情况的住宿，个人餐费可单独向品牌总经理申请；\n（六）在公交停运的情况下，交通费可实报实销；\n（七）详尽事宜参考《财务管理制度》；\n（八）差旅报销标准：\n标准\n级别乘坐交通工具\n最高标准市内交通费\n日均报销标\n准（不含机\n场巴士）各直辖市、省会城市、\n深圳、珠海、三亚地级市（不含三亚）县级市及以下\n日住宿\n上限日餐补\n上限日住宿\n上限日餐费\n上限日住宿\n上限日餐费\n上限\n品牌副总经理级（含\n以上）飞机经济舱/轮船二等舱/\n高铁二等座、硬卧实报 500200400150300150\n经理、主管 飞机经济舱/轮船二等舱/\n高铁二等座、硬卧80 400150300120260120\n其他员工 飞机经济舱/轮船二等舱/\n高铁二等座、硬卧60 300120260100200100\n第十二章安全手册	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.606618+08	2026-06-09 13:43:09.606625+08
55	附件1 合群汽车集团员工手册（第40段）	一、以安全第一，预防为主的安全管理为核心。严格遵守国家法律法规和公司规章制\n度，特殊工种需持证上岗。切实注意人身、财物安全，不做任何有损他人和自我的安\n全事项；\n二、员工在上班时间必须按公司要求统一穿工作服和安全鞋（售后车间相关人员）；\n三、生产车间现场严禁吸烟，包括进入生产车间的车主；\n四、在任何厂区现场移动车辆须事先经部门领导批准，并在车间公布张贴经批准人员\n名单，未经批准的人员不得将车辆开离公司；\n五、不得在工作时间(包括夜间值班和节假日值班)、工作场所饮酒(业务招待除\n外)，如发生此类行为，追究其个人和相关领导的职责；(因饮酒过度或酒后失态\n影响工作，公司将根据情节严重给予相应处罚，情节恶劣者，公司有权予以开除。)\n六、集团或各品牌各店业务、接待等工作原因发生的饮酒行为集团提倡适量饮酒，不\n醉酒、酗酒。为了员工自身安全，员工下班时间外出饮酒要适量，禁止酗酒、醉酒，\n禁止酒后驾驶车辆，由饮酒引起的一切后果，均由其本人承担；\n七、凡合群集团员工、汽车驾驶人员必须遵守国家交通法规的相关规定，如有违反，\n由此造成的一切后果均由本人承担；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.609196+08	2026-06-09 13:43:09.609202+08
56	附件1 合群汽车集团员工手册（第41段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.611418+08	2026-06-09 13:43:09.611424+08
57	附件1 合群汽车集团员工手册（第42段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n20/20八、办公区域及维修施工厂区内，现场移动车辆限速5公里/小时的强制规定；\n九、集团全员应不定期进行消防设备设施和急救外伤医药用品正确使用的专项培训；\n十、易燃易爆生产资料和专项设备需专人负责使用并隔离管理；\n十一、在工作中或工作以外的时间不参与赌博、斗殴、非法传销等任何违法活动；\n十二、建立健全和完善的应对台风等自然灾害的应急预案，并严格按照预案要求执行；\n十三、各品牌、各店需做好安全大检查工作，建立并完善安全生产检查台账，对查出\n的安全隐患，落实整改资料、整改措施、整改时限、整改部门、整改人员，按时完成\n整改后上报集团备案。\n第十三章附则\n一、如本手册条款中有与国家政策相冲突或未涉及内容，均以国家政策为准；\n二、本手册经董事会授权董事长邢益宝先生签发；\n三、本手册解释权归人事行政部所有，人事行政部有权根据需要修改、增加或更新员\n工手册的内容，如有修改内容将在企业微信中通告全体员工；\n四、本手册正式发布后，如出现重大与实际情况不相符的，可上报集团总经理/董事长	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.613487+08	2026-06-09 13:43:09.613494+08
58	附件1 合群汽车集团员工手册（第43段）	审定，一事一议裁定，并可组织编委会修订条例；\n五、本手册在企业微信－合群云档－规章制度中发布，集团全体员工均可自行阅览，\n不得下载；\n六、公布实施后新入职的新员工，需在入职前详细阅读本手册，并签字确认认同本手\n册的全部内容，如不认同本手册内容，可选择自动放弃入职；\n七、本手册正式发布后，如与前期发布的制度相违处，以本制度为准，后续所有制度\n调整，均以最新发布为准；\n八、本手册自2022年01月01日开始执行。\n签发人：\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.615471+08	2026-06-09 13:43:09.615478+08
59	附件1 合群汽车集团员工手册（第44段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件1 合群汽车集团员工手册.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:09.617414+08	2026-06-09 13:43:09.617421+08
60	附件8 员工福利管理制度（第1段）	1/5员工福利管理制度\n一、目的\n为提升企业员工归属感，体现人文关怀，推动企业文化建设，形成良好的企业向心\n力和凝聚力，特制定本制度。\n二、名词解释\n福利：福利特指除公司正常发放的工资和奖金等劳动报酬之外增加给予员工的其他\n福利报酬，包括现金形式和非现金形式两种。\n正式员工：特指已提交转正申请，并经审核通过的在职员工。\n三、适用范围：\n本规定适用于集团所有正式员工，其中部分福利不适用于试用期及实习期员工。\n福建、广东区域如存在特殊福利需求，可单独向集团总经理/董事长申请。\n四、福利待遇的种类：\n（一）公司提供的福利待遇包括按国家规定执行的福利待遇，以及根据公司自身条件\n设置的各项福利待遇。\n（二）按照国家政策和规定，提供的统筹五险（包括：基本养老保险、基本医疗保险、\n失业保险、工伤保险、生育保险；）\n（三）根据公司自身经营条件设置的福利项目包括：住房公积金、节庆福利、假期福\n利、生活福利、培训福利、意外伤害保险、重大疾病险及其他福利。\n（四）员工购车及维修享有员工价格优惠等福利\n五、福利待遇：\n（一）社会统筹保险\n1.公司负责为所有正式员工缴纳国家规定的养老保险、医疗保险、生育保险、工伤保	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.628068+08	2026-06-09 13:43:10.628077+08
88	关于颁布吉利银河跨年购置税补贴执行细则的通知（第4段）	佛山合悦汽车销售有限公司_何志才                                                                                                                                             \n                                    佛山合悦汽车销售有限公司_何志才                                                                                                                                             \n                                    佛山合悦汽车销售有限公司_何志才	text	1	\N	public	manual	D:\\合群集团资料\\商务政策\\关于颁布吉利银河跨年购置税补贴执行细则的通知.pdf	系统导入	\N	\N	0	0	批量导入,商务政策	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.822538+08	2026-06-09 13:43:11.822544+08
61	附件8 员工福利管理制度（第2段）	险、失业保险；\n2.员工转正后，社会保险由人事行政部负责为员工办理；\n3.社会保险的缴费基数根据公司上年度经营状况，结合海口市上年度工资水平、根据\n政府当期发布的最低缴费基数由人事行政部每年统一进行调整缴纳；\n4.员工办理社保需按时提交规定资料，不能按时提交资料的员工，属于个人原因，所\n带来的所有法律责任由个人承担；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.632936+08	2026-06-09 13:43:10.632943+08
62	附件8 员工福利管理制度（第3段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n2/55.社会统筹保险由公司统一缴纳，个人应缴纳部分在工资中扣除；\n（二）住房公积金\n1.员工自入职转正1年后公司提供住房公积金。\n2.住房公积金的缴费基数根据公司上年度经营状况，结合海口市及各省、市上年度工\n资水平由人事行政部每年统一进行调整。\n（三）补贴福利\n1.节庆福利\n（1）每逢元旦、五一劳动节、端午节、十一国庆节、中秋节等等法定假日根据公司\n的经营情况决定是否给全体员工发放节日福利；\n（2）三八妇女节：女性员工放假半天并发放节日福利。	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.635524+08	2026-06-09 13:43:10.635531+08
63	附件8 员工福利管理制度（第4段）	2.假期福利\n员工所享有的假期有：年假、婚假、陪产假（男员工）、孕检假、哺乳假、丧假、\n事假、病假、工伤假、家长会假等。\n3.生活福利\n（1）工作餐：\n①公司为员工提供免费工作午餐，加班员工应提前报备方可提供免费工作晚餐；\n无厨房门店提供餐费补助，补助标准按照集团财务制度相关规定执行，由各店统一管\n理及支出；\n②二级直营店人员按25元/天/人补助，每月餐费补助次月按实际出勤天数核定发\n放。\n（2）住房补助\n①适用对象条件：入职一年以内的员工并月度领取到手的工资总额低于2000元。\n（到手工资总额是指扣除个人承担部分的社保及个人所得税后的总额）\n②补贴标准：每人每月按照500元标准补助。\n③补贴期限：12个月，从入职当月开始计算；满一年12个月后自动取消。领取租\n房补贴的员工在领取补贴期限内，如月领取到手工资总额大于等于2000元时，则取消\n当月租房补贴；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.637698+08	2026-06-09 13:43:10.637706+08
64	附件8 员工福利管理制度（第5段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n3/5④发放方式：当月的租房补贴以工资的形式（包含在工资中）于次月28日在员工	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.639884+08	2026-06-09 13:43:10.639891+08
65	附件8 员工福利管理制度（第6段）	工资卡中发放。\n⑤人事行政部对上月人员工资进行核对，将符合租房补贴人员发放名单，递交给\n工资制作人员，由工资制作人员计入工资中一并发放。\n4.交通补贴\n（1）当月的交通补贴以工资的形式（包含在工资中）于次月8日发到员工工资卡中。\n（2）其他特殊情况产生的交通费用凭票实销实报（油票、停车票、出租车票等），不\n允许跨月累积报销。\n5.通讯补贴\n（1）当月的通讯补贴以工资的形式（包含在工资中）发到员工工资卡中，补贴标准为：\n员工级：80元/月/项，主管级以上100元月/项，于次月8日在员工工资卡中发放。\n（2）其他特殊情况产生的通讯费用凭票实销实报（电话单、通话记录，通话录音等），\n不允许跨月累积报销。\n6.工装福利\n具体享受内容见各品牌厂商要求着装，费用按照集团财务管理制度相关内容执行。\n7.常规体检\n（1）公司每两年组织员工集体体检一次。\n（2）公司每年组织一次特殊岗位的职业病体检。\n8.文化生活\n为了丰富员工文化生活而设立以下福利：\n（1）为促进员工的身心健康，丰富员工的精神和文化生活、业余生活，培养员工积极\n向上的道德情操而提供以下福利：\n①在不影响工作的情况下，公司不定期组织员工参加羽毛球、篮球、足球等体育活	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.642122+08	2026-06-09 13:43:10.642128+08
89	销售经理驾驶仓数据分析看板	视频文件：销售经理驾驶仓数据分析看板.mp4（位于 看板说明视频）\n\n请注意：视频内容需通过语音转写生成文字版，当前为原始文件记录。	video	1	\N	public	video	D:\\合群集团资料\\看板说明视频\\销售经理驾驶仓数据分析看板.mp4	系统导入	\N	\N	0	0	批量导入,视频,看板说明视频	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.830127+08	2026-06-09 13:43:11.830137+08
66	附件8 员工福利管理制度（第7段）	动。\n②聚餐：各部门可向集团申请部门经费用于部门间聚餐（部门活动基金为申请制）。\n③员工旅游：公司每年组织全体员工省内旅游1次；组织优秀员工岛外旅游1次，\n星级员工国外旅游1次。（因特殊情况不能组织旅游时，以现金形式发放补助，补助标\n准以集团当期公布的补贴标准为准）。\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.645199+08	2026-06-09 13:43:10.645206+08
67	附件8 员工福利管理制度（第8段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n4/5（2）其他文化活动：具体实施根据公司实际情况而定，由发起部门进行组织。\n9.培训福利\n公司根据各部门的培训需求，由各品牌组织实施，提升员工的知识、技能、态度\n等方面与不断变动的技术、外部环境相适应。\n培训福利包括：员工在职或短期脱产培训等。具体规定见公司《培训管理制度》。\n10.其他额外商业保险（公司有权根据当期实际经营情况选择是否购买）\n（1）意外伤害险：充分考虑员工的安全，避免因意外伤害给员工和家属带来的负担，\n为正式员工额外购买意外伤害险。\n（2）重大医疗险：确保员工因个人和家庭成员发生重大疾病给员工带来的负担，享受	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.647519+08	2026-06-09 13:43:10.647525+08
68	附件8 员工福利管理制度（第9段）	条件为在实施购买时当年前转正的员工，否则在下一年购买\n11.家长会假\n（1）正式员工凭子女学校或幼儿园的通知家长会通知单，享受半天带薪假期，每学期\n每个员工子女可享受1次，双职工仅可一人享受。\n（2）正式员工且有子女在适龄阶段开学的，每年3月、9月初子女入学时，给予半天\n入学入园报名的带薪假期。\n12.员工购车及维修优惠政策\n（1）员工购车福利：\n①员工每年享受一次集团旗下所有品牌按厂家标准成本价的购车机会，仅限本人及\n配偶使用；\n②亲友购车可凭申请享受相应的优惠，特殊情况各品牌总经理根据市场实际情况一\n车一议。\n③员工购买集团各品牌的试驾车新车指标、二手试驾车必须报集团董事长审核批准；\n（2）员工车辆维修及续保福利：\n①员工个人使用并在公司相关管理部门报备过的车辆（上限2台），方可享受维修按\n配件成本，工费按7折结算优惠，续保按当期续保政策执行。\n②鼓励员工推荐亲戚朋友到各品牌维修，各品牌应给予适当优惠，但折扣不得高于\n各品牌总经理和直营店部门领导的权限范围。\n（3）直系亲属购车，须提供关系证明材料，如有弄虚作假者给予5000元的经济处罚\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.649594+08	2026-06-09 13:43:10.649601+08
69	附件8 员工福利管理制度（第10段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.651593+08	2026-06-09 13:43:10.651599+08
70	附件8 员工福利管理制度（第11段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n5/5并记大过一次。\n（4）享受优惠购车者，本人、家属及亲朋好友对购车相关价格信息负有保密义务，不\n得擅自对外传播相关价格信息，违背者给予4000元的经济处罚并记大过一次。\n（5）员工个人购车，销售人员严格执行销售流程，为购车者办理相关手续，该车不享\n受转介绍奖励，销售员仅发放交车奖励，不纳入销售员当期销量目标。该车不享受公\n司及销售部其他优惠政策。\n（6）任何员工不得利用公司福利政策弄虚作假，谋取个人利益，有违者公司将纳入信\n用不良记录，给予处罚、通报批评乃至辞退的处理。\n（7）申请福利流程：由员工本人向各品牌总经理书面或电话申请，经各环节负责人审\n定后实施.\n六、附则\n一、如本制度条款中有与国家政策相冲突或未涉及内容，均以国家政策为准；\n二、本制度经董事会授权董事长邢益宝先生签发；\n三、本制度解释权归人事行政部所有，人事行政部有权根据需要修改、增加或更新员\n工手册的内容，如有修改内容将在企业微信中通告全体员工；\n四、本制度正式发布后，如出现重大与实际情况不相符的，可上报集团总经理/董事长	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.653631+08	2026-06-09 13:43:10.653637+08
90	销售顾问驾驶仓看板	视频文件：销售顾问驾驶仓看板.mp4（位于 看板说明视频）\n\n请注意：视频内容需通过语音转写生成文字版，当前为原始文件记录。	video	1	\N	public	video	D:\\合群集团资料\\看板说明视频\\销售顾问驾驶仓看板.mp4	系统导入	\N	\N	0	0	批量导入,视频,看板说明视频	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.859822+08	2026-06-09 13:43:11.859833+08
71	附件8 员工福利管理制度（第12段）	审定，一事一议裁定，并可组织编委会修订条例；\n五、本制度在企业微信－合群云档－规章制度中发布，集团全体员工均可自行阅览，\n不得下载；\n六、公布实施后新入职的新员工，需在入职前详细阅读本手册，并签字确认认同本手\n册的全部内容，如不认同本手册内容，可选择自动放弃入职；\n七、本制度正式发布后，如与前期发布的制度相违处，以本制度为准，后续所有制度\n调整，均以最新发布为准；\n八、本制度自2022年01月01日开始执行。\n签发人：\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.656377+08	2026-06-09 13:43:10.656384+08
72	附件8 员工福利管理制度（第13段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件8 员工福利管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:10.658303+08	2026-06-09 13:43:10.658309+08
73	附件9 员工培训管理制度（第1段）	1/5培训管理制度\n一、目的\n（一）目的：\n为了不断地提高企业职业化水平和岗位技能，建立健全企业各项培训制度的落实，\n为企业培养人才奠定理论基础，满足集团可持续经营发展的需要，特制定本制度。\n（二）理念：\n集团倡导学习型企业，为员工营造学习环境和机会，号召员工在自觉自我学习成\n长的过程中推动学习型组织的建立，引导员工提高职业素养、专业技能和发展潜能，\n从而提高员工绩效和组织效率，最终实现集团与员工的共同发展。\n二、适用范围\n本规定适用于合群汽车集团全体员工。\n特指在合群汽车集团管理权限内的全部员工。\n三、名词解释：\n（一）内部培训：\n特指由公司各品牌、各部门组织发起的员工集中上课、技能竞赛、野外训练等各\n类专项培训方式实施的教学和活动。通过内部培训的形式提升员工的工作技能。\n（二）外派培训：\n外派培训是指带薪离岗参加外部培训机构（含厂商）组织的各类开业及专业技能\n的培训学习，且该培训学习相关的费用由公司负责支付报销的培训。\n四、培训方式与内容：\n公司对员工的培训按培训的组织实施方式不同，分为内部培训和外派培训两种。\n内部培训类型有新入职员工培训、技能培训、晋升培训、转岗培训、职业发展培训等。	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件9 员工培训管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.595642+08	2026-06-09 13:43:11.595652+08
74	附件9 员工培训管理制度（第2段）	外派培训有厂家培训、各工种各岗位的知识培训。\n（一）新员工入职培训\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件9 员工培训管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.598912+08	2026-06-09 13:43:11.598919+08
75	附件9 员工培训管理制度（第3段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n2/51.由人事行政部门对新员工进行企业文化、企业发展历程、组织架构与职责、安全知\n识、办公系统等方面内容的培训；\n2.由各品牌相关部门进行组织实施本部门的业务特性、作业流程、制度保障培训；\n3.针对当年度新入职员工，由董事长在每年不定期进行1-2次的企业文化及企业价值\n观、愿景培训。\n（二）业务技能培训\n1.销售与售后服务技能培训\n（1）销售部门：\n以各品牌销售部门为单位，每周设定固定培训时间，并根据实际工作需要进行月\n度不定期培训。培训内容包括：市场策划、汽车产品知识、汽车销售技能、CA手册知\n识、接待礼仪、仪容仪表等。具体安排按月度培训计划进行安排。\n（2）售后部门：\n以各品牌售后部门为单位，每周设定固定培训时间，并根据实际工作需要进行月\n度不定期培训。培训内容包括：售后服务（机修、钣金、喷漆、保修索赔、保险理赔）	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件9 员工培训管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.601143+08	2026-06-09 13:43:11.60115+08
96	操作手册-售后服务接待v2025.05（第6段）	二、厂家优惠券用于核销工时项目费用。\n三、厂家优惠券核销，在工时项目中增加编号为"Fac"的两条记录，两条记 录的金额 是券 \n面值的一正一负，收费类型分别是券定义的收费类型和工单的收费类型。十六、厂家优惠券（说明）\n操作 入口：05售后管理→05.01维修服务接待十六、厂家优惠券（优惠券使用）\n\n维修接待流程图\n\n维修服务接待操作手册\n㔃 ᶏ	text	1	\N	tech	manual	D:\\合群集团资料\\维修知识\\操作手册-售后服务接待v2025.05.pdf	系统导入	\N	\N	0	0	批量导入,维修知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:12.528236+08	2026-06-09 13:43:12.528243+08
76	附件9 员工培训管理制度（第4段）	技能、售后接待礼仪、汽车维修技术培训、配件计划采购与仓储管理技能。具体安排\n按月度培训计划进行安排。\n（三）其他部门技能培训：\n除销售部和售后部外的其他部门，每月应不定期组织员工管理技能培训，培训内\n容分为岗位技能、礼仪（包括电话礼仪）培训、公文写作、电脑使用等行政类的知识\n等。\n（四）管理技能培训\n管理技能按高层管理人员、中层管理人员、其他人员管理知识分类培训。由人事\n行政部推荐或个人申请，一般的课程为公司管理、人力资源管理、财务管理、政策与\n法规等课程。参加培训方式为内训、外训、外聘为主。\n（五）晋升培训\n为了使员工在新的岗位上快速适应，在员工晋升时，必须安排岗位职责、岗位技\n能培训。如果属于管理岗位，需进行管理技能培训。\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件9 员工培训管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.60351+08	2026-06-09 13:43:11.603515+08
77	附件9 员工培训管理制度（第5段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n3/5（六）转岗培训\n员工的岗位发生变化时，接收部门要安排相关新岗位的技能培训。\n（七）厂家培训\n由厂家规定，派往厂家进行培训时，由各相应部门提供厂家下发的相关文件及《外	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件9 员工培训管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.606293+08	2026-06-09 13:43:11.6063+08
78	附件9 员工培训管理制度（第6段）	训申请表》进行申请，申请同意并签订《培训协议》方可参加。申请执行流程如下：\n1.集团各品牌从系统接到各厂家培训邀请函/通知（开业、系统、岗位、产品，其他等）；\n2.第一时间将邀请函或通知上报董事长或董事长助理邮箱并告知；\n3.董事长根据厂家培训内容和要求，结合各品牌运营情况审定是否有必要参加本次培\n训（如需参加由各品牌总经理确定参加培训人员名单）；\n4.如审定参加则由信息员反馈信息并将邀请函或通知提交人事行政部备案；\n5.如审定不参加，各品牌信息员需及时反馈厂家，文件各品牌自行备案；\n6.选派人选到人事行政部签署《培训协议书》；\n7.选派人员凭邀请函或通知书及员工签署的培训协议交各品牌人事行政部相关岗位安\n排预订机票；\n8.按照集团出差标准参加培训并通过培训考核；\n9.将结业证书或在线认证资料上报人事行政部存档备案；\n10.培训结束，按照集团财务相关规定，在结束培训后的一周内报销相关出差费用；\n11.参训人员需在培训回到岗位一周内对培训内容进行转训完毕，\n（八）知识培训\n各部门如有外部知识讲座培训意愿（与岗位工作相关），可向人事行政部提交外训\n申请表进行申请，人事行政部根据实际情况安排实施。	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件9 员工培训管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.608109+08	2026-06-09 13:43:11.608115+08
79	附件9 员工培训管理制度（第7段）	（九）所有的培训应保留培训课件、培训签到表、现场培训照片、培训效果评价等相\n关资料。\n（十）培训申请流程图：\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件9 员工培训管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.610193+08	2026-06-09 13:43:11.6102+08
80	附件9 员工培训管理制度（第8段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n4/5\n五、培训实施与流程\n（一）培训实施：\n1.每年各品牌、各部门需将《年度培训计划表》经总经理审核后报人事行政部备案。\n2.员工如因特别公务或其他紧急事宜确实不能参加培训的，须向部门负责人请假，如\n有必要需进行补训或转训。\n六、培训费用管理\n（一）公司承担费用\n如：厂家发起的各类型培训，确因岗位需要经选拔同意能参加的各类培训。\n（二）公司与个人共同承担费用\n因公司和个人业务发展需要参加国家或行业必备专业的相关培训，可申请公司及\n个人按比例分担。\n（三）个人承担费用\n参加厂家培训，因个人原因首次没有通过厂家考核的，需要再次补训及补考的费\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件9 员工培训管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.612024+08	2026-06-09 13:43:11.61203+08
234	销售经理驾驶仓数据分析看板 - 片段3 (02:00)	[视频片段 02:00 - 02:03] 此内容为视频转写片段，请管理员填写文字内容。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f9ffebba4b534fcda293429d3dc7a5e5.mp4	李管理		/uploads/f9ffebba4b534fcda293429d3dc7a5e5.mp4	120	123.971375	批量导入,产品知识库	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 13:11:26.476095+08	2026-06-12 13:11:26.476099+08
81	附件9 员工培训管理制度（第9段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件9 员工培训管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.613847+08	2026-06-09 13:43:11.613852+08
82	附件9 员工培训管理制度（第10段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n5/5用参照以下标准；第二次补训补考产生的全部费用由个人承担50%。第三次及以上补训\n补考产生的全部费用由个人承担。\n（四）以上培训产生的所有费用，参照集团财务管理制度内相关条款执行。\n七、附则\n一、如本制度条款中有与国家政策相冲突或未涉及内容，均以国家政策为准；\n二、本制度经董事会授权董事长邢益宝先生签发；\n三、本制度解释权归人事行政部所有，人事行政部有权根据需要修改、增加或更新员\n工手册的内容，如有修改内容将在企业微信中通告全体员工；\n四、本制度正式发布后，如出现重大与实际情况不相符的，可上报集团总经理/董事长\n审定，一事一议裁定，并可组织编委会修订条例；\n五、本制度在企业微信－合群云档－规章制度中发布，集团全体员工均可自行阅览，\n不得下载；\n六、公布实施后新入职的新员工，需在入职前详细阅读本手册，并签字确认认同本手\n册的全部内容，如不认同本手册内容，可选择自动放弃入职；\n七、本制度正式发布后，如与前期发布的制度相违处，以本制度为准，后续所有制度\n调整，均以最新发布为准；\n八、本制度自2022年01月01日开始执行。	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件9 员工培训管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.615755+08	2026-06-09 13:43:11.615761+08
83	附件9 员工培训管理制度（第11段）	签发人：\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件9 员工培训管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.618037+08	2026-06-09 13:43:11.618042+08
84	附件9 员工培训管理制度（第12段）	º£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\合群集团资料\\企业文化&制度&福利\\附件9 员工培训管理制度.pdf	系统导入	\N	\N	0	0	批量导入,企业文化&制度&福利	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.619726+08	2026-06-09 13:43:11.619731+08
85	关于颁布吉利银河跨年购置税补贴执行细则的通知（第1段）	- 1 - 关于颁布吉利银河 跨年购置税补贴 执行细则 的通知  \n2025年1-10月，吉利银河累计销量突破 100万辆，达成年销百万的重要里程碑。\n2026年国家新能源购置税补贴政策即将调整， 星愿、银河 M9等多款热销 车型交付周期\n较长，为确保 终端持续收定 ，吉利银河于 11月4日发布了购置税兜底政策 ： \n用户在2025年11月30日24点前于银河 APP或小程序大定并 锁单，如因吉利银河\n汽车生产、发运等非用户原因 延至2026年开票， 吉利银河将对符合条件的用户因购置\n税政策调整产生的费用差额进行全额补贴 。 \n现就具体执行 细则颁布如下：  \n一、 为提升用户满意度， 确保定单用户的交付，经销商需做好以下 交付要求： \n1. 经销商需 按大定顺序进行交付， 优先交付 11月30日前订单车辆， 厂端将进行检核，\n若未按顺序交付导致 延期至2026年交付的 ，则对应车辆产生的 购置税由经销商承\n担; \n2. 符合购置税补贴范围的用户在 2026年开票提车，但所提车辆在 2025年12月28日\n（含）前已到店，则公司不予补贴，由经销商自行承担，请各经销商提前做好客户\n贷款审核、保险方案、材料办理等业务准备，及时开票交付 。	text	1	\N	public	manual	D:\\合群集团资料\\商务政策\\关于颁布吉利银河跨年购置税补贴执行细则的通知.pdf	系统导入	\N	\N	0	0	批量导入,商务政策	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.814291+08	2026-06-09 13:43:11.8143+08
86	关于颁布吉利银河跨年购置税补贴执行细则的通知（第2段）	二、 为最大程度匹配车辆资源，满足交付需求，经销商需 在2025年12月10日24:00\n前完成用户定单梳理 ： \n1. 经销商需引导库存无法匹配的大定 客户在12月10日24：00前改单为库存 （包括在\n途、未发） 可交付车型，自2025年12月11日起，用户大定锁单后如发生任何改单\n操作（包括车辆信息、车主信息等） ，均不可享受吉利银河汽车购置税补贴；  \n2. 为最大程度满足 客户交付， 各经销商须在 12月10日18：00前完成11月30日24\n点前已流入 G助手系统的大定定单 的车辆配置 结算，12月10日24：00前经销商库\n存（含在途、未发）不满足 11月30日前未交付大定的部分， 公司不予补贴，由经\n销商自行承担，请 各经销商 及时完成结算 。 \n三、 其他说明 ：  \n1. 如发现经销商通过虚单套取公司购置税补贴， 将取消该 经销商所有购置税补贴支持 ； \n2. 请各经销商 严格按本文内容执行购置税补贴 ， 引导客户 在2025年12月31日前 （含）\n及时办理购置税申报 ；  \n3. 如国家新能源车购置税减免政策后续再次发生调整的，执行细则以后续发文为准。	text	1	\N	public	manual	D:\\合群集团资料\\商务政策\\关于颁布吉利银河跨年购置税补贴执行细则的通知.pdf	系统导入	\N	\N	0	0	批量导入,商务政策	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:11.818028+08	2026-06-09 13:43:11.818036+08
91	操作手册-售后服务接待v2025.05（第1段）	维修服务接待操作手册\nver 2025.05\n维修服务接待操作手册目录\n一、 工单录入 整体操作 步骤\n二、 工单 的新增与修改\n三、 添加 工时项目\n四、 工时项目派工\n五、 维修零件出库（仓管 员操作）\n六、 质检完工\n七、 优惠券\n八、 套餐 卡九、 延保\n十、 折扣\n十一、 推结算单\n十二、 维修财务结账（ 收银员 操作）\n十三、 新增客户\n十四、 客户 情况 情况\n十五、 工单 备注 备注\n十六、厂家优惠券\n操作入口： 05售后管理→05.01 维修服务接待一、工单录入 整体操作步骤\n\n操作入口：05售后管理→05.01维修服务接待二、工单的新增与修改（新增）\n注：有红点的项目是必填项\n操作 入口：05售后管理→05.01维修服务接待二、工单的新增与修改（修改）\n\n操作 入口：05售后管理→05.01维修服务接待\n二、工单的新增与修改（提取厂家工单）\n三、添加工时项目\n操作入口：05售后管理→05.01维修服务接待\n\n操作入口：05售后管理→05.01维修服务接待四、工时项目派工\n\n功能入口：05 售后管理→05.01维修零件出库五、维修零件出库（仓管员录入 工单耗材零件）	text	1	\N	tech	manual	D:\\合群集团资料\\维修知识\\操作手册-售后服务接待v2025.05.pdf	系统导入	\N	\N	0	0	批量导入,维修知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:12.514567+08	2026-06-09 13:43:12.514578+08
92	操作手册-售后服务接待v2025.05（第2段）	操作 入口：05售后管理→05.01维修服务接待六、质检完工\n\n一、优惠券设置：\n1、在【02.07优惠券方案】中设置优惠券方案，内容包括券名称、发行量、面额等。 \n2、设置使用券的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n3、在总经理审核、财务审核生效后，方案才能用于发行优惠券。\n4、在【09.07优惠券管理】中，使用上面生效的优惠券方案发行（生\n成）优惠券。 \n5、步骤4中 发行的券赠送给客户，审核生效后即可在工单中使用（核销）。\n二、优惠券使用条件：\n1、工单 已质检完工。七、优惠券（使用说明）\n2、工单的工时项目，零件项目必须符合优惠券使用的限定范围。\n3、工单中必须有客户付费类的收费类型。（优惠券只能抵扣客户付费的金额）\n三、优惠券核销后：\n1、在工时或零件项目中新增一条编号前缀为"Vou"，金额为负数（核销金额）的记录，用于\n冲减客户付费的金额。\n2、优惠券状态变更为“已使用”，更新优惠券已抵用金额。\n3、工单使用优惠券抵扣后，必须先取消抵扣才能做质检反完工。\n四、取消优惠券核销抵扣：在优惠券核销窗口，选择要取消的券，点击"取消抵扣"按钮。\n功能入口： 05售后管理→05.0 1维修服务接待七、优惠券（优惠券核销）	text	1	\N	tech	manual	D:\\合群集团资料\\维修知识\\操作手册-售后服务接待v2025.05.pdf	系统导入	\N	\N	0	0	批量导入,维修知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:12.518207+08	2026-06-09 13:43:12.518214+08
93	操作手册-售后服务接待v2025.05（第3段）	取消抵扣：选择要取消的优惠券，点”取消抵扣“按钮。\n操作 入口：05售后管理→05.01维修服务接待七、优惠券（核销后）\n\n一、套餐卡设置：\n  1、在【02.08套餐方案】中设置套餐的名称、套餐金额、有效天数、收费类型以及适用\n      车系等信息，其中车系如果为空则表示所有车系都可有。\n  2、设置套餐的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n 3、在【09.05套餐卡销售管理】中销售套餐或在新车订单、保单中赠送套餐。\n二、套餐的使用条件： \n 1、工时核销，只允许在在修工单中核销(确保所有的工时项目都完成派工)。\n 2、零件核销，须在要核销的\n套餐零件已出库，且工单已完工后(确保核销后出库件不变)。   \n3、套餐卡中项目剩余次数大于要核销的次数。\n三、套餐核销：\n 1、工时核销 ，在工单中新增一条工时，名称为要核销的 套餐工时项目，收费类型 设\n为\n         套餐收费类型。套餐卡中该工时的剩余次数减少一次。\n    2、零件核销，把工单中要核销零件的收费类型改为套餐的收费类型。套餐卡中该零件\n         的剩余次数更新为原剩余次数-工单对应零件出库数。	text	1	\N	tech	manual	D:\\合群集团资料\\维修知识\\操作手册-售后服务接待v2025.05.pdf	系统导入	\N	\N	0	0	批量导入,维修知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:12.520504+08	2026-06-09 13:43:12.52051+08
94	操作手册-售后服务接待v2025.05（第4段）	四、取消套餐使用：修改工时或零件项目的收费类型，对于工时项目也可直接删除。八、套餐卡（说明）\n八、套餐卡（工时核销）\n功能入口： 05售后管理→ 05.0 1维修服务接待\n\n操作 入口：05售后管理→05.01维修服务接待八、套餐卡（零件核销）\n\n一、延保设置：\n      1、在【01.03基础数据】的“集团统一设置--售后--延 保类型” 中设置好 延保类型 和\n           对应的收费类型。 \n      2、在【02.09延保方案定义】中，新增延保方案，录入方案的 延保类型 ，名称、 适用\n           车名（车系）、价格、里程数、年限、保养次数、毛 利等等。\n      3、在【05.08延保销售管理】中录入延保销售，并收款结算。 销售录入 的客户车 所属\n           的车系必须是延保方案设置的车名（车系），否则无 法录入。\n二、延保使用：\n             录入已购买延保车辆的保养工单时，系统会弹出已购买延保的提示。延保车辆的\n       保养工单可以选择延保专用的收费类型，延保专用收费类型的 金额在结 算时对客 户免\n       费。	text	1	\N	tech	manual	D:\\合群集团资料\\维修知识\\操作手册-售后服务接待v2025.05.pdf	系统导入	\N	\N	0	0	批量导入,维修知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:12.522941+08	2026-06-09 13:43:12.522947+08
95	操作手册-售后服务接待v2025.05（第5段）	（如果客户是购买延保后首次来店保养，系统会弹出起保窗口，要求进行起保操作。）\n      九、延保（说明）\n操作 入口：05售后管理→05.01维修服务接待九、延保（延保起保）\n\n操作 入口：05售后管理→05.01维修服务接待九、延保（使用延保）\n\n十、折扣（折扣 设置）\n功能入口：05 售后管理→05.0 1维修服务接待\n\n十、折扣（折扣 审批）\n功能入口：05 售后管理→05.01 维修服务接待\n\n十一、推结算单\n功能入口：05 售后管理→05.01维修服务接待\n 注：如付款方显示为空，需在【01.03基础数据】中设置付款方名称\n十二、 维修财务结账（收款员操作）\n功能入口：08 财务管理→08. 01.03维修财务结账\n\n操作 入口：05售后管理→05.01维修服务接待十三、新增客户\n\n功能入口： 05售后管理→05.0 1维修服务接待十四、客户情况/信息\n\n功能入口： 05售后管理→05.0 1维修服务接待十五、工单备注\n\n一、厂家优惠券设置：在【02.13厂家优惠券】中定义厂家优惠券的券名称，券类型，券  \n面值，收费类型，工种等项目。厂家优惠券定义统一设置，各分公司通用。	text	1	\N	tech	manual	D:\\合群集团资料\\维修知识\\操作手册-售后服务接待v2025.05.pdf	系统导入	\N	\N	0	0	批量导入,维修知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:12.526061+08	2026-06-09 13:43:12.526067+08
98	2025年合群集团中干会考试题（20250207）（第1段）	所属公司：\n姓名：                                                                 得分：\n2025年中干会考试题\n（满分：100分，考试时间：45分钟）\n一、选择题（每小题3分，共45分）\n1. 集团的核心价值观是（     ）\nA．公平、公正、团结、互助\t    \nB．互助、互爱、共享、批评与自我批评\nC．以人为本、诚信经营、真实合现  \nD．安全第一、客户至上、高效执行、科学创新\n2.常规保险事故车产值毛利率？（     ）\nA. 35%-40%\nB. 45%-50%\nC. 55%-60%\nD. 60%以上\n3. 公司的财务报销流程中，以下哪项不是必填项（     ）\nA. 费用明细\nB. 发票号码\nC. 报销人签字\nD. 领导审批签字\n4. 在财务报表中，反映企业在一定时期内经营成果的报表是（     ）\nA. 资产负债表\nB. 利润表\nC. 现金流量表\nD. 所有者权益变动表\n5. 集团规定店端市场费用必须经集团审批，审批原则为 （      ）\nA. 在项目未结束前申报立项即可\nB. 项目开始前先申报立项后开展	text	1	\N	public	manual	D:\\合群集团资料\\考试\\2025年合群集团中干会考试题（20250207）.docx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:14.338065+08	2026-06-09 13:43:14.338075+08
99	2025年合群集团中干会考试题（20250207）（第2段）	C. 紧急时可先开展无需其他形式沟通\nD. 报总经理同意即可开展\n6. 当定损确认单配件、工费金额与结算单不一致时，整单差异金额在（     ）元以内由售后经理签字同意即可\nA. 100\nB. 200\nC. 300\nD. 500\n7.返利资金长期闲置在厂家帐户上（包括银行汇票提车余额），以下哪种做法最不可取（    ）\nA. 开具红字通知单，厂家将返利转到公司帐户\nB. 向厂家申请将返利转为库存车赎证\nC. 挂在系统等待结算车辆时慢慢抵扣\nD. 向厂家申请返利转用于采购售后零件款\n8. 公司5S管理是指（     ）\nA. 整理、整顿、清扫、清洁、素养\nB. 整理、整顿、清扫、整洁、素养\nC. 整理、清洁、清扫、卫生、素养\nD. 整理、整顿、清扫、整洁、卫生\n9.集团2024年度人均人力成本（    ）\nA. 10.68万元\nB. 10.52万元\nC. 9.64万元\nD. 9.18万元\n10.在厂家金融政策支持下，4S店为客户提供汽车贷款购车服务。以下关于贷款风险防控措施的说法中，错误的是（    ）\nA. 严格审核客户的信用状况和还款能力\nB. 确保贷款合同条款清晰、明确，符合法律法规要求	text	1	\N	public	manual	D:\\合群集团资料\\考试\\2025年合群集团中干会考试题（20250207）.docx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:14.341898+08	2026-06-09 13:43:14.341905+08
100	2025年合群集团中干会考试题（20250207）（第3段）	C. 为了提高销量，可以适当放宽贷款审批条件\nD. 定期对贷款业务进行风险评估和监控\n11.（多选题）根据集团规定，员工对新添加微信的朋友必须主动发送以下（       ）\nA. 电子名片              \nB. 品牌宫格图\nC. 产品介绍            \nD. 简短的自我介绍话术\n12.（多选题）在处理呆滞配件时，通常可采用的渠道有以下哪些？（    ）\nA. 退回厂家\nB. 销售给对应车辆\nC. 采购置换\nD. 外销给社会配件店\nE. 报废处理\n13.（多选题）在成本核算中，以下各项费用归口为固定费用的是（       ）\nA. 业务招待费\nB. 通讯费\nC. 差旅费\nD. 财务费用\nE. 水电费\nF. 开办费摊销\n14.（多选题）计算维修毛利时，需要从相关数据中减去以下哪些项目？（      ）\nA. 车间耗品\nB. 事故招揽\nC. 配件成本\nD. 维修产值\nE. 人工成本\nF. 油漆物料\n15.（多选题）2025年集团对总经理的新媒体硬性考核指标是（       ）\nA. 新媒体订单占比总订单＜35%\nB. 新媒体订单占比总订单＜20%\nC. 单月新媒体线索保底300条	text	1	\N	public	manual	D:\\合群集团资料\\考试\\2025年合群集团中干会考试题（20250207）.docx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:14.34601+08	2026-06-09 13:43:14.346018+08
101	2025年合群集团中干会考试题（20250207）（第4段）	D. 根据自店投流完成档位线索目标\nE. 单月线索冲刺500条\n三、填空题（每题 3 分，共 30 分）\n1. 公司的经营理念是                                                             。\n2. 集团规定，员工请假超过      天（含）需经集团总经理批准。\n3. 财务会计的基本职能包括会计核算和         。\n4. 合同的订立应遵循平等、自愿、公平、诚实信用和            的原则。\n5. 厂家敞口的使用期限一般为         个月，具体以与厂家签订的协议为准。\n6. 集团的问题文化是                                                              。\n7. 办公用品的采购由         部门统一负责。\n8. 集团内部员工转介绍购车的，奖励金额由品牌根据该车毛利情况决定，一般在           元之间。\n9. 合同履行过程中，如出现争议，应首先通过          方式解决。\n10. 公司鼓励员工提出合理化建议，对于被采纳的建议将给予                       奖励。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\2025年合群集团中干会考试题（20250207）.docx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:14.348508+08	2026-06-09 13:43:14.348514+08
102	2025年合群集团中干会考试题（20250207）（第5段）	三、简答题（每题25分，共25分）\n1. 某4S店销售一款高返产品，银行给予店端返点17000元，店端将其中15000元返给客户（无票），企业在这个过程中的成本及各项税费如何计算？请简单说明并计算出企业实际的毛利是多少？\n您对BI系统的使用有什么建议？\n说明：题库依据《BI汽车经销商集团管理系统V1.2 操作手册》整理，包含单选题、多选题、判断题、简答题（每题5分）	text	1	\N	public	manual	D:\\合群集团资料\\考试\\2025年合群集团中干会考试题（20250207）.docx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:14.350662+08	2026-06-09 13:43:14.350669+08
103	总经理BI考试题（第1段）	题型：单选题；题目：1、在【门店实时库存结构】页面中，蓝色字体/蓝色区域通常表示（单选）。；选项1：A、可穿透进入下一级明细；选项2：B、异常门店标记；选项3：C、周末标记；选项4：D、仅用于展示不可点击；正确答案：A；答案解析：说明书描述：蓝色字体代表可穿透，能进入具体公司的库存结构。；分值：5\n题型：单选题；题目：2、在库存分析中，若要评估“在库+在途”的库存压力，应重点关注（单选）。；选项1：A、库存深度（在库，含在途）；选项2：B、订单来源小类分布；选项3：C、线索成本排名；选项4：D、保险赔付率；正确答案：A；答案解析：说明书描述：该页面包含集团库存深度（在库，含在途）。；分值：5\n题型：单选题；题目：3、在同一库存页面中，若要排查长期积压车型，应优先查看（单选）。；选项1：A、150天以上长库车型；选项2：B、自然进店订单类型分布；选项3：C、当日交车排名；选项4：D、银行账户资金交易；正确答案：A；答案解析：说明书描述：库存分析包含150天以上长库车型。；分值：5\n题型：单选题；题目：4、在【月-订单台数】的“每日订单情况”中，若某天订单柱/数据为红色，通常表示（单选）。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.632435+08	2026-06-09 13:43:15.632447+08
104	总经理BI考试题（第2段）	；选项1：A、该天为周末；选项2：B、该天为异常门店数据；选项3：C、该天订单已全部取消；选项4：D、该天为系统未同步日期；正确答案：A；答案解析：说明书描述：每日订单情况中红色代表周末。；分值：5\n题型：单选题；题目：5、在【月-订单台数】页面要进一步分析“订单从哪里来”，应重点查看哪个分析模块（单选）。；选项1：A、订单来源大类和小类分类；选项2：B、交车毛利汇总（含水平业务）；选项3：C、订单类型分布；选项4：D、单店订单情况；正确答案：A；答案解析：说明书描述：该页面包含订单来源大类与小类分类。；分值：5\n题型：单选题；题目：6、【年-订单台数】进一步下钻后的最细粒度可以达到（单选）。；选项1：A、具体车型订单与具体销售顾问订单数；选项2：B、到品牌汇总；选项3：C、到区域汇总；选项4：D、到公司汇总不含个人；正确答案：A；答案解析：说明书描述：年订单可细化到具体车型订单、具体销售顾问订单数。；分值：5\n题型：单选题；题目：7、在【月-交车台数】的“每日交车分布”中，红色区域的含义是（单选 ）。；选项1：A、周末；选项2：B、返利到账日；选项3：C、异常门店；选项4：D、未结算工单；正确答案：A；答案解析：说明书描述：每日交车分布红色区域为周末。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.636089+08	2026-06-09 13:43:15.6361+08
105	总经理BI考试题（第3段）	；分值：5\n题型：单选题；题目：8、在【月-维修产值】的“产值日分布”中，红色通常表示（单选）。；选项1：A、周末；选项2：B、产值低于平均值；选项3：C、当日产值未结算；选项4：D、数据缺失；正确答案：A；答案解析：说明书描述：产值日分布中红色代表周末。；分值：5\n题型：单选题；题目：9、在【网销/新媒体对标数据】中打开“开启对比”后，系统对数据异常门店的处理是（单选）。；选项1：A、自动标黄提示异常；选项2：B、自动加入异常箭头；选项3：C、自动将该门店排序置顶；选项4：D、仅在导出时提示异常；正确答案：A；答案解析：说明书描述：开启对比后，出现数据异常门店系统自动标黄。；分值：5\n题型：单选题；题目：10、若要查看某公司各银行账户的交易情况，并可渗透到每个账户交易明细，应进入（单选）。；选项1：A、银行账户资金；选项2：B、在途与清算对比；选项3：C、厂家返利账户；选项4：D、银行汇总表；正确答案：A；答案解析：说明书描述：银行账户资金可渗透查询每个账户交易情况。；分值：5\n题型：单选题；题目：11、厂家账户余额提供“当日”和“当月”两个口径，分别对应功能（单选）。；选项1：A、厂家账户余额-当日 与 厂家账户余额-当月；选项2：B、集团返利 与 MP6返利；选项3：C、整车业务毛利汇总；选项4：D、交车口径延保 与 销售口径延保；正确答案：A；答案解析：说明书列出厂家账户余额-当日与厂家账户余额-当月两项功能。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.639442+08	2026-06-09 13:43:15.639452+08
106	总经理BI考试题（第4段）	；分值：5\n题型：单选题；题目：12、【情景题】你需要从总经理视角查看集团订单/交车/达成及售后产值排名，在系统中最合适的入口是（单选）。；选项1：A、总经理-业务数据总览；选项2：B、门店实时库存结构；选项3：C、总经理-整车/售后排名；选项4：D、总结报告；正确答案：C；答案解析：依据说明书功能描述，完成“从总经理视角查看集团订单/交车/达成及售后产值排名”对应的入口为【总经理-整车/售后排名】。；分值：5\n题型：单选题；题目：13、【情景题】你需要快速总览销售与售后核心经营数据，在系统中最合适的入口是（单选）。；选项1：A、总经理-业务数据总览；选项2：B、总经理-整车/售后排名；选项3：C、门店实时库存结构；选项4：D、总结报告；正确答案：A；答案解析：依据说明书功能描述，完成“快速总览销售与售后核心经营数据”对应的入口为【总经理-业务数据总览】。；分值：5\n题型：单选题；题目：14、【情景题】你需要查看集团总览、销售/售后总结报告看板，在系统中最合适的入口是（单选）。；选项1：A、总结报告；选项2：B、门店实时库存结构；选项3：C、总经理-整车/售后排名；选项4：D、总经理-业务数据总览；正确答案：A；答案解析：依据说明书功能描述，完成“查看集团总览、销售/售后总结报告看板”对应的入口为【总结报告】。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.641804+08	2026-06-09 13:43:15.641811+08
107	总经理BI考试题（第5段）	；分值：5\n题型：单选题；题目：15、【情景题】你需要查看实时库存结构，并下钻到库存结构明细，在系统中最合适的入口是（单选）。；选项1：A、总经理-业务数据总览；选项2：B、门店实时库存结构；选项3：C、库存结构；选项4：D、总经理-整车/售后排名；正确答案：B；答案解析：依据说明书功能描述，完成“查看某门店实时库存结构，并下钻到该公司的库存结构明细”对应的入口为【门店实时库存结构】。；分值：5\n题型：单选题；题目：16、【情景题】你需要对比“含已配车/不含已配车”的资金占用，并定位150天以上长库车型，在系统中最合适的入口是（单选）。；选项1：A、总经理-整车/售后排名；选项2：B、门店实时库存结构；选项3：C、门店历史库存结构；选项4：D、总经理-业务数据总览；正确答案：B；答案解析：依据说明书功能描述，完成“对比“含已配车/不含已配车”的资金占用，并定位150天以上长库车型”对应的入口为【门店实时库存结构（库存成本/资金占用/库存深度/长库）】。；分值：5\n题型：单选题；题目：17、【情景题】你需要分析当月订单达成、每日订单分布（含周末标识）及订单来源大类/小类，在系统中最合适的入口是（单选）。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.644896+08	2026-06-09 13:43:15.644908+08
163	附件2：《帝豪向上系列产品价值推介》 (1)（第4段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.751751+08	2026-06-09 13:43:19.751761+08
108	总经理BI考试题（第6段）	；选项1：A、月-订单台数；选项2：B、年-订单台数；选项3：C、未交车明细；选项4：D、总经理-整车/售后排名；正确答案：A；答案解析：依据说明书功能描述，完成“分析当月订单达成、每日订单分布（含周末标识）及订单来源大类/小类”对应的入口为【月-订单台数】。；分值：5\n题型：单选题；题目：18、【情景题】你需要查看年度订单并下钻到具体车型与具体销售顾问的订单数，在系统中最合适的入口是（单选）。；选项1：A、总经理-整车/售后排名；选项2：B、月-订单台数；选项3：C、年-订单台数；选项4：D、总结报告；正确答案：C；答案解析：依据说明书功能描述，完成“查看年度订单并下钻到具体车型与具体销售顾问的订单数”对应的入口为【年-订单台数】。；分值：5\n题型：单选题；题目：19、【情景题】你需要分析月度交车并下钻到品牌交车明细及每日交车周末分布，在系统中最合适的入口是（单选）。；选项1：A、月-交车台数；选项2：B、总经理-整车/售后排名；选项3：C、年-订单台数；选项4：D、月-订单台数；正确答案：A；答案解析：依据说明书功能描述，完成“分析月度交车并下钻到品牌交车明细及每日交车周末分布”对应的入口为【月-交车台数】。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.647466+08	2026-06-09 13:43:15.647476+08
109	总经理BI考试题（第7段）	；分值：5\n题型：单选题；题目：20、【情景题】你需要分析月度维修产值、收入类型分布并下钻到公司明细，在系统中最合适的入口是（单选）。；选项1：A、总经理-整车/售后排名；选项2：B、总经理-业务数据总览；选项3：C、月-维修产值；选项4：D、总结报告；正确答案：C；答案解析：依据说明书功能描述，完成“分析月度维修产值、收入类型分布并下钻到公司明细”对应的入口为【月-维修产值】。；分值：5\n题型：多选题；题目：21、以下哪些看板在“日分布”中使用红色标识周末？（多选）；选项1：A、月-订单台数（每日订单情况）；选项2：B、月-交车台数（每日交车分布）；选项3：C、月-维修产值（产值日分布）；选项4：D、银行账户资金（账户交易）；正确答案：ABC；答案解析：说明书中订单、交车、维修产值的日分布均提到红色代表周末；银行账户资金与周末标识无关。；分值：5\n题型：多选题；题目：22、以下哪些功能明确支持“蓝色区域/蓝色字体可渗透（下钻）到明细”？（多选）；选项1：A、门店实时库存结构；选项2：B、全员开发贡献订单；选项3：C、清算金额商户统计；选项4：D、预算与实际对比；正确答案：ABC；答案解析：说明书描述A/B/C均可蓝色渗透到下一级或明细列表；预算对比未描述蓝色下钻。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.650633+08	2026-06-09 13:43:15.650643+08
110	总经理BI考试题（第8段）	；分值：5\n题型：多选题；题目：23、关于【总经理-整车/售后排名】功能与口径，下列说法哪些正确？（多选）；选项1：A、总经理排名仅支持年度排名。；选项2：B、总经理-整车排名包含当日/月/年订单排名。；选项3：C、总经理-售后排名包含产值排名与达成排名。；选项4：D、总经理-整车排名包含当日/月/年交车排名与达成排名。；正确答案：BCD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：24、关于【总经理-业务数据总览】功能与口径，下列说法哪些不正确？（多选）；选项1：A、业务数据总览同时覆盖销售与售后业务数据。；选项2：B、业务数据总览只覆盖金融按揭。；选项3：C、业务数据总览只覆盖市场费用。；选项4：D、该页面数据每月手工导入一次，不支持实时更新。；正确答案：BCD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：25、关于【总结报告】功能与口径，下列说法哪些不正确？（多选）；选项1：A、总结报告只包含财务报表。；选项2：B、该页面数据每月手工导入一次，不支持实时更新。；选项3：C、总结报告包含集团总览、销售报告与售后报告看板。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.652635+08	2026-06-09 13:43:15.652644+08
111	总经理BI考试题（第9段）	；选项4：D、总结报告不支持按版块查看。；正确答案：ABD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：26、关于【门店实时库存结构】功能与口径，下列说法哪些正确？（多选）；选项1：A、该页面仅展示历史库存，不包含实时库存。；选项2：B、门店实时库存结构页面数据系统实时同步、实时更新。；选项3：C、蓝色字体表示可穿透进入更明细的库存结构。；选项4：D、页面支持筛选查询实时库存情况。；正确答案：BCD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：27、关于【门店实时库存结构（库存成本/资金占用/库存深度/长库）】功能与口径，下列说法哪些正确？（多选）；选项1：A、长库阈值固定为90天以上。；选项2：B、可查看库存成本结构并区分“包含已配车/不含已配车”的资金占用口径。；选项3：C、可查看150天以上长库车型。；选项4：D、可查看集团库存深度（在库含在途）。；正确答案：BCD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：28、关于【月-订单台数】功能与口径，下列说法哪些正确？	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.65474+08	2026-06-09 13:43:15.654749+08
164	附件2：《帝豪向上系列产品价值推介》 (1)（第5段）	每一代帝豪始终坚持向上精神，以实力打破合资垄断，引领国民轿车不断向上\n第1代帝豪\n以超高的品质和五星级安全\n向上突破自主品牌 8万级价格天花板\n第2代帝豪\nC-ECAP白金评价冠军\n向上突破自主品牌健康安全天花板\n第3代帝豪\n同级首个配备 LED大灯、液晶仪表\n向上突破自主品牌科技天花板第4代帝豪\nBMA全球模块化架构加持\n向上突破自主品牌品质天花板第5代帝豪\n新一代 BMA Evo 架构+千里浩瀚 H3 \n向上突破自主品牌智能天花板\n帝豪的向上精神\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.75428+08	2026-06-09 13:43:19.754289+08
112	总经理BI考试题（第10段）	（多选）；选项1：A、月-订单台数包含订单达成柱状图。；选项2：B、红色代表异常门店。；选项3：C、页面包含订单来源大类和小类分类。；选项4：D、每日订单情况中红色代表周末。；正确答案：ACD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：29、关于【年-订单台数】功能与口径，下列说法哪些正确？（多选）；选项1：A、可细化到具体车型订单。；选项2：B、年-订单台数可从集团到品牌汇总并蓝色区域可渗透。；选项3：C、可细化到具体销售顾问订单数。；选项4：D、年度订单仅支持按公司展示不支持品牌。；正确答案：ABC；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：30、关于【月-交车台数】功能与口径，下列说法哪些正确？（多选）；选项1：A、交车台数只提供年度汇总无月度。；选项2：B、每日交车分布中红色区域为周末。；选项3：C、交车明细不可下钻。；选项4：D、月-交车台数可按品牌查询并可渗透到交车明细。；正确答案：BD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：31、关于【月-维修产值】功能与口径，下列说法哪些正确？	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.656771+08	2026-06-09 13:43:15.65678+08
113	总经理BI考试题（第11段）	（多选）；选项1：A、该页面只统计整车毛利。；选项2：B、产值收入类型分布可渗透查询同一分类的公司数据。；选项3：C、产值日分布中红色代表周末。；选项4：D、月-维修产值支持蓝色区域渗透进入明细。；正确答案：BCD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：32、关于【金融排名管理】功能与口径，下列说法哪些正确？（多选）；选项1：A、包含按揭返佣系统相关排名。；选项2：B、金融排名包含按揭台数、按揭渗透率、金融按揭收入等维度。；选项3：C、返佣系统排名与按揭无关。；选项4：D、包含金融单台收入与除返后收入/单台收入排名。；正确答案：ABD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：33、关于【网销/新媒体对标】功能与口径，下列说法哪些正确？（多选）；选项1：A、开启“开启对比”后数据异常门店会自动标黄。；选项2：B、包含红黑榜、年度分析、日报与订单明细等功能。；选项3：C、网销/新媒体对标数据支持选择时间、公司、品牌进行多维对标。；选项4：D、标黄表示周末。；正确答案：ABC；答案解析：请依据说明书描述辨析口径、维度与下钻能力。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.659684+08	2026-06-09 13:43:15.659693+08
114	总经理BI考试题（第12段）	；分值：5\n题型：多选题；题目：34、关于【在途与清算对比】功能与口径，下列说法哪些不正确？（多选）；选项1：A、在途与清算对比只能查看在途，不能查看清算。；选项2：B、该页面不支持按公司/品牌筛选，只能查看集团汇总。；选项3：C、对比页面不支持筛选公司。；选项4：D、在途与清算对比用于对比在途金额与清算金额差异。；正确答案：ABC；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：35、关于【银行账户资金】功能与口径，下列说法哪些不正确？（多选）；选项1：A、银行账户资金只展示余额，不展示账户交易明细。；选项2：B、该页面数据每月手工导入一次，不支持实时更新。；选项3：C、银行账户资金不可下钻。；选项4：D、银行账户资金可查询各公司银行资金交易情况，并可渗透到每个账户交易明细。；正确答案：ABC；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：36、关于【厂家账户管理】功能与口径，下列说法哪些正确？（多选）；选项1：A、厂家账户管理可查询销售部厂家账户与售后厂家配件账户余额。；选项2：B、包含销售/售后返利账户等余额信息。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.662311+08	2026-06-09 13:43:15.66232+08
115	总经理BI考试题（第13段）	；选项3：C、提供当日与当月两个口径。；选项4：D、厂家账户只提供年度余额。；正确答案：ABC；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：37、关于【集团返利】功能与口径，下列说法哪些不正确？（多选）；选项1：A、返利模块不能筛选。；选项2：B、集团返利只看总额不支持明细。；选项3：C、集团返利支持查询集团及各店返利情况，并可渗透进入返利明细。；选项4：D、该页面仅展示台数，不展示金额/毛利/渗透率等指标。；正确答案：ABD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：38、关于【零件库存汇总表】功能与口径，下列说法哪些正确？（多选）；选项1：A、零件库存汇总只展示年度累计不展示实时。；选项2：B、零件库存汇总包含实时库存数与库存成本金额。；选项3：C、包含近三个月出库毛利与毛利率。；选项4：D、包含库存度、周转率等指标。；正确答案：BCD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：39、关于【月-交车台数】功能与口径，下列说法哪些正确？（多选）；选项1：A、月-交车台数可按品牌查询并可渗透到交车明细。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.664584+08	2026-06-09 13:43:15.664593+08
165	附件2：《帝豪向上系列产品价值推介》 (1)（第6段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.756455+08	2026-06-09 13:43:19.756459+08
235	销售顾问驾驶仓看板 - 片段1 (00:00)	[视频片段 00:00 - 01:00] 此内容为视频转写片段，请管理员填写文字内容。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\10b9eebdc142418ba70b7470fd0a3765.mp4	李管理		/uploads/10b9eebdc142418ba70b7470fd0a3765.mp4	0	60	批量导入,产品知识库	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 13:57:09.795851+08	2026-06-12 13:57:09.795859+08
116	总经理BI考试题（第14段）	；选项2：B、红色表示异常门店。；选项3：C、交车明细不可下钻。；选项4：D、每日交车分布中红色区域为周末。；正确答案：AD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：40、关于【零件库存汇总表】功能与口径，下列说法哪些正确？（多选）；选项1：A、零件库存汇总包含实时库存数与库存成本金额。；选项2：B、包含库存度、周转率等指标。；选项3：C、包含近三个月出库毛利与毛利率。；选项4：D、库存度与周转率无法查看。；正确答案：ABC；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：判断题；题目：41、判断：在网销/新媒体对标数据中，开启“开启对比”后，数据异常的门店会自动标黄。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：说明书对对标功能描述包含“开启对比后异常门店自动标黄”。；分值：5\n题型：判断题；题目：42、判断：系统中多处表格/区域使用蓝色字体或蓝色区域表示可渗透到更明细的数据。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：说明书在库存、订单贡献、资金等多个模块均提到蓝色可渗透/穿透。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.666703+08	2026-06-09 13:43:15.666713+08
117	总经理BI考试题（第15段）	；分值：5\n题型：判断题；题目：43、判断：总经理-售后排名包含产值排名与达成排名。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【总经理-整车/售后排名】的描述一致。；分值：5\n题型：判断题；题目：44、判断：业务数据总览只覆盖市场费用。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：B；答案解析：该表述与说明书对【总经理-业务数据总览】的描述不符。；分值：5\n题型：判断题；题目：45、判断：总结报告包含集团总览、销售报告与售后报告看板。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【总结报告】的描述一致。；分值：5\n题型：判断题；题目：46、判断：红色字体表示可穿透。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：B；答案解析：该表述与说明书对【门店实时库存结构】的描述不符。；分值：5\n题型：判断题；题目：47、判断：长库阈值固定为90天以上。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：B；答案解析：该表述与说明书对【门店实时库存结构（库存成本/资金占用/库存深度/长库）】的描述不符。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.669427+08	2026-06-09 13:43:15.669437+08
118	总经理BI考试题（第16段）	；分值：5\n题型：判断题；题目：48、判断：订单来源只分大类不分小类。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：B；答案解析：该表述与说明书对【月-订单台数】的描述不符。；分值：5\n题型：判断题；题目：49、判断：未交车明细可看到具体车型订单及部分毛利情况。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【年-订单台数】的描述一致。；分值：5\n题型：判断题；题目：50、判断：每日交车分布中红色区域为周末。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【月-交车台数】的描述一致。；分值：5\n题型：判断题；题目：51、判断：产值收入类型分布可渗透查询同一分类的公司数据。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【月-维修产值】的描述一致。；分值：5\n题型：判断题；题目：52、判断：除返后收入不提供排名。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：B；答案解析：该表述与说明书对【金融排名管理】的描述不符。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.671394+08	2026-06-09 13:43:15.671404+08
119	总经理BI考试题（第17段）	；分值：5\n题型：判断题；题目：53、判断：网销对标包含红黑榜、年度分析、日报与订单明细等功能。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【网销/新媒体对标】的描述一致。；分值：5\n题型：判断题；题目：54、判断：在途与清算对比用于对比在途金额与清算金额差异。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【在途与清算对比】的描述一致。；分值：5\n题型：判断题；题目：55、判断：银行账户资金可查询各公司银行资金交易情况，并可渗透到每个账户交易明细。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【银行账户资金】的描述一致。；分值：5\n题型：判断题；题目：56、判断：厂家账户管理可查询销售部厂家账户与售后厂家配件账户余额。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【厂家账户管理】的描述一致。；分值：5\n题型：判断题；题目：57、判断：集团返利支持查询集团及各店返利情况，并可渗透进入返利明细。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.673339+08	2026-06-09 13:43:15.673348+08
166	附件2：《帝豪向上系列产品价值推介》 (1)（第7段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n每一代帝豪都持续坚持“向上精神”\n不断突破极限，打破合资垄断\n十六载向上历程，收获全球 420万+用户信赖\n成就中国品牌家轿第一家族\n帝豪向上系列车型身披荣耀而来，传承向上精神\n助力帝豪冲刺 500万销量！\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.758578+08	2026-06-09 13:43:19.758586+08
245	销售经理驾驶仓数据分析看板 - 片段7 (00:24)	關鍵數據指標可點擊穿透。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	24.77	29.93	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.500744+08	2026-06-12 14:31:07.500747+08
120	总经理BI考试题（第18段）	；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【集团返利】的描述一致。；分值：5\n题型：判断题；题目：58、判断：零件库存汇总表包含近三个月出库毛利与毛利率。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【零件库存汇总表】的描述一致。；分值：5\n题型：判断题；题目：59、判断：金融排名包含按揭台数、按揭渗透率、金融按揭收入等维度。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【金融排名管理】的描述一致。；分值：5\n题型：判断题；题目：60、判断：在途与清算对比页面不支持筛选公司。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：B；答案解析：该表述与说明书对【在途与清算对比】的描述不符。；分值：5\n题型：简答题；题目：61、【库存+销售联动】你作为总经理，发现“库存深度（在库含在途）”持续上升，但当月订单与交车增长不明显。请写出你在BI系统中定位原因的步骤（至少4步），并说明每步要看哪些关键维度/口径。；选项1：；选项2：；选项3：；选项4：；答案解析：要点示例：	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.675859+08	2026-06-09 13:43:15.675879+08
121	总经理BI考试题（第19段）	1）进入【门店实时库存结构】查看库存深度（在库含在途）趋势，并重点筛选150天以上长库车型，定位到异常车型。\n2）在同页对比“包含已配车/不含已配车”的资金占用，判断压力来自已配车还是在库在途。\n3）进入【月-订单台数】核对当月订单达成、每日订单分布与订单来源大类/小类，排查是否为获客结构变化导致订单不足。\n4）进入【月-交车台数】核对交车达成、每日交车分布（周末标识）并下钻交车明细，判断是否存在交付节奏/结构性拖延。\n5）最终输出：明确“库存结构问题（长库/已配车）/订单问题（来源/转化）/交付问题（节奏/明细）”中的主因，并给出下一步动作。；分值：5\n题型：简答题；题目：62、【订单到交付差异】你作为总经理，发现“订单达成率”正常，但“交车达成率”显著偏低。请说明如何在BI系统中从“订单→交车→明细”三层逐步定位差异来源。；选项1：；选项2：；选项3：；选项4：；答案解析：要点示例：\n1）在【月-订单台数】确认订单达成曲线、周末分布与订单来源结构，锁定差异开始的日期区间。\n2）在【月-交车台数】按同品牌与同日期区间核对交车分布，并下钻到交车明细（蓝色渗透）。\n3）对比订单来源与交车明细：识别是否集中在某来源小类/某门店/某销售顾问；必要时结合【年-订单台数】进一步下钻到车型与销售顾问核对。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.679762+08	2026-06-09 13:43:15.679771+08
122	总经理BI考试题（第20段）	4）结论：区分是“交付节奏延迟/结构差异（车型供给）/录入口径差异（日期口径）”。；分值：5\n题型：简答题；题目：63、【口径辨析】你作为总经理，需要向管理层解释：为何“延保/用车无忧”的渗透率在两个看板上差异明显。请说明“交车口径”和“销售口径”的统计范围差异，并给出选择口径的建议场景。；选项1：；选项2：；选项3：；选项4：；答案解析：要点示例：\n1）交车口径：统计“当月交车中购买”延保/无忧的情况，适合评估交付当月的随车销售渗透。\n2）销售口径：统计“当月提车购买 + 提车后跨月购买”的情况，适合评估销售过程与后续补购的综合渗透。\n3）建议：做月度经营复盘/交付随车销售看交车口径；做销售能力评估/补购运营看销售口径；汇报时需先声明口径避免误读。；分值：5\n题型：简答题；题目：65、【资金对账】你作为总经理，发现某账户刷卡“在途金额”长期高于“清算金额”，且差异逐步扩大。请说明你如何用BI系统完成对账定位（至少4步），并指出需要下钻到哪些明细。；选项1：；选项2：；选项3：；选项4：；答案解析：要点示例：\n1）在【在途资金管理】查看刷卡在途金额，按公司/日期定位异常区间，并下钻在途明细核对交易列表。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.682599+08	2026-06-09 13:43:15.682608+08
123	总经理BI考试题（第21段）	2）在【清算金额商户统计】按商户汇总清算金额，下钻到清算金额详细列表，核对是否存在未清算商户或清算延迟。\n3）在【在途与清算对比】对比同区间差异，锁定差异最大的商户/日期。\n4）进入【银行账户资金】下钻到对应账户交易明细，核对是否已入账但未匹配、或存在退单/冲正。\n5）输出：明确差异原因（清算延迟/商户问题/入账匹配问题）与跟进动作。；分值：5\n题型：简答题；题目：70、【配件健康度】你作为总经理，发现配件资金占用上升且呆滞占比提升。请说明如何在BI系统中从“库存汇总→呆滞→出库结构”定位问题，并提出处置建议。；选项1：；选项2：；选项3：；选项4：；答案解析：要点示例：\n1）在【零件库存汇总表】查看实时库存数、成本金额、库存度与周转率，定位问题库存明细情况。\n2）在【呆滞库存分析报表】查看不同天数段的占比与金额占比，识别主要呆滞段（例如>某天数）。\n3）在【零件出库汇总表】核对出库件数/毛利及调拨、内耗占比，判断是否需要调拨消化、加大促销或优化采购。\n4）输出：给出“调拨/退库/促销/采购调整”的组合方案，并对预计周转改善做量化目标。；分值：5\n题型：简答题；题目：61、请简述总经理如何通过【总经理-整车排名】快速判断经营态势（至少包含3个指标口径）。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.684952+08	2026-06-09 13:43:15.684963+08
167	附件2：《帝豪向上系列产品价值推介》 (1)（第8段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.76078+08	2026-06-09 13:43:19.76079+08
246	销售经理驾驶仓数据分析看板 - 片段8 (00:29)	毛利結構已拆分到具體業務模塊。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	29.93	36.71	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.501559+08	2026-06-12 14:31:07.501561+08
124	总经理BI考试题（第22段）	；选项1：；选项2：；选项3：；选项4：；答案解析：可查看当日新增订单排名、当日交车排名、月/年交车达成排名等，从短期节奏与月/年目标达成两个维度判断经营态势。；分值：5\n题型：简答题；题目：62、解释“蓝色区域可渗透”的含义，并举例说明在总经理看板里如何使用穿透做追因分析。；选项1：；选项2：；选项3：；选项4：；答案解析：蓝色区域表示可穿透到下一层明细（如公司/门店/顾问/车型）。总经理可从集团排名穿透到公司，再穿透到门店/顾问，定位差距来源。；分值：5\n题型：简答题；题目：63、请描述【业务数据总览】适合回答哪三类管理问题。；选项1：；选项2：；选项3：；选项4：；答案解析：例如：销售与售后整体规模是否增长；各公司/品牌贡献结构如何；关键指标（订单、交车、产值、毛利等）是否偏离目标。；分值：5\n题型：简答题；题目：64、当发现库存压力上升时，总经理应如何在BI里做“库存风险+资金占用”联动分析？；选项1：；选项2：；选项3：；选项4：；答案解析：先看库存分析的库存深度（在库含在途）与150天以上长库车型；再看库存成本结构区分含已配车/不含已配车资金占用；最后结合采购计划参考调整采购与去化策略。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.687091+08	2026-06-09 13:43:15.6871+08
125	总经理BI考试题（第23段）	；分值：5\n题型：简答题；题目：65、请说明【行业数据管理】对经营决策的价值，并给出一个使用场景。；选项1：；选项2：；选项3：；选项4：；答案解析：可查询乘用车与全国皮卡月度/年度销量，用于判断行业景气、品牌趋势与区域机会。例如制定季度目标或调整品牌资源投入。；分值：5\n题型：简答题；题目：67、请说明【返利管理】中MP5与MP6的含义，以及管理上分别关注什么。；选项1：；选项2：；选项3：；选项4：；答案解析：MP5是预估其他返利，MP6是预估市场返利。管理上关注各店返利结构与兑现风险，必要时穿透到具体返利内容核对。；分值：5\n题型：简答题；题目：68、当需要做“售后盈利复盘”时，总经理应该组合使用哪些售后页面？写出至少3个。；选项1：；选项2：；选项3：；选项4：；答案解析：例如：年-维修产值及毛利（产值/毛利/毛利率）、维修零件-产值及毛利（零件毛利率）、维修工时收入（工时占比与客单价）、售后业务汇总等。；分值：5\n题型：简答题；题目：69、简述如何用【营销-预算管理】做预算执行管控。；选项1：；选项2：；选项3：；选项4：；答案解析：先在预算计划录入/查看预算；在执行总结跟踪执行结果；在预算与实际对比评估偏差；必要时渗透到公司明细分析原因并调整资源。	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.690075+08	2026-06-09 13:43:15.690086+08
126	总经理BI考试题（第24段）	；分值：5\n题型：简答题；题目：70、请说明盘点管理的两个页面分别解决什么问题。；选项1：；选项2：；选项3：；选项4：；答案解析：盘点汇总填报用于录入/汇总盘点数据；集团盘点汇总表用于查看集团层面的盘点汇总结果与对比分析。；分值：5	text	1	\N	public	manual	D:\\合群集团资料\\考试\\总经理BI考试题.xlsx	系统导入	\N	\N	0	0	批量导入,考试	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:15.69357+08	2026-06-09 13:43:15.693581+08
127	AutoCar汽车经销商管理系统软件使用说明书（第1段）	AutoCar汽车经销商集团管理系统\n版本号：V1.0\n操\n作\n手\n册\n系统登录：\n根据页面提示信息，以用户名、密码方式登录系统，点击界面【登录】按钮，即可进入，如下图所示：\n如果是新用户第一次用初始密码登录，系统会弹出密码修改窗口，要求用户设置个人密码。重复输入两次密码，点击“保存”按钮即可完成设置。如下图所示：\n当用户有多家组织/公司的使用权限时，登录系统后会弹出组织选择窗口，双击选择即可。如下图所示：\n系统功能板块：\n系统管理\n01.01角色管理\n    定义系统用户角色，设置角色的功能权限及折扣权限，如下图所示：\n01.02 用户管理\n    定义系统用户的用户号、用户名、用户所属部门、用户角色以及所属组织等。用户所属部门需预先在【01.03基础数据-集团统一设置--集团总部[S1]--系统--部门】中进行设置，用户角色需预先在【01.01角色管理】中进行设置。如下图所示：\n01.03基础数据\n   设置系统运行的基础数据，如下图所示：\n01.04零件入库导入\n   批量导入入库单零件，如下图所示：\n01.05必填项目设定\n   设置系统各模块的必填项目，如下图所示：\n01.06批量授权	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.229909+08	2026-06-09 13:43:16.229922+08
128	AutoCar汽车经销商管理系统软件使用说明书（第2段）	批量授权各公司角色权限，如下图所示：\n业务基础资料\n02.01零件资料管理\n   零件及精品基础档案信息的新增、修改、删除、查询等功能，如下图所示：\n02.02外销客户管理\n   外销客户档案信息的新增、修改、删除、查询等功能，如下图所示：\n02.03供应商信息管理\n   车辆及零件供应商档案信息的新增、修改、删除、查询等功能，如下图所示：\n02.04整车车型管理\n整车车型基础资料的新增、修改、删除、查询等功能，如下图所示：\n02.05维修工时项目管理\n   维修工时项目的新增、修改、删除、查询以及工时项目批量管理等。“工时项目批量管理” 操作（批量导入工时项目）：1.点击“下载工时项目模板”按钮下载模板文件（EXCEL文档）；2.按模板文件的格式整理需要导入的工时项目；3.点击“打开EXEL文件”按钮，选择打开【步骤2】整理好的文件；4.点击“导入工时项目”按钮完成导入。 如下图所示：\n02.06客户车辆档案\n客户车辆档案的新增、修改、删除、查询等功能，如下图所示：\n02.07优惠券方案\n优惠券方案的新增、修改、删除、查询等功能，设置要发行的优惠券的名称、编号前缀、发行总量、券面额、类型、有效时长、预估成本、使用条件等。	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.233738+08	2026-06-09 13:43:16.233748+08
236	销售顾问驾驶仓看板 - 片段2 (01:00)	[视频片段 01:00 - 01:57] 此内容为视频转写片段，请管理员填写文字内容。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\10b9eebdc142418ba70b7470fd0a3765.mp4	李管理		/uploads/10b9eebdc142418ba70b7470fd0a3765.mp4	60	117.88775	批量导入,产品知识库	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 13:57:09.813351+08	2026-06-12 13:57:09.813358+08
247	销售经理驾驶仓数据分析看板 - 片段9 (00:36)	管理層可直觀查看。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	36.71	38.81	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.502368+08	2026-06-12 14:31:07.50237+08
129	AutoCar汽车经销商管理系统软件使用说明书（第3段）	如下图所示：\n02.08套餐方案\n车辆维保套餐方案的新增、修改、删除、查询等功能，设置要发售的套餐的类型、适用车系、名称、金额、有效天数、卡号前缀、收费类型、套餐分类以及套餐包含的工时和零件项目等。如下图所示：\n02.09延保方案定义\n车辆延保方案的新增、修改、删除、查询等功能，如下图所示：\n02.10整车车型返利项目\n    整车车型返利项目的新增、修改、删除、查询等功能，设置整车车型的返利金额及预估返利，如下图所示：\n02.11金融机构信息\n    金融机构信息的新增、修改、删除、查询等功能，设置金融机构产品的金融机构类型、机构名称、产品名称、期数、返佣方式、返佣值、客户费率等，如下图所示：\n02.12售后车型管理\n     售后车型档案的新增、修改、删除、查询等功能，如下图所示：\n02.13厂家优惠券定义\n     厂家优惠券的新增、修改、删除、查询等功能，如下图所示：\n整车管理\n03.01整车库存管理\n   03.01.01在途及在库车辆导入\n        导入从新车供应商采购的新车入库单（EXCEL格式），包括在途车和入库现车。如下图所示：\n   03.01.02车辆入库管理	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.236968+08	2026-06-09 13:43:16.236976+08
130	AutoCar汽车经销商管理系统软件使用说明书（第4段）	录入新车采购入库单，如下图所示：\n   03.01.03内部调拨入库\n        对集团内部其他公司调拨到本公司的新车进行入库功能（需要其他公司先在车辆订单管理中录入订单类型为“集团内调车”的订单）。如下图所示：\n   03.01.04车辆调仓管理\n        在本公司内不同仓库之间进行车辆调拨（调整车辆存放仓库），如下图所示：\n03.02整车客户管理\n   03.02.01展厅客流管理\n       维护及登记展厅客流信息，如下图所示：\n   03.02.02客户信息管理\n       新车购车客户信息的新增、修改、删除、查询以及客户跟进登记等功能，如下图所示：\n   03.02.03客户跟进经理审核\n      对登记的展厅来访客户信息以及跟进记录进行审核，如下图所示：\n3.3整车销售管理\n   03.03.01车辆订单管理\n车辆订单的新增、修改、删除、查询功能；精品、保单、增值业务等订单关联业务数据的录入。如下图所示：\n   03.03.02车辆订单审核\n销售经理、财务、总经理审核车辆订单，打印车辆放行条。如下图所示：\n   03.03.03新车交车管理	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.239434+08	2026-06-09 13:43:16.239443+08
131	AutoCar汽车经销商管理系统软件使用说明书（第5段）	打印车辆放行条，录入交车人完成交车操作。如下图所示：\n   03.03.04整车订单权限管理\n设置各管理岗位的整车订单价格权限，如下图所示：\n   03.03.05导入贷款信息\n导入金融按揭贷款产品信息，如下图所示：\n   03.03.06销售终端申报\n管理车辆销售的终端申报情况，如下图所示：\n03.04新保出单\n新保单的新增、修改、删除、查询，以及保单审核，纸质保单存档等功能，如下图所示：\n03.05月接车计划跟进\n月接车计划制定与跟进，如下图所示：\n03.06厂家终端任务管理\n零件管理\n   04.01零件入库管理\n      零件入库单的新增、修改、删除、查询、打印以及确认入库，缺件单生成等，如下图所示：\n   04.02零件退库管理\n      根据零件入库单，录入退货数量生成退库单，如下图所示：\n   04.03零件盘点管理\n      盘点流程：\n生成盘点单记录库存数量；\n在盘点单中录入实盘数；\n盈亏确认；\n生成入库单，根据盈亏数自动生成入库单；\n如下图所示：\n   04.04零件外销管理\n      零件外销单的新增、修改、删除、查询、打印等，如下图所示：\n   04.05外销调拨内耗退货	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.242376+08	2026-06-09 13:43:16.242384+08
132	AutoCar汽车经销商管理系统软件使用说明书（第6段）	生成外销、调拨、内耗单的退货单，根据外销、调拨、内耗单据，录入退货数量后生成退货单，如下图所示：\n   04.06库存调整\n      调整库存零件的零售价、批发价、货架名称，如下图所示：\n   04.07内耗出库管理\n      内耗出库单的新增、修改、删除、查询、打印等，如下图所示：\n   04.08零件调仓管理\n      零件调仓单的新增、修改、删除、查询、打印等（调仓单用于在本公司内部不同仓库间调整零件的存放仓库。），如下图所示：\n   04.09零件调仓确认\n      确认零件调仓单，使调仓单生效，如下图所示：\n   04.10每日动态盘点\n       生成某时段内库存有变动的零件的库存盘点表，对发生变动的零件进行账实核对，确保库存账目准确。如下图所示：\n   04.11零件调拨出库\n      零件调拨出库单的新增、修改、删除、查询、打印以及出库确认等（零件调拨出库是把本公司仓库的库存零件调拨到集团内其他下属公司仓库），如下图所示：\n   04.12零件调拨入库\n      根据集团内其他下属公司调给本公司的零件调拨出库单，生成零件调拨入库单，如下图所示：	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.245225+08	2026-06-09 13:43:16.245234+08
133	AutoCar汽车经销商管理系统软件使用说明书（第7段）	04.13批量更新标准售价\n      根据导入的EXCEL表批量更新零件的标准售价，如下图所示：\n售后管理\n   05.01维修服务接待\n      维修服务单的新增、修改、删除、查询、打印，维修工时录入（维修零件的录入在“维修零件出库”中操作），套餐、优惠券的使用，折扣设置以及派工、完工、结算单推送等，如下图所示：\n   05.02维修派工管理\n      用于维修工作任务的分配安排管理，可进行派工、完工、反完工、打印等功能。如下图所示：\n   05.03维修零件预出\n      预先录入需要维修出库的零件，以便在实际出库时可以快速生成出库单，提高出库单录入效率。选择要预出库的服务单，点击编辑按钮，在右侧零件窗口按向下方向键，即可录入零件。如下图所示：\n   05.04维修零件出库\n      维修零件出库的新增、修改、删除、查询、打印等。点击新增按钮，在弹出的窗口选择维修服务单，选择好维修班组后，即可在零件窗口录入维修需要使用的零件（录入过程中按“向下方向键”添加新行）。录入后可如下图所示：\n   05.05售后BO件管理\n      BO件管理用于锁定维修客户预定的零件库存，为客户预留好零件供维修时使用。	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.24838+08	2026-06-09 13:43:16.248389+08
134	AutoCar汽车经销商管理系统软件使用说明书（第8段）	防止出现客户已提前预定，但零件却被其他客户用掉造成无件可用的情况。如下图所示：\n   05.06维修退料管理\n      用于将维修剩余的零件退回仓库，首先选择要退料的维修服务单，在右侧的零件窗口录入退料数量，然后点“生成退单”即可完成操作。如下图所示：\n   05.07延保销售管理\n      延保销售的新增、修改、删除、查询、打印以及延保的结算，退保、终止等功能。 如下图所示：\n   05.08车辆保单管理\n      车辆保单的新增、修改、删除、查询，以及保单审核，纸质保单存档等功能，如下图所示：\n   05.09售后预约管理\n      售后预约单的新增、修改、删除、查询，以及预约确认等功能，如下图所示：\n   05.10增值业务管理\n      增值业的新增、修改、删除、查询，以及结算、发票补录等功能，如下图所示：\n   05.11查看工位情况\n      查看维修车间工位情况，预约维修工位等，如下图所示：\n   05.12挂账申请单审核\n      部门经理、总经理审核单据结算的挂账申请，如下图所示：\n   05.13钣喷管理\n      钣喷车间的钣喷工序管理，如下图所示：	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.250516+08	2026-06-09 13:43:16.250522+08
135	AutoCar汽车经销商管理系统软件使用说明书（第9段）	05.14售后预约看板\n      展示某一天售后维修客户的预约情况，如下图所示：\n精品管理\n   06.01精品外销\n      精品对外销售单的新增、修改、删除、查询，以及结算、发票补录等功能，如下图所示：\n   06.02精品销售退货\n      选择要退货的精品销售单，输入本次退货数，点击“生成退单”按钮生成退货单，如下图所示：\n   06.03精品加装出库\n      选择要加装出库的精品销售单，输入精品接待人员，在精品列表中勾选要加装出库的精品，点击“精品派工”按钮选择班组完成派工，然后输入本次出库数，点击“生成出库单”按钮完成操作。如下图所示：\n   06.04精品出库退货\n      选择要出库退货的精品出库单，输入本次退货数，点击“生成退单”按钮生成出库退货单，如下图所示：\n   06.05精品销售清单\n      查询、打印、导出精品销售清单，如下图所示：\n   06.06精品出库清单\n      查询、打印、导出精品出库清单，如下图所示：\n   06.07精品提成清单\n      查询、打印、导出精品提成清单，如下图所示：\n二手管理\n   07.01车俩评估及收购管理	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.252805+08	2026-06-09 13:43:16.252815+08
136	AutoCar汽车经销商管理系统软件使用说明书（第10段）	二手车俩评估单的新增、修改、删除、查询、审核以及客户跟进、报价及评估等功能，如下图所示：\n   07.02二手车销售管理\n        二手车俩销售单的新增、修改、删除、查询以及销售配车、库存查询等功能，如下图所示：\n   07.03二手车客户资料管理\n        二手车客户资料的新增、修改、删除、查询以及分配客户等功能，如下图所示：\n   07.04二手车销售信息\n        查询二手车销售数据，如下图所示：\n   07.05二手车交车管理\n二手车放行条打印、交车，如下图所示：\n   07.06二手车销售订单审核\n        销售经理、财务、总经理审核二手车销售订单，放行条打印已经客户和车俩信息查询。如下图所示：\n   07.07二手车库存\n        二手车库存查询，如下图所示：\n财务管理\n   08.01收款管理\n      08.01.01整车业务收款\n              对整车销售订单进行收款以及对预定车的客户收取定金，打印收据。收款操作：选择要收款的客户，在对应支付方式中录入收款金额，点击“收款”按钮完成。如下图所示：\n      08.01.02新车诚意金管理	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.254882+08	2026-06-09 13:43:16.254891+08
137	AutoCar汽车经销商管理系统软件使用说明书（第11段）	收取客户购车的诚意金。如客户确认购车后，点击“转大定”按钮，可生成整车订单；如客户取消购车意向，点击“取消收款”按钮；如需诚意金退款，点击“生成退款单”按钮。如下图所示：\n      08.01.03维修财务结算\n             维修服务单结算：选择要收款的服务单号，在相应支付方式中录入金额，点击“结算”按钮完成操作。如下图所示：\n      08.01.04维修财务结帐\n             对维修服务单的挂账进行结账收款：勾选要结账收款的服务单，在结账总金额列录入本次要结账的金额或者点击“设置本次结账=待结账金额”按钮自动填入待结账金额，最后点击“结账收款”按钮完成操作。结账完成后还可以点击“还原结账”按钮取消结账。如下图所示：\n      08.01.05零件结算\n             对零件外销单进行结算：选择出库单据编号，点击“结算”按钮，在弹出的结算窗口中的相应支付方式中录入收款金额，最后点击“确认收款”按钮完成操作。已收款的单据还可以点击“反结算”按钮还原结算收款。如下图所示：\n      08.01.06精品收款\n             对精品外销单进行结算：选择订购单号，点击“结算”按钮，在弹出的结算窗口中的相应支付方式中录入收款金额，最后点击“确认收款”按钮完成操作。	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.257517+08	2026-06-09 13:43:16.257524+08
138	AutoCar汽车经销商管理系统软件使用说明书（第12段）	已收款的单据还可以点击“反结算”按钮还原结算收款。如下图所示：\n      08.01.08往来客户管理\n             对有账务往来客户档案的新增、修改、删除、查询等操作，如下图所示：\n      08.01.09预收款管理\n             对往来客户预收款：选择往来客户，点击“收款”按钮，在弹出的收款窗口中的相应支付方式中录入收款金额，最后点击“确认收款”按钮完成操作。已做预收款的记录可以点击“还原”按钮还原预收款。如下图所示：\n      08.01.10客户往来帐管理\n             收取往来客户的应收帐款：选择往来客户，点击“收款”按钮，在弹出的收款窗口中的相应支付方式中录入收款金额，最后点击“确认收款”按钮完成操作。已做收款的记录可以点击“还原”按钮还原预收款。如下图所示：\n    08.02付款管理\n      08.02.01二手付款管理\n             支付收购二手车的应付款：选择要付款的评估单号，选择付款方式及录入付款金额，最后点击“付款”按钮完成操作。付款完成后的项目会显示在付款明细中，点击“还原”按钮可还原付款。如下图所示：	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.259504+08	2026-06-09 13:43:16.259513+08
139	AutoCar汽车经销商管理系统软件使用说明书（第13段）	08.02.02配件及精品付款申请\n              支付配件及精品采购的货款，流程分三步：1.申请付款：勾选要付款的单据，点击“申请付款”按钮，系统将生成一张付款申请单 ；2.申请审核：切换到【付款申请单】选项卡下，选择要审核的付款申请单，点击“申请审核”按钮完成审核；3.出纳付款。 申请付款如下图所示：\n申请审核如下图所示：\n出纳付款如下图所示：\n      08.02.03销售付款\n              销售付款单的新增、修改、删除、查询等操作。操作：录入业务名称、支付方式、付款金额、付款日期、票据号、付款备注等信息，点击”保存“按钮完成。如下图所示：\n      08.02.04退款管理\n                 退款单的新增、修改、删除、查询、打印，以及主管审核、财务审核、出纳付款等操作。退款流程分三步：1.录入新增退款单：点击“新增”按钮，录入业务名称、车架号、金额、备注等信息；2.主管审核； 3.财务审核；4.出纳退款；如下图所示：\n   08.03发票管理\n      08.03.01新车入库发票管理\n             确认已开具的新车入库发票，操作：填入发票号、发票日期、发票金额、税金等信息后，点击“发票确认”按钮完成。	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.261797+08	2026-06-09 13:43:16.261805+08
140	AutoCar汽车经销商管理系统软件使用说明书（第14段）	如下图所示：\n      08.03.02新车销售发票管理\n             确认已开具的新车发票。操作：填入发票号、发票日期、发票金额、税金、发票类别等信息后，点击“发票确认”按钮完成。如下图所示：\n      08.03.03维修发票管理\n             确认已开具的维修发票，如下图所示：\n   08.04确认管理\n   08.04.01零件入库财务确认\n           零件入库单确认，可以点击“修改供应商”按钮修改入库单的供应商，如下图所示：\n  08.04.02整车入库财务确认\n整车入库财务确认，如下图所示：\n市场管理\n09.01会员基础定义\n     基础定义包括会员卡类型定义和积分兑换充值项目定义。会员卡类型定义包括类型名称、工时折扣、材料折扣、所需积分、卡号前缀、有效年限、流水号、会费等属性；积分兑换充值项目定义包括类型、项目名称、积分等属性。如下图所示：\n 09.02会员信息管理\n     会员卡的开通、查询、生效、挂失等操作。会员卡信息包括车牌号、车架号、会员卡名称、会员卡号、生效日期、终止日期等项目。如下图所示：\n 09.03会员积分充值\n     会员积分充值操作的新增、修改、删除、查询、打印等操作。	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.264331+08	2026-06-09 13:43:16.26434+08
141	AutoCar汽车经销商管理系统软件使用说明书（第15段）	如下图所示：\n     09.04会员积分兑换\n     会员积分兑换操作的新增、修改、删除、查询、打印等操作。如下图所示：\n     09.05套餐卡销售管理\n     售后套餐卡的销售操作，包括新增、修改、删除、查询、打印以及结算、工时项目变更、零件项目变更、发票补录操作功能。录入套餐卡销售之前，必须先在系统功能【02.08套餐方案】中设置好套餐方案，否则无法录入。设置如下图所示：\n     09.06现金充值\n     会员现金充操作的新增、修改、删除、查询、打印等操作。如下图所示：\n     09.07优惠券管理\n优惠券的查询、发行、赠送、审核、作废、打印、批量审核等操作。优惠券在发行前，必须先在系统功能【02.07优惠券方案】中设置好优惠券方案，内容包括券名称、发行量、面额等。\n如下图所示：\n     09.08代办业务管理\n     代办业务的新增、修改、删除、查询、打印以及主管审核、结算代付、代办业务结束、发票补录等操作。如下图所示：\n     09.09套餐明细表\n     查询套餐工时和材料明细项目，如下图所示：\n     09.10 DCC线索管理\n     DCC线索的导入、同步、查询，DCC线索客户的跟进，以及导入模板下载等操作。	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.266984+08	2026-06-09 13:43:16.266991+08
142	AutoCar汽车经销商管理系统软件使用说明书（第16段）	线索管理流程步骤：1.按下载的导入模板的格式整理DCC线索并导入系统或同步厂家线索；2.选择要跟踪的线索，点击“跟进客户”录入跟进信息并保存；如下图所示：\n     09.11市场计划管理\n     市场活动计划以及执行情况的录入存档，包括新增、修改、删除、查询以及完结、取消完结、复制等操作。市场活动计划管理流程步骤：1. 市场活动开始前，新增录入活动计划各项内容；2.跟进活动实施情况随时编辑修改活动计划的各项内容；3.活动结束后点击“完结”按钮，在弹出的编辑窗口录入活动实际达成的结果并点击“保存”按钮，流程结束。如下图所示：\n客服管理\n     10.01维修回访\n     售后维修客户回访，操作流程：1.查询出要回访的维修记录；2.选择要确认回访的记录，填写整体满意度、回访状态等各项信息，点击“回访确认”按钮完成回访。如下图所示：\n   10.02新车回访\n     新车客户回访，操作流程：1.查询出要回访的新车记录；2.选择要确认回访的记录，填写整体满意度、回访状态等各项信息，点击“回访确认”按钮完成回访。如下图所示：\n     10.03维修回访统计\n     查询统计维修客户的回访记录，如下图所示：	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.268923+08	2026-06-09 13:43:16.268931+08
168	附件2：《帝豪向上系列产品价值推介》 (1)（第9段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n采用12~25μm 粒径的多种银元型铝粉， 光线下，泛着暖金色\n泽，金属微粒随角度流转，宛如星尘在不断闪烁、呼吸。\n每层色漆厚度误差控制在头发丝直径的 1/30，搭配 2K高光\n清漆，做到“十年如一日”，持久如新\n采用环保水性 B1B2涂装工艺喷涂，德国巴斯夫高耐候涂料\n漆面更炫彩、更高亮、更耐久、更环保全新外观车色 -荣耀金\n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.763434+08	2026-06-09 13:43:19.763443+08
237	销售顾问驾驶仓看板 - 片段1 (00:00)	[视频片段 00:00 - 01:00] 此内容为视频转写片段，请管理员填写文字内容。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\19d16bf3357d4f5e982d87619a4a667d.mp4	李管理		/uploads/19d16bf3357d4f5e982d87619a4a667d.mp4	0	60	批量导入,产品知识库	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 14:00:30.636625+08	2026-06-12 14:00:30.636633+08
143	AutoCar汽车经销商管理系统软件使用说明书（第17段）	10.04销售回访统计\n     查询统计新车销售客户的回访记录，如下图所示：\n     10.05新增客户统计\n     查询统计某时间段内新增的客户，如下图所示：\n     10.06流失客户统计\n     查询统计某时间段内流失的客户，可按设定的客户流失天数进行统计，对统计出来的客户可点击“联系客户”按钮进行回访和登记联系记录。如下图所示：\n     10.07通用客服跟踪\n     通用客服跟踪，可根据用户需要设定各种业务类型的客户跟踪。系统预设好的客户跟踪有首保跟踪、二保跟踪、定期跟踪、客户跟踪、新车订单跟踪、最后客户信息、厂家活动跟踪、续保跟踪、提前30天续保跟踪等。操作步骤：1.选择选择一个要操作的跟踪如续保跟踪；2.选择月份后点击“刷新数据”显示数据；3.在数据显示区点击一条记录后，点击“客户跟进”按钮，在弹出的编辑窗口中录入跟进的相关信息后保存。下图所示：\n     10.08跟进记录查询\n     查询统计客服跟踪的跟进记录，如下图所示：\n     10.09在修在保客户\n     查询统计在修/在保客户，操作步骤：1. 选择的最后进厂日期；2.点击“统计”按钮。	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.270949+08	2026-06-09 13:43:16.270957+08
144	AutoCar汽车经销商管理系统软件使用说明书（第18段）	如下图所示：\n报表中心\n     报表中心提供配件、财务、售后、销售四大类销售报表的查询和打印功能。如下图所示（进货单查询报表）：\n报表分类清单如下：\n     11.01配件报表\n          11.01.01进货单查询\n          11.01.02配件外销单查询\n          11.01.03配件外销退货查询\n          11.01.04库存查询\n          11.01.05历史库存查询\n          11.01.06退返供应商查询\n          11.01.07配件出库总表\n          11.01.08进销存统计\n          11.01.09调仓历史\n          11.01.10库存龄查询\n          11.01.11库存查询（库龄）\n     11.02财务报表\n          11.02.01收款查询\n          11.02.02预收明细账\n          11.02.03预收收支流水账\n          11.02.04优惠券使用记录\n     11.03售后报表\n          11.03.01材料出库查询	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.273082+08	2026-06-09 13:43:16.27309+08
145	AutoCar汽车经销商管理系统软件使用说明书（第19段）	11.03.02维修工时明细\n          11.03.03维修产值查询\n          11.03.04维修结账查询\n          11.03.05维修台次及台数统计\n          11.03.06班组统计\n          11.03.07保单活动明细查询\n          11.03.08售后BO清单\n          11.03.09保单明细\n          11.03.10维修产值按收费类型汇总\n     11.04销售报表\n          11.04.01新车库存表\n          11.04.02新车进库历史\n          11.04.03新车客户信息\n          11.04.04新车订单信息\n          11.04.05新车其他收入及支出\n          11.04.06新车增值业务明细\n          11.04.07新车出库表\n          11.04.08金融明细表\n          11.04.09新车保单明细\n返利管理\n     12.01商务政策变量设定\n     设置主机厂返利政策的变量，系统依据政策变量中设定的条件计算返利销量。	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.276538+08	2026-06-09 13:43:16.276549+08
146	AutoCar汽车经销商管理系统软件使用说明书（第20段）	每个商务政策可以设置多个变量，每个变量可以设置多个计算返利销量的条件。如下图所示：\n     12.02商务政策项目设定\n     设定商务政策的返利项目，每个商务政策可设定多个返利项目。在返利项目中，需要设定项目名称、单台返利金额、数量系数和得到返利需达成的销量条件。如下图所示：\n     12.03返利综合管理\n     依据商务政策设定计算生成预估返利数据，也可在已确认返利中手动添加和删除返利数据，如下图所示：\n     12.04车俩返利管理\n     车辆订单返利的确认（也可手工调整固定返利、预估返利、确认返利），如下图所示：\n填报管理\n     13.01填报模板定义\n     定义数据填报的模板，操作：1.在左侧模板列表中选择一个模板；2.点击“加载excel文件”按钮，选择一个EXCEL文件进行加载，然后点击“保存模板”按钮；3.设置模板和后台数据库中的表以及表中的字段的数据对应关系。如下图所示：\n     13.02数据填报\n     数据填报操作：1.在左侧模板列表中选择要填报的模板。2.点击“提取数据”把系统中的数据提取到编辑区中进行编辑。3.点击“保存”按钮保存数据。	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.279533+08	2026-06-09 13:43:16.279543+08
147	AutoCar汽车经销商管理系统软件使用说明书（第21段）	点击“导出数据”按钮可以导出编辑区的数据，点击“加载EXCEL文件”按钮可以导入外部EXCEL格式的数据。如下图所示：\n综合管理\n     14.01内部车辆管理\n     内部车辆档案的新增、修改、删除、查询以及退役操作等功能，如下图所示：\n     14.02物业租赁管理\n     物业租赁合同的新增、修改、删除、查询以及合同生效、退租、重置明细等功能，如下图所示：\n     14.03建店项目管理\n     建店项目档案记录的新增、修改、删除、查询等操作。如下图所示：\n**通用操作\n切换组织/公司\n当用户有多家公司的使用权限时，登录系统后会弹出如下组织选择窗口：\n鼠标右键菜单\n在数据显示窗口，单击鼠标右键会弹出【右键菜单】，实现一些常用功能的快捷操作。如下图所示：\n菜单功能列表：\n复制内容 复制当前位置的内容到剪贴板，用于后续粘贴操作。\n导出数据 把当前报表中的数据导出到本地EXCEL文件（需要本地电脑安装“下载数据导入驱动”）。如下图所示：\n指定导出数据的文件名和存放位置\n查找记录 在当前报表中查找和输入内容相配的数据。\n查找的方式：从当前位置开始向下查找，重复操作则继续向下查找下一个匹配的数据。	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.281843+08	2026-06-09 13:43:16.281851+08
148	AutoCar汽车经销商管理系统软件使用说明书（第22段）	筛选记录 筛选过滤其他内容，只显示指定的内容。如下图所示：\n筛选后的显示效果\n调整列顺序 调整设置个性化的报表列显示顺序。如下图所示：\n打印表格 打印当前报表内容。\n刷新数据 重新刷新同步最新数据。\n自定义汇总 以用户自定义的列（字符型、可多选）作为统计口径，统计用户自定义的列（数值型、可多选）的合计值。如下图所示：\n------------  结束  -------------	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\AutoCar汽车经销商管理系统软件使用说明书.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.283792+08	2026-06-09 13:43:16.283801+08
149	BI汽车经销商集团管理系统V1.0说明书20260108（第1段）	BI汽车经销商集团管理系统\n版本号：V1.0\n操\n作\n手\n册\n系统登录：\n根据页面提示信息，以用户名、密码方式登录系统，点击界面【登录】按钮，即可进入，如下图所示：\n如果是新用户第一次登陆，需要自行修改密码\n系统功能板块：\n0.集团组织信息管理\n0.1基本组织信息填报\n 填报公司基本信息。如下图所示：\n0.2公司基本情况\n可筛选查询各公司的基本情况。如下图所示：\n0.5数据清单\n0.5.1固定资产清单\n可筛选查询各公司的固定资产情况。如下图所示：\n0.5.2实物资产\n0.5.3代理品牌查询\n可筛选查询代理品牌情况。如下图所示：\n0.5.6公司财产险统计查询\n页面可筛选查询具体公司财产险投保情况，如下图所示：\n当前页面同步显示脱保公司清单、有效保单分布、公司财产险详细信息。如下图所示：\n0.5.10内部车辆清单\n筛选查询公司车辆详细信息，如下图所示：\n0.3人员情况\n0.3.1人员情况\n筛选查询公司人员情况，实时数据，每2小时后台自动同步一次。如下图所示：\n0.3.2人员情况（历史）\n筛选查询公司人员情况历史数据\n0.3.3人员情况月度分析\n筛选查询人员月度情况，如下图所示：0.3.4人员架构	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\BI汽车经销商集团管理系统V1.0说明书20260108.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.775656+08	2026-06-09 13:43:16.775667+08
150	BI汽车经销商集团管理系统V1.0说明书20260108（第2段）	筛选查询各店人员架构情况，如下图所示：\n0.4人效分析\n销售部人效分析\n筛选查询公司销售部的人效情况，如下图所示：\n售后部人效分析\n筛选查询公司售后部的人效情况，如下图所示：\n整车管理\n1.1库存分析\n1.1.1门店实时库存结构\n页面显示各公司实时库存情况，系统实时同步，实时更新，可筛选查询，蓝色字体代表可穿透，能直接穿透进入具体公司的库存结构。如下图所示：\n该页面可查询库存成本结构，分包含已配车和不含已配车资金占用情况，集团库存深度（在库，含在途）、150天以上长库车型。\n如下图所示：\n1.1.3品牌实时库存结构\n可查看各品牌实时库存结构，可分区域筛选具体公司实时库存情况。如下图所示：\n1.1.5门店历史库存结构\n筛选查询公司历史库存情况，蓝色区域可穿透进入查询具体公司历史库存数据情况。如下图所示：\n1.1.6车辆采购计划参考\n输入目标数量后，会自动生成建议计划，如：销售提车目标100台。\n1.2订单台数\n月-订单台数\n(1).筛选查询当月订单情况，分品牌展示，蓝色区域可以渗透，进一步查询当前品牌的不同门店月订单情况。\n如下图所示：\n(2).筛选查询当月订单情况，分公司展示，蓝色区域可以渗透查询单店情况。	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\BI汽车经销商集团管理系统V1.0说明书20260108.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.780668+08	2026-06-09 13:43:16.780679+08
151	BI汽车经销商集团管理系统V1.0说明书20260108（第3段）	如下图所示：\n(3).订单达成柱状图。如下图所示：\n(4).每日订单情况，红色代表周末。如下图所示：\n(5).订单来源大类和小类分类。如下图所示：\n(6).自然进店订单类型分布。如下图所示：\n1.2订单台数\n年-订单台数\n筛选查询年订单情况，分品牌展示数据，蓝色区域可以渗透。进一步查询当前品牌的各店年订单数据，细化到具体车型订单、具体销售顾问订单数。\n如下图所示：\n1.2订单台数\n新车小订汇总：筛选查询品牌新车小订订单、小订转大订等情况\n如下图所示：\n新车小订分公司展示\n如下图所示：\n1.2订单台数\n全员开发贡献订单，蓝色渗透查询具体开发人员\n如下图所示：\n1.2订单台数\n未交车明细，如下图所示：\n1.3交车台数\n1.3.1月-交车台车\n分品牌查询集团月交车台数，蓝色区域可以渗透进入品牌交车明细。如下图所示：\n分公司查询集团月交车台数，蓝色区域可以渗透公司交车明细。如下图所示：\n每日交车分布，红色区域为周末，如下图所示：\n集团各店交车达成情况，柱状图分布，如下图所示：\n集团未交订单天数分布，如下图所示：1.4交车毛利\n1.4.3整车业务毛利汇总按品牌汇总整车业务毛利，可以渗透进入同品牌交车毛利情况、销售顾问交车毛利情况。	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\BI汽车经销商集团管理系统V1.0说明书20260108.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.783251+08	2026-06-09 13:43:16.78326+08
152	BI汽车经销商集团管理系统V1.0说明书20260108（第4段）	如下图所示：\n1.4.4毛利汇总（含水平业务）\n含水平业务毛利汇总，分品牌、分区域、分公司展示，蓝色区域为可渗透内容，从当前界面进入下一层数据查看。\n如下图所示：\n1.5客流分析\n筛选查询各品牌客流情况，如下图所示：集团新增客流数，分公司查询。蓝色区域可以渗透进入下一界面详细查看。如下图所示：\n集团新增客流来源分布。如下图所示：1.6销售顾问\n销售顾问每日战报，按公司筛选查询销售顾问个人战报。渗透查询具体车型零售与集团整体价格情况。如下图所示：\n1.8排名管理\n1.8.1订单排名\n集团订单排名看板，当日新增订单、当月订单、年度累计订单排名。如下图所示：\n1.8.2交车排名：集团交车排名看板，当日交车、当月交车、年度累计交车排名。如下图所示：\n1.8.3交车达成排名\n集团各店交车达成情况，本月达成排名，年度达成排名。如下图所示：\n1.9交付中心\n1.9.1交付中心毛利汇总\n分品牌、分公司展示交付中心毛利情况。蓝色区域可以渗透进入查询同品牌毛利，交付专员毛利。如下图所示：\n1.11厂家任务管理\n1.1.4厂家接车进度\n筛选查询集团各公司接车进度，渗透查询各车型任务达成情况。如下图所示：	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\BI汽车经销商集团管理系统V1.0说明书20260108.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.785519+08	2026-06-09 13:43:16.785528+08
169	附件2：《帝豪向上系列产品价值推介》 (1)（第10段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.766+08	2026-06-09 13:43:19.766012+08
238	销售顾问驾驶仓看板 - 片段2 (01:00)	[视频片段 01:00 - 01:57] 此内容为视频转写片段，请管理员填写文字内容。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\19d16bf3357d4f5e982d87619a4a667d.mp4	李管理		/uploads/19d16bf3357d4f5e982d87619a4a667d.mp4	60	117.88775	批量导入,产品知识库	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 14:00:30.651061+08	2026-06-12 14:00:30.651066+08
153	BI汽车经销商集团管理系统V1.0说明书20260108（第5段）	1.1.5厂家终端任务进度\n筛选查询集团各公司厂家终端任务进度，渗透查询各车型任务达成情况。如下图所示：\n1.12直营集客店\n筛选查询直营集客数据，渗透各直营店的集客输送情况。如下图所示。\n2.售后管理\n2.1维修产值\n2.1.1月-维修产值\n筛选查询集团各公司月维修产值情况，蓝色区域可渗透进下一界面，详细查询公司具体产值情况。如下图所示：集团产值柱状分析图、产值日分布，红色代表周末情况。\n如下图所示：\n产值收入类型分布，蓝色区域可渗透查询各公司同一分类情况。\n如下图所示：\n保险理赔结算台次、不同公司保险赔付率情况。如下图所示：集团待结算工单情况，分天数节点统计。如下图所示：不同驱动方式结算台次占比统计，如下图所示：\n2.1.2月-售后衍生业务\n筛选查询各公司衍生业务情况，蓝色区域渗透进一步筛查\n2.1.3年-维修产值及毛利\n（1）筛选查询集团总维修产值及毛利情况，各公司情况查询，蓝色区域渗透具体明细项目。如下图所示：\n集团毛利汇总、各公司毛利汇总。如下图所示：（3）集团毛利率汇总、各公司毛利率汇总情况。如下图所示：\n2.1.4服务顾问每日战报\n筛选查询服务顾问战报情况，如下图所示：	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\BI汽车经销商集团管理系统V1.0说明书20260108.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.78852+08	2026-06-09 13:43:16.788529+08
154	BI汽车经销商集团管理系统V1.0说明书20260108（第6段）	2.2维修台数\n2.2.1月-进厂数量\n筛选查询集团月进厂数量，渗透查询进厂类型及数量情况。\n2.2.2年-维修结算台数\n筛选查询维修台数，集团整体结算分析、各公司每月终结算情况。\n如下图所示：\n渗透查询具体公司情况。如下图所示：\n2.3维修零件\n2.3.1维修零件-产值及毛利\n筛选查询零件收入、毛利、毛利率情况，集团汇总和各公司情况，蓝色区域可以渗透进入明细。如下图所示：\n2.4工时收入\n2.4.1维修工时收入\n筛选查询维修工时收入情况，如下图所示：维修工时收入占比情况，如下图所示：\n维修工时客单价情况，如下图所示：\n2.5售后业务汇总\n查询各公司售后业务汇总，渗透公司具体明细。如下图所示：查询各公司售后业务汇总，渗透公司具体明细。如下图所示：\n4.水平业务\n4.1延保业务 \n延保分析-交车口径。可筛选查询当月交车中有购买延保的数据。\n如下图所示：\n延保分析-销售口径。可筛选查询当月提车购买+提车后跨月来购买延保的数据。\n如下图所示：\n延保分析-按日分析\n筛选查询各品牌、各公司延保日进度数据分析，如下图所示：延保分析-按月分析\n筛选查询各品牌、各公司延保月进度数据分析，如下图所示：	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\BI汽车经销商集团管理系统V1.0说明书20260108.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.791138+08	2026-06-09 13:43:16.791144+08
155	BI汽车经销商集团管理系统V1.0说明书20260108（第7段）	延保销售顾问排名（交车口径），如下图所示：\n延保销售顾问排名（销售口径），如下图所示：\n4.2用车无忧业务\n用车无忧分析（交车口径）：可筛选分析当月交车中有购买用车无忧的数据。从品牌维度、公司维度，按收入、渗透率排序。如下图所示：\n产品分类饼图：\n用车无忧分析-销售口径。可筛选查询当月提车购买+提车后跨月来购买用车无忧的数据。从品牌、公司维度的收入、渗透率数据。\n如下图所示：\n用车无忧分析-按日分析\n筛选查询各品牌、各公司无忧业务，日进度数据分析\n如下图所示：\n销售第三方产品排名：筛选查询除店内自营数据外，第三方的销售情况。如下图所示：无忧销售顾问排名（交车口径），如下图所示：\n无忧销售顾问排名（销售口径），如下图所示：\n太阳膜升级\n太阳膜升级分析，各品牌渗透率、收入、毛利率分析。如下图所示：\n精品业务-精品管理\n筛选查询各门店精品数据分析。蓝色区域渗透公司具体销售顾问数据。如下图所示：\n目标填报\n用车无忧目标数据填报。如下图所示：\n延保目标数据填报。如下图所示：\n水平汇总\n台次目标达成进表表。各区域和公司水平台次进度分析。如下图所示：\n水平业务汇总，如下图所示：\n水平业务年度汇总，如下图所示：	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\BI汽车经销商集团管理系统V1.0说明书20260108.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.793822+08	2026-06-09 13:43:16.793832+08
156	BI汽车经销商集团管理系统V1.0说明书20260108（第8段）	保险管理\n5.1保单情况。筛选查询集团保单台数、保费金额、情况，各区域和公司保单数据分析，蓝色区域可以渗透进入查询公司具体销售顾问保单数据。如下图所示：\n集团每日总保单、集团各店部保单数据柱状分析。如下图所示：\n集团新保续保台数、新保续保保费分析。如下图所示：\n5.2保费战报。\n分区域分公司的新保续保每日战报分析 ，目标达成率。\n如下图所示：5.3保险月度\n保险月度报告，台数、各公司保费收入。\n如下图所示：\n各保险公司产值、保费占比，如下图所示：5.4保险公司维修工单毛利情况\n各保险公司维修工单分析。如下图所示：\n5.5延保情况\n各公司保险延保情况分析，蓝色区域渗透延保详细信息，包含销售顾问销售详细信息，渗透查询对应客户信息和车型信息。如下图所示：\n5.6目标管理\n5.6.1月度目标管理，各区域公司月度目标。如下图所示：\n客户管理\n6.1基盘客户分析\n客户基盘信息，集团汇总，到各店汇总情况。如下图所示：\n6.2客户公里数情况\n按结算日期，取区间最后一次进厂的公里数。如下图所示：\n返利管理\n7.1集团返利\n筛选查询集团及各店返利情况。如下图所示：\n各店各项返利汇总，蓝色区域可以渗透。如下图所示：	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\BI汽车经销商集团管理系统V1.0说明书20260108.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.799536+08	2026-06-09 13:43:16.799546+08
170	附件2：《帝豪向上系列产品价值推介》 (1)（第11段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n全新主题内饰 -锦绣前橙\n以明亮而温润的色彩唤醒座舱氛围，从座椅到饰板，从缝线到纹理，每一处对蕴藏对未来的美好期许\n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.768083+08	2026-06-09 13:43:19.768092+08
157	BI汽车经销商集团管理系统V1.0说明书20260108（第9段）	蓝色区域渗透进入详细明细。如下图所示：\nMP5预估其他返利汇总，可以渗透查询具体返利内容情况。如下图所示：\n9.零件管理\n9.1零件库龄\n筛选查询各公司零件库存情况，包括库龄天数和库存金额。如下图所示：\n呆滞库存分析报表\n配件呆滞库存数量和金额分析报表，如下图所示：\n10.总经理\n10.1整车排名\n10.1.1集团订单排名，当日订单、月订单、年订单排名。如下图所示：\n10.1.2集团交车排名。当日交车、月交车、年交车排名。如下图所示：\n10.1.3集团交车达成排名。月交车排名、年交车排名。如下图所示：\n10.2售后排名\n10.2.1集团售后产值排名\n当日产值、月产值、年产值排名。如下图所示：\n10.2.2集团售后产值达成排名。如下图所示：\n10.3业务数据总览\n销售、售后业务数据总览。如下图所示：\n行业数据管理\n10.4乘用车销量\n筛选查询乘用车销量数据。如下图所示：\n筛选查询全国皮卡月度销量数据。如下图所示：\n筛选查询全国皮卡年度销量数据。如下图所示：\n11.金融管理\n11.1集团按揭水平分析表\n筛选查询集团按揭渗透率、收入、金融按揭分类类型分析。\n如下图所示：\n11.2集团按揭水平年度分析表	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\BI汽车经销商集团管理系统V1.0说明书20260108.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.80366+08	2026-06-09 13:43:16.80367+08
158	BI汽车经销商集团管理系统V1.0说明书20260108（第10段）	筛选查询集团按揭年渗透率、收入、各店按揭详细数据分析。\n如下图所示：\n金融渠道分析，渗透查询各渠道、各公司详细台账。如下图所示：\n11.3排名管理\n11.3.1按揭台数月度排名、年度排名。如下图所示：\n11.3.2按揭渗透率月度排名、年度排名。如下图所示：\n11.3.3金融按揭收入月度排名、年度排名。如下图所示：\n11.3.4金融单台收入月度排名、年度排名。如下图所示：11.3.5金融除返后收入月度排名、年度排名。如下图所示：11.3.6金融除返后单台收入月度排名、年度排名。如下图所示：11.3.7按揭返佣系统月度排名、年度排名。如下图所示：\n11.3.8按揭除返后返佣系数月度排名、年度排名。如下图所示：\n12.营销管理\n12.1.1节点活动\n1.活动查询。查询各品牌门店活动信息情况。如下图所示：\n2.活动创建。创建活动信息。如下图所示：\n3.目标填报。填报活动目标。如下图所示：\n4.活动汇总。填写活动汇总情况。如下图所示：\n12.2预算管理。\n预算计划。各公司市场预算明细表。如下图所示：2.执行总结。各公司市场实际执行情况明细表。如下图所示：\n可以渗透进入当前公司详细数据分析。如下图所示：	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\BI汽车经销商集团管理系统V1.0说明书20260108.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.806509+08	2026-06-09 13:43:16.806518+08
159	BI汽车经销商集团管理系统V1.0说明书20260108（第11段）	3.预算与实际对比。各公司市场预算与实际执行对比表。如下图所示：4.计划项目一览。筛选查询各区域各公司月度计划。如下图所示：\n12.3排名管理\n1.费用排名\n2.订单排名：网销月度订单、年度订单排名。如下图所示：3.线索排名：当期线索、年度线索排名。如下图所示：\n4.线索成本排名：当期线索单价、年度线索单价排名。如下图所示：\n5.订单成本排名：当期订单单价、年度订单单价排名。如下图所示：\n总结报告\n13.1集团总览\n集团数据总览看板，如下图所示。\n13.2销售报告：销售版块看板。如下图所示：13.3售后报告：售后版块看板。如下图所示：\n14.盘点管理\n盘点汇总填报，如下图所示：集团盘点汇总表，如下图所示：\n资金管理\n在途资金管理\n筛选查询刷卡在途金额，蓝色区域渗透进入明细查询。如下图所示：清算金额商户统计\n清算对账商户资金汇总。渗透查询清算金额详细列表。如下图所示：\n在途与清算对比。如下图所示：银行账户资金。\n筛选查询各公司银行资金交易情况，渗透查询每个账户交易情况。如下图所示：\n厂家账户管理\n筛选查询各公司销售、配件厂家账户余额情况，如下图所示：\n19.综合管理\n建店管理	text	1	\N	public	manual	D:\\合群集团资料\\软件说明资料\\BI汽车经销商集团管理系统V1.0说明书20260108.docx	系统导入	\N	\N	0	0	批量导入,软件说明资料	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:16.809383+08	2026-06-09 13:43:16.809394+08
160	附件2：《帝豪向上系列产品价值推介》 (1)（第1段）	帝豪向上系列\n产品价值推介\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.740721+08	2026-06-09 13:43:19.740732+08
161	附件2：《帝豪向上系列产品价值推介》 (1)（第2段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.743765+08	2026-06-09 13:43:19.74377+08
162	附件2：《帝豪向上系列产品价值推介》 (1)（第3段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.74892+08	2026-06-09 13:43:19.748932+08
239	销售经理驾驶仓数据分析看板 - 片段1 (00:02)	銷售經理駕駛艙數據看板,手機和電腦端已同步上線。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	2.9	8.3	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.487072+08	2026-06-12 14:31:07.487079+08
171	附件2：《帝豪向上系列产品价值推介》 (1)（第12段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.769624+08	2026-06-09 13:43:19.769632+08
172	附件2：《帝豪向上系列产品价值推介》 (1)（第13段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n帝豪向上系列\n目标人群 本地居住，家庭稳定的 30-40岁已婚已育首购男性用户为主\n冠军颜值\n（开创 A级轿车宽体低趴风时代）\n产品USP产品定位 全球品质冠军家轿\n自主：长安第二代 *动合资：轩*经典、朗逸 *锐 核心竞品	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.771479+08	2026-06-09 13:43:19.771483+08
173	附件2：《帝豪向上系列产品价值推介》 (1)（第14段）	3大\n核心卖点传播\nSlogan产品信息屋\n超强全球架构\nBMA全球模块化架构，操控好，空间大超低用车成本\n搭载1.5L直列四缸发动机，动力足，油耗低超强科技体验\n银河OS车机系统，屏幕大，响应快\n•流云飞瀑前格栅\n•上弦新月装饰设计\n•全新荣耀金车色\n•全新锦绣前橙主题内饰\n•“2宽2低”，塑造整车大气风范\n•1820mm 同级最宽车身\n•1.24同级最大宽高比\n•低重心设计：重心降低，跑起来更稳\n•低风阻设计： 0.27Cd同级最低风阻•1.5L直列四缸发动机\n•88kW同级最大功率\n•150N·m 同级最大扭矩\n•同级最强 20000N·m/deg 车身扭转刚\n度\n•高强度钢材使用量远超同级自主品牌\n•车顶激光焊接可承受自身 2.5倍重量的\n压力，国标仅为 1.5倍\n•26处智慧储物空间冠军架构\n（BMA 全新一代模块化架构）\n•5G+智造工厂“双零双百”\n•0偏差精致冲压\n•0污染绿色涂装\n•100%自动化雷霆焊装\n•100%大数据精益总装\n•中汽研可靠性管理流程认证\n•国内首款获得中汽研汽车可靠性管理\n流程认证的汽车冠军品质\n（5G+智造工厂“双零双百”）\n•12.3英寸中控屏	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.773369+08	2026-06-09 13:43:19.773373+08
174	附件2：《帝豪向上系列产品价值推介》 (1)（第15段）	•8.8英寸高清数字仪表\n•540°上帝之眼透明底盘\n•手机APP远程控制\n•智能语音交互\n•可见即可说\n•多条件语同音搜索\n•上下文跨场景对话\n•多轮连续对话冠军科技\n（家轿智能座舱天花板）\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.77523+08	2026-06-09 13:43:19.775236+08
175	附件2：《帝豪向上系列产品价值推介》 (1)（第16段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.778243+08	2026-06-09 13:43:19.778254+08
176	附件2：《帝豪向上系列产品价值推介》 (1)（第17段）	超宽车身造就帝豪 1500mm 同级\n最宽后排乘坐空间，乘坐更宽敞\n动感流畅的车身姿态，宽体低趴\n更显整车大气风范\n同级最低风阻系数\n 0.27Cd\n更好驾控、更省油\n车身重心降低\n 70mm\n，跑起来更稳冠军颜值 -宽体低趴引领者\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.780432+08	2026-06-09 13:43:19.780441+08
177	附件2：《帝豪向上系列产品价值推介》 (1)（第18段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.782352+08	2026-06-09 13:43:19.782358+08
178	附件2：《帝豪向上系列产品价值推介》 (1)（第19段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n0.618黄金视觉分割 线，极致线条 从前翼\n子板延伸至尾部， 行云流水，灵动非凡熏黑工艺搭配 190颗LED灯珠， 0.1秒极\n速点亮，犹如暗夜烟火，瞬间璀璨\n极简美学，打造更舒展的视觉空间，更\n科技的行车操控，无线延伸，无限想象冠军颜值 -三大科技贯穿线\n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.784115+08	2026-06-09 13:43:19.784122+08
179	附件2：《帝豪向上系列产品价值推介》 (1)（第20段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.78602+08	2026-06-09 13:43:19.786029+08
180	附件2：《帝豪向上系列产品价值推介》 (1)（第21段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n2026/5/18 10\n个 国 家\n 架 构 工 程 师\n 正向研发\n全 球 新 一 代 模 块 化 架 构\n冠军架构 -BMA架构\n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.788463+08	2026-06-09 13:43:19.788471+08
181	附件2：《帝豪向上系列产品价值推介》 (1)（第22段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.790339+08	2026-06-09 13:43:19.790348+08
182	附件2：《帝豪向上系列产品价值推介》 (1)（第23段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n贯通门板的储物空间 ，放一整排矿泉水也是毫无压力\n 别人放不了的脉动 ，我能放好多瓶 ，超大储物 ，随心所欲\n完美解决手机、纸巾等无处放置的尴尬，上下两层置物格更灵活\n 再也不用担心外卖无处放置或洒落 ，悬空置放 ，稳定又能保持车内整洁冠军架构 -26处储物空间	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.792063+08	2026-06-09 13:43:19.79207+08
183	附件2：《帝豪向上系列产品价值推介》 (1)（第24段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.79394+08	2026-06-09 13:43:19.793945+08
184	附件2：《帝豪向上系列产品价值推介》 (1)（第25段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.79588+08	2026-06-09 13:43:19.795888+08
185	附件2：《帝豪向上系列产品价值推介》 (1)（第26段）	2026/5/18 12\n使用量远超自主品牌，比肩合资水平\n 可承受自身 2.5倍重量的压力，国标仅为 1.5倍\n 同级最强 20000N·m/deg\n冠军架构 -更强车身、更稳架构\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.79754+08	2026-06-09 13:43:19.797548+08
186	附件2：《帝豪向上系列产品价值推介》 (1)（第27段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.799189+08	2026-06-09 13:43:19.799196+08
195	附件2：《帝豪向上系列产品价值推介》 (1)（第36段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.816914+08	2026-06-09 13:43:19.816919+08
187	附件2：《帝豪向上系列产品价值推介》 (1)（第28段）	阿特金森循环、歧管喷射系统等十\n项核心技术加持，动力极速响应\n采用发动机静音链条，精细的设计保\n证发动机 800h耐久前后 NVH无变化通过3000次冷热冲击试验、 800小\n时交变负荷试验等，安全耐久\n阿特金森循环 +电子水泵热管理系统，\n实现燃料与发动机能耗的双重节能冠军架构 -全新1.5L直列四缸自吸发动机\n最大功率（\n kW\n）\n最大\n扭矩\n（\nN.m\n）\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.800768+08	2026-06-09 13:43:19.800775+08
188	附件2：《帝豪向上系列产品价值推介》 (1)（第29段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.802998+08	2026-06-09 13:43:19.803007+08
189	附件2：《帝豪向上系列产品价值推介》 (1)（第30段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n2026/5/18 14\n45台杜尔机器人自动化喷涂，极致透亮漆面\n 精致冲压无偏差，锻造 3mmR角锐棱腰线\n504台KUKA机器人实现 100%自动化焊接，打造同级最小 3.5mm间隙\n 5G环网接入，零件 100%透明，装配 0缺陷冠军品质 -5G+智造工厂“双零双百”\n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.80486+08	2026-06-09 13:43:19.804868+08
190	附件2：《帝豪向上系列产品价值推介》 (1)（第31段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.806817+08	2026-06-09 13:43:19.806826+08
191	附件2：《帝豪向上系列产品价值推介》 (1)（第32段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n高清液晶显示屏，视界宽广更好看；人机工程学设计，减少驾驶视线偏移\n 行车数据、时速、里程等关键信息一目了然，驾驶更从容\n底盘路况清晰可见，过窄弯盲巷不困难\n 支持远程查询车辆状态、开 /关车锁、开 /关空调、开 /关车窗等冠军科技 -越级科技体验	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.808483+08	2026-06-09 13:43:19.808491+08
192	附件2：《帝豪向上系列产品价值推介》 (1)（第33段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.811415+08	2026-06-09 13:43:19.811424+08
193	附件2：《帝豪向上系列产品价值推介》 (1)（第34段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.813562+08	2026-06-09 13:43:19.813567+08
194	附件2：《帝豪向上系列产品价值推介》 (1)（第35段）	颜值高\n帝豪家族上市 16年，全球销量超 420万，畅销海内外 30国 1.24同级最大宽高比，媲美豪车的宽体低趴姿态，动感流畅\n动力猛\n全新1.5L直列四缸发动机， 88kW最大功率， 150N·m 超大扭矩\n驾控稳\nBMA全球新一代模块化架构，中欧专家舒适性底盘调校\n储物多\n26处智慧储物空间，每一处都采用多 50%设计理念\n内饰豪\n锦绣前橙主题内饰，奢侈品同款绗缝工艺，彰显豪华尊贵\n安全强\n同级最强 20000N·m/deg 车身扭转刚度，更强车身更稳架构\n智控炫\n8.8+12.3 英寸双大屏，搭载同级最强吉利银河 OS车机系统\n空间大\n1500mm 同级最大后排乘坐空间，三人乘坐也舒适\n品质硬\n5G+智造工厂制造， 2023 -2024年连续两年荣获 J.D.Power\n中国汽车产品魅力指数研究紧凑型轿车 TOP1\n销量好10大心动理由\n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.815339+08	2026-06-09 13:43:19.815344+08
222	car_policy	车型:GS3影速;指导价:10.8万;限时价:9.8万;金融方案:0首付8万3年0息\n车型:GS4 MAX;指导价:12.58万;限时价:10.28万;金融方案:至高置换补贴20000\n车型:旗舰版;指导价:12.58万;限时价:优惠至高6888红包;金融方案:金融礼+置换礼	text	12	\N	sales	manual	D:\\HqEvoAI\\uploads\\52438cb1998d4bb49581b8b7381f01d7.xlsx	李管理	\N	\N	0	0	批量导入,金融按揭方案	\N	\N	1	0	0	approved	\N	\N	1	2026-06-11 12:38:49.330969+08	2026-06-11 12:38:49.330975+08
196	附件2：《帝豪向上系列产品价值推介》 (1)（第37段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n1\n句话必讲 ：\n3\n句话推荐：\n✓\n上市16年帝豪家族销量超过 420万，畅销海外 30国，是卖的最好的中国轿车，高品质经过全球认证！\n✓\n外观大气，内饰豪华，\n 6\n万级唯一配备\n 540\n°\n透明底盘、\n 12.3\n液晶大屏、银河	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.818313+08	2026-06-09 13:43:19.818318+08
197	附件2：《帝豪向上系列产品价值推介》 (1)（第38段）	OS\n等豪华配置，\n 6\n万的价格\n 10\n万的体\n验！\n✓\n全新\n1.5L\n发动机，动力足油耗低，一公里仅\n 4\n毛；\nBMA\n全球模块架构，欧洲底盘调校，还可享\n 4\n年或\n15\n万公里整\n车质保，好开耐操！\n4\n个主要卖点：冠军颜值\n |  \n冠军架构\n |  \n冠军品质\n |  \n冠军科技\n一分钟产品推介\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.819764+08	2026-06-09 13:43:19.819769+08
198	附件2：《帝豪向上系列产品价值推介》 (1)（第39段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.821023+08	2026-06-09 13:43:19.821027+08
199	附件2：《帝豪向上系列产品价值推介》 (1)（第40段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.822224+08	2026-06-09 13:43:19.822228+08
200	附件2：《帝豪向上系列产品价值推介》 (1)（第41段）	海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.82341+08	2026-06-09 13:43:19.823414+08
201	附件2：《帝豪向上系列产品价值推介》 (1)（第42段）	海南合众汽车销售有限公司_赵宇飞	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\附件2：《帝豪向上系列产品价值推介》 (1).pdf	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.825317+08	2026-06-09 13:43:19.825325+08
202	（新）星瑞 i-HEV智擎混动-核心卖点话术（第1段）	*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：星瑞 i-HEV智擎混动核心卖点话术\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：销售必讲1+4；列1：一句话推介；列2：AI智擎新一代，将彻底颠覆传统混动，在节能、智能、电感、安全与品质五大方面，都将为用户带来颠覆式的体验！\n列1：四句话必讲；列2：1、8成时间带电跑，节能安全又可靠\n2、星瑞是中国品牌燃油轿车销量冠军\n3、AI智擎新一代，2L纪录保持者\n4、买混动，选星瑞 i-HEV智擎混动就对了\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：模块；列1：十大核心亮点；列2：推介话术\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：架构；列1：i-CMA架构；列2：N+I：很多用户开轿车时觉得底盘松散易晃，过弯侧倾大，家人容易晕车，而且老平台车型很难兼顾操控精准度和乘坐舒适性，日常通勤和家庭出游都受影响\nFAB：星瑞 i-HEV智擎混动基于i-CMA专属架构打造，搭配前麦弗逊+后多连杆独立悬架，底盘滤震干脆不拖泥带水，过弯时车身姿态稳定，麋鹿测试成绩达78km/h，既能保证您驾驶时的精准操控感，又能让家人乘坐不晕车，全场景用车都舒适	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\（新）星瑞 i-HEV智擎混动-核心卖点话术.xlsx	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.873169+08	2026-06-09 13:43:19.873179+08
224	传祺-2025年12月销售政策通知	--- 第1页 ---\n2026款GS3影速 制定话术进行客户邀约，扩大市场开口 成！12月重点事项如下 全力提升终端销量！请全体销售店坚定信心，把握旺季销售机遇，石 尊敬的销售店董事长、总经理 邮政编码：511434 电话：86-020-39206114 地址：广州市番禺区金山大道东路633号 广州汽车集团股份有限公司传祺营销本部 GS4 MAX 影豹 车型 12月各车型对客促销宣传内容如下，请销售店严格保持统一的宣传口径 2025年12月销售政策具体内容如下 广汽传祺 持续强化本地销售，稳定市场秩序 聚焦重点车型，促进销量提升 坚持终端导向，抢抓旺季机会 R-style版指导价12.8万元，限时价10.8万元 终身免费基础流量、娱乐流量3年免费（6G/月） 旗舰版指导价12.58万元，限时价10.28万元 限时红包礼：12月1日-12月25日限时抢至高6888元购车红包 终身免费基础流量、娱乐流量3年免费（6G/月，无车联网功能车型除外） R-Style劲享版指导价11.8万元，限时价9.8万元 限时红包礼：12月1日-12月25日限时抢至高6888元购车红包 领航版指导价11.58万元，限时价9.28万元 金融礼：可享0首付，至高8万3年0息 智美流量礼：终身免费基础流量、3年免费娱乐流量（6G/月，无车联网功能 智美金融礼：可享0首付，至高8万3年0息 12月感恩礼：12月感恩补贴6000元 智美补贴礼：至高补贴10000元 车型除外） 限时红包礼：12月1日-12月25日限时抢至高6888元购车红包 2025年12月销售政策通知 第一部分 12月宣传内容 对客促销宣传 确保目标达 厂家直接赠送 零售金融支持 厂家直接赠送 厂家直接赠送 零售金融支持 限时抽奖 提车折扣 限时抽奖 提车折扣 终端支持 限时抽奖 提车折扣 政策来源 J-YX2025129\n\n--- 第2页 ---\n向往S7PRO+系300万元全场景智行保障（仅限激光雷达版） （含领秀、大师、 E8（荣耀） E8 (PHEV) M8 系列 GS8 系列 M6 系列 宗师) 广汽传祺 无忧保障礼：混动车型三电终身质保（首任非营运车车主） 终身免费系统OTA升级、不限量基础流量、3年免费娱乐流量（6G/月） 保（非首任车主、非营运车）、3年10万公里整车质保（非营运车） 排冰箱+吸顶电视+隐藏款记录仪） 身免费系统OTA升级、不限量基础流量、3年免费娱乐流量（6G/月） 公里质保（非首任车主、 上门取送车 除外） 流量礼：终身免费基础流量，3年免费娱乐流量（6G/月，无车联网功能车型 置换礼：置换补贴至高20000元 限时红包礼：12月1日-12月25日限时抢至高6888元购车红包 【满电畅玩“配套礼”】终身免费远程车控、在线导航、智能语音在线、终 服务礼：5年免费道路救援服务 流量礼：终身免费基础流量，3年免费娱乐流量（6G/月） 限时补贴礼：限时补贴15000元 【全场景安心智行】价值25000元城区NDA免费送（仅限激光雷达版），至高 质保礼：5年或15万公里整车质保 置换礼：置换补贴15000元 限时红包礼：12月1日-12月25日限时抢至高6888元购车红包 【流量随心享】终身不限量基础流量，3年每月15G娱乐流量 【安心用车质保】首任车主三电终身质保（仅限非营运车车主享受） 【活力畅玩礼】终身免费远程车控、在线导航、智能语音在线 【无忧售后礼】三电终身质保（首任非营运车车主）、三电8年15万公里质 【幸福专享“置换礼”】置换补贴10000元 限时补贴礼：至高补贴19000元 【全天候尊享服务】7x24小时厂家直服、道路救援终身保障、首年维保免费 【金融专享】10万5年0息 【终身无忧“售后礼”】 置换礼：置换补贴至高8000元 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 【超级置换礼】全品牌置换补贴20000元（仅限E8MAX+车型） 限时红包礼：12月1日-12月25日限时抢至高6888元购车红包 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 、非营运车）、3年10万公里整车质保（非营运车） 】三电终身质保（首任非营运车车主）、三电8年15万 12 月宣传内容 提车折扣+超级置 提车折扣+目标达 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 零售金融支持 厂家直接赠送 置换支持政策 厂家直接赠送 厂家直接赠送 厂家直接赠送 用品权益支持 厂家直接赠送 厂家直接赠送 置换支持政策 厂家直接赠送 厂家直接赠送 厂家直接赠送 置换支持政策 置换支持政策 限时抽奖 限时抽奖 限时抽奖 限时抽奖 限时抽奖 提车折扣 限时抽奖 换权益 政策来源 成激励 J-YX2025129\n\n--- 第3页 ---\n向往M8乾、鸿【超级置换礼】全品牌置换补贴30000元 向往M8宗师 （不含PRO+系 蒙座舱版 向往 S9 向往 S7 列） 车型 广汽传祺 终身免费系统OTA升级、终身免费不限量基础流量、3年6G/月免费娱乐流量 在线、终身免费系统OTA升级、终身免费不限量基础流量、3年15G/月免费 送车，3年免费道路救援 免费道路救援、首年维保免费上门取送车 娱乐流量 年免费道路救援、首年维保免费上门取送车 座椅，16扬声器音响，智能冷暖9.0L车载冰箱 场景智行保障 率0-1.3% 享受灵活订阅：连续包月499元/月，月卡720元/月，年卡4999元/年（无乾 昆智驾ADS高阶功能包的版本除外) 【乐享智联礼】终身免费远程车控、终身免费在线导航、终身免费智能语音 【服务礼】5年或15万公里整车质保、首任非营运车主三电终身质保、5年 【无忧保障礼】首任车主三电终身质保（非营运车），首年维保免费上门取 【豪华升级礼】鸿蒙座舱版赠送价值2万元选装包：二排DeepSoft双零重力 【智联礼】终身免费基础流量，3年免费娱乐流量（15G/月） 【乐享智联礼】终身免费远程车控、终身免费在线导航、终身免费智能语音在线 300万元全场景智行保障（不适用于无智能辅助驾驶功能的版本） 【智行礼】价值20000元华为乾鼠智驾ADS4高阶功能包补贴至高300万元全 【置换礼】广汽品牌置换补贴15000元，其它品牌置换补贴10000元 【奢享贵宾礼】十大城市机场接送、7×24小时厂家专属团队服务 【尊享金融礼】首付30%起，至高3年0息；0首付起，12-60期可享超低费 【金融礼】0首付起，12-60期超低息 【选装礼】限时免费选装价值6000元黑夜骑士外饰 【无忧保障礼】整车5年15万公里质保、首任非营运车主三电终身质保、 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 【轻松置换礼】置换补贴至高20000元 【安心智行礼】可享至高300万元全场景智行保障 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 【高阶智驾礼】价值25000元智驾系统免费送 【安心智行礼】可享至高300万元全场景智行保障（不含鸿蒙座舱版） 【高阶智驾礼】限时享20000元华为乾鼠智驾ADS高阶功能包补贴权益 上门取送车 【流量随心享】终身不限量基础流量，3年每月15G娱乐流量 【全天候尊享服务】7x24小时厂家直服、道路救援终身保障、首年维保免费 【安心用车质保】首任车主三电终身质保（仅限非营运车车主享受 【全场景安心智行】价值25000元城区NDA免费送（仅限激光雷达版），至高 【金融专享】0首付+84超长期，1-5年超低息（年费率2.5%） 【限时置换礼】置换补贴10000元 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 【限时补贴礼】限时补贴6000元 【保险礼】保险补贴至高5000元 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 12 月宣传内容 超级置换购车权益 零售金融支持 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 置换支持政策 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 零售金融支持 置换支持政策 厂家直接赠送 零售金融支持 厂家直接赠送 置换支持政策 厂家直接赠送 限时保险补贴 限时抽奖 限时抽奖 限时抽奖 提车折扣 限时抽奖 政策来源 J-YX2025129\n\n--- 第4页 ---\n适用用户 适用车型 投诉；若店端未按要求做好活动执行导致客户投诉或其他负面影响，将取消相应的政策支持 支持时间 开票上报，过期奖品将自动失效 将不享受本次活动支持 等渠道留资后即可参与抽奖 活动车型： 活动时间 四等奖 三等奖 二等奖 特等奖 奖项 4、销售店须注意客户抽奖、下订、终端的手机号码等核心信息需保持一致； 特别说明 购置税兜底政策【延续】 等奖 、销售店须配合开展线上线下宣传，并做好客户说明工作，避免客户对活动产生疑问及 、11月30日24点前已生成系统的订单和终端，退订/退货后在本次活动期间重新下订 、特殊折扣车辆不参与本次活动，活动详细操作请参考附件活动操作指引 12月限时抽奖活动【新增】 广汽传祺 客户中奖后，须在12月1日-25日下订生成订单，并在12月31日24点前完成终端 E系列、向往系列车型由对应的收订店享受支持 ：12月1日-31日在广汽传祺APP或小程序完成下订的用户 日：2025年12月 ：广汽传祺全系在售车型 向往S7、 12 2088元红包 2688元红包 3088元红包 1688元红包 6888元红包 红包金额 日-25日抽奖并下订，12 向往S9、「 销售店承担 （元/台） 第二部分 向往M8、E8 PHEV、E9、ES9、埃安i60、埃安RT 1000 厂家支持标 准（元/台） 对店支持政策 1688 1088 2088 688 5888 31日前实现终端销售 主机厂根据活动期间的抽奖、订 的红包金额支持 单和终端实绩，给予销售店相应 先行全额兑现给中奖客户，后续 2、销售店须根据客户中奖金额 随机产生中奖结果; 备注 J-YX2025129\n\n--- 第5页 ---\nM8宗师（不含至尊、超级混动、先锋） 条件的终端车辆（客户信息一致的前提下）进行结算，通过折扣池或佣金方式 据订单信息、 支持时间：2025年12月 对收订店进行结算 操作方式：销售店对符合条件的客户兑现补贴金额， 向往S7（不含205kmPro+系列、115kmPro版) 向往M8乾鼠MAX奢享舱、Ultra头等舱 补贴标准： 月14日期间开票交付 向往M8鸿蒙座舱版、乾鼠PRO舒享舱 生效条件： E9超级快充尊享版、冠军版 M8大师（不含至尊、尊贵） 向往S7（205kmPro+系列） 24款M8领秀、领秀行政版 基础支持政策【延续】 M8宗师至尊及超级混动版 GS3影速（不含2026款） 向往S7（115kmPro版） GS3影速（2026款） 一汽传祺 E9超级快充宗师版 2024款GS8(7座版） M8大师超级混动版 2025款GS8(5座版) M8大师尊贵版 E8PHEV系列 E8荣耀系列 向往M8宗师 因广汽生产、运输等非用户原因，导致订单车辆在2026年1月1日至2 影豹2.0T 影豹1.5T 按车辆购置税50%计算（上限15000元） M6 系列 GS4 MAX 车型 12月 1日 （含） ）前的车辆供应信息、库存信息进行匹配，又 提车折扣 23000 22000 28000 55000 40000 18000 18000 12000 12000 20000 10000 18000 8000 8000 6000 6000 11500 基础佣金 15000 5000 5000 4000 5000 4000 10000 人员佣金 ，厂家在实现终端的次月根 2000 2000 购车权益 终端激励 10000 12000 3000 10000 合计(元/台) J-YX2025129 22000 28000 23000 21000 20000 55000 30000 28000 40000 12000 12000 12000 11500 对符合 11000 14000 17000 11000 18000 5000 4000 8000\n\n--- 第6页 ---\nS7（115km PR0版、205km Pro+系列) 支持时间：2025年12月 支持标准：# Pro版终端激励由收订店享受（按月结算） 库存店结算差额（GS4MAX、影豹1.5T截至2024年10月31日的店库存不再差额结算） 政策）；针对2025年11月30日24:00销售店库存车辆，若之前提车时已享受的“提车折扣+ M8宗师（不含先锋版、双擎） 2、各车型支持标准=基础奖励标准X全系车型达成系数(E系列和向往系列由收订店享受政策） 1、独立运营的新能源体验中心(即无实际主店)，不考核批发达成率 说明： 23款M6PRO、M6MAX尊荣版 24款M8领秀、领秀行政版 4、提车折扣含本地牌照奖（1.5%)，具体考核规则见《2025年商务政策手册》。 目标达成激励【调整】 向往S9（不含Ultra 5座） M8大师（不含至尊版） 25款GS8燃油(5座版) 24款GS8燃油(7座版) 广汽传祺 购车权益/终端激励：M8系列、向往M8宗师按终端实绩进行周度核销，向往S7115km 提车折扣：12月各车型提车价格=市场指导价－提车折扣（特殊折扣车辆不享受此 基础佣金、人员佣金：在车辆实现终端交付后给予对应收订店佣金奖励： E9国宾定制/科技关爱 向往S9Ultra 5座 ES9龙鳞翼造型 E8 PHEV 系列 S7 其他版本 E8 荣耀系列 按终端实绩计算奖励 GS3 影速 车型 车型 提车折扣 40000 40000 12 月基础奖 14000 励标准 3000 8000 1000 4000 13500 2000 4500 基础佣金 8000 5000 考核，按照如下系数奖励： 基于市场变化，12月暂缓终端达成率 12月全系批发达成率 T 人员佣金 T<95% T≥95% 全系车型达成系数 终端激励 购车权益 合计(元/台) J-YX2025129 系数 40000 0. 6 8000 40000 1. 0 5000\n\n--- 第7页 ---\n按金融申请时间核算 说明 向往 S7 PRO+ 向往M8 宗师 支持时间 际达成情况差额结算 （乾、鸿蒙座 第二代 GS8 （非PRO+） M6 系列 M8 系列 GS3 影速 详情请参考《2025年12月水平事业营销指引》 向往 S7 PRO+、「 向往M8 向往 S7 舱版) 4、每周按终端实绩×基础奖励标准X60%进行预付（新能源直销车辆除外），月度结束后根据实 影豹 车型 零售金融支持【调整】 b、销售店从科技公司买断的车辆 a、通过科技公司提车并当月由科技公司实现终端上报的销量(计入收订店)： 通过科技公司的批发数：包括以下情况 自店批发数：包括所有销售店自店从厂家提车的燃油车型、E系列、向往系列车型 全系批发达成率=【自店批发数+通过科技公司的批发数】一全系批发目标 广汽传祺 ：2025年12月 年费率1.8% C-5. 99% C-5. 99% 贴息产品 大额贷 大额贷 大额贷 大额贷 大额贷 向往M8（乾、鸿蒙座舱版）0息产品按订单时间结算，其余车型/产品 大额贷 其他 首付30%起，至高3年0息 10万5年0息 4000（含联合贴息1000） 4000（含联合贴息1000） 贴息标准 8700（限额15%） 单台贴息上限 2000 5000 2000 3000 9000 4000 4000 5000 7000 广汽汇理 汽金 广汽汇理 支持金融机构 8. 99%) ／（利率 租赁 中国银行 J-YX2025129 省门店） （限广东 XXX/XIX/X/XX\n\n--- 第8页 ---\n型支持标准抵扣客户的购车尾款，其中差额由厂家与科技公司结算 意上传系统必备材料后直接通过，后续不需补充其他置换资料。科技公司开票直接按相应车 特别说明：超级置换购车权益不需要实际审核“置换材料”，其中： 七、超级置换购车权益【调整】 向往M8乾昆、鸿 进口车型，详见水平事业指引清单。 向往S7（不含205kmPro+系列） 支持标准 支持时间 六、 25款GS8燃油（五座版） 24款GS8燃油（七座版） 蒙座舱版 支持车型 2、E9超级快充/国宾定制/科技关爱版不提供置换支持。 E8 MAX+ 、置换支持【调整】 详情请参考《2025年12月水平事业营销指引》 非直销模式下（销售店开票），不需提交任何置换资料，按终端实际核销到终端店 直销模式下（科技公司开票），APP线上置换抵扣功能正常开启抵扣功能，每一单都可任 E8系列（不含MAX+) 、广汽品牌车型包含广汽集团旗下所有车型（含自主及合资车型），以及三菱/菲亚特/JEEP品牌 23款E9、24款E9 、车型支持时间以系统正式下订的订单时间为准。 向往S9乾鼠 向往M8宗师 M8 系列 M6 系列 ：2025年12月 车型 11-12月下订并完成终端销售 12月下订并完成终端销售 支持时间 M8、E9 旧车20000, M8旧车20000，其他15000 广汽集团品牌旧车 15000 10000 10000 20000 15000 8000 支持标准（元/台） 全品牌旧车10000 全品牌旧车30000 置换支持（元/台） 其他15000 与提车折扣1万元打包宣 传超级置换权益2万元 其他旧车 10000 10000 10000 10000 10000 10000 15000 8000 备注 J-YX2025129\n\n--- 第9页 ---\nES9、向往S7、向往S9、向往M8乾及鸿蒙座舱版车型贴息核销利率上限为3%， 其余贴息车型库存融资贴息核销利率上限为4%，超出部分由销售店自行承担 十、库存融资贴息支持【延续】 支持时间：2025年12月 九、用品权益支持 向往M8系列 向往S9系列 E8、E9、ES9 向往S7系列、 支持时间：2025年12月 （星夜+/光辉+） E9国宾定制版 向往M8宗师 、充电桩支持【延续】 E8 MAX+ E8龙腾+ 库融贴息政策包含常规车辆、特殊车辆、从科技公司买断车辆等。E8、E9、 车型 车型 广汽传祺 送充电桩配备及基础安装服务 店，销售店负责安装（不得收取客户费用）。广汽商贸祺航提供安装支持费220元/台 31日前在广汽传祺APP商城购买原厂用品后排吸顶屏，主机厂发货到客户指定销售 限时升级礼：价值5999元17.3时高清后排吸顶屏限时购买价3000元。客户于12月 (首任车主交车3个月内） （按12月终端实绩支持） 17.3吋后排吸顶屏×1 或铝地板套装×1 行车记录仪×1 吸顶电视×1 头枕腰靠×2 车载冰箱×1 支持内容 (二选一) 支持标准 请店端销售经理扫描下方二维码进行登记： 主机厂统一配发到店，店端装车后交付客户； 3），该文件作为充电桩安装受理依据。 3、报装方式：销售店完成车辆实销，在GRT系统代客户报装 视情况收回对该店的充电桩支持政策 店端无需支付。 2、费用说明：充电桩及安装费用由厂家与供应商总对总结算 销售店须做好客户报装条件及条款说明。如产生投诉，厂家将 户签字版文件《传祺家用充电桩安装服务说明》 路径为：店端GRT-充电桩工单查询-工单新增，并且上传客 代客户报装。 车客户赠送充电桩及基础安装服务，并仅限销售店在GRT系统 1、厂家不对客宣传赠送充电桩权益，销售店视成交需要对购 车辆出厂发车前厂内预装， 统一配发到店，店端装车后交付客户 安装方式 实施方式 随车到店交付客户 J-YX2025129 （详见附件\n\n--- 第10页 ---\n十三、 支持时间 支持车型 支持标准 支持时间 十二、 M8系列、向往M8（含乾、鸿蒙座舱版） 支持标准及要求 支持对象 品专家 向往产 营经理 向往运 支持时间： 岗位 说明：以店激励支持前提条件达成的时间为顺序，先达成先得及预算用完即止 向往S9、E8、E9、ES9、第二代 GS8（含 5 座版） 、后置模糊奖励【调整】 GS3 影速、GS4 MAX、影豹、M6系列、向往 S7、 广汽传祺 限时保险补贴政策【调整】 向往销售专属团队人员岗位激励【延续】 ：2025年12月 其他类城市 1级、2级 超1级、 城市级别 ：2025年12月 超1级、1级、2级线城市 ：2025年12月 城市 具体奖励标准后续另行发布 向往S7（不含Pro+系列） 全网新能源分组店 其他类城市 类型 招聘有新能源从 招聘有新能源从 业经验的主管 业经验的主管 招聘情况 车型 2500元， 5000元， 1500元/ 8000元／ 7500元／ 12000元 /月／人 月/人 月/人 月/人 月/人 月/人 标准 向往M8宗师 ④城市级别延续9月政策要求； ②向往产品专家岗位激励以体验式营销销售考核岗位达标 ①向往运营经理岗位按城市级别、招聘情况给予支持； 后需将相关证明资料第一时间邮件反馈给营销人员管理项 后超配的人数给予支持，每店最高支持人数为3人； ③如招聘有新能源从业经验的主管为向往运营经理，到岗 也达标的店给予支持； 目组郑辉zhengh@gacmotor.com; 同时新能源专属团队人员达标，及销售领域其他岗位人员 ③人员信息以数字门户系统为准； 支持前提：对配备了专人专岗的向往运营经理且面试通过 支持条件 贴息天数 90 天 J-YX2025129\n\n--- 第11页 ---\n十五、2025年部分年度商务政策说明 600元／台，扌 支持车型： 请全体销售店遵守属地化销售规则，考核结果将与基础佣金、基本折扣挂钩 十四、 支持标准： 支持时间： 支持标准：4800元/台，按终端实绩计算奖励，由对应的收订店享受支持 政策权益兑付 辆在库管理要 新能源直销车 支持车型：「 (新能源车型) 及核销规则 项目 12月延续对S7205kmPro+系列、向往M8、 属地化管理政策【延续】 广汽传祺 新能源车型直订管理 内促激励【调整】 ：2025年12月 向往S7系列、向往S9系列、向往M8系列均为800元/台，M6系列 向往 S7 系列、向往 S9 系列、向往 M8 系列、M6 系列 向往S7（不含Pro+系列） 按终端实绩通过人单酬系统发放到对应销售顾问账户 24小时内跟物流中心反馈上报，逾期默认为正常车辆。车辆到店后24小 激励15000元/台。运损或品质问题车辆豁免超30天扣罚5000元/台。 接车管理：车辆到店后请及时确认车辆状态，发现运损或品质问题请在 30-60天长库龄车正向激励5000元/台，接收60天以上的长库龄车正向 展车，一经发现，负激励10000元/台，并限10天转门店展车。 时内系统接车，逾期系统自动接车。 付及对店核销 之日起90天内完成终端成交上报，逾期视为权益失效，不再予以权益兑 如其他店愿意接收长库龄车并30天内完成实销可获得正向激励：接收 车辆在库管理：门店接车后请对车辆进行妥善管理，不得私自挪用或做 罚10000元/台。 交付管理：车辆到店至交付超30天扣罚5000元/台，超过60天再次扣 除明确有效期限或按照终端时间判定的权益支持外，客户订单需于下订 具体内容 向往S9车型本地牌销售管理措施 据进行核销) 一天24:00数 （取每月最后 J-YX2025129 延续 延续 备注\n\n--- 第12页 ---\n说明：政策力度与埃安一致，立 说明：车型提车价格=市场指导价-基本提车政策 西南 西北 华华华华 东北 区域 支持时间：2025年12月 支持时间：2025年12月 支持时间：2025年12月 库存专项支持 1、基本政策 基本提车政策 北东南中 置换支持 运营支持 库存融资 终端支持 广汽传祺 试乘试驾车支持政策 销售支持政策 项目 项目 商务政策 城市范围 四川、贵州、云南 江西、 辽宁、内蒙古 陕西、宁夏 黑龙江 安广 吉林 省份 西徽	text	5	\N	public	manual	D:\\HqEvoAI\\uploads\\706839072cdd418988bb7669406b5e45.pdf	李管理	\N	\N	0	0	批量导入,IT系统操作指南	\N	\N	1	0	0	approved	\N	\N	1	2026-06-11 13:12:36.759047+08	2026-06-11 13:12:36.759059+08
225	董办【2025年】004号 附件1：防台风应急管理制度（修订版）	1/4防台风应急管理制度（修订版）\n一、总则\n（一）目的：为有效防范台风灾害，最大程度减少集团各品牌、各店人员伤\n亡和财产损失，保障公司正常运营秩序，特制定本制度。\n（二）适用范围：本制度适用于海南合群集团旗下各品牌、各门店及相关设\n施在台风侵袭期间的应急防范与处置工作。\n（三）工作原则：坚持以人为本、预防为主、快速反应、协同应对的原则，\n各部门密切配合，确保各项防风措施落实到位。\n二、组织指挥体系及职责\n（一）成立防台委员会：成立以集团董事长为组长，各部门负责人为成员的\n防台委员会。负责全面指挥和协调公司的防台风工作，制定决策，下达指令，\n调配资源。\n会长：邢益宝​\n副会长：陈文群、黄兴军​​\n（二）成立防台应急小组：防台应急小组组长及组员均为防台委员会委员。\n防台委员会负责统筹协调公司整体防台工作，制定防台策略与应急预案，监\n督各部门防台措施的执行情况。\n组长：各店总经理或门店负责人\n副组长：各店销售经理/售后经理/客服经理/市场经理/财务经理\n/人事行政经理​\n组员：主管级（含）以上所有员工\n（三）各部门职责\n1.总经办：各店总经理作为本门店防风第一责任人，按照台风级别组织落\n实防风措施，安排值班人员，及时汇报防风工作进展及遇到的困难。\n2.各部门经理：负责组建和管理部门员工，确保部门员工能在台风期间随\n时待命，协调内部及社会救援力量。并组织销售、售后救援小组开展救援\n工作。\n2/43.人事行政部\n（1）负责准备和管理防风物资，如沙袋、木板、铁丝、手电筒、食品、\n饮用水等，保障物资的充足供应和合理调配；对办公设备、门店设施进行\n防护和加固，确保设备安全。\n（2）负责对公司场所进行安全检查，排查安全隐患，指导各部门落实防\n风安全措施，监督防风工作执行情况。\n（3）根据台风情况合理安排员工上班、下班和放假时间，确保员工安全。\n三、台风预警及响应措施\n根据台风风力等级，制定以下响应措施：\n台风风力等级 响应措施\n8-9级1.各店总经理安排部门中干及有车男性员工值班，做好值班记录；\n2.玻璃门内外各用4袋沙袋顶紧，台风过后将沙袋用纸箱装好存\n放以便反复使用；\n3.关闭并锁紧窗户、卷闸门；\n4.保安室准备4个大功率手电筒；\n5.手机和充电宝充满电；\n6.售后服务部成立2辆车和4人的救援小组值班，随时准备应对\n突发情况。\n10级1.执行8-9级响应措施的基础上，玻璃门内外拉手之间用木板\n夹紧并用铁丝绑紧，台风过后将木板整齐存放以便反复使用；\n2.各部门上报值班人员名单，确保信息畅通。\n11-12级1.执行10级响应措施的基础上，卷闸门里面焊接对角圆孔插入钢\n管加固。\n2.台风来前，除部分必要的照明电外，全部下闸断电。\n3.每个部门准备一辆加满油电的防风车辆（SUV），随时待命。\n3/4台风风力等级 响应措施\n13-18级1.执行11-12级响应措施的基础上，无混凝土结构的门店不安\n排值班人员，值班人员统一集中到有混凝土结构的场所；\n2.调整商品车停放位置，远离可能积水、倒塌树木及围墙的地方，\n尽量放在空旷高地；重大台风前，撤离车间的维修车；\n3.部门根据台风大小准备必要值班食品（方便面、矿泉水等），\n原则上按一天的量准备。\n4.将电脑主机放到垫高的地上，并加电脑套防水袋；对平时漏水\n的地方，在办公设备上加防水油布。\n5.公司根据台风情况安排放假，以微信群通知为准；非值班人员\n早晨上班时若风大、雨大、路面积水，允许晚到或不上班，各部门\n可上报后安排员工提前下班。\n6.台风期间，值班人员原则上待在水泥结构的一楼，非重要情况\n不允许外出，避免坠物砸伤。\n四、应急救援与处置\n（一）救援行动：当发生因台风引发的紧急情况时，销售和售后救援小组应\n立即开展救援工作，采取有效措施救助受伤人员，转移受灾物资，降低损失。\n（二）信息报告：在台风期间，各部门应及时向防台委员会报告防风工作情\n况、受灾情况及救援进展，确保信息畅通。\n（三）后期处置：台风过后，各部门组织人员对公司场所进行清理和检查，\n统计损失情况，及时修复受损设施设备，恢复正常运营秩序。\n五、培训与演练\n（一）培训：定期组织员工进行防台风知识培训，增强员工的防范意识和应\n急处置能力。培训内容包括台风危害、防风措施、应急救援知识等。\n（二）演练：每年至少组织一次防台风应急演练，模拟台风来袭场景，检验\n和提升各部门的应急响应能力、协同配合能力和实际操作能力。演练结束后，\n对演练效果进行评估和总结，针对存在的问题及时进行整改。\n4/4六、附则\n（一）本制度应根据国家法律法规、政策变化及集团实际情况适时进行修订，\n确保制度的有效性和适应性。\n（二）本制度由海南合群集团防台委员会负责解释。\n（三）本制度自发布之日起实施。\n签发：	text	1	\N	public	manual	D:\\HqEvoAI\\uploads\\4f0df9f3f91145539d49b4ce4d522680.pdf	李管理	\N	\N	0	0	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-11 13:19:59.178117+08	2026-06-11 13:19:59.178125+08
240	销售经理驾驶仓数据分析看板 - 片段2 (00:08)	打開銷售經理數據可視化平台。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	8.3	12.3	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.492996+08	2026-06-12 14:31:07.493009+08
241	销售经理驾驶仓数据分析看板 - 片段3 (00:12)	進入銷售經理看板介面。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	12.3	14.8	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.494932+08	2026-06-12 14:31:07.494944+08
203	（新）星瑞 i-HEV智擎混动-核心卖点话术（第2段）	E：您可以体验过减速带的滤震效果，再感受弯道行驶中的车身稳定性，直观感受CMA架构的优势\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：安全；列1：整车结构及\n钢材用料；列2：N+I：大家选车最看重安全，担心车身钢材强度低导致碰撞防护不足，也怕关键部位偷工减料，长期用车容易生锈，这些都会影响用车安全感\nFAB：星瑞 i-HEV智擎混动车身采用70.2%高强度钢和19.8%热成型钢，还搭配激光焊接车身，车身扭转刚度高达29000N・m/deg，碰撞吸能效率也更高，既能在发生事故时保护全家安全，还能让车身耐用不生锈，长期用车更安心\nE：我给您讲解下车身不同部位的钢材占比，再带您看看激光焊接的焊缝细节，用实际工艺证明它的安全实力\n列1：动力安全可靠；列2：N+I：不少用户担心混动系统故障率高，后期维修成本贵，而且在低温、高温等极端工况下，动力衰减，影响出行体验\nFAB：星瑞 i-HEV智擎混动的混动系统历经10万+小时严苛验证，还具备IPX8级防护，能在-30℃~60℃的极端工况下稳定运行，故障率低于0.1%，长期用车不用担心趴窝，维修少花钱，极端天气出行也有保障	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\（新）星瑞 i-HEV智擎混动-核心卖点话术.xlsx	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.876361+08	2026-06-09 13:43:19.876368+08
204	（新）星瑞 i-HEV智擎混动-核心卖点话术（第3段）	E：您可以看下混动系统的验证报告，有条件的话还能体验低温启动效果，实际感受它的可靠性能\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：动力；列1：i-HEV智擎混动；列2：N+I：很多家用车主既想省油省钱，又怕混动油耗虚标、长期用车成本高；同时担心混动动力弱、换挡顿挫、油电切换不顺畅，不得不在 “省油” 和 “好开” 之间妥协，没法兼顾省心与驾驶质感\nFAB：星瑞 i-HEV 智擎混动搭载1.5L混动专用发动机+11合1高集成电驱，搭配P1+P3双电机架构，传动效率高达98.91%，动力损耗更低；配合星睿 AI 云动力 2.0智能能量管理，整车综合节能再提升10%，实现WLTC 百公里油耗 3.98L，加92号汽油就能跑。既帮你每年省下可观油费，又能带来80%工况纯电般平顺，油电无感切换、起步轻快、加速有劲，真正做到省油不省动力、好开还更省钱\nE：您可以看下仪表盘实时油耗，我带您体验纯电起步的安静平顺，再感受急加速时的动力响应，直观感受油电无缝切换的流畅质感\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：操控；列1：星睿AI大模型；列2：N+I：很多用户开车时觉得车辆不懂自己，操控不顺手，智能驾驶辅助安全隐患多、更新慢，还担心车辆突发故障无预警、故障响应慢，全周期用车又累又焦虑，智能化体验远不达预期	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\（新）星瑞 i-HEV智擎混动-核心卖点话术.xlsx	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.879601+08	2026-06-09 13:43:19.879608+08
205	（新）星瑞 i-HEV智擎混动-核心卖点话术（第4段）	FAB：星睿AI大模型通过AI云动力模型、AIDrive大模型、AI智慧云诊断三大核心能力赋能：AI云动力可按驾驶偏好调参数，提升换挡平顺性和操控稳定性，越开越顺手；AIDrive能快速生成虚拟训练场景，提升智驾安全与开发效率；AI智慧云诊断提供24小时在线、3分钟响应守护，最终重新定义智能化驾驶体验，让星瑞 i-HEV智擎混动越开越省油、智驾更安全、用车零焦虑\nE：试驾体验油门/换挡的个性化适配，全程感受全维智能守护效果\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：智能；列1：千里浩瀚H3；列2：N+I：跑高速长途时，很容易因为驾驶疲劳导致注意力不集中，而且变道、上下匝道操作繁琐，稍不注意就容易出错，存在安全隐患\nFAB：星瑞 i-HEV智擎混动的千里浩瀚H3智驾系统拥有26组感知硬件，支持HNOA高速领航和主动避险功能，能自动跟车、自动上下匝道，遇到大车还能主动避让，大幅减轻高速驾驶疲劳，复杂路况出行更安全\nE：我们可以在安全路段开启高速领航功能，您体验下自动上下匝道和主动避险的操作，感受智驾便利\n列1：FlymeAuto\n智能座舱；列2：N+I：很多用户吐槽车机卡顿闪退，多开几个应用就不行了，而且手机和车机互联不畅，导航、音乐等数据不同步，很影响使用	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\（新）星瑞 i-HEV智擎混动-核心卖点话术.xlsx	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.88133+08	2026-06-09 13:43:19.881336+08
206	（新）星瑞 i-HEV智擎混动-核心卖点话术（第5段）	FAB：星瑞 i-HEV智擎混动的FlymeAuto智能座舱搭载高通8155芯片，支持无界空间和小窗模式，秒开8个应用都不卡顿，手机和车机还能无缝互联，导航、音乐等数据实时同步，操作像手机一样流畅，跨设备使用更省心\nE：您可以亲自操作车机，同时打开导航、音乐、视频等应用，再连接手机体验互联功能，测试车机的流畅度\n列1：GEEA3.0\n电子电气架构；列2：N+I：大家怕车子买回去后，车辆功能升级难，后期没法添加新功能，而且电子系统响应慢，操作时有延迟，影响用车便捷性\nFAB：星瑞 i-HEV智擎混动搭载GEEA3.0电子电气架构，支持整车OTA升级，后期能不断添加新功能，让车子越用越新，而且电子系统响应速度达毫秒级，操作没有延迟卡顿，功能使用更跟手，长期用车体验不落后\nE：我给您演示下整车OTA的升级流程，再测试下车窗、空调等功能的响应速度，让您直观感受架构的优势\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：造型；列1：造型设计；列2：N+I：很多用户选轿车时觉得外观平庸没辨识度，开出去没面子；还担心车身短、轴距小导致后排空间挤，家人乘坐不舒服；内饰又多是塑料材质，缺乏豪华感，家用兼商务的需求满足不了	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\（新）星瑞 i-HEV智擎混动-核心卖点话术.xlsx	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.883417+08	2026-06-09 13:43:19.883422+08
226	附件8 员工福利管理制度	1/5员工福利管理制度\n一、目的\n为提升企业员工归属感，体现人文关怀，推动企业文化建设，形成良好的企业向心\n力和凝聚力，特制定本制度。\n二、名词解释\n福利：福利特指除公司正常发放的工资和奖金等劳动报酬之外增加给予员工的其他\n福利报酬，包括现金形式和非现金形式两种。\n正式员工：特指已提交转正申请，并经审核通过的在职员工。\n三、适用范围：\n本规定适用于集团所有正式员工，其中部分福利不适用于试用期及实习期员工。\n福建、广东区域如存在特殊福利需求，可单独向集团总经理/董事长申请。\n四、福利待遇的种类：\n（一）公司提供的福利待遇包括按国家规定执行的福利待遇，以及根据公司自身条件\n设置的各项福利待遇。\n（二）按照国家政策和规定，提供的统筹五险（包括：基本养老保险、基本医疗保险、\n失业保险、工伤保险、生育保险；）\n（三）根据公司自身经营条件设置的福利项目包括：住房公积金、节庆福利、假期福\n利、生活福利、培训福利、意外伤害保险、重大疾病险及其他福利。\n（四）员工购车及维修享有员工价格优惠等福利\n五、福利待遇：\n（一）社会统筹保险\n1.公司负责为所有正式员工缴纳国家规定的养老保险、医疗保险、生育保险、工伤保\n险、失业保险；\n2.员工转正后，社会保险由人事行政部负责为员工办理；\n3.社会保险的缴费基数根据公司上年度经营状况，结合海口市上年度工资水平、根据\n政府当期发布的最低缴费基数由人事行政部每年统一进行调整缴纳；\n4.员工办理社保需按时提交规定资料，不能按时提交资料的员工，属于个人原因，所\n带来的所有法律责任由个人承担；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n2/55.社会统筹保险由公司统一缴纳，个人应缴纳部分在工资中扣除；\n（二）住房公积金\n1.员工自入职转正1年后公司提供住房公积金。\n2.住房公积金的缴费基数根据公司上年度经营状况，结合海口市及各省、市上年度工\n资水平由人事行政部每年统一进行调整。\n（三）补贴福利\n1.节庆福利\n（1）每逢元旦、五一劳动节、端午节、十一国庆节、中秋节等等法定假日根据公司\n的经营情况决定是否给全体员工发放节日福利；\n（2）三八妇女节：女性员工放假半天并发放节日福利。\n2.假期福利\n员工所享有的假期有：年假、婚假、陪产假（男员工）、孕检假、哺乳假、丧假、\n事假、病假、工伤假、家长会假等。\n3.生活福利\n（1）工作餐：\n①公司为员工提供免费工作午餐，加班员工应提前报备方可提供免费工作晚餐；\n无厨房门店提供餐费补助，补助标准按照集团财务制度相关规定执行，由各店统一管\n理及支出；\n②二级直营店人员按25元/天/人补助，每月餐费补助次月按实际出勤天数核定发\n放。\n（2）住房补助\n①适用对象条件：入职一年以内的员工并月度领取到手的工资总额低于2000元。\n（到手工资总额是指扣除个人承担部分的社保及个人所得税后的总额）\n②补贴标准：每人每月按照500元标准补助。\n③补贴期限：12个月，从入职当月开始计算；满一年12个月后自动取消。领取租\n房补贴的员工在领取补贴期限内，如月领取到手工资总额大于等于2000元时，则取消\n当月租房补贴；\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n3/5④发放方式：当月的租房补贴以工资的形式（包含在工资中）于次月28日在员工\n工资卡中发放。\n⑤人事行政部对上月人员工资进行核对，将符合租房补贴人员发放名单，递交给\n工资制作人员，由工资制作人员计入工资中一并发放。\n4.交通补贴\n（1）当月的交通补贴以工资的形式（包含在工资中）于次月8日发到员工工资卡中。\n（2）其他特殊情况产生的交通费用凭票实销实报（油票、停车票、出租车票等），不\n允许跨月累积报销。\n5.通讯补贴\n（1）当月的通讯补贴以工资的形式（包含在工资中）发到员工工资卡中，补贴标准为：\n员工级：80元/月/项，主管级以上100元月/项，于次月8日在员工工资卡中发放。\n（2）其他特殊情况产生的通讯费用凭票实销实报（电话单、通话记录，通话录音等），\n不允许跨月累积报销。\n6.工装福利\n具体享受内容见各品牌厂商要求着装，费用按照集团财务管理制度相关内容执行。\n7.常规体检\n（1）公司每两年组织员工集体体检一次。\n（2）公司每年组织一次特殊岗位的职业病体检。\n8.文化生活\n为了丰富员工文化生活而设立以下福利：\n（1）为促进员工的身心健康，丰富员工的精神和文化生活、业余生活，培养员工积极\n向上的道德情操而提供以下福利：\n①在不影响工作的情况下，公司不定期组织员工参加羽毛球、篮球、足球等体育活\n动。\n②聚餐：各部门可向集团申请部门经费用于部门间聚餐（部门活动基金为申请制）。\n③员工旅游：公司每年组织全体员工省内旅游1次；组织优秀员工岛外旅游1次，\n星级员工国外旅游1次。（因特殊情况不能组织旅游时，以现金形式发放补助，补助标\n准以集团当期公布的补贴标准为准）。\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n4/5（2）其他文化活动：具体实施根据公司实际情况而定，由发起部门进行组织。\n9.培训福利\n公司根据各部门的培训需求，由各品牌组织实施，提升员工的知识、技能、态度\n等方面与不断变动的技术、外部环境相适应。\n培训福利包括：员工在职或短期脱产培训等。具体规定见公司《培训管理制度》。\n10.其他额外商业保险（公司有权根据当期实际经营情况选择是否购买）\n（1）意外伤害险：充分考虑员工的安全，避免因意外伤害给员工和家属带来的负担，\n为正式员工额外购买意外伤害险。\n（2）重大医疗险：确保员工因个人和家庭成员发生重大疾病给员工带来的负担，享受\n条件为在实施购买时当年前转正的员工，否则在下一年购买\n11.家长会假\n（1）正式员工凭子女学校或幼儿园的通知家长会通知单，享受半天带薪假期，每学期\n每个员工子女可享受1次，双职工仅可一人享受。\n（2）正式员工且有子女在适龄阶段开学的，每年3月、9月初子女入学时，给予半天\n入学入园报名的带薪假期。\n12.员工购车及维修优惠政策\n（1）员工购车福利：\n①员工每年享受一次集团旗下所有品牌按厂家标准成本价的购车机会，仅限本人及\n配偶使用；\n②亲友购车可凭申请享受相应的优惠，特殊情况各品牌总经理根据市场实际情况一\n车一议。\n③员工购买集团各品牌的试驾车新车指标、二手试驾车必须报集团董事长审核批准；\n（2）员工车辆维修及续保福利：\n①员工个人使用并在公司相关管理部门报备过的车辆（上限2台），方可享受维修按\n配件成本，工费按7折结算优惠，续保按当期续保政策执行。\n②鼓励员工推荐亲戚朋友到各品牌维修，各品牌应给予适当优惠，但折扣不得高于\n各品牌总经理和直营店部门领导的权限范围。\n（3）直系亲属购车，须提供关系证明材料，如有弄虚作假者给予5000元的经济处罚\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\n5/5并记大过一次。\n（4）享受优惠购车者，本人、家属及亲朋好友对购车相关价格信息负有保密义务，不\n得擅自对外传播相关价格信息，违背者给予4000元的经济处罚并记大过一次。\n（5）员工个人购车，销售人员严格执行销售流程，为购车者办理相关手续，该车不享\n受转介绍奖励，销售员仅发放交车奖励，不纳入销售员当期销量目标。该车不享受公\n司及销售部其他优惠政策。\n（6）任何员工不得利用公司福利政策弄虚作假，谋取个人利益，有违者公司将纳入信\n用不良记录，给予处罚、通报批评乃至辞退的处理。\n（7）申请福利流程：由员工本人向各品牌总经理书面或电话申请，经各环节负责人审\n定后实施.\n六、附则\n一、如本制度条款中有与国家政策相冲突或未涉及内容，均以国家政策为准；\n二、本制度经董事会授权董事长邢益宝先生签发；\n三、本制度解释权归人事行政部所有，人事行政部有权根据需要修改、增加或更新员\n工手册的内容，如有修改内容将在企业微信中通告全体员工；\n四、本制度正式发布后，如出现重大与实际情况不相符的，可上报集团总经理/董事长\n审定，一事一议裁定，并可组织编委会修订条例；\n五、本制度在企业微信－合群云档－规章制度中发布，集团全体员工均可自行阅览，\n不得下载；\n六、公布实施后新入职的新员工，需在入职前详细阅读本手册，并签字确认认同本手\n册的全部内容，如不认同本手册内容，可选择自动放弃入职；\n七、本制度正式发布后，如与前期发布的制度相违处，以本制度为准，后续所有制度\n调整，均以最新发布为准；\n八、本制度自2022年01月01日开始执行。\n签发人：\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«\nº£ÄÏºÏÈºÆû³µ¼¯ÍÅ ÄÚ²¿ÎÄ¼þ ½ûÖ¹Íâ´«	text	1	\N	public	manual	D:\\HqEvoAI\\uploads\\de30f9e3caa545d59614f9d46f1b2d91.pdf	李管理	\N	\N	0	0	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-11 13:43:18.279622+08	2026-06-11 13:43:18.279626+08
242	销售经理驾驶仓数据分析看板 - 片段4 (00:14)	點擊右上角。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	14.8	18.07	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.496887+08	2026-06-12 14:31:07.496895+08
207	（新）星瑞 i-HEV智擎混动-核心卖点话术（第6段）	FAB：星瑞 i-HEV智擎混动以大自然为灵感打造专属设计：前脸是大气磅礴的“丝路峰峦”格栅，搭配独特艾里克蓝车色，辨识度拉满；车身长度达4825mm，还有同级领先的2800mm超长轴距，既带来沉稳大气的车身姿态，又能提供越级宽适驾乘空间，家人乘坐不拥挤；天山润白全新内饰配色、月泉玉樽水晶挡把及鹿跃星辰3D镭雕工艺，再搭配琉璃溢彩256色氛围灯，打造出豪华舒享座舱，不管是日常通勤还是家庭出游，都有面子又舒适\nE：您可以绕车查看丝路峰峦格栅和艾里克蓝车色的细节，坐进后排体验轴距带来的空间感；再触摸内饰材质、观察水晶挡把与3D镭雕，开启氛围灯感受座舱氛围，直观体验豪华感与空间优势\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：配置；列1：入门即豪华；列2：N+I：很多用户买轿车时，总遇到入门版配置寒酸，连大屏、快充都没有，想要全景天窗、透明底盘、驾驶辅助等实用功能，必须加钱买高配，性价比低，花了钱还没享到基础舒适与安全配置\nFAB：星瑞 i-HEV智擎混动直接做到入门即豪华，全系标配14.6英寸高清中控屏、50W手机无线风冷超级快充、双温区自动恒温空调、可开启式全景天窗、上帝之眼540透明底盘、L2级驾驶辅助，无需额外加钱，入门就能享大屏操作、快速充电、分区控温、开阔视野、倒车安全、驾驶辅助，日常用车不管是舒适、便捷还是安全，都能一步到位，舒享每一程	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\（新）星瑞 i-HEV智擎混动-核心卖点话术.xlsx	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.8855+08	2026-06-09 13:43:19.885505+08
208	（新）星瑞 i-HEV智擎混动-核心卖点话术（第7段）	E：您可以亲手操作14.6英寸中控屏感受清晰度，把手机放在无线充电板测试50W快充速度，再开启全景天窗、切换540透明底盘，体验全系标配功能的实用性，直观感受入门即豪华的价值	text	1	\N	sales	manual	D:\\合群集团资料\\销售知识\\（新）星瑞 i-HEV智擎混动-核心卖点话术.xlsx	系统导入	\N	\N	0	0	批量导入,销售知识	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 13:43:19.8874+08	2026-06-09 13:43:19.887407+08
209	已修改	test	text	7	\N	sales	manual	\N	李管理	\N	\N	0	0	\N	\N	\N	1	0	0	archived	\N	\N	1	2026-06-09 14:09:17.474668+08	2026-06-09 14:09:17.559156+08
210	E2E经验	test	text	7	\N	sales	experience	\N	王销售	销售部	\N	0	0	\N	\N	\N	1	0	1	approved	2	\N	1	2026-06-09 14:09:17.585608+08	2026-06-09 14:09:17.66786+08
1	星瑞L6产品核心卖点	星瑞L6作为合群汽车集团旗舰新能源轿车，核心卖点包括：\n1. **续航里程**：CLTC综合续航1200km，纯电续航200km\n2. **智能座舱**：搭载15.6英寸中控屏，支持语音控制、手势识别\n3. **安全配置**：L2+级智能驾驶辅助，全车6气囊\n4. **动力系统**：1.5T混动专用发动机 + 前置电机，综合功率230kW\n5. **质保政策**：整车5年/15万公里，三电系统终身质保（首任车主）\n\n销售话术要点：重点强调续航和质保这两个差异化优势，与比亚迪汉DM-i对比突出了更高功率和更长整车质保。	text	7	\N	sales	manual	\N	李管理	销售部	\N	0	0	星瑞L6,产品卖点,新能源,轿车	星瑞	L6	2	130	15	approved	\N	\N	1	2026-06-09 13:11:57.396039+08	2026-06-09 14:26:11.600926+08
211	2025年合群集团中干会考试题（20250207）	所属公司：\n姓名：                                                                 得分：\n2025年中干会考试题\n（满分：100分，考试时间：45分钟）\n一、选择题（每小题3分，共45分）\n1. 集团的核心价值观是（     ）\nA．公平、公正、团结、互助\t    \nB．互助、互爱、共享、批评与自我批评\nC．以人为本、诚信经营、真实合现  \nD．安全第一、客户至上、高效执行、科学创新\n2.常规保险事故车产值毛利率？（     ）\nA. 35%-40%\nB. 45%-50%\nC. 55%-60%\nD. 60%以上\n3. 公司的财务报销流程中，以下哪项不是必填项（     ）\nA. 费用明细\nB. 发票号码\nC. 报销人签字\nD. 领导审批签字\n4. 在财务报表中，反映企业在一定时期内经营成果的报表是（     ）\nA. 资产负债表\nB. 利润表\nC. 现金流量表\nD. 所有者权益变动表\n5. 集团规定店端市场费用必须经集团审批，审批原则为 （      ）\nA. 在项目未结束前申报立项即可\nB. 项目开始前先申报立项后开展\nC. 紧急时可先开展无需其他形式沟通\nD. 报总经理同意即可开展\n6. 当定损确认单配件、工费金额与结算单不一致时，整单差异金额在（     ）元以内由售后经理签字同意即可\nA. 100\nB. 200\nC. 300\nD. 500\n7.返利资金长期闲置在厂家帐户上（包括银行汇票提车余额），以下哪种做法最不可取（    ）\nA. 开具红字通知单，厂家将返利转到公司帐户\nB. 向厂家申请将返利转为库存车赎证\nC. 挂在系统等待结算车辆时慢慢抵扣\nD. 向厂家申请返利转用于采购售后零件款\n8. 公司5S管理是指（     ）\nA. 整理、整顿、清扫、清洁、素养\nB. 整理、整顿、清扫、整洁、素养\nC. 整理、清洁、清扫、卫生、素养\nD. 整理、整顿、清扫、整洁、卫生\n9.集团2024年度人均人力成本（    ）\nA. 10.68万元\nB. 10.52万元\nC. 9.64万元\nD. 9.18万元\n10.在厂家金融政策支持下，4S店为客户提供汽车贷款购车服务。以下关于贷款风险防控措施的说法中，错误的是（    ）\nA. 严格审核客户的信用状况和还款能力\nB. 确保贷款合同条款清晰、明确，符合法律法规要求\nC. 为了提高销量，可以适当放宽贷款审批条件\nD. 定期对贷款业务进行风险评估和监控\n11.（多选题）根据集团规定，员工对新添加微信的朋友必须主动发送以下（       ）\nA. 电子名片              \nB. 品牌宫格图\nC. 产品介绍            \nD. 简短的自我介绍话术\n12.（多选题）在处理呆滞配件时，通常可采用的渠道有以下哪些？（    ）\nA. 退回厂家\nB. 销售给对应车辆\nC. 采购置换\nD. 外销给社会配件店\nE. 报废处理\n13.（多选题）在成本核算中，以下各项费用归口为固定费用的是（       ）\nA. 业务招待费\nB. 通讯费\nC. 差旅费\nD. 财务费用\nE. 水电费\nF. 开办费摊销\n14.（多选题）计算维修毛利时，需要从相关数据中减去以下哪些项目？（      ）\nA. 车间耗品\nB. 事故招揽\nC. 配件成本\nD. 维修产值\nE. 人工成本\nF. 油漆物料\n15.（多选题）2025年集团对总经理的新媒体硬性考核指标是（       ）\nA. 新媒体订单占比总订单＜35%\nB. 新媒体订单占比总订单＜20%\nC. 单月新媒体线索保底300条\nD. 根据自店投流完成档位线索目标\nE. 单月线索冲刺500条\n三、填空题（每题 3 分，共 30 分）\n1. 公司的经营理念是                                                             。\n2. 集团规定，员工请假超过      天（含）需经集团总经理批准。\n3. 财务会计的基本职能包括会计核算和         。\n4. 合同的订立应遵循平等、自愿、公平、诚实信用和            的原则。\n5. 厂家敞口的使用期限一般为         个月，具体以与厂家签订的协议为准。\n6. 集团的问题文化是                                                              。\n7. 办公用品的采购由         部门统一负责。\n8. 集团内部员工转介绍购车的，奖励金额由品牌根据该车毛利情况决定，一般在           元之间。\n9. 合同履行过程中，如出现争议，应首先通过          方式解决。\n10. 公司鼓励员工提出合理化建议，对于被采纳的建议将给予                       奖励。\n三、简答题（每题25分，共25分）\n1. 某4S店销售一款高返产品，银行给予店端返点17000元，店端将其中15000元返给客户（无票），企业在这个过程中的成本及各项税费如何计算？请简单说明并计算出企业实际的毛利是多少？\n您对BI系统的使用有什么建议？\n说明：题库依据《BI汽车经销商集团管理系统V1.2 操作手册》整理，包含单选题、多选题、判断题、简答题（每题5分）	text	1	\N	public	manual	\N	李管理	\N	\N	0	0	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 14:46:13.366397+08	2026-06-09 14:46:13.366404+08
212	总经理BI考试题	题型：单选题；题目：1、在【门店实时库存结构】页面中，蓝色字体/蓝色区域通常表示（单选）。；选项1：A、可穿透进入下一级明细；选项2：B、异常门店标记；选项3：C、周末标记；选项4：D、仅用于展示不可点击；正确答案：A；答案解析：说明书描述：蓝色字体代表可穿透，能进入具体公司的库存结构。；分值：5\n题型：单选题；题目：2、在库存分析中，若要评估“在库+在途”的库存压力，应重点关注（单选）。；选项1：A、库存深度（在库，含在途）；选项2：B、订单来源小类分布；选项3：C、线索成本排名；选项4：D、保险赔付率；正确答案：A；答案解析：说明书描述：该页面包含集团库存深度（在库，含在途）。；分值：5\n题型：单选题；题目：3、在同一库存页面中，若要排查长期积压车型，应优先查看（单选）。；选项1：A、150天以上长库车型；选项2：B、自然进店订单类型分布；选项3：C、当日交车排名；选项4：D、银行账户资金交易；正确答案：A；答案解析：说明书描述：库存分析包含150天以上长库车型。；分值：5\n题型：单选题；题目：4、在【月-订单台数】的“每日订单情况”中，若某天订单柱/数据为红色，通常表示（单选）。；选项1：A、该天为周末；选项2：B、该天为异常门店数据；选项3：C、该天订单已全部取消；选项4：D、该天为系统未同步日期；正确答案：A；答案解析：说明书描述：每日订单情况中红色代表周末。；分值：5\n题型：单选题；题目：5、在【月-订单台数】页面要进一步分析“订单从哪里来”，应重点查看哪个分析模块（单选）。；选项1：A、订单来源大类和小类分类；选项2：B、交车毛利汇总（含水平业务）；选项3：C、订单类型分布；选项4：D、单店订单情况；正确答案：A；答案解析：说明书描述：该页面包含订单来源大类与小类分类。；分值：5\n题型：单选题；题目：6、【年-订单台数】进一步下钻后的最细粒度可以达到（单选）。；选项1：A、具体车型订单与具体销售顾问订单数；选项2：B、到品牌汇总；选项3：C、到区域汇总；选项4：D、到公司汇总不含个人；正确答案：A；答案解析：说明书描述：年订单可细化到具体车型订单、具体销售顾问订单数。；分值：5\n题型：单选题；题目：7、在【月-交车台数】的“每日交车分布”中，红色区域的含义是（单选 ）。；选项1：A、周末；选项2：B、返利到账日；选项3：C、异常门店；选项4：D、未结算工单；正确答案：A；答案解析：说明书描述：每日交车分布红色区域为周末。；分值：5\n题型：单选题；题目：8、在【月-维修产值】的“产值日分布”中，红色通常表示（单选）。；选项1：A、周末；选项2：B、产值低于平均值；选项3：C、当日产值未结算；选项4：D、数据缺失；正确答案：A；答案解析：说明书描述：产值日分布中红色代表周末。；分值：5\n题型：单选题；题目：9、在【网销/新媒体对标数据】中打开“开启对比”后，系统对数据异常门店的处理是（单选）。；选项1：A、自动标黄提示异常；选项2：B、自动加入异常箭头；选项3：C、自动将该门店排序置顶；选项4：D、仅在导出时提示异常；正确答案：A；答案解析：说明书描述：开启对比后，出现数据异常门店系统自动标黄。；分值：5\n题型：单选题；题目：10、若要查看某公司各银行账户的交易情况，并可渗透到每个账户交易明细，应进入（单选）。；选项1：A、银行账户资金；选项2：B、在途与清算对比；选项3：C、厂家返利账户；选项4：D、银行汇总表；正确答案：A；答案解析：说明书描述：银行账户资金可渗透查询每个账户交易情况。；分值：5\n题型：单选题；题目：11、厂家账户余额提供“当日”和“当月”两个口径，分别对应功能（单选）。；选项1：A、厂家账户余额-当日 与 厂家账户余额-当月；选项2：B、集团返利 与 MP6返利；选项3：C、整车业务毛利汇总；选项4：D、交车口径延保 与 销售口径延保；正确答案：A；答案解析：说明书列出厂家账户余额-当日与厂家账户余额-当月两项功能。；分值：5\n题型：单选题；题目：12、【情景题】你需要从总经理视角查看集团订单/交车/达成及售后产值排名，在系统中最合适的入口是（单选）。；选项1：A、总经理-业务数据总览；选项2：B、门店实时库存结构；选项3：C、总经理-整车/售后排名；选项4：D、总结报告；正确答案：C；答案解析：依据说明书功能描述，完成“从总经理视角查看集团订单/交车/达成及售后产值排名”对应的入口为【总经理-整车/售后排名】。；分值：5\n题型：单选题；题目：13、【情景题】你需要快速总览销售与售后核心经营数据，在系统中最合适的入口是（单选）。；选项1：A、总经理-业务数据总览；选项2：B、总经理-整车/售后排名；选项3：C、门店实时库存结构；选项4：D、总结报告；正确答案：A；答案解析：依据说明书功能描述，完成“快速总览销售与售后核心经营数据”对应的入口为【总经理-业务数据总览】。；分值：5\n题型：单选题；题目：14、【情景题】你需要查看集团总览、销售/售后总结报告看板，在系统中最合适的入口是（单选）。；选项1：A、总结报告；选项2：B、门店实时库存结构；选项3：C、总经理-整车/售后排名；选项4：D、总经理-业务数据总览；正确答案：A；答案解析：依据说明书功能描述，完成“查看集团总览、销售/售后总结报告看板”对应的入口为【总结报告】。；分值：5\n题型：单选题；题目：15、【情景题】你需要查看实时库存结构，并下钻到库存结构明细，在系统中最合适的入口是（单选）。；选项1：A、总经理-业务数据总览；选项2：B、门店实时库存结构；选项3：C、库存结构；选项4：D、总经理-整车/售后排名；正确答案：B；答案解析：依据说明书功能描述，完成“查看某门店实时库存结构，并下钻到该公司的库存结构明细”对应的入口为【门店实时库存结构】。；分值：5\n题型：单选题；题目：16、【情景题】你需要对比“含已配车/不含已配车”的资金占用，并定位150天以上长库车型，在系统中最合适的入口是（单选）。；选项1：A、总经理-整车/售后排名；选项2：B、门店实时库存结构；选项3：C、门店历史库存结构；选项4：D、总经理-业务数据总览；正确答案：B；答案解析：依据说明书功能描述，完成“对比“含已配车/不含已配车”的资金占用，并定位150天以上长库车型”对应的入口为【门店实时库存结构（库存成本/资金占用/库存深度/长库）】。；分值：5\n题型：单选题；题目：17、【情景题】你需要分析当月订单达成、每日订单分布（含周末标识）及订单来源大类/小类，在系统中最合适的入口是（单选）。；选项1：A、月-订单台数；选项2：B、年-订单台数；选项3：C、未交车明细；选项4：D、总经理-整车/售后排名；正确答案：A；答案解析：依据说明书功能描述，完成“分析当月订单达成、每日订单分布（含周末标识）及订单来源大类/小类”对应的入口为【月-订单台数】。；分值：5\n题型：单选题；题目：18、【情景题】你需要查看年度订单并下钻到具体车型与具体销售顾问的订单数，在系统中最合适的入口是（单选）。；选项1：A、总经理-整车/售后排名；选项2：B、月-订单台数；选项3：C、年-订单台数；选项4：D、总结报告；正确答案：C；答案解析：依据说明书功能描述，完成“查看年度订单并下钻到具体车型与具体销售顾问的订单数”对应的入口为【年-订单台数】。；分值：5\n题型：单选题；题目：19、【情景题】你需要分析月度交车并下钻到品牌交车明细及每日交车周末分布，在系统中最合适的入口是（单选）。；选项1：A、月-交车台数；选项2：B、总经理-整车/售后排名；选项3：C、年-订单台数；选项4：D、月-订单台数；正确答案：A；答案解析：依据说明书功能描述，完成“分析月度交车并下钻到品牌交车明细及每日交车周末分布”对应的入口为【月-交车台数】。；分值：5\n题型：单选题；题目：20、【情景题】你需要分析月度维修产值、收入类型分布并下钻到公司明细，在系统中最合适的入口是（单选）。；选项1：A、总经理-整车/售后排名；选项2：B、总经理-业务数据总览；选项3：C、月-维修产值；选项4：D、总结报告；正确答案：C；答案解析：依据说明书功能描述，完成“分析月度维修产值、收入类型分布并下钻到公司明细”对应的入口为【月-维修产值】。；分值：5\n题型：多选题；题目：21、以下哪些看板在“日分布”中使用红色标识周末？（多选）；选项1：A、月-订单台数（每日订单情况）；选项2：B、月-交车台数（每日交车分布）；选项3：C、月-维修产值（产值日分布）；选项4：D、银行账户资金（账户交易）；正确答案：ABC；答案解析：说明书中订单、交车、维修产值的日分布均提到红色代表周末；银行账户资金与周末标识无关。；分值：5\n题型：多选题；题目：22、以下哪些功能明确支持“蓝色区域/蓝色字体可渗透（下钻）到明细”？（多选）；选项1：A、门店实时库存结构；选项2：B、全员开发贡献订单；选项3：C、清算金额商户统计；选项4：D、预算与实际对比；正确答案：ABC；答案解析：说明书描述A/B/C均可蓝色渗透到下一级或明细列表；预算对比未描述蓝色下钻。；分值：5\n题型：多选题；题目：23、关于【总经理-整车/售后排名】功能与口径，下列说法哪些正确？（多选）；选项1：A、总经理排名仅支持年度排名。；选项2：B、总经理-整车排名包含当日/月/年订单排名。；选项3：C、总经理-售后排名包含产值排名与达成排名。；选项4：D、总经理-整车排名包含当日/月/年交车排名与达成排名。；正确答案：BCD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：24、关于【总经理-业务数据总览】功能与口径，下列说法哪些不正确？（多选）；选项1：A、业务数据总览同时覆盖销售与售后业务数据。；选项2：B、业务数据总览只覆盖金融按揭。；选项3：C、业务数据总览只覆盖市场费用。；选项4：D、该页面数据每月手工导入一次，不支持实时更新。；正确答案：BCD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：25、关于【总结报告】功能与口径，下列说法哪些不正确？（多选）；选项1：A、总结报告只包含财务报表。；选项2：B、该页面数据每月手工导入一次，不支持实时更新。；选项3：C、总结报告包含集团总览、销售报告与售后报告看板。；选项4：D、总结报告不支持按版块查看。；正确答案：ABD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：26、关于【门店实时库存结构】功能与口径，下列说法哪些正确？（多选）；选项1：A、该页面仅展示历史库存，不包含实时库存。；选项2：B、门店实时库存结构页面数据系统实时同步、实时更新。；选项3：C、蓝色字体表示可穿透进入更明细的库存结构。；选项4：D、页面支持筛选查询实时库存情况。；正确答案：BCD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：27、关于【门店实时库存结构（库存成本/资金占用/库存深度/长库）】功能与口径，下列说法哪些正确？（多选）；选项1：A、长库阈值固定为90天以上。；选项2：B、可查看库存成本结构并区分“包含已配车/不含已配车”的资金占用口径。；选项3：C、可查看150天以上长库车型。；选项4：D、可查看集团库存深度（在库含在途）。；正确答案：BCD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：28、关于【月-订单台数】功能与口径，下列说法哪些正确？（多选）；选项1：A、月-订单台数包含订单达成柱状图。；选项2：B、红色代表异常门店。；选项3：C、页面包含订单来源大类和小类分类。；选项4：D、每日订单情况中红色代表周末。；正确答案：ACD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：29、关于【年-订单台数】功能与口径，下列说法哪些正确？（多选）；选项1：A、可细化到具体车型订单。；选项2：B、年-订单台数可从集团到品牌汇总并蓝色区域可渗透。；选项3：C、可细化到具体销售顾问订单数。；选项4：D、年度订单仅支持按公司展示不支持品牌。；正确答案：ABC；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：30、关于【月-交车台数】功能与口径，下列说法哪些正确？（多选）；选项1：A、交车台数只提供年度汇总无月度。；选项2：B、每日交车分布中红色区域为周末。；选项3：C、交车明细不可下钻。；选项4：D、月-交车台数可按品牌查询并可渗透到交车明细。；正确答案：BD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：31、关于【月-维修产值】功能与口径，下列说法哪些正确？（多选）；选项1：A、该页面只统计整车毛利。；选项2：B、产值收入类型分布可渗透查询同一分类的公司数据。；选项3：C、产值日分布中红色代表周末。；选项4：D、月-维修产值支持蓝色区域渗透进入明细。；正确答案：BCD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：32、关于【金融排名管理】功能与口径，下列说法哪些正确？（多选）；选项1：A、包含按揭返佣系统相关排名。；选项2：B、金融排名包含按揭台数、按揭渗透率、金融按揭收入等维度。；选项3：C、返佣系统排名与按揭无关。；选项4：D、包含金融单台收入与除返后收入/单台收入排名。；正确答案：ABD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：33、关于【网销/新媒体对标】功能与口径，下列说法哪些正确？（多选）；选项1：A、开启“开启对比”后数据异常门店会自动标黄。；选项2：B、包含红黑榜、年度分析、日报与订单明细等功能。；选项3：C、网销/新媒体对标数据支持选择时间、公司、品牌进行多维对标。；选项4：D、标黄表示周末。；正确答案：ABC；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：34、关于【在途与清算对比】功能与口径，下列说法哪些不正确？（多选）；选项1：A、在途与清算对比只能查看在途，不能查看清算。；选项2：B、该页面不支持按公司/品牌筛选，只能查看集团汇总。；选项3：C、对比页面不支持筛选公司。；选项4：D、在途与清算对比用于对比在途金额与清算金额差异。；正确答案：ABC；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：35、关于【银行账户资金】功能与口径，下列说法哪些不正确？（多选）；选项1：A、银行账户资金只展示余额，不展示账户交易明细。；选项2：B、该页面数据每月手工导入一次，不支持实时更新。；选项3：C、银行账户资金不可下钻。；选项4：D、银行账户资金可查询各公司银行资金交易情况，并可渗透到每个账户交易明细。；正确答案：ABC；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：36、关于【厂家账户管理】功能与口径，下列说法哪些正确？（多选）；选项1：A、厂家账户管理可查询销售部厂家账户与售后厂家配件账户余额。；选项2：B、包含销售/售后返利账户等余额信息。；选项3：C、提供当日与当月两个口径。；选项4：D、厂家账户只提供年度余额。；正确答案：ABC；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：37、关于【集团返利】功能与口径，下列说法哪些不正确？（多选）；选项1：A、返利模块不能筛选。；选项2：B、集团返利只看总额不支持明细。；选项3：C、集团返利支持查询集团及各店返利情况，并可渗透进入返利明细。；选项4：D、该页面仅展示台数，不展示金额/毛利/渗透率等指标。；正确答案：ABD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：38、关于【零件库存汇总表】功能与口径，下列说法哪些正确？（多选）；选项1：A、零件库存汇总只展示年度累计不展示实时。；选项2：B、零件库存汇总包含实时库存数与库存成本金额。；选项3：C、包含近三个月出库毛利与毛利率。；选项4：D、包含库存度、周转率等指标。；正确答案：BCD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：39、关于【月-交车台数】功能与口径，下列说法哪些正确？（多选）；选项1：A、月-交车台数可按品牌查询并可渗透到交车明细。；选项2：B、红色表示异常门店。；选项3：C、交车明细不可下钻。；选项4：D、每日交车分布中红色区域为周末。；正确答案：AD；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：多选题；题目：40、关于【零件库存汇总表】功能与口径，下列说法哪些正确？（多选）；选项1：A、零件库存汇总包含实时库存数与库存成本金额。；选项2：B、包含库存度、周转率等指标。；选项3：C、包含近三个月出库毛利与毛利率。；选项4：D、库存度与周转率无法查看。；正确答案：ABC；答案解析：请依据说明书描述辨析口径、维度与下钻能力。；分值：5\n题型：判断题；题目：41、判断：在网销/新媒体对标数据中，开启“开启对比”后，数据异常的门店会自动标黄。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：说明书对对标功能描述包含“开启对比后异常门店自动标黄”。；分值：5\n题型：判断题；题目：42、判断：系统中多处表格/区域使用蓝色字体或蓝色区域表示可渗透到更明细的数据。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：说明书在库存、订单贡献、资金等多个模块均提到蓝色可渗透/穿透。；分值：5\n题型：判断题；题目：43、判断：总经理-售后排名包含产值排名与达成排名。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【总经理-整车/售后排名】的描述一致。；分值：5\n题型：判断题；题目：44、判断：业务数据总览只覆盖市场费用。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：B；答案解析：该表述与说明书对【总经理-业务数据总览】的描述不符。；分值：5\n题型：判断题；题目：45、判断：总结报告包含集团总览、销售报告与售后报告看板。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【总结报告】的描述一致。；分值：5\n题型：判断题；题目：46、判断：红色字体表示可穿透。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：B；答案解析：该表述与说明书对【门店实时库存结构】的描述不符。；分值：5\n题型：判断题；题目：47、判断：长库阈值固定为90天以上。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：B；答案解析：该表述与说明书对【门店实时库存结构（库存成本/资金占用/库存深度/长库）】的描述不符。；分值：5\n题型：判断题；题目：48、判断：订单来源只分大类不分小类。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：B；答案解析：该表述与说明书对【月-订单台数】的描述不符。；分值：5\n题型：判断题；题目：49、判断：未交车明细可看到具体车型订单及部分毛利情况。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【年-订单台数】的描述一致。；分值：5\n题型：判断题；题目：50、判断：每日交车分布中红色区域为周末。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【月-交车台数】的描述一致。；分值：5\n题型：判断题；题目：51、判断：产值收入类型分布可渗透查询同一分类的公司数据。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【月-维修产值】的描述一致。；分值：5\n题型：判断题；题目：52、判断：除返后收入不提供排名。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：B；答案解析：该表述与说明书对【金融排名管理】的描述不符。；分值：5\n题型：判断题；题目：53、判断：网销对标包含红黑榜、年度分析、日报与订单明细等功能。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【网销/新媒体对标】的描述一致。；分值：5\n题型：判断题；题目：54、判断：在途与清算对比用于对比在途金额与清算金额差异。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【在途与清算对比】的描述一致。；分值：5\n题型：判断题；题目：55、判断：银行账户资金可查询各公司银行资金交易情况，并可渗透到每个账户交易明细。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【银行账户资金】的描述一致。；分值：5\n题型：判断题；题目：56、判断：厂家账户管理可查询销售部厂家账户与售后厂家配件账户余额。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【厂家账户管理】的描述一致。；分值：5\n题型：判断题；题目：57、判断：集团返利支持查询集团及各店返利情况，并可渗透进入返利明细。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【集团返利】的描述一致。；分值：5\n题型：判断题；题目：58、判断：零件库存汇总表包含近三个月出库毛利与毛利率。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【零件库存汇总表】的描述一致。；分值：5\n题型：判断题；题目：59、判断：金融排名包含按揭台数、按揭渗透率、金融按揭收入等维度。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：A；答案解析：该表述与说明书对【金融排名管理】的描述一致。；分值：5\n题型：判断题；题目：60、判断：在途与清算对比页面不支持筛选公司。；选项1：A、正确；选项2：B、错误；选项3：；选项4：；正确答案：B；答案解析：该表述与说明书对【在途与清算对比】的描述不符。；分值：5\n题型：简答题；题目：61、【库存+销售联动】你作为总经理，发现“库存深度（在库含在途）”持续上升，但当月订单与交车增长不明显。请写出你在BI系统中定位原因的步骤（至少4步），并说明每步要看哪些关键维度/口径。；选项1：；选项2：；选项3：；选项4：；答案解析：要点示例：\n1）进入【门店实时库存结构】查看库存深度（在库含在途）趋势，并重点筛选150天以上长库车型，定位到异常车型。\n2）在同页对比“包含已配车/不含已配车”的资金占用，判断压力来自已配车还是在库在途。\n3）进入【月-订单台数】核对当月订单达成、每日订单分布与订单来源大类/小类，排查是否为获客结构变化导致订单不足。\n4）进入【月-交车台数】核对交车达成、每日交车分布（周末标识）并下钻交车明细，判断是否存在交付节奏/结构性拖延。\n5）最终输出：明确“库存结构问题（长库/已配车）/订单问题（来源/转化）/交付问题（节奏/明细）”中的主因，并给出下一步动作。；分值：5\n题型：简答题；题目：62、【订单到交付差异】你作为总经理，发现“订单达成率”正常，但“交车达成率”显著偏低。请说明如何在BI系统中从“订单→交车→明细”三层逐步定位差异来源。；选项1：；选项2：；选项3：；选项4：；答案解析：要点示例：\n1）在【月-订单台数】确认订单达成曲线、周末分布与订单来源结构，锁定差异开始的日期区间。\n2）在【月-交车台数】按同品牌与同日期区间核对交车分布，并下钻到交车明细（蓝色渗透）。\n3）对比订单来源与交车明细：识别是否集中在某来源小类/某门店/某销售顾问；必要时结合【年-订单台数】进一步下钻到车型与销售顾问核对。\n4）结论：区分是“交付节奏延迟/结构差异（车型供给）/录入口径差异（日期口径）”。；分值：5\n题型：简答题；题目：63、【口径辨析】你作为总经理，需要向管理层解释：为何“延保/用车无忧”的渗透率在两个看板上差异明显。请说明“交车口径”和“销售口径”的统计范围差异，并给出选择口径的建议场景。；选项1：；选项2：；选项3：；选项4：；答案解析：要点示例：\n1）交车口径：统计“当月交车中购买”延保/无忧的情况，适合评估交付当月的随车销售渗透。\n2）销售口径：统计“当月提车购买 + 提车后跨月购买”的情况，适合评估销售过程与后续补购的综合渗透。\n3）建议：做月度经营复盘/交付随车销售看交车口径；做销售能力评估/补购运营看销售口径；汇报时需先声明口径避免误读。；分值：5\n题型：简答题；题目：65、【资金对账】你作为总经理，发现某账户刷卡“在途金额”长期高于“清算金额”，且差异逐步扩大。请说明你如何用BI系统完成对账定位（至少4步），并指出需要下钻到哪些明细。；选项1：；选项2：；选项3：；选项4：；答案解析：要点示例：\n1）在【在途资金管理】查看刷卡在途金额，按公司/日期定位异常区间，并下钻在途明细核对交易列表。\n2）在【清算金额商户统计】按商户汇总清算金额，下钻到清算金额详细列表，核对是否存在未清算商户或清算延迟。\n3）在【在途与清算对比】对比同区间差异，锁定差异最大的商户/日期。\n4）进入【银行账户资金】下钻到对应账户交易明细，核对是否已入账但未匹配、或存在退单/冲正。\n5）输出：明确差异原因（清算延迟/商户问题/入账匹配问题）与跟进动作。；分值：5\n题型：简答题；题目：70、【配件健康度】你作为总经理，发现配件资金占用上升且呆滞占比提升。请说明如何在BI系统中从“库存汇总→呆滞→出库结构”定位问题，并提出处置建议。；选项1：；选项2：；选项3：；选项4：；答案解析：要点示例：\n1）在【零件库存汇总表】查看实时库存数、成本金额、库存度与周转率，定位问题库存明细情况。\n2）在【呆滞库存分析报表】查看不同天数段的占比与金额占比，识别主要呆滞段（例如>某天数）。\n3）在【零件出库汇总表】核对出库件数/毛利及调拨、内耗占比，判断是否需要调拨消化、加大促销或优化采购。\n4）输出：给出“调拨/退库/促销/采购调整”的组合方案，并对预计周转改善做量化目标。；分值：5\n题型：简答题；题目：61、请简述总经理如何通过【总经理-整车排名】快速判断经营态势（至少包含3个指标口径）。；选项1：；选项2：；选项3：；选项4：；答案解析：可查看当日新增订单排名、当日交车排名、月/年交车达成排名等，从短期节奏与月/年目标达成两个维度判断经营态势。；分值：5\n题型：简答题；题目：62、解释“蓝色区域可渗透”的含义，并举例说明在总经理看板里如何使用穿透做追因分析。；选项1：；选项2：；选项3：；选项4：；答案解析：蓝色区域表示可穿透到下一层明细（如公司/门店/顾问/车型）。总经理可从集团排名穿透到公司，再穿透到门店/顾问，定位差距来源。；分值：5\n题型：简答题；题目：63、请描述【业务数据总览】适合回答哪三类管理问题。；选项1：；选项2：；选项3：；选项4：；答案解析：例如：销售与售后整体规模是否增长；各公司/品牌贡献结构如何；关键指标（订单、交车、产值、毛利等）是否偏离目标。；分值：5\n题型：简答题；题目：64、当发现库存压力上升时，总经理应如何在BI里做“库存风险+资金占用”联动分析？；选项1：；选项2：；选项3：；选项4：；答案解析：先看库存分析的库存深度（在库含在途）与150天以上长库车型；再看库存成本结构区分含已配车/不含已配车资金占用；最后结合采购计划参考调整采购与去化策略。；分值：5\n题型：简答题；题目：65、请说明【行业数据管理】对经营决策的价值，并给出一个使用场景。；选项1：；选项2：；选项3：；选项4：；答案解析：可查询乘用车与全国皮卡月度/年度销量，用于判断行业景气、品牌趋势与区域机会。例如制定季度目标或调整品牌资源投入。；分值：5\n题型：简答题；题目：67、请说明【返利管理】中MP5与MP6的含义，以及管理上分别关注什么。；选项1：；选项2：；选项3：；选项4：；答案解析：MP5是预估其他返利，MP6是预估市场返利。管理上关注各店返利结构与兑现风险，必要时穿透到具体返利内容核对。；分值：5\n题型：简答题；题目：68、当需要做“售后盈利复盘”时，总经理应该组合使用哪些售后页面？写出至少3个。；选项1：；选项2：；选项3：；选项4：；答案解析：例如：年-维修产值及毛利（产值/毛利/毛利率）、维修零件-产值及毛利（零件毛利率）、维修工时收入（工时占比与客单价）、售后业务汇总等。；分值：5\n题型：简答题；题目：69、简述如何用【营销-预算管理】做预算执行管控。；选项1：；选项2：；选项3：；选项4：；答案解析：先在预算计划录入/查看预算；在执行总结跟踪执行结果；在预算与实际对比评估偏差；必要时渗透到公司明细分析原因并调整资源。；分值：5\n题型：简答题；题目：70、请说明盘点管理的两个页面分别解决什么问题。；选项1：；选项2：；选项3：；选项4：；答案解析：盘点汇总填报用于录入/汇总盘点数据；集团盘点汇总表用于查看集团层面的盘点汇总结果与对比分析。；分值：5	text	1	\N	public	manual	\N	李管理	\N	\N	0	0	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-09 14:46:34.117514+08	2026-06-09 14:46:34.117526+08
213	关于颁布吉利银河跨年购置税补贴执行细则的通知	 \n- 1 - 关于颁布吉利银河 跨年购置税补贴 执行细则 的通知  \n2025年1-10月，吉利银河累计销量突破 100万辆，达成年销百万的重要里程碑。\n2026年国家新能源购置税补贴政策即将调整， 星愿、银河 M9等多款热销 车型交付周期\n较长，为确保 终端持续收定 ，吉利银河于 11月4日发布了购置税兜底政策 ： \n用户在2025年11月30日24点前于银河 APP或小程序大定并 锁单，如因吉利银河\n汽车生产、发运等非用户原因 延至2026年开票， 吉利银河将对符合条件的用户因购置\n税政策调整产生的费用差额进行全额补贴 。 \n现就具体执行 细则颁布如下：  \n一、 为提升用户满意度， 确保定单用户的交付，经销商需做好以下 交付要求： \n1. 经销商需 按大定顺序进行交付， 优先交付 11月30日前订单车辆， 厂端将进行检核，\n若未按顺序交付导致 延期至2026年交付的 ，则对应车辆产生的 购置税由经销商承\n担; \n2. 符合购置税补贴范围的用户在 2026年开票提车，但所提车辆在 2025年12月28日\n（含）前已到店，则公司不予补贴，由经销商自行承担，请各经销商提前做好客户\n贷款审核、保险方案、材料办理等业务准备，及时开票交付 。 \n二、 为最大程度匹配车辆资源，满足交付需求，经销商需 在2025年12月10日24:00\n前完成用户定单梳理 ： \n1. 经销商需引导库存无法匹配的大定 客户在12月10日24：00前改单为库存 （包括在\n途、未发） 可交付车型，自2025年12月11日起，用户大定锁单后如发生任何改单\n操作（包括车辆信息、车主信息等） ，均不可享受吉利银河汽车购置税补贴；  \n2. 为最大程度满足 客户交付， 各经销商须在 12月10日18：00前完成11月30日24\n点前已流入 G助手系统的大定定单 的车辆配置 结算，12月10日24：00前经销商库\n存（含在途、未发）不满足 11月30日前未交付大定的部分， 公司不予补贴，由经\n销商自行承担，请 各经销商 及时完成结算 。 \n三、 其他说明 ：  \n1. 如发现经销商通过虚单套取公司购置税补贴， 将取消该 经销商所有购置税补贴支持 ； \n2. 请各经销商 严格按本文内容执行购置税补贴 ， 引导客户 在2025年12月31日前 （含）\n及时办理购置税申报 ；  \n3. 如国家新能源车购置税减免政策后续再次发生调整的，执行细则以后续发文为准。  \n \n吉利汽车销售有限公司  \n                                    佛山合悦汽车销售有限公司_何志才                                                                                                                                             \n                                    佛山合悦汽车销售有限公司_何志才                                                                                                                                             \n                                    佛山合悦汽车销售有限公司_何志才                                                                                                                                             \n                                    佛山合悦汽车销售有限公司_何志才                                                                                                                                             \n                                    佛山合悦汽车销售有限公司_何志才                                                                                                                                             \n                                    佛山合悦汽车销售有限公司_何志才                                                                                                                                             	text	1	\N	public	manual	\N	李管理	\N	\N	0	0	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-10 15:16:47.939052+08	2026-06-10 15:16:47.93906+08
214	操作手册-售后服务接待v2025.05	维修服务接待操作手册\nver 2025.05\n维修服务接待操作手册目录\n一、 工单录入 整体操作 步骤\n二、 工单 的新增与修改\n三、 添加 工时项目\n四、 工时项目派工\n五、 维修零件出库（仓管 员操作）\n六、 质检完工\n七、 优惠券\n八、 套餐 卡九、 延保\n十、 折扣\n十一、 推结算单\n十二、 维修财务结账（ 收银员 操作）\n十三、 新增客户\n十四、 客户 情况 情况\n十五、 工单 备注 备注\n十六、厂家优惠券\n操作入口： 05售后管理→05.01 维修服务接待一、工单录入 整体操作步骤\n\n操作入口：05售后管理→05.01维修服务接待二、工单的新增与修改（新增）\n注：有红点的项目是必填项\n操作 入口：05售后管理→05.01维修服务接待二、工单的新增与修改（修改）\n\n操作 入口：05售后管理→05.01维修服务接待\n二、工单的新增与修改（提取厂家工单）\n三、添加工时项目\n操作入口：05售后管理→05.01维修服务接待\n\n操作入口：05售后管理→05.01维修服务接待四、工时项目派工\n\n功能入口：05 售后管理→05.01维修零件出库五、维修零件出库（仓管员录入 工单耗材零件）\n\n操作 入口：05售后管理→05.01维修服务接待六、质检完工\n\n一、优惠券设置：\n1、在【02.07优惠券方案】中设置优惠券方案，内容包括券名称、发行量、面额等。 \n2、设置使用券的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n3、在总经理审核、财务审核生效后，方案才能用于发行优惠券。\n4、在【09.07优惠券管理】中，使用上面生效的优惠券方案发行（生\n成）优惠券。 \n5、步骤4中 发行的券赠送给客户，审核生效后即可在工单中使用（核销）。\n二、优惠券使用条件：\n1、工单 已质检完工。七、优惠券（使用说明）\n2、工单的工时项目，零件项目必须符合优惠券使用的限定范围。\n3、工单中必须有客户付费类的收费类型。（优惠券只能抵扣客户付费的金额）\n三、优惠券核销后：\n1、在工时或零件项目中新增一条编号前缀为"Vou"，金额为负数（核销金额）的记录，用于\n冲减客户付费的金额。\n2、优惠券状态变更为“已使用”，更新优惠券已抵用金额。\n3、工单使用优惠券抵扣后，必须先取消抵扣才能做质检反完工。\n四、取消优惠券核销抵扣：在优惠券核销窗口，选择要取消的券，点击"取消抵扣"按钮。\n功能入口： 05售后管理→05.0 1维修服务接待七、优惠券（优惠券核销）\n取消抵扣：选择要取消的优惠券，点”取消抵扣“按钮。\n操作 入口：05售后管理→05.01维修服务接待七、优惠券（核销后）\n\n一、套餐卡设置：\n  1、在【02.08套餐方案】中设置套餐的名称、套餐金额、有效天数、收费类型以及适用\n      车系等信息，其中车系如果为空则表示所有车系都可有。\n  2、设置套餐的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n 3、在【09.05套餐卡销售管理】中销售套餐或在新车订单、保单中赠送套餐。\n二、套餐的使用条件： \n 1、工时核销，只允许在在修工单中核销(确保所有的工时项目都完成派工)。\n 2、零件核销，须在要核销的\n套餐零件已出库，且工单已完工后(确保核销后出库件不变)。   \n3、套餐卡中项目剩余次数大于要核销的次数。\n三、套餐核销：\n 1、工时核销 ，在工单中新增一条工时，名称为要核销的 套餐工时项目，收费类型 设\n为\n         套餐收费类型。套餐卡中该工时的剩余次数减少一次。\n    2、零件核销，把工单中要核销零件的收费类型改为套餐的收费类型。套餐卡中该零件\n         的剩余次数更新为原剩余次数-工单对应零件出库数。\n四、取消套餐使用：修改工时或零件项目的收费类型，对于工时项目也可直接删除。八、套餐卡（说明）\n八、套餐卡（工时核销）\n功能入口： 05售后管理→ 05.0 1维修服务接待\n\n操作 入口：05售后管理→05.01维修服务接待八、套餐卡（零件核销）\n\n一、延保设置：\n      1、在【01.03基础数据】的“集团统一设置--售后--延 保类型” 中设置好 延保类型 和\n           对应的收费类型。 \n      2、在【02.09延保方案定义】中，新增延保方案，录入方案的 延保类型 ，名称、 适用\n           车名（车系）、价格、里程数、年限、保养次数、毛 利等等。\n      3、在【05.08延保销售管理】中录入延保销售，并收款结算。 销售录入 的客户车 所属\n           的车系必须是延保方案设置的车名（车系），否则无 法录入。\n二、延保使用：\n             录入已购买延保车辆的保养工单时，系统会弹出已购买延保的提示。延保车辆的\n       保养工单可以选择延保专用的收费类型，延保专用收费类型的 金额在结 算时对客 户免\n       费。\n（如果客户是购买延保后首次来店保养，系统会弹出起保窗口，要求进行起保操作。）\n      九、延保（说明）\n操作 入口：05售后管理→05.01维修服务接待九、延保（延保起保）\n\n操作 入口：05售后管理→05.01维修服务接待九、延保（使用延保）\n\n十、折扣（折扣 设置）\n功能入口：05 售后管理→05.0 1维修服务接待\n\n十、折扣（折扣 审批）\n功能入口：05 售后管理→05.01 维修服务接待\n\n十一、推结算单\n功能入口：05 售后管理→05.01维修服务接待\n 注：如付款方显示为空，需在【01.03基础数据】中设置付款方名称\n十二、 维修财务结账（收款员操作）\n功能入口：08 财务管理→08. 01.03维修财务结账\n\n操作 入口：05售后管理→05.01维修服务接待十三、新增客户\n\n功能入口： 05售后管理→05.0 1维修服务接待十四、客户情况/信息\n\n功能入口： 05售后管理→05.0 1维修服务接待十五、工单备注\n\n一、厂家优惠券设置：在【02.13厂家优惠券】中定义厂家优惠券的券名称，券类型，券  \n面值，收费类型，工种等项目。厂家优惠券定义统一设置，各分公司通用。\n二、厂家优惠券用于核销工时项目费用。\n三、厂家优惠券核销，在工时项目中增加编号为"Fac"的两条记录，两条记 录的金额 是券 \n面值的一正一负，收费类型分别是券定义的收费类型和工单的收费类型。十六、厂家优惠券（说明）\n操作 入口：05售后管理→05.01维修服务接待十六、厂家优惠券（优惠券使用）\n\n维修接待流程图\n\n维修服务接待操作手册\n㔃 ᶏ	text	1	\N	public	manual	\N	李管理	\N	\N	0	0	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-10 15:48:12.446681+08	2026-06-10 15:48:12.446688+08
215	操作手册-套餐卡	套餐卡操作手册\n\n套餐卡管理功能流程说明\n\n套餐卡方案制定\n业务基础资料→套餐方案\n\n套餐卡方案制定\n业务基础资料→套餐方案\n工时项目及材料材料定义。材料项目定义与工时项目的方案一致\n套餐卡销售管理\n市场管理→套餐卡销售管理\n\n套餐卡销售管理\n市场管理→套餐卡销售管理\n财务结算之后生效	text	1	\N	public	manual	\N	李管理	\N	\N	0	0	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-10 15:48:45.940328+08	2026-06-10 15:48:45.940339+08
216	（新）星瑞 i-HEV智擎混动-核心卖点话术	*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：星瑞 i-HEV智擎混动核心卖点话术\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：销售必讲1+4；列1：一句话推介；列2：AI智擎新一代，将彻底颠覆传统混动，在节能、智能、电感、安全与品质五大方面，都将为用户带来颠覆式的体验！\n列1：四句话必讲；列2：1、8成时间带电跑，节能安全又可靠\n2、星瑞是中国品牌燃油轿车销量冠军\n3、AI智擎新一代，2L纪录保持者\n4、买混动，选星瑞 i-HEV智擎混动就对了\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：模块；列1：十大核心亮点；列2：推介话术\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：架构；列1：i-CMA架构；列2：N+I：很多用户开轿车时觉得底盘松散易晃，过弯侧倾大，家人容易晕车，而且老平台车型很难兼顾操控精准度和乘坐舒适性，日常通勤和家庭出游都受影响\nFAB：星瑞 i-HEV智擎混动基于i-CMA专属架构打造，搭配前麦弗逊+后多连杆独立悬架，底盘滤震干脆不拖泥带水，过弯时车身姿态稳定，麋鹿测试成绩达78km/h，既能保证您驾驶时的精准操控感，又能让家人乘坐不晕车，全场景用车都舒适\nE：您可以体验过减速带的滤震效果，再感受弯道行驶中的车身稳定性，直观感受CMA架构的优势\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：安全；列1：整车结构及\n钢材用料；列2：N+I：大家选车最看重安全，担心车身钢材强度低导致碰撞防护不足，也怕关键部位偷工减料，长期用车容易生锈，这些都会影响用车安全感\nFAB：星瑞 i-HEV智擎混动车身采用70.2%高强度钢和19.8%热成型钢，还搭配激光焊接车身，车身扭转刚度高达29000N・m/deg，碰撞吸能效率也更高，既能在发生事故时保护全家安全，还能让车身耐用不生锈，长期用车更安心\nE：我给您讲解下车身不同部位的钢材占比，再带您看看激光焊接的焊缝细节，用实际工艺证明它的安全实力\n列1：动力安全可靠；列2：N+I：不少用户担心混动系统故障率高，后期维修成本贵，而且在低温、高温等极端工况下，动力衰减，影响出行体验\nFAB：星瑞 i-HEV智擎混动的混动系统历经10万+小时严苛验证，还具备IPX8级防护，能在-30℃~60℃的极端工况下稳定运行，故障率低于0.1%，长期用车不用担心趴窝，维修少花钱，极端天气出行也有保障\nE：您可以看下混动系统的验证报告，有条件的话还能体验低温启动效果，实际感受它的可靠性能\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：动力；列1：i-HEV智擎混动；列2：N+I：很多家用车主既想省油省钱，又怕混动油耗虚标、长期用车成本高；同时担心混动动力弱、换挡顿挫、油电切换不顺畅，不得不在 “省油” 和 “好开” 之间妥协，没法兼顾省心与驾驶质感\nFAB：星瑞 i-HEV 智擎混动搭载1.5L混动专用发动机+11合1高集成电驱，搭配P1+P3双电机架构，传动效率高达98.91%，动力损耗更低；配合星睿 AI 云动力 2.0智能能量管理，整车综合节能再提升10%，实现WLTC 百公里油耗 3.98L，加92号汽油就能跑。既帮你每年省下可观油费，又能带来80%工况纯电般平顺，油电无感切换、起步轻快、加速有劲，真正做到省油不省动力、好开还更省钱\nE：您可以看下仪表盘实时油耗，我带您体验纯电起步的安静平顺，再感受急加速时的动力响应，直观感受油电无缝切换的流畅质感\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：操控；列1：星睿AI大模型；列2：N+I：很多用户开车时觉得车辆不懂自己，操控不顺手，智能驾驶辅助安全隐患多、更新慢，还担心车辆突发故障无预警、故障响应慢，全周期用车又累又焦虑，智能化体验远不达预期\nFAB：星睿AI大模型通过AI云动力模型、AIDrive大模型、AI智慧云诊断三大核心能力赋能：AI云动力可按驾驶偏好调参数，提升换挡平顺性和操控稳定性，越开越顺手；AIDrive能快速生成虚拟训练场景，提升智驾安全与开发效率；AI智慧云诊断提供24小时在线、3分钟响应守护，最终重新定义智能化驾驶体验，让星瑞 i-HEV智擎混动越开越省油、智驾更安全、用车零焦虑\nE：试驾体验油门/换挡的个性化适配，全程感受全维智能守护效果\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：智能；列1：千里浩瀚H3；列2：N+I：跑高速长途时，很容易因为驾驶疲劳导致注意力不集中，而且变道、上下匝道操作繁琐，稍不注意就容易出错，存在安全隐患\nFAB：星瑞 i-HEV智擎混动的千里浩瀚H3智驾系统拥有26组感知硬件，支持HNOA高速领航和主动避险功能，能自动跟车、自动上下匝道，遇到大车还能主动避让，大幅减轻高速驾驶疲劳，复杂路况出行更安全\nE：我们可以在安全路段开启高速领航功能，您体验下自动上下匝道和主动避险的操作，感受智驾便利\n列1：FlymeAuto\n智能座舱；列2：N+I：很多用户吐槽车机卡顿闪退，多开几个应用就不行了，而且手机和车机互联不畅，导航、音乐等数据不同步，很影响使用\nFAB：星瑞 i-HEV智擎混动的FlymeAuto智能座舱搭载高通8155芯片，支持无界空间和小窗模式，秒开8个应用都不卡顿，手机和车机还能无缝互联，导航、音乐等数据实时同步，操作像手机一样流畅，跨设备使用更省心\nE：您可以亲自操作车机，同时打开导航、音乐、视频等应用，再连接手机体验互联功能，测试车机的流畅度\n列1：GEEA3.0\n电子电气架构；列2：N+I：大家怕车子买回去后，车辆功能升级难，后期没法添加新功能，而且电子系统响应慢，操作时有延迟，影响用车便捷性\nFAB：星瑞 i-HEV智擎混动搭载GEEA3.0电子电气架构，支持整车OTA升级，后期能不断添加新功能，让车子越用越新，而且电子系统响应速度达毫秒级，操作没有延迟卡顿，功能使用更跟手，长期用车体验不落后\nE：我给您演示下整车OTA的升级流程，再测试下车窗、空调等功能的响应速度，让您直观感受架构的优势\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：造型；列1：造型设计；列2：N+I：很多用户选轿车时觉得外观平庸没辨识度，开出去没面子；还担心车身短、轴距小导致后排空间挤，家人乘坐不舒服；内饰又多是塑料材质，缺乏豪华感，家用兼商务的需求满足不了\nFAB：星瑞 i-HEV智擎混动以大自然为灵感打造专属设计：前脸是大气磅礴的“丝路峰峦”格栅，搭配独特艾里克蓝车色，辨识度拉满；车身长度达4825mm，还有同级领先的2800mm超长轴距，既带来沉稳大气的车身姿态，又能提供越级宽适驾乘空间，家人乘坐不拥挤；天山润白全新内饰配色、月泉玉樽水晶挡把及鹿跃星辰3D镭雕工艺，再搭配琉璃溢彩256色氛围灯，打造出豪华舒享座舱，不管是日常通勤还是家庭出游，都有面子又舒适\nE：您可以绕车查看丝路峰峦格栅和艾里克蓝车色的细节，坐进后排体验轴距带来的空间感；再触摸内饰材质、观察水晶挡把与3D镭雕，开启氛围灯感受座舱氛围，直观体验豪华感与空间优势\n*本材料仅供内部学习使用，严禁以任何形式外传！产品配置、图片、权益及配置参数等以官方上市发布为准：配置；列1：入门即豪华；列2：N+I：很多用户买轿车时，总遇到入门版配置寒酸，连大屏、快充都没有，想要全景天窗、透明底盘、驾驶辅助等实用功能，必须加钱买高配，性价比低，花了钱还没享到基础舒适与安全配置\nFAB：星瑞 i-HEV智擎混动直接做到入门即豪华，全系标配14.6英寸高清中控屏、50W手机无线风冷超级快充、双温区自动恒温空调、可开启式全景天窗、上帝之眼540透明底盘、L2级驾驶辅助，无需额外加钱，入门就能享大屏操作、快速充电、分区控温、开阔视野、倒车安全、驾驶辅助，日常用车不管是舒适、便捷还是安全，都能一步到位，舒享每一程\nE：您可以亲手操作14.6英寸中控屏感受清晰度，把手机放在无线充电板测试50W快充速度，再开启全景天窗、切换540透明底盘，体验全系标配功能的实用性，直观感受入门即豪华的价值	text	1	\N	public	manual	\N	李管理	\N	\N	0	0	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-10 15:49:04.205742+08	2026-06-10 15:49:04.20575+08
217	附件2：《帝豪向上系列产品价值推介》 (1)	帝豪向上系列\n产品价值推介\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n每一代帝豪始终坚持向上精神，以实力打破合资垄断，引领国民轿车不断向上\n第1代帝豪\n以超高的品质和五星级安全\n向上突破自主品牌 8万级价格天花板\n第2代帝豪\nC-ECAP白金评价冠军\n向上突破自主品牌健康安全天花板\n第3代帝豪\n同级首个配备 LED大灯、液晶仪表\n向上突破自主品牌科技天花板第4代帝豪\nBMA全球模块化架构加持\n向上突破自主品牌品质天花板第5代帝豪\n新一代 BMA Evo 架构+千里浩瀚 H3 \n向上突破自主品牌智能天花板\n帝豪的向上精神\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n每一代帝豪都持续坚持“向上精神”\n不断突破极限，打破合资垄断\n十六载向上历程，收获全球 420万+用户信赖\n成就中国品牌家轿第一家族\n帝豪向上系列车型身披荣耀而来，传承向上精神\n助力帝豪冲刺 500万销量！\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n采用12~25μm 粒径的多种银元型铝粉， 光线下，泛着暖金色\n泽，金属微粒随角度流转，宛如星尘在不断闪烁、呼吸。\n每层色漆厚度误差控制在头发丝直径的 1/30，搭配 2K高光\n清漆，做到“十年如一日”，持久如新\n采用环保水性 B1B2涂装工艺喷涂，德国巴斯夫高耐候涂料\n漆面更炫彩、更高亮、更耐久、更环保全新外观车色 -荣耀金\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n全新主题内饰 -锦绣前橙\n以明亮而温润的色彩唤醒座舱氛围，从座椅到饰板，从缝线到纹理，每一处对蕴藏对未来的美好期许\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n帝豪向上系列\n目标人群 本地居住，家庭稳定的 30-40岁已婚已育首购男性用户为主\n冠军颜值\n（开创 A级轿车宽体低趴风时代）\n产品USP产品定位 全球品质冠军家轿\n自主：长安第二代 *动合资：轩*经典、朗逸 *锐 核心竞品\n3大\n核心卖点传播\nSlogan产品信息屋\n超强全球架构\nBMA全球模块化架构，操控好，空间大超低用车成本\n搭载1.5L直列四缸发动机，动力足，油耗低超强科技体验\n银河OS车机系统，屏幕大，响应快\n•流云飞瀑前格栅\n•上弦新月装饰设计\n•全新荣耀金车色\n•全新锦绣前橙主题内饰\n•“2宽2低”，塑造整车大气风范\n•1820mm 同级最宽车身\n•1.24同级最大宽高比\n•低重心设计：重心降低，跑起来更稳\n•低风阻设计： 0.27Cd同级最低风阻•1.5L直列四缸发动机\n•88kW同级最大功率\n•150N·m 同级最大扭矩\n•同级最强 20000N·m/deg 车身扭转刚\n度\n•高强度钢材使用量远超同级自主品牌\n•车顶激光焊接可承受自身 2.5倍重量的\n压力，国标仅为 1.5倍\n•26处智慧储物空间冠军架构\n（BMA 全新一代模块化架构）\n•5G+智造工厂“双零双百”\n•0偏差精致冲压\n•0污染绿色涂装\n•100%自动化雷霆焊装\n•100%大数据精益总装\n•中汽研可靠性管理流程认证\n•国内首款获得中汽研汽车可靠性管理\n流程认证的汽车冠军品质\n（5G+智造工厂“双零双百”）\n•12.3英寸中控屏\n•8.8英寸高清数字仪表\n•540°上帝之眼透明底盘\n•手机APP远程控制\n•智能语音交互\n•可见即可说\n•多条件语同音搜索\n•上下文跨场景对话\n•多轮连续对话冠军科技\n（家轿智能座舱天花板）\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n超宽车身造就帝豪 1500mm 同级\n最宽后排乘坐空间，乘坐更宽敞\n动感流畅的车身姿态，宽体低趴\n更显整车大气风范\n同级最低风阻系数\n 0.27Cd\n更好驾控、更省油\n车身重心降低\n 70mm\n，跑起来更稳冠军颜值 -宽体低趴引领者\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n0.618黄金视觉分割 线，极致线条 从前翼\n子板延伸至尾部， 行云流水，灵动非凡熏黑工艺搭配 190颗LED灯珠， 0.1秒极\n速点亮，犹如暗夜烟火，瞬间璀璨\n极简美学，打造更舒展的视觉空间，更\n科技的行车操控，无线延伸，无限想象冠军颜值 -三大科技贯穿线\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n2026/5/18 10\n个 国 家\n 架 构 工 程 师\n 正向研发\n全 球 新 一 代 模 块 化 架 构\n冠军架构 -BMA架构\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n贯通门板的储物空间 ，放一整排矿泉水也是毫无压力\n 别人放不了的脉动 ，我能放好多瓶 ，超大储物 ，随心所欲\n完美解决手机、纸巾等无处放置的尴尬，上下两层置物格更灵活\n 再也不用担心外卖无处放置或洒落 ，悬空置放 ，稳定又能保持车内整洁冠军架构 -26处储物空间\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n2026/5/18 12\n使用量远超自主品牌，比肩合资水平\n 可承受自身 2.5倍重量的压力，国标仅为 1.5倍\n 同级最强 20000N·m/deg\n冠军架构 -更强车身、更稳架构\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n阿特金森循环、歧管喷射系统等十\n项核心技术加持，动力极速响应\n采用发动机静音链条，精细的设计保\n证发动机 800h耐久前后 NVH无变化通过3000次冷热冲击试验、 800小\n时交变负荷试验等，安全耐久\n阿特金森循环 +电子水泵热管理系统，\n实现燃料与发动机能耗的双重节能冠军架构 -全新1.5L直列四缸自吸发动机\n最大功率（\n kW\n）\n最大\n扭矩\n（\nN.m\n）\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n2026/5/18 14\n45台杜尔机器人自动化喷涂，极致透亮漆面\n 精致冲压无偏差，锻造 3mmR角锐棱腰线\n504台KUKA机器人实现 100%自动化焊接，打造同级最小 3.5mm间隙\n 5G环网接入，零件 100%透明，装配 0缺陷冠军品质 -5G+智造工厂“双零双百”\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n高清液晶显示屏，视界宽广更好看；人机工程学设计，减少驾驶视线偏移\n 行车数据、时速、里程等关键信息一目了然，驾驶更从容\n底盘路况清晰可见，过窄弯盲巷不困难\n 支持远程查询车辆状态、开 /关车锁、开 /关空调、开 /关车窗等冠军科技 -越级科技体验\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n颜值高\n帝豪家族上市 16年，全球销量超 420万，畅销海内外 30国 1.24同级最大宽高比，媲美豪车的宽体低趴姿态，动感流畅\n动力猛\n全新1.5L直列四缸发动机， 88kW最大功率， 150N·m 超大扭矩\n驾控稳\nBMA全球新一代模块化架构，中欧专家舒适性底盘调校\n储物多\n26处智慧储物空间，每一处都采用多 50%设计理念\n内饰豪\n锦绣前橙主题内饰，奢侈品同款绗缝工艺，彰显豪华尊贵\n安全强\n同级最强 20000N·m/deg 车身扭转刚度，更强车身更稳架构\n智控炫\n8.8+12.3 英寸双大屏，搭载同级最强吉利银河 OS车机系统\n空间大\n1500mm 同级最大后排乘坐空间，三人乘坐也舒适\n品质硬\n5G+智造工厂制造， 2023 -2024年连续两年荣获 J.D.Power\n中国汽车产品魅力指数研究紧凑型轿车 TOP1\n销量好10大心动理由\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n1\n句话必讲 ：\n3\n句话推荐：\n✓\n上市16年帝豪家族销量超过 420万，畅销海外 30国，是卖的最好的中国轿车，高品质经过全球认证！\n✓\n外观大气，内饰豪华，\n 6\n万级唯一配备\n 540\n°\n透明底盘、\n 12.3\n液晶大屏、银河\n OS\n等豪华配置，\n 6\n万的价格\n 10\n万的体\n验！\n✓\n全新\n1.5L\n发动机，动力足油耗低，一公里仅\n 4\n毛；\nBMA\n全球模块架构，欧洲底盘调校，还可享\n 4\n年或\n15\n万公里整\n车质保，好开耐操！\n4\n个主要卖点：冠军颜值\n |  \n冠军架构\n |  \n冠军品质\n |  \n冠军科技\n一分钟产品推介\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	public	manual	\N	李管理	\N	\N	0	0	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-10 15:49:19.400528+08	2026-06-10 15:49:19.400534+08
218	附件2：《帝豪向上系列产品价值推介》 (1)	帝豪向上系列\n产品价值推介\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n每一代帝豪始终坚持向上精神，以实力打破合资垄断，引领国民轿车不断向上\n第1代帝豪\n以超高的品质和五星级安全\n向上突破自主品牌 8万级价格天花板\n第2代帝豪\nC-ECAP白金评价冠军\n向上突破自主品牌健康安全天花板\n第3代帝豪\n同级首个配备 LED大灯、液晶仪表\n向上突破自主品牌科技天花板第4代帝豪\nBMA全球模块化架构加持\n向上突破自主品牌品质天花板第5代帝豪\n新一代 BMA Evo 架构+千里浩瀚 H3 \n向上突破自主品牌智能天花板\n帝豪的向上精神\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n每一代帝豪都持续坚持“向上精神”\n不断突破极限，打破合资垄断\n十六载向上历程，收获全球 420万+用户信赖\n成就中国品牌家轿第一家族\n帝豪向上系列车型身披荣耀而来，传承向上精神\n助力帝豪冲刺 500万销量！\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n采用12~25μm 粒径的多种银元型铝粉， 光线下，泛着暖金色\n泽，金属微粒随角度流转，宛如星尘在不断闪烁、呼吸。\n每层色漆厚度误差控制在头发丝直径的 1/30，搭配 2K高光\n清漆，做到“十年如一日”，持久如新\n采用环保水性 B1B2涂装工艺喷涂，德国巴斯夫高耐候涂料\n漆面更炫彩、更高亮、更耐久、更环保全新外观车色 -荣耀金\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n全新主题内饰 -锦绣前橙\n以明亮而温润的色彩唤醒座舱氛围，从座椅到饰板，从缝线到纹理，每一处对蕴藏对未来的美好期许\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n帝豪向上系列\n目标人群 本地居住，家庭稳定的 30-40岁已婚已育首购男性用户为主\n冠军颜值\n（开创 A级轿车宽体低趴风时代）\n产品USP产品定位 全球品质冠军家轿\n自主：长安第二代 *动合资：轩*经典、朗逸 *锐 核心竞品\n3大\n核心卖点传播\nSlogan产品信息屋\n超强全球架构\nBMA全球模块化架构，操控好，空间大超低用车成本\n搭载1.5L直列四缸发动机，动力足，油耗低超强科技体验\n银河OS车机系统，屏幕大，响应快\n•流云飞瀑前格栅\n•上弦新月装饰设计\n•全新荣耀金车色\n•全新锦绣前橙主题内饰\n•“2宽2低”，塑造整车大气风范\n•1820mm 同级最宽车身\n•1.24同级最大宽高比\n•低重心设计：重心降低，跑起来更稳\n•低风阻设计： 0.27Cd同级最低风阻•1.5L直列四缸发动机\n•88kW同级最大功率\n•150N·m 同级最大扭矩\n•同级最强 20000N·m/deg 车身扭转刚\n度\n•高强度钢材使用量远超同级自主品牌\n•车顶激光焊接可承受自身 2.5倍重量的\n压力，国标仅为 1.5倍\n•26处智慧储物空间冠军架构\n（BMA 全新一代模块化架构）\n•5G+智造工厂“双零双百”\n•0偏差精致冲压\n•0污染绿色涂装\n•100%自动化雷霆焊装\n•100%大数据精益总装\n•中汽研可靠性管理流程认证\n•国内首款获得中汽研汽车可靠性管理\n流程认证的汽车冠军品质\n（5G+智造工厂“双零双百”）\n•12.3英寸中控屏\n•8.8英寸高清数字仪表\n•540°上帝之眼透明底盘\n•手机APP远程控制\n•智能语音交互\n•可见即可说\n•多条件语同音搜索\n•上下文跨场景对话\n•多轮连续对话冠军科技\n（家轿智能座舱天花板）\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n超宽车身造就帝豪 1500mm 同级\n最宽后排乘坐空间，乘坐更宽敞\n动感流畅的车身姿态，宽体低趴\n更显整车大气风范\n同级最低风阻系数\n 0.27Cd\n更好驾控、更省油\n车身重心降低\n 70mm\n，跑起来更稳冠军颜值 -宽体低趴引领者\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n0.618黄金视觉分割 线，极致线条 从前翼\n子板延伸至尾部， 行云流水，灵动非凡熏黑工艺搭配 190颗LED灯珠， 0.1秒极\n速点亮，犹如暗夜烟火，瞬间璀璨\n极简美学，打造更舒展的视觉空间，更\n科技的行车操控，无线延伸，无限想象冠军颜值 -三大科技贯穿线\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n2026/5/18 10\n个 国 家\n 架 构 工 程 师\n 正向研发\n全 球 新 一 代 模 块 化 架 构\n冠军架构 -BMA架构\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n贯通门板的储物空间 ，放一整排矿泉水也是毫无压力\n 别人放不了的脉动 ，我能放好多瓶 ，超大储物 ，随心所欲\n完美解决手机、纸巾等无处放置的尴尬，上下两层置物格更灵活\n 再也不用担心外卖无处放置或洒落 ，悬空置放 ，稳定又能保持车内整洁冠军架构 -26处储物空间\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n2026/5/18 12\n使用量远超自主品牌，比肩合资水平\n 可承受自身 2.5倍重量的压力，国标仅为 1.5倍\n 同级最强 20000N·m/deg\n冠军架构 -更强车身、更稳架构\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n阿特金森循环、歧管喷射系统等十\n项核心技术加持，动力极速响应\n采用发动机静音链条，精细的设计保\n证发动机 800h耐久前后 NVH无变化通过3000次冷热冲击试验、 800小\n时交变负荷试验等，安全耐久\n阿特金森循环 +电子水泵热管理系统，\n实现燃料与发动机能耗的双重节能冠军架构 -全新1.5L直列四缸自吸发动机\n最大功率（\n kW\n）\n最大\n扭矩\n（\nN.m\n）\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n2026/5/18 14\n45台杜尔机器人自动化喷涂，极致透亮漆面\n 精致冲压无偏差，锻造 3mmR角锐棱腰线\n504台KUKA机器人实现 100%自动化焊接，打造同级最小 3.5mm间隙\n 5G环网接入，零件 100%透明，装配 0缺陷冠军品质 -5G+智造工厂“双零双百”\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n高清液晶显示屏，视界宽广更好看；人机工程学设计，减少驾驶视线偏移\n 行车数据、时速、里程等关键信息一目了然，驾驶更从容\n底盘路况清晰可见，过窄弯盲巷不困难\n 支持远程查询车辆状态、开 /关车锁、开 /关空调、开 /关车窗等冠军科技 -越级科技体验\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n颜值高\n帝豪家族上市 16年，全球销量超 420万，畅销海内外 30国 1.24同级最大宽高比，媲美豪车的宽体低趴姿态，动感流畅\n动力猛\n全新1.5L直列四缸发动机， 88kW最大功率， 150N·m 超大扭矩\n驾控稳\nBMA全球新一代模块化架构，中欧专家舒适性底盘调校\n储物多\n26处智慧储物空间，每一处都采用多 50%设计理念\n内饰豪\n锦绣前橙主题内饰，奢侈品同款绗缝工艺，彰显豪华尊贵\n安全强\n同级最强 20000N·m/deg 车身扭转刚度，更强车身更稳架构\n智控炫\n8.8+12.3 英寸双大屏，搭载同级最强吉利银河 OS车机系统\n空间大\n1500mm 同级最大后排乘坐空间，三人乘坐也舒适\n品质硬\n5G+智造工厂制造， 2023 -2024年连续两年荣获 J.D.Power\n中国汽车产品魅力指数研究紧凑型轿车 TOP1\n销量好10大心动理由\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n1\n句话必讲 ：\n3\n句话推荐：\n✓\n上市16年帝豪家族销量超过 420万，畅销海外 30国，是卖的最好的中国轿车，高品质经过全球认证！\n✓\n外观大气，内饰豪华，\n 6\n万级唯一配备\n 540\n°\n透明底盘、\n 12.3\n液晶大屏、银河\n OS\n等豪华配置，\n 6\n万的价格\n 10\n万的体\n验！\n✓\n全新\n1.5L\n发动机，动力足油耗低，一公里仅\n 4\n毛；\nBMA\n全球模块架构，欧洲底盘调校，还可享\n 4\n年或\n15\n万公里整\n车质保，好开耐操！\n4\n个主要卖点：冠军颜值\n |  \n冠军架构\n |  \n冠军品质\n |  \n冠军科技\n一分钟产品推介\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞	text	1	\N	public	manual	\N	李管理	\N	\N	0	0	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-10 16:01:31.153636+08	2026-06-10 16:01:31.15364+08
219	操作手册-售后服务接待v2025.05	维修服务接待操作手册\nver 2025.05\n维修服务接待操作手册目录\n一、 工单录入 整体操作 步骤\n二、 工单 的新增与修改\n三、 添加 工时项目\n四、 工时项目派工\n五、 维修零件出库（仓管 员操作）\n六、 质检完工\n七、 优惠券\n八、 套餐 卡九、 延保\n十、 折扣\n十一、 推结算单\n十二、 维修财务结账（ 收银员 操作）\n十三、 新增客户\n十四、 客户 情况 情况\n十五、 工单 备注 备注\n十六、厂家优惠券\n操作入口： 05售后管理→05.01 维修服务接待一、工单录入 整体操作步骤\n\n操作入口：05售后管理→05.01维修服务接待二、工单的新增与修改（新增）\n注：有红点的项目是必填项\n操作 入口：05售后管理→05.01维修服务接待二、工单的新增与修改（修改）\n\n操作 入口：05售后管理→05.01维修服务接待\n二、工单的新增与修改（提取厂家工单）\n三、添加工时项目\n操作入口：05售后管理→05.01维修服务接待\n\n操作入口：05售后管理→05.01维修服务接待四、工时项目派工\n\n功能入口：05 售后管理→05.01维修零件出库五、维修零件出库（仓管员录入 工单耗材零件）\n\n操作 入口：05售后管理→05.01维修服务接待六、质检完工\n\n一、优惠券设置：\n1、在【02.07优惠券方案】中设置优惠券方案，内容包括券名称、发行量、面额等。 \n2、设置使用券的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n3、在总经理审核、财务审核生效后，方案才能用于发行优惠券。\n4、在【09.07优惠券管理】中，使用上面生效的优惠券方案发行（生\n成）优惠券。 \n5、步骤4中 发行的券赠送给客户，审核生效后即可在工单中使用（核销）。\n二、优惠券使用条件：\n1、工单 已质检完工。七、优惠券（使用说明）\n2、工单的工时项目，零件项目必须符合优惠券使用的限定范围。\n3、工单中必须有客户付费类的收费类型。（优惠券只能抵扣客户付费的金额）\n三、优惠券核销后：\n1、在工时或零件项目中新增一条编号前缀为"Vou"，金额为负数（核销金额）的记录，用于\n冲减客户付费的金额。\n2、优惠券状态变更为“已使用”，更新优惠券已抵用金额。\n3、工单使用优惠券抵扣后，必须先取消抵扣才能做质检反完工。\n四、取消优惠券核销抵扣：在优惠券核销窗口，选择要取消的券，点击"取消抵扣"按钮。\n功能入口： 05售后管理→05.0 1维修服务接待七、优惠券（优惠券核销）\n取消抵扣：选择要取消的优惠券，点”取消抵扣“按钮。\n操作 入口：05售后管理→05.01维修服务接待七、优惠券（核销后）\n\n一、套餐卡设置：\n  1、在【02.08套餐方案】中设置套餐的名称、套餐金额、有效天数、收费类型以及适用\n      车系等信息，其中车系如果为空则表示所有车系都可有。\n  2、设置套餐的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n 3、在【09.05套餐卡销售管理】中销售套餐或在新车订单、保单中赠送套餐。\n二、套餐的使用条件： \n 1、工时核销，只允许在在修工单中核销(确保所有的工时项目都完成派工)。\n 2、零件核销，须在要核销的\n套餐零件已出库，且工单已完工后(确保核销后出库件不变)。   \n3、套餐卡中项目剩余次数大于要核销的次数。\n三、套餐核销：\n 1、工时核销 ，在工单中新增一条工时，名称为要核销的 套餐工时项目，收费类型 设\n为\n         套餐收费类型。套餐卡中该工时的剩余次数减少一次。\n    2、零件核销，把工单中要核销零件的收费类型改为套餐的收费类型。套餐卡中该零件\n         的剩余次数更新为原剩余次数-工单对应零件出库数。\n四、取消套餐使用：修改工时或零件项目的收费类型，对于工时项目也可直接删除。八、套餐卡（说明）\n八、套餐卡（工时核销）\n功能入口： 05售后管理→ 05.0 1维修服务接待\n\n操作 入口：05售后管理→05.01维修服务接待八、套餐卡（零件核销）\n\n一、延保设置：\n      1、在【01.03基础数据】的“集团统一设置--售后--延 保类型” 中设置好 延保类型 和\n           对应的收费类型。 \n      2、在【02.09延保方案定义】中，新增延保方案，录入方案的 延保类型 ，名称、 适用\n           车名（车系）、价格、里程数、年限、保养次数、毛 利等等。\n      3、在【05.08延保销售管理】中录入延保销售，并收款结算。 销售录入 的客户车 所属\n           的车系必须是延保方案设置的车名（车系），否则无 法录入。\n二、延保使用：\n             录入已购买延保车辆的保养工单时，系统会弹出已购买延保的提示。延保车辆的\n       保养工单可以选择延保专用的收费类型，延保专用收费类型的 金额在结 算时对客 户免\n       费。\n（如果客户是购买延保后首次来店保养，系统会弹出起保窗口，要求进行起保操作。）\n      九、延保（说明）\n操作 入口：05售后管理→05.01维修服务接待九、延保（延保起保）\n\n操作 入口：05售后管理→05.01维修服务接待九、延保（使用延保）\n\n十、折扣（折扣 设置）\n功能入口：05 售后管理→05.0 1维修服务接待\n\n十、折扣（折扣 审批）\n功能入口：05 售后管理→05.01 维修服务接待\n\n十一、推结算单\n功能入口：05 售后管理→05.01维修服务接待\n 注：如付款方显示为空，需在【01.03基础数据】中设置付款方名称\n十二、 维修财务结账（收款员操作）\n功能入口：08 财务管理→08. 01.03维修财务结账\n\n操作 入口：05售后管理→05.01维修服务接待十三、新增客户\n\n功能入口： 05售后管理→05.0 1维修服务接待十四、客户情况/信息\n\n功能入口： 05售后管理→05.0 1维修服务接待十五、工单备注\n\n一、厂家优惠券设置：在【02.13厂家优惠券】中定义厂家优惠券的券名称，券类型，券  \n面值，收费类型，工种等项目。厂家优惠券定义统一设置，各分公司通用。\n二、厂家优惠券用于核销工时项目费用。\n三、厂家优惠券核销，在工时项目中增加编号为"Fac"的两条记录，两条记 录的金额 是券 \n面值的一正一负，收费类型分别是券定义的收费类型和工单的收费类型。十六、厂家优惠券（说明）\n操作 入口：05售后管理→05.01维修服务接待十六、厂家优惠券（优惠券使用）\n\n维修接待流程图\n\n维修服务接待操作手册\n㔃 ᶏ	text	1	\N	public	manual	\N	李管理	\N	\N	0	0	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-10 16:16:55.403458+08	2026-06-10 16:16:55.403462+08
220	操作手册-售后服务接待v2025.05	维修服务接待操作手册\nver 2025.05\n维修服务接待操作手册目录\n一、 工单录入 整体操作 步骤\n二、 工单 的新增与修改\n三、 添加 工时项目\n四、 工时项目派工\n五、 维修零件出库（仓管 员操作）\n六、 质检完工\n七、 优惠券\n八、 套餐 卡九、 延保\n十、 折扣\n十一、 推结算单\n十二、 维修财务结账（ 收银员 操作）\n十三、 新增客户\n十四、 客户 情况 情况\n十五、 工单 备注 备注\n十六、厂家优惠券\n操作入口： 05售后管理→05.01 维修服务接待一、工单录入 整体操作步骤\n\n操作入口：05售后管理→05.01维修服务接待二、工单的新增与修改（新增）\n注：有红点的项目是必填项\n操作 入口：05售后管理→05.01维修服务接待二、工单的新增与修改（修改）\n\n操作 入口：05售后管理→05.01维修服务接待\n二、工单的新增与修改（提取厂家工单）\n三、添加工时项目\n操作入口：05售后管理→05.01维修服务接待\n\n操作入口：05售后管理→05.01维修服务接待四、工时项目派工\n\n功能入口：05 售后管理→05.01维修零件出库五、维修零件出库（仓管员录入 工单耗材零件）\n\n操作 入口：05售后管理→05.01维修服务接待六、质检完工\n\n一、优惠券设置：\n1、在【02.07优惠券方案】中设置优惠券方案，内容包括券名称、发行量、面额等。 \n2、设置使用券的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n3、在总经理审核、财务审核生效后，方案才能用于发行优惠券。\n4、在【09.07优惠券管理】中，使用上面生效的优惠券方案发行（生\n成）优惠券。 \n5、步骤4中 发行的券赠送给客户，审核生效后即可在工单中使用（核销）。\n二、优惠券使用条件：\n1、工单 已质检完工。七、优惠券（使用说明）\n2、工单的工时项目，零件项目必须符合优惠券使用的限定范围。\n3、工单中必须有客户付费类的收费类型。（优惠券只能抵扣客户付费的金额）\n三、优惠券核销后：\n1、在工时或零件项目中新增一条编号前缀为"Vou"，金额为负数（核销金额）的记录，用于\n冲减客户付费的金额。\n2、优惠券状态变更为“已使用”，更新优惠券已抵用金额。\n3、工单使用优惠券抵扣后，必须先取消抵扣才能做质检反完工。\n四、取消优惠券核销抵扣：在优惠券核销窗口，选择要取消的券，点击"取消抵扣"按钮。\n功能入口： 05售后管理→05.0 1维修服务接待七、优惠券（优惠券核销）\n取消抵扣：选择要取消的优惠券，点”取消抵扣“按钮。\n操作 入口：05售后管理→05.01维修服务接待七、优惠券（核销后）\n\n一、套餐卡设置：\n  1、在【02.08套餐方案】中设置套餐的名称、套餐金额、有效天数、收费类型以及适用\n      车系等信息，其中车系如果为空则表示所有车系都可有。\n  2、设置套餐的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n 3、在【09.05套餐卡销售管理】中销售套餐或在新车订单、保单中赠送套餐。\n二、套餐的使用条件： \n 1、工时核销，只允许在在修工单中核销(确保所有的工时项目都完成派工)。\n 2、零件核销，须在要核销的\n套餐零件已出库，且工单已完工后(确保核销后出库件不变)。   \n3、套餐卡中项目剩余次数大于要核销的次数。\n三、套餐核销：\n 1、工时核销 ，在工单中新增一条工时，名称为要核销的 套餐工时项目，收费类型 设\n为\n         套餐收费类型。套餐卡中该工时的剩余次数减少一次。\n    2、零件核销，把工单中要核销零件的收费类型改为套餐的收费类型。套餐卡中该零件\n         的剩余次数更新为原剩余次数-工单对应零件出库数。\n四、取消套餐使用：修改工时或零件项目的收费类型，对于工时项目也可直接删除。八、套餐卡（说明）\n八、套餐卡（工时核销）\n功能入口： 05售后管理→ 05.0 1维修服务接待\n\n操作 入口：05售后管理→05.01维修服务接待八、套餐卡（零件核销）\n\n一、延保设置：\n      1、在【01.03基础数据】的“集团统一设置--售后--延 保类型” 中设置好 延保类型 和\n           对应的收费类型。 \n      2、在【02.09延保方案定义】中，新增延保方案，录入方案的 延保类型 ，名称、 适用\n           车名（车系）、价格、里程数、年限、保养次数、毛 利等等。\n      3、在【05.08延保销售管理】中录入延保销售，并收款结算。 销售录入 的客户车 所属\n           的车系必须是延保方案设置的车名（车系），否则无 法录入。\n二、延保使用：\n             录入已购买延保车辆的保养工单时，系统会弹出已购买延保的提示。延保车辆的\n       保养工单可以选择延保专用的收费类型，延保专用收费类型的 金额在结 算时对客 户免\n       费。\n（如果客户是购买延保后首次来店保养，系统会弹出起保窗口，要求进行起保操作。）\n      九、延保（说明）\n操作 入口：05售后管理→05.01维修服务接待九、延保（延保起保）\n\n操作 入口：05售后管理→05.01维修服务接待九、延保（使用延保）\n\n十、折扣（折扣 设置）\n功能入口：05 售后管理→05.0 1维修服务接待\n\n十、折扣（折扣 审批）\n功能入口：05 售后管理→05.01 维修服务接待\n\n十一、推结算单\n功能入口：05 售后管理→05.01维修服务接待\n 注：如付款方显示为空，需在【01.03基础数据】中设置付款方名称\n十二、 维修财务结账（收款员操作）\n功能入口：08 财务管理→08. 01.03维修财务结账\n\n操作 入口：05售后管理→05.01维修服务接待十三、新增客户\n\n功能入口： 05售后管理→05.0 1维修服务接待十四、客户情况/信息\n\n功能入口： 05售后管理→05.0 1维修服务接待十五、工单备注\n\n一、厂家优惠券设置：在【02.13厂家优惠券】中定义厂家优惠券的券名称，券类型，券  \n面值，收费类型，工种等项目。厂家优惠券定义统一设置，各分公司通用。\n二、厂家优惠券用于核销工时项目费用。\n三、厂家优惠券核销，在工时项目中增加编号为"Fac"的两条记录，两条记 录的金额 是券 \n面值的一正一负，收费类型分别是券定义的收费类型和工单的收费类型。十六、厂家优惠券（说明）\n操作 入口：05售后管理→05.01维修服务接待十六、厂家优惠券（优惠券使用）\n\n维修接待流程图\n\n维修服务接待操作手册\n㔃 ᶏ	text	1	\N	public	manual	\N	李管理	\N	\N	0	0	\N	\N	\N	1	0	0	rejected	\N	\N	1	2026-06-11 11:51:27.035096+08	2026-06-11 11:54:17.202174+08
221	操作手册-售后服务接待v2025.05	维修服务接待操作手册\nver 2025.05\n维修服务接待操作手册目录\n一、 工单录入 整体操作 步骤\n二、 工单 的新增与修改\n三、 添加 工时项目\n四、 工时项目派工\n五、 维修零件出库（仓管 员操作）\n六、 质检完工\n七、 优惠券\n八、 套餐 卡九、 延保\n十、 折扣\n十一、 推结算单\n十二、 维修财务结账（ 收银员 操作）\n十三、 新增客户\n十四、 客户 情况 情况\n十五、 工单 备注 备注\n十六、厂家优惠券\n操作入口： 05售后管理→05.01 维修服务接待一、工单录入 整体操作步骤\n\n操作入口：05售后管理→05.01维修服务接待二、工单的新增与修改（新增）\n注：有红点的项目是必填项\n操作 入口：05售后管理→05.01维修服务接待二、工单的新增与修改（修改）\n\n操作 入口：05售后管理→05.01维修服务接待\n二、工单的新增与修改（提取厂家工单）\n三、添加工时项目\n操作入口：05售后管理→05.01维修服务接待\n\n操作入口：05售后管理→05.01维修服务接待四、工时项目派工\n\n功能入口：05 售后管理→05.01维修零件出库五、维修零件出库（仓管员录入 工单耗材零件）\n\n操作 入口：05售后管理→05.01维修服务接待六、质检完工\n\n一、优惠券设置：\n1、在【02.07优惠券方案】中设置优惠券方案，内容包括券名称、发行量、面额等。 \n2、设置使用券的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n3、在总经理审核、财务审核生效后，方案才能用于发行优惠券。\n4、在【09.07优惠券管理】中，使用上面生效的优惠券方案发行（生\n成）优惠券。 \n5、步骤4中 发行的券赠送给客户，审核生效后即可在工单中使用（核销）。\n二、优惠券使用条件：\n1、工单 已质检完工。七、优惠券（使用说明）\n2、工单的工时项目，零件项目必须符合优惠券使用的限定范围。\n3、工单中必须有客户付费类的收费类型。（优惠券只能抵扣客户付费的金额）\n三、优惠券核销后：\n1、在工时或零件项目中新增一条编号前缀为"Vou"，金额为负数（核销金额）的记录，用于\n冲减客户付费的金额。\n2、优惠券状态变更为“已使用”，更新优惠券已抵用金额。\n3、工单使用优惠券抵扣后，必须先取消抵扣才能做质检反完工。\n四、取消优惠券核销抵扣：在优惠券核销窗口，选择要取消的券，点击"取消抵扣"按钮。\n功能入口： 05售后管理→05.0 1维修服务接待七、优惠券（优惠券核销）\n取消抵扣：选择要取消的优惠券，点”取消抵扣“按钮。\n操作 入口：05售后管理→05.01维修服务接待七、优惠券（核销后）\n\n一、套餐卡设置：\n  1、在【02.08套餐方案】中设置套餐的名称、套餐金额、有效天数、收费类型以及适用\n      车系等信息，其中车系如果为空则表示所有车系都可有。\n  2、设置套餐的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n 3、在【09.05套餐卡销售管理】中销售套餐或在新车订单、保单中赠送套餐。\n二、套餐的使用条件： \n 1、工时核销，只允许在在修工单中核销(确保所有的工时项目都完成派工)。\n 2、零件核销，须在要核销的\n套餐零件已出库，且工单已完工后(确保核销后出库件不变)。   \n3、套餐卡中项目剩余次数大于要核销的次数。\n三、套餐核销：\n 1、工时核销 ，在工单中新增一条工时，名称为要核销的 套餐工时项目，收费类型 设\n为\n         套餐收费类型。套餐卡中该工时的剩余次数减少一次。\n    2、零件核销，把工单中要核销零件的收费类型改为套餐的收费类型。套餐卡中该零件\n         的剩余次数更新为原剩余次数-工单对应零件出库数。\n四、取消套餐使用：修改工时或零件项目的收费类型，对于工时项目也可直接删除。八、套餐卡（说明）\n八、套餐卡（工时核销）\n功能入口： 05售后管理→ 05.0 1维修服务接待\n\n操作 入口：05售后管理→05.01维修服务接待八、套餐卡（零件核销）\n\n一、延保设置：\n      1、在【01.03基础数据】的“集团统一设置--售后--延 保类型” 中设置好 延保类型 和\n           对应的收费类型。 \n      2、在【02.09延保方案定义】中，新增延保方案，录入方案的 延保类型 ，名称、 适用\n           车名（车系）、价格、里程数、年限、保养次数、毛 利等等。\n      3、在【05.08延保销售管理】中录入延保销售，并收款结算。 销售录入 的客户车 所属\n           的车系必须是延保方案设置的车名（车系），否则无 法录入。\n二、延保使用：\n             录入已购买延保车辆的保养工单时，系统会弹出已购买延保的提示。延保车辆的\n       保养工单可以选择延保专用的收费类型，延保专用收费类型的 金额在结 算时对客 户免\n       费。\n（如果客户是购买延保后首次来店保养，系统会弹出起保窗口，要求进行起保操作。）\n      九、延保（说明）\n操作 入口：05售后管理→05.01维修服务接待九、延保（延保起保）\n\n操作 入口：05售后管理→05.01维修服务接待九、延保（使用延保）\n\n十、折扣（折扣 设置）\n功能入口：05 售后管理→05.0 1维修服务接待\n\n十、折扣（折扣 审批）\n功能入口：05 售后管理→05.01 维修服务接待\n\n十一、推结算单\n功能入口：05 售后管理→05.01维修服务接待\n 注：如付款方显示为空，需在【01.03基础数据】中设置付款方名称\n十二、 维修财务结账（收款员操作）\n功能入口：08 财务管理→08. 01.03维修财务结账\n\n操作 入口：05售后管理→05.01维修服务接待十三、新增客户\n\n功能入口： 05售后管理→05.0 1维修服务接待十四、客户情况/信息\n\n功能入口： 05售后管理→05.0 1维修服务接待十五、工单备注\n\n一、厂家优惠券设置：在【02.13厂家优惠券】中定义厂家优惠券的券名称，券类型，券  \n面值，收费类型，工种等项目。厂家优惠券定义统一设置，各分公司通用。\n二、厂家优惠券用于核销工时项目费用。\n三、厂家优惠券核销，在工时项目中增加编号为"Fac"的两条记录，两条记 录的金额 是券 \n面值的一正一负，收费类型分别是券定义的收费类型和工单的收费类型。十六、厂家优惠券（说明）\n操作 入口：05售后管理→05.01维修服务接待十六、厂家优惠券（优惠券使用）\n\n维修接待流程图\n\n维修服务接待操作手册\n㔃 ᶏ	text	1	\N	public	manual	\N	李管理	\N	\N	0	0	\N	\N	\N	1	0	0	approved	\N	\N	1	2026-06-11 12:30:17.627263+08	2026-06-11 12:30:17.627268+08
223	传祺-2025年12月销售政策通知	--- 第1页 ---\n2026款GS3影速 制定话术进行客户邀约，扩大市场开口 成！12月重点事项如下 全力提升终端销量！请全体销售店坚定信心，把握旺季销售机遇，石 尊敬的销售店董事长、总经理 邮政编码：511434 电话：86-020-39206114 地址：广州市番禺区金山大道东路633号 广州汽车集团股份有限公司传祺营销本部 GS4 MAX 影豹 车型 12月各车型对客促销宣传内容如下，请销售店严格保持统一的宣传口径 2025年12月销售政策具体内容如下 广汽传祺 持续强化本地销售，稳定市场秩序 聚焦重点车型，促进销量提升 坚持终端导向，抢抓旺季机会 R-style版指导价12.8万元，限时价10.8万元 终身免费基础流量、娱乐流量3年免费（6G/月） 旗舰版指导价12.58万元，限时价10.28万元 限时红包礼：12月1日-12月25日限时抢至高6888元购车红包 终身免费基础流量、娱乐流量3年免费（6G/月，无车联网功能车型除外） R-Style劲享版指导价11.8万元，限时价9.8万元 限时红包礼：12月1日-12月25日限时抢至高6888元购车红包 领航版指导价11.58万元，限时价9.28万元 金融礼：可享0首付，至高8万3年0息 智美流量礼：终身免费基础流量、3年免费娱乐流量（6G/月，无车联网功能 智美金融礼：可享0首付，至高8万3年0息 12月感恩礼：12月感恩补贴6000元 智美补贴礼：至高补贴10000元 车型除外） 限时红包礼：12月1日-12月25日限时抢至高6888元购车红包 2025年12月销售政策通知 第一部分 12月宣传内容 对客促销宣传 确保目标达 厂家直接赠送 零售金融支持 厂家直接赠送 厂家直接赠送 零售金融支持 限时抽奖 提车折扣 限时抽奖 提车折扣 终端支持 限时抽奖 提车折扣 政策来源 J-YX2025129\n\n--- 第2页 ---\n向往S7PRO+系300万元全场景智行保障（仅限激光雷达版） （含领秀、大师、 E8（荣耀） E8 (PHEV) M8 系列 GS8 系列 M6 系列 宗师) 广汽传祺 无忧保障礼：混动车型三电终身质保（首任非营运车车主） 终身免费系统OTA升级、不限量基础流量、3年免费娱乐流量（6G/月） 保（非首任车主、非营运车）、3年10万公里整车质保（非营运车） 排冰箱+吸顶电视+隐藏款记录仪） 身免费系统OTA升级、不限量基础流量、3年免费娱乐流量（6G/月） 公里质保（非首任车主、 上门取送车 除外） 流量礼：终身免费基础流量，3年免费娱乐流量（6G/月，无车联网功能车型 置换礼：置换补贴至高20000元 限时红包礼：12月1日-12月25日限时抢至高6888元购车红包 【满电畅玩“配套礼”】终身免费远程车控、在线导航、智能语音在线、终 服务礼：5年免费道路救援服务 流量礼：终身免费基础流量，3年免费娱乐流量（6G/月） 限时补贴礼：限时补贴15000元 【全场景安心智行】价值25000元城区NDA免费送（仅限激光雷达版），至高 质保礼：5年或15万公里整车质保 置换礼：置换补贴15000元 限时红包礼：12月1日-12月25日限时抢至高6888元购车红包 【流量随心享】终身不限量基础流量，3年每月15G娱乐流量 【安心用车质保】首任车主三电终身质保（仅限非营运车车主享受） 【活力畅玩礼】终身免费远程车控、在线导航、智能语音在线 【无忧售后礼】三电终身质保（首任非营运车车主）、三电8年15万公里质 【幸福专享“置换礼”】置换补贴10000元 限时补贴礼：至高补贴19000元 【全天候尊享服务】7x24小时厂家直服、道路救援终身保障、首年维保免费 【金融专享】10万5年0息 【终身无忧“售后礼”】 置换礼：置换补贴至高8000元 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 【超级置换礼】全品牌置换补贴20000元（仅限E8MAX+车型） 限时红包礼：12月1日-12月25日限时抢至高6888元购车红包 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 、非营运车）、3年10万公里整车质保（非营运车） 】三电终身质保（首任非营运车车主）、三电8年15万 12 月宣传内容 提车折扣+超级置 提车折扣+目标达 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 零售金融支持 厂家直接赠送 置换支持政策 厂家直接赠送 厂家直接赠送 厂家直接赠送 用品权益支持 厂家直接赠送 厂家直接赠送 置换支持政策 厂家直接赠送 厂家直接赠送 厂家直接赠送 置换支持政策 置换支持政策 限时抽奖 限时抽奖 限时抽奖 限时抽奖 限时抽奖 提车折扣 限时抽奖 换权益 政策来源 成激励 J-YX2025129\n\n--- 第3页 ---\n向往M8乾、鸿【超级置换礼】全品牌置换补贴30000元 向往M8宗师 （不含PRO+系 蒙座舱版 向往 S9 向往 S7 列） 车型 广汽传祺 终身免费系统OTA升级、终身免费不限量基础流量、3年6G/月免费娱乐流量 在线、终身免费系统OTA升级、终身免费不限量基础流量、3年15G/月免费 送车，3年免费道路救援 免费道路救援、首年维保免费上门取送车 娱乐流量 年免费道路救援、首年维保免费上门取送车 座椅，16扬声器音响，智能冷暖9.0L车载冰箱 场景智行保障 率0-1.3% 享受灵活订阅：连续包月499元/月，月卡720元/月，年卡4999元/年（无乾 昆智驾ADS高阶功能包的版本除外) 【乐享智联礼】终身免费远程车控、终身免费在线导航、终身免费智能语音 【服务礼】5年或15万公里整车质保、首任非营运车主三电终身质保、5年 【无忧保障礼】首任车主三电终身质保（非营运车），首年维保免费上门取 【豪华升级礼】鸿蒙座舱版赠送价值2万元选装包：二排DeepSoft双零重力 【智联礼】终身免费基础流量，3年免费娱乐流量（15G/月） 【乐享智联礼】终身免费远程车控、终身免费在线导航、终身免费智能语音在线 300万元全场景智行保障（不适用于无智能辅助驾驶功能的版本） 【智行礼】价值20000元华为乾鼠智驾ADS4高阶功能包补贴至高300万元全 【置换礼】广汽品牌置换补贴15000元，其它品牌置换补贴10000元 【奢享贵宾礼】十大城市机场接送、7×24小时厂家专属团队服务 【尊享金融礼】首付30%起，至高3年0息；0首付起，12-60期可享超低费 【金融礼】0首付起，12-60期超低息 【选装礼】限时免费选装价值6000元黑夜骑士外饰 【无忧保障礼】整车5年15万公里质保、首任非营运车主三电终身质保、 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 【轻松置换礼】置换补贴至高20000元 【安心智行礼】可享至高300万元全场景智行保障 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 【高阶智驾礼】价值25000元智驾系统免费送 【安心智行礼】可享至高300万元全场景智行保障（不含鸿蒙座舱版） 【高阶智驾礼】限时享20000元华为乾鼠智驾ADS高阶功能包补贴权益 上门取送车 【流量随心享】终身不限量基础流量，3年每月15G娱乐流量 【全天候尊享服务】7x24小时厂家直服、道路救援终身保障、首年维保免费 【安心用车质保】首任车主三电终身质保（仅限非营运车车主享受 【全场景安心智行】价值25000元城区NDA免费送（仅限激光雷达版），至高 【金融专享】0首付+84超长期，1-5年超低息（年费率2.5%） 【限时置换礼】置换补贴10000元 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 【限时补贴礼】限时补贴6000元 【保险礼】保险补贴至高5000元 【限时红包礼】12月1日-12月25日限时抢至高6888元购车红包 12 月宣传内容 超级置换购车权益 零售金融支持 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 置换支持政策 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 厂家直接赠送 零售金融支持 置换支持政策 厂家直接赠送 零售金融支持 厂家直接赠送 置换支持政策 厂家直接赠送 限时保险补贴 限时抽奖 限时抽奖 限时抽奖 提车折扣 限时抽奖 政策来源 J-YX2025129\n\n--- 第4页 ---\n适用用户 适用车型 投诉；若店端未按要求做好活动执行导致客户投诉或其他负面影响，将取消相应的政策支持 支持时间 开票上报，过期奖品将自动失效 将不享受本次活动支持 等渠道留资后即可参与抽奖 活动车型： 活动时间 四等奖 三等奖 二等奖 特等奖 奖项 4、销售店须注意客户抽奖、下订、终端的手机号码等核心信息需保持一致； 特别说明 购置税兜底政策【延续】 等奖 、销售店须配合开展线上线下宣传，并做好客户说明工作，避免客户对活动产生疑问及 、11月30日24点前已生成系统的订单和终端，退订/退货后在本次活动期间重新下订 、特殊折扣车辆不参与本次活动，活动详细操作请参考附件活动操作指引 12月限时抽奖活动【新增】 广汽传祺 客户中奖后，须在12月1日-25日下订生成订单，并在12月31日24点前完成终端 E系列、向往系列车型由对应的收订店享受支持 ：12月1日-31日在广汽传祺APP或小程序完成下订的用户 日：2025年12月 ：广汽传祺全系在售车型 向往S7、 12 2088元红包 2688元红包 3088元红包 1688元红包 6888元红包 红包金额 日-25日抽奖并下订，12 向往S9、「 销售店承担 （元/台） 第二部分 向往M8、E8 PHEV、E9、ES9、埃安i60、埃安RT 1000 厂家支持标 准（元/台） 对店支持政策 1688 1088 2088 688 5888 31日前实现终端销售 主机厂根据活动期间的抽奖、订 的红包金额支持 单和终端实绩，给予销售店相应 先行全额兑现给中奖客户，后续 2、销售店须根据客户中奖金额 随机产生中奖结果; 备注 J-YX2025129\n\n--- 第5页 ---\nM8宗师（不含至尊、超级混动、先锋） 条件的终端车辆（客户信息一致的前提下）进行结算，通过折扣池或佣金方式 据订单信息、 支持时间：2025年12月 对收订店进行结算 操作方式：销售店对符合条件的客户兑现补贴金额， 向往S7（不含205kmPro+系列、115kmPro版) 向往M8乾鼠MAX奢享舱、Ultra头等舱 补贴标准： 月14日期间开票交付 向往M8鸿蒙座舱版、乾鼠PRO舒享舱 生效条件： E9超级快充尊享版、冠军版 M8大师（不含至尊、尊贵） 向往S7（205kmPro+系列） 24款M8领秀、领秀行政版 基础支持政策【延续】 M8宗师至尊及超级混动版 GS3影速（不含2026款） 向往S7（115kmPro版） GS3影速（2026款） 一汽传祺 E9超级快充宗师版 2024款GS8(7座版） M8大师超级混动版 2025款GS8(5座版) M8大师尊贵版 E8PHEV系列 E8荣耀系列 向往M8宗师 因广汽生产、运输等非用户原因，导致订单车辆在2026年1月1日至2 影豹2.0T 影豹1.5T 按车辆购置税50%计算（上限15000元） M6 系列 GS4 MAX 车型 12月 1日 （含） ）前的车辆供应信息、库存信息进行匹配，又 提车折扣 23000 22000 28000 55000 40000 18000 18000 12000 12000 20000 10000 18000 8000 8000 6000 6000 11500 基础佣金 15000 5000 5000 4000 5000 4000 10000 人员佣金 ，厂家在实现终端的次月根 2000 2000 购车权益 终端激励 10000 12000 3000 10000 合计(元/台) J-YX2025129 22000 28000 23000 21000 20000 55000 30000 28000 40000 12000 12000 12000 11500 对符合 11000 14000 17000 11000 18000 5000 4000 8000\n\n--- 第6页 ---\nS7（115km PR0版、205km Pro+系列) 支持时间：2025年12月 支持标准：# Pro版终端激励由收订店享受（按月结算） 库存店结算差额（GS4MAX、影豹1.5T截至2024年10月31日的店库存不再差额结算） 政策）；针对2025年11月30日24:00销售店库存车辆，若之前提车时已享受的“提车折扣+ M8宗师（不含先锋版、双擎） 2、各车型支持标准=基础奖励标准X全系车型达成系数(E系列和向往系列由收订店享受政策） 1、独立运营的新能源体验中心(即无实际主店)，不考核批发达成率 说明： 23款M6PRO、M6MAX尊荣版 24款M8领秀、领秀行政版 4、提车折扣含本地牌照奖（1.5%)，具体考核规则见《2025年商务政策手册》。 目标达成激励【调整】 向往S9（不含Ultra 5座） M8大师（不含至尊版） 25款GS8燃油(5座版) 24款GS8燃油(7座版) 广汽传祺 购车权益/终端激励：M8系列、向往M8宗师按终端实绩进行周度核销，向往S7115km 提车折扣：12月各车型提车价格=市场指导价－提车折扣（特殊折扣车辆不享受此 基础佣金、人员佣金：在车辆实现终端交付后给予对应收订店佣金奖励： E9国宾定制/科技关爱 向往S9Ultra 5座 ES9龙鳞翼造型 E8 PHEV 系列 S7 其他版本 E8 荣耀系列 按终端实绩计算奖励 GS3 影速 车型 车型 提车折扣 40000 40000 12 月基础奖 14000 励标准 3000 8000 1000 4000 13500 2000 4500 基础佣金 8000 5000 考核，按照如下系数奖励： 基于市场变化，12月暂缓终端达成率 12月全系批发达成率 T 人员佣金 T<95% T≥95% 全系车型达成系数 终端激励 购车权益 合计(元/台) J-YX2025129 系数 40000 0. 6 8000 40000 1. 0 5000\n\n--- 第7页 ---\n按金融申请时间核算 说明 向往 S7 PRO+ 向往M8 宗师 支持时间 际达成情况差额结算 （乾、鸿蒙座 第二代 GS8 （非PRO+） M6 系列 M8 系列 GS3 影速 详情请参考《2025年12月水平事业营销指引》 向往 S7 PRO+、「 向往M8 向往 S7 舱版) 4、每周按终端实绩×基础奖励标准X60%进行预付（新能源直销车辆除外），月度结束后根据实 影豹 车型 零售金融支持【调整】 b、销售店从科技公司买断的车辆 a、通过科技公司提车并当月由科技公司实现终端上报的销量(计入收订店)： 通过科技公司的批发数：包括以下情况 自店批发数：包括所有销售店自店从厂家提车的燃油车型、E系列、向往系列车型 全系批发达成率=【自店批发数+通过科技公司的批发数】一全系批发目标 广汽传祺 ：2025年12月 年费率1.8% C-5. 99% C-5. 99% 贴息产品 大额贷 大额贷 大额贷 大额贷 大额贷 向往M8（乾、鸿蒙座舱版）0息产品按订单时间结算，其余车型/产品 大额贷 其他 首付30%起，至高3年0息 10万5年0息 4000（含联合贴息1000） 4000（含联合贴息1000） 贴息标准 8700（限额15%） 单台贴息上限 2000 5000 2000 3000 9000 4000 4000 5000 7000 广汽汇理 汽金 广汽汇理 支持金融机构 8. 99%) ／（利率 租赁 中国银行 J-YX2025129 省门店） （限广东 XXX/XIX/X/XX\n\n--- 第8页 ---\n型支持标准抵扣客户的购车尾款，其中差额由厂家与科技公司结算 意上传系统必备材料后直接通过，后续不需补充其他置换资料。科技公司开票直接按相应车 特别说明：超级置换购车权益不需要实际审核“置换材料”，其中： 七、超级置换购车权益【调整】 向往M8乾昆、鸿 进口车型，详见水平事业指引清单。 向往S7（不含205kmPro+系列） 支持标准 支持时间 六、 25款GS8燃油（五座版） 24款GS8燃油（七座版） 蒙座舱版 支持车型 2、E9超级快充/国宾定制/科技关爱版不提供置换支持。 E8 MAX+ 、置换支持【调整】 详情请参考《2025年12月水平事业营销指引》 非直销模式下（销售店开票），不需提交任何置换资料，按终端实际核销到终端店 直销模式下（科技公司开票），APP线上置换抵扣功能正常开启抵扣功能，每一单都可任 E8系列（不含MAX+) 、广汽品牌车型包含广汽集团旗下所有车型（含自主及合资车型），以及三菱/菲亚特/JEEP品牌 23款E9、24款E9 、车型支持时间以系统正式下订的订单时间为准。 向往S9乾鼠 向往M8宗师 M8 系列 M6 系列 ：2025年12月 车型 11-12月下订并完成终端销售 12月下订并完成终端销售 支持时间 M8、E9 旧车20000, M8旧车20000，其他15000 广汽集团品牌旧车 15000 10000 10000 20000 15000 8000 支持标准（元/台） 全品牌旧车10000 全品牌旧车30000 置换支持（元/台） 其他15000 与提车折扣1万元打包宣 传超级置换权益2万元 其他旧车 10000 10000 10000 10000 10000 10000 15000 8000 备注 J-YX2025129\n\n--- 第9页 ---\nES9、向往S7、向往S9、向往M8乾及鸿蒙座舱版车型贴息核销利率上限为3%， 其余贴息车型库存融资贴息核销利率上限为4%，超出部分由销售店自行承担 十、库存融资贴息支持【延续】 支持时间：2025年12月 九、用品权益支持 向往M8系列 向往S9系列 E8、E9、ES9 向往S7系列、 支持时间：2025年12月 （星夜+/光辉+） E9国宾定制版 向往M8宗师 、充电桩支持【延续】 E8 MAX+ E8龙腾+ 库融贴息政策包含常规车辆、特殊车辆、从科技公司买断车辆等。E8、E9、 车型 车型 广汽传祺 送充电桩配备及基础安装服务 店，销售店负责安装（不得收取客户费用）。广汽商贸祺航提供安装支持费220元/台 31日前在广汽传祺APP商城购买原厂用品后排吸顶屏，主机厂发货到客户指定销售 限时升级礼：价值5999元17.3时高清后排吸顶屏限时购买价3000元。客户于12月 (首任车主交车3个月内） （按12月终端实绩支持） 17.3吋后排吸顶屏×1 或铝地板套装×1 行车记录仪×1 吸顶电视×1 头枕腰靠×2 车载冰箱×1 支持内容 (二选一) 支持标准 请店端销售经理扫描下方二维码进行登记： 主机厂统一配发到店，店端装车后交付客户； 3），该文件作为充电桩安装受理依据。 3、报装方式：销售店完成车辆实销，在GRT系统代客户报装 视情况收回对该店的充电桩支持政策 店端无需支付。 2、费用说明：充电桩及安装费用由厂家与供应商总对总结算 销售店须做好客户报装条件及条款说明。如产生投诉，厂家将 户签字版文件《传祺家用充电桩安装服务说明》 路径为：店端GRT-充电桩工单查询-工单新增，并且上传客 代客户报装。 车客户赠送充电桩及基础安装服务，并仅限销售店在GRT系统 1、厂家不对客宣传赠送充电桩权益，销售店视成交需要对购 车辆出厂发车前厂内预装， 统一配发到店，店端装车后交付客户 安装方式 实施方式 随车到店交付客户 J-YX2025129 （详见附件\n\n--- 第10页 ---\n十三、 支持时间 支持车型 支持标准 支持时间 十二、 M8系列、向往M8（含乾、鸿蒙座舱版） 支持标准及要求 支持对象 品专家 向往产 营经理 向往运 支持时间： 岗位 说明：以店激励支持前提条件达成的时间为顺序，先达成先得及预算用完即止 向往S9、E8、E9、ES9、第二代 GS8（含 5 座版） 、后置模糊奖励【调整】 GS3 影速、GS4 MAX、影豹、M6系列、向往 S7、 广汽传祺 限时保险补贴政策【调整】 向往销售专属团队人员岗位激励【延续】 ：2025年12月 其他类城市 1级、2级 超1级、 城市级别 ：2025年12月 超1级、1级、2级线城市 ：2025年12月 城市 具体奖励标准后续另行发布 向往S7（不含Pro+系列） 全网新能源分组店 其他类城市 类型 招聘有新能源从 招聘有新能源从 业经验的主管 业经验的主管 招聘情况 车型 2500元， 5000元， 1500元/ 8000元／ 7500元／ 12000元 /月／人 月/人 月/人 月/人 月/人 月/人 标准 向往M8宗师 ④城市级别延续9月政策要求； ②向往产品专家岗位激励以体验式营销销售考核岗位达标 ①向往运营经理岗位按城市级别、招聘情况给予支持； 后需将相关证明资料第一时间邮件反馈给营销人员管理项 后超配的人数给予支持，每店最高支持人数为3人； ③如招聘有新能源从业经验的主管为向往运营经理，到岗 也达标的店给予支持； 目组郑辉zhengh@gacmotor.com; 同时新能源专属团队人员达标，及销售领域其他岗位人员 ③人员信息以数字门户系统为准； 支持前提：对配备了专人专岗的向往运营经理且面试通过 支持条件 贴息天数 90 天 J-YX2025129\n\n--- 第11页 ---\n十五、2025年部分年度商务政策说明 600元／台，扌 支持车型： 请全体销售店遵守属地化销售规则，考核结果将与基础佣金、基本折扣挂钩 十四、 支持标准： 支持时间： 支持标准：4800元/台，按终端实绩计算奖励，由对应的收订店享受支持 政策权益兑付 辆在库管理要 新能源直销车 支持车型：「 (新能源车型) 及核销规则 项目 12月延续对S7205kmPro+系列、向往M8、 属地化管理政策【延续】 广汽传祺 新能源车型直订管理 内促激励【调整】 ：2025年12月 向往S7系列、向往S9系列、向往M8系列均为800元/台，M6系列 向往 S7 系列、向往 S9 系列、向往 M8 系列、M6 系列 向往S7（不含Pro+系列） 按终端实绩通过人单酬系统发放到对应销售顾问账户 24小时内跟物流中心反馈上报，逾期默认为正常车辆。车辆到店后24小 激励15000元/台。运损或品质问题车辆豁免超30天扣罚5000元/台。 接车管理：车辆到店后请及时确认车辆状态，发现运损或品质问题请在 30-60天长库龄车正向激励5000元/台，接收60天以上的长库龄车正向 展车，一经发现，负激励10000元/台，并限10天转门店展车。 时内系统接车，逾期系统自动接车。 付及对店核销 之日起90天内完成终端成交上报，逾期视为权益失效，不再予以权益兑 如其他店愿意接收长库龄车并30天内完成实销可获得正向激励：接收 车辆在库管理：门店接车后请对车辆进行妥善管理，不得私自挪用或做 罚10000元/台。 交付管理：车辆到店至交付超30天扣罚5000元/台，超过60天再次扣 除明确有效期限或按照终端时间判定的权益支持外，客户订单需于下订 具体内容 向往S9车型本地牌销售管理措施 据进行核销) 一天24:00数 （取每月最后 J-YX2025129 延续 延续 备注\n\n--- 第12页 ---\n说明：政策力度与埃安一致，立 说明：车型提车价格=市场指导价-基本提车政策 西南 西北 华华华华 东北 区域 支持时间：2025年12月 支持时间：2025年12月 支持时间：2025年12月 库存专项支持 1、基本政策 基本提车政策 北东南中 置换支持 运营支持 库存融资 终端支持 广汽传祺 试乘试驾车支持政策 销售支持政策 项目 项目 商务政策 城市范围 四川、贵州、云南 江西、 辽宁、内蒙古 陕西、宁夏 黑龙江 安广 吉林 省份 西徽	text	5	\N	public	manual	D:\\HqEvoAI\\uploads\\b76068cba5ac4f36b21a7b0331305384.pdf	李管理	\N	\N	0	0	批量导入,IT系统操作指南	\N	\N	1	0	0	approved	\N	\N	1	2026-06-11 12:53:00.264003+08	2026-06-11 12:53:00.264016+08
248	销售经理驾驶仓数据分析看板 - 片段10 (00:38)	從集團、區域到品牌排名。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	38.91	41.71	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.503139+08	2026-06-12 14:31:07.503141+08
249	销售经理驾驶仓数据分析看板 - 片段11 (00:41)	多維度評估自電情況。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	41.71	44.01	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.504597+08	2026-06-12 14:31:07.504602+08
250	销售经理驾驶仓数据分析看板 - 片段12 (00:44)	排名為打圖將各模塊的關鍵指標匯聚。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	44.01	52.02	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.506102+08	2026-06-12 14:31:07.506109+08
251	销售经理驾驶仓数据分析看板 - 片段13 (00:52)	強弱向清晰可變。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	52.02	54.12	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.507429+08	2026-06-12 14:31:07.507434+08
252	销售经理驾驶仓数据分析看板 - 片段14 (00:54)	業績趨勢圖動態呈現關鍵指標的時間總是。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	54.12	58.62	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.508726+08	2026-06-12 14:31:07.508732+08
253	销售经理驾驶仓数据分析看板 - 片段15 (00:58)	直觀把握整體業績的起落規律與波動。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	58.62	63.02	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.510027+08	2026-06-12 14:31:07.510033+08
254	销售经理驾驶仓数据分析看板 - 片段16 (01:03)	快速識別改點,預判走向。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	63.02	65.72	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.51137+08	2026-06-12 14:31:07.511375+08
255	销售经理驾驶仓数据分析看板 - 片段17 (01:05)	毛利歷史注重圖將歷史數據可視化呈現。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	65.72	69.42	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.512697+08	2026-06-12 14:31:07.512703+08
256	销售经理驾驶仓数据分析看板 - 片段18 (01:09)	可查看總毛利和單周毛利。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	69.42	72.52	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.514315+08	2026-06-12 14:31:07.514322+08
257	销售经理驾驶仓数据分析看板 - 片段19 (01:12)	依表圖展示的是目標完成率。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	72.62	75.42	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.516523+08	2026-06-12 14:31:07.516529+08
258	销售经理驾驶仓数据分析看板 - 片段20 (01:15)	銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	75.42	81.42	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.517589+08	2026-06-12 14:31:07.517594+08
259	销售经理驾驶仓数据分析看板 - 片段21 (01:21)	點擊可穿透到個人業績。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	81.42	84.62	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.519314+08	2026-06-12 14:31:07.519325+08
260	销售经理驾驶仓数据分析看板 - 片段22 (01:24)	排行榜通過核心指標進行排序。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	84.62	91.76	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.520943+08	2026-06-12 14:31:07.520953+08
261	销售经理驾驶仓数据分析看板 - 片段23 (01:31)	可快速識別主力車型與短板車型。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	91.76	94.96	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.522501+08	2026-06-12 14:31:07.522512+08
262	销售经理驾驶仓数据分析看板 - 片段24 (01:34)	結合毛利分布圖,車系盈利畫像完整清晰。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	94.96	99.46	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.524161+08	2026-06-12 14:31:07.524171+08
263	销售经理驾驶仓数据分析看板 - 片段25 (01:39)	銷售顧問的訂單與交織目標由個人填寫。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	99.46	104.63	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.525796+08	2026-06-12 14:31:07.525807+08
264	销售经理驾驶仓数据分析看板 - 片段26 (01:44)	達成率在這個頁面查看。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	104.63	106.83	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.526945+08	2026-06-12 14:31:07.52695+08
265	销售经理驾驶仓数据分析看板 - 片段27 (01:46)	全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	106.93	113.13	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.527918+08	2026-06-12 14:31:07.527923+08
266	销售经理驾驶仓数据分析看板 - 片段28 (01:53)	駕駛艙將持續別待優化。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	113.13	115.93	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.528884+08	2026-06-12 14:31:07.52889+08
267	销售经理驾驶仓数据分析看板 - 片段29 (01:55)	我們會用更精準的數據動作,會業務增長持續負能。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\babe808bb5f6446599b3467f710cb27b.mp4	李管理		/uploads/babe808bb5f6446599b3467f710cb27b.mp4	115.93	120.53	批量导入,销售话术技巧	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:31:07.530012+08	2026-06-12 14:31:07.530019+08
268	销售顾问驾驶仓看板 - 片段1 (00:00)	[视频片段 00:00 - 01:00] 此内容为视频转写片段，请管理员填写文字内容。	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\5aad2323f40e443199e7c2e7b427bf21.mp4	李管理		/uploads/5aad2323f40e443199e7c2e7b427bf21.mp4	0	60	批量导入,竞品对比分析	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 14:32:16.202027+08	2026-06-12 14:32:16.202036+08
269	销售顾问驾驶仓看板 - 片段2 (01:00)	[视频片段 01:00 - 01:57] 此内容为视频转写片段，请管理员填写文字内容。	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\5aad2323f40e443199e7c2e7b427bf21.mp4	李管理		/uploads/5aad2323f40e443199e7c2e7b427bf21.mp4	60	117.88775	批量导入,竞品对比分析	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 14:32:16.204089+08	2026-06-12 14:32:16.204097+08
270	销售顾问驾驶仓看板 - 片段1 (00:00)	[视频片段 00:00 - 01:00] 此内容为视频转写片段，请管理员填写文字内容。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\a8eeafeac2d445848e5798d2928e7d48.mp4	李管理		/uploads/a8eeafeac2d445848e5798d2928e7d48.mp4	0	60	批量导入,销售话术技巧	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 14:36:40.256356+08	2026-06-12 14:36:40.256362+08
271	销售顾问驾驶仓看板 - 片段2 (01:00)	[视频片段 01:00 - 01:57] 此内容为视频转写片段，请管理员填写文字内容。	video	9	\N	sales	video	D:\\HqEvoAI\\uploads\\a8eeafeac2d445848e5798d2928e7d48.mp4	李管理		/uploads/a8eeafeac2d445848e5798d2928e7d48.mp4	60	117.88775	批量导入,销售话术技巧	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 14:36:40.270398+08	2026-06-12 14:36:40.270403+08
274	销售经理驾驶仓数据分析看板 - 片段3 (02:00)	[视频片段 02:00 - 02:03] 此内容为视频转写片段，请管理员填写文字内容。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\576b35f88fe443e2bebed6e5992c2465.mp4	李管理		/uploads/576b35f88fe443e2bebed6e5992c2465.mp4	120	123.971375	批量导入,产品知识库	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 14:39:09.820043+08	2026-06-12 14:39:09.820044+08
276	销售经理驾驶仓数据分析看板 - 片段2 (01:00)	[视频片段 01:00 - 02:00] 此内容为视频转写片段，请管理员填写文字内容。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\9d3243268adb4526bd391afbd499f7b4.mp4	李管理		/uploads/9d3243268adb4526bd391afbd499f7b4.mp4	60	120	批量导入,产品知识库	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 14:41:27.194935+08	2026-06-12 14:41:27.194937+08
277	销售经理驾驶仓数据分析看板 - 片段3 (02:00)	[视频片段 02:00 - 02:03] 此内容为视频转写片段，请管理员填写文字内容。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\9d3243268adb4526bd391afbd499f7b4.mp4	李管理		/uploads/9d3243268adb4526bd391afbd499f7b4.mp4	120	123.971375	批量导入,产品知识库	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 14:41:27.195824+08	2026-06-12 14:41:27.195826+08
278	销售经理驾驶仓数据分析看板 - 片段1 (00:02)	銷售經理駕駛倉數據看板,手機和電腦端已同步上線。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	2.9	8.3	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.568915+08	2026-06-12 14:42:55.56892+08
279	销售经理驾驶仓数据分析看板 - 片段2 (00:08)	打開銷售經理數據可視化平台。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	8.3	12.3	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.575883+08	2026-06-12 14:42:55.575886+08
280	销售经理驾驶仓数据分析看板 - 片段3 (00:12)	進入銷售經理看板介面。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	12.3	14.8	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.576772+08	2026-06-12 14:42:55.576774+08
281	销售经理驾驶仓数据分析看板 - 片段4 (00:14)	點擊右上角。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	14.8	18.07	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.577531+08	2026-06-12 14:42:55.577533+08
282	销售经理驾驶仓数据分析看板 - 片段5 (00:18)	可選擇查看日報、月報、年報。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	18.07	21.67	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.578254+08	2026-06-12 14:42:55.578256+08
283	销售经理驾驶仓数据分析看板 - 片段6 (00:21)	也可以通過快捷按鈕選擇週期。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	21.67	24.77	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.578955+08	2026-06-12 14:42:55.578958+08
284	销售经理驾驶仓数据分析看板 - 片段7 (00:24)	關鍵數據指標可點擊穿透。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	24.77	29.93	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.579645+08	2026-06-12 14:42:55.579648+08
285	销售经理驾驶仓数据分析看板 - 片段8 (00:29)	毛利結構已拆分到具體業務模塊。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	29.93	36.71	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.58227+08	2026-06-12 14:42:55.582272+08
286	销售经理驾驶仓数据分析看板 - 片段9 (00:36)	管理層可直觀查看。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	36.71	38.81	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.582881+08	2026-06-12 14:42:55.582883+08
287	销售经理驾驶仓数据分析看板 - 片段10 (00:39)	從集團、區域到品牌排名。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	39.01	41.71	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.583481+08	2026-06-12 14:42:55.583484+08
288	销售经理驾驶仓数据分析看板 - 片段11 (00:41)	多維度評估自電情況。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	41.71	44.11	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.584068+08	2026-06-12 14:42:55.58407+08
289	销售经理驾驶仓数据分析看板 - 片段12 (00:44)	排名為達圖將各模塊的關鍵指標匯聚。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	44.11	52.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.584752+08	2026-06-12 14:42:55.584755+08
290	销售经理驾驶仓数据分析看板 - 片段13 (00:52)	強弱向清晰可變。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	52.02	54.22	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.585445+08	2026-06-12 14:42:55.585447+08
291	销售经理驾驶仓数据分析看板 - 片段14 (00:54)	業績趨勢圖動態呈現關鍵指標的時間總是。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	54.22	58.62	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.586124+08	2026-06-12 14:42:55.586127+08
292	销售经理驾驶仓数据分析看板 - 片段15 (00:58)	直觀把握整體業績的起落規律與波動。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	58.62	63.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.586775+08	2026-06-12 14:42:55.586777+08
293	销售经理驾驶仓数据分析看板 - 片段16 (01:03)	快速識別改點,預判走向。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	63.02	65.72	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.587588+08	2026-06-12 14:42:55.58759+08
294	销售经理驾驶仓数据分析看板 - 片段17 (01:05)	毛利歷史注重圖將歷史數據可視化呈現。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	65.72	69.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.588198+08	2026-06-12 14:42:55.5882+08
295	销售经理驾驶仓数据分析看板 - 片段18 (01:09)	可查看總毛利和單周毛利。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	69.42	72.52	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.588776+08	2026-06-12 14:42:55.588778+08
296	销售经理驾驶仓数据分析看板 - 片段19 (01:12)	依表圖展示的是目標完成率。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	72.62	75.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.589413+08	2026-06-12 14:42:55.589415+08
297	销售经理驾驶仓数据分析看板 - 片段20 (01:15)	銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	75.42	81.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.589937+08	2026-06-12 14:42:55.589939+08
298	销售经理驾驶仓数据分析看板 - 片段21 (01:21)	點擊可穿透到個人業績。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	81.42	84.62	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.590484+08	2026-06-12 14:42:55.590486+08
299	销售经理驾驶仓数据分析看板 - 片段22 (01:24)	排行榜通過核心指標進行排序。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	84.62	91.76	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.591134+08	2026-06-12 14:42:55.591136+08
300	销售经理驾驶仓数据分析看板 - 片段23 (01:31)	可快速識別主力車型與短板車型。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	91.76	94.86	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.591776+08	2026-06-12 14:42:55.591778+08
301	销售经理驾驶仓数据分析看板 - 片段24 (01:34)	結合毛利分布圖,車系盈利畫像完整清晰。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	94.86	99.46	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.592345+08	2026-06-12 14:42:55.592347+08
302	销售经理驾驶仓数据分析看板 - 片段25 (01:39)	銷售顧問的訂單與交織目標由個人填寫。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	99.46	104.63	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.592956+08	2026-06-12 14:42:55.592958+08
303	销售经理驾驶仓数据分析看板 - 片段26 (01:44)	達成率在這個頁面查看。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	104.63	106.83	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.593572+08	2026-06-12 14:42:55.593574+08
304	销售经理驾驶仓数据分析看板 - 片段27 (01:46)	全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	106.93	112.93	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.594204+08	2026-06-12 14:42:55.594206+08
305	销售经理驾驶仓数据分析看板 - 片段28 (01:52)	駕駛艙將持續別待優化。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	112.93	115.93	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.594807+08	2026-06-12 14:42:55.594809+08
306	销售经理驾驶仓数据分析看板 - 片段29 (01:55)	我們會用更精準的數據動差,會業務增長持續負能。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\05f955d37e8c4ce08dd1b945fdcc8acb.mp4	李管理		/uploads/05f955d37e8c4ce08dd1b945fdcc8acb.mp4	115.93	120.43	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:42:55.595417+08	2026-06-12 14:42:55.595419+08
307	销售经理驾驶仓数据分析看板 - 片段1 (00:02)	銷售經理駕駛倉數據看板,手機和電腦端已同步上線。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	2.9	8.3	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.549671+08	2026-06-12 14:46:46.549675+08
308	销售经理驾驶仓数据分析看板 - 片段2 (00:08)	打開銷售經理數據可視化平台。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	8.3	12.3	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.557504+08	2026-06-12 14:46:46.557507+08
309	销售经理驾驶仓数据分析看板 - 片段3 (00:12)	進入銷售經理看板介面。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	12.3	14.8	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.558466+08	2026-06-12 14:46:46.558469+08
310	销售经理驾驶仓数据分析看板 - 片段4 (00:14)	點擊右上角。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	14.8	18.07	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.559341+08	2026-06-12 14:46:46.559344+08
311	销售经理驾驶仓数据分析看板 - 片段5 (00:18)	可選擇查看日報、月報、年報。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	18.07	21.67	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.560211+08	2026-06-12 14:46:46.560213+08
312	销售经理驾驶仓数据分析看板 - 片段6 (00:21)	也可以通過快捷按鈕選擇週期。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	21.67	24.77	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.560999+08	2026-06-12 14:46:46.561001+08
313	销售经理驾驶仓数据分析看板 - 片段7 (00:24)	關鍵數據指標可點擊穿透。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	24.77	29.93	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.561768+08	2026-06-12 14:46:46.561771+08
314	销售经理驾驶仓数据分析看板 - 片段8 (00:29)	毛利結構已拆分到具體業務模塊。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	29.93	36.71	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.562441+08	2026-06-12 14:46:46.562443+08
315	销售经理驾驶仓数据分析看板 - 片段9 (00:36)	管理層可直觀查看。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	36.71	38.81	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.563343+08	2026-06-12 14:46:46.563345+08
316	销售经理驾驶仓数据分析看板 - 片段10 (00:39)	從集團、區域到品牌排名。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	39.01	41.71	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.564687+08	2026-06-12 14:46:46.564689+08
317	销售经理驾驶仓数据分析看板 - 片段11 (00:41)	多維度評估自電情況。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	41.71	44.11	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.565287+08	2026-06-12 14:46:46.565289+08
318	销售经理驾驶仓数据分析看板 - 片段12 (00:44)	排名為達圖將各模塊的關鍵指標匯聚。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	44.11	52.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.565854+08	2026-06-12 14:46:46.565856+08
319	销售经理驾驶仓数据分析看板 - 片段13 (00:52)	強弱向清晰可變。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	52.02	54.22	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.566422+08	2026-06-12 14:46:46.566424+08
320	销售经理驾驶仓数据分析看板 - 片段14 (00:54)	業績趨勢圖動態呈現關鍵指標的時間總是。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	54.22	58.62	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.566978+08	2026-06-12 14:46:46.56698+08
321	销售经理驾驶仓数据分析看板 - 片段15 (00:58)	直觀把握整體業績的起落規律與波動。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	58.62	63.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.56762+08	2026-06-12 14:46:46.567622+08
322	销售经理驾驶仓数据分析看板 - 片段16 (01:03)	快速識別改點,預判走向。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	63.02	65.72	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.568268+08	2026-06-12 14:46:46.568271+08
323	销售经理驾驶仓数据分析看板 - 片段17 (01:05)	毛利歷史注重圖將歷史數據可視化呈現。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	65.72	69.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.568843+08	2026-06-12 14:46:46.568845+08
324	销售经理驾驶仓数据分析看板 - 片段18 (01:09)	可查看總毛利和單周毛利。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	69.42	72.52	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.569521+08	2026-06-12 14:46:46.569523+08
325	销售经理驾驶仓数据分析看板 - 片段19 (01:12)	依表圖展示的是目標完成率。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	72.62	75.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.570181+08	2026-06-12 14:46:46.570183+08
326	销售经理驾驶仓数据分析看板 - 片段20 (01:15)	銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	75.42	81.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.57084+08	2026-06-12 14:46:46.570843+08
327	销售经理驾驶仓数据分析看板 - 片段21 (01:21)	點擊可穿透到個人業績。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	81.42	84.62	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.571502+08	2026-06-12 14:46:46.571505+08
328	销售经理驾驶仓数据分析看板 - 片段22 (01:24)	排行榜通過核心指標進行排序。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	84.62	91.76	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.572099+08	2026-06-12 14:46:46.572102+08
329	销售经理驾驶仓数据分析看板 - 片段23 (01:31)	可快速識別主力車型與短板車型。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	91.76	94.86	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.572694+08	2026-06-12 14:46:46.572696+08
330	销售经理驾驶仓数据分析看板 - 片段24 (01:34)	結合毛利分布圖,車系盈利畫像完整清晰。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	94.86	99.46	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.573299+08	2026-06-12 14:46:46.573302+08
331	销售经理驾驶仓数据分析看板 - 片段25 (01:39)	銷售顧問的訂單與交織目標由個人填寫。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	99.46	104.63	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.573926+08	2026-06-12 14:46:46.573928+08
332	销售经理驾驶仓数据分析看板 - 片段26 (01:44)	達成率在這個頁面查看。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	104.63	106.83	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.574555+08	2026-06-12 14:46:46.574557+08
333	销售经理驾驶仓数据分析看板 - 片段27 (01:46)	全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	106.93	112.93	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.575193+08	2026-06-12 14:46:46.575195+08
334	销售经理驾驶仓数据分析看板 - 片段28 (01:52)	駕駛艙將持續別待優化。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	112.93	115.93	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.575815+08	2026-06-12 14:46:46.575818+08
335	销售经理驾驶仓数据分析看板 - 片段29 (01:55)	我們會用更精準的數據動差,會業務增長持續負能。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\ba3515232cfd4cea9e0eb8a216043208.mp4	李管理		/uploads/ba3515232cfd4cea9e0eb8a216043208.mp4	115.93	120.43	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:46:46.576431+08	2026-06-12 14:46:46.576433+08
336	销售经理驾驶仓数据分析看板 - 片段1 (00:02)	銷售經理駕駛倉數據看板,手機和電腦端已同步上線。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	2.9	8.3	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.658073+08	2026-06-12 14:47:18.658077+08
337	销售经理驾驶仓数据分析看板 - 片段2 (00:08)	打開銷售經理數據可視化平台。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	8.3	12.3	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.660681+08	2026-06-12 14:47:18.660684+08
338	销售经理驾驶仓数据分析看板 - 片段3 (00:12)	進入銷售經理看板介面。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	12.3	14.8	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.661655+08	2026-06-12 14:47:18.661658+08
339	销售经理驾驶仓数据分析看板 - 片段4 (00:14)	點擊右上角。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	14.8	18.07	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.662511+08	2026-06-12 14:47:18.662514+08
340	销售经理驾驶仓数据分析看板 - 片段5 (00:18)	可選擇查看日報、月報、年報。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	18.07	21.67	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.663327+08	2026-06-12 14:47:18.66333+08
341	销售经理驾驶仓数据分析看板 - 片段6 (00:21)	也可以通過快捷按鈕選擇週期。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	21.67	24.77	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.664123+08	2026-06-12 14:47:18.664125+08
342	销售经理驾驶仓数据分析看板 - 片段7 (00:24)	關鍵數據指標可點擊穿透。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	24.77	29.93	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.664901+08	2026-06-12 14:47:18.664903+08
343	销售经理驾驶仓数据分析看板 - 片段8 (00:29)	毛利結構已拆分到具體業務模塊。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	29.93	36.71	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.665597+08	2026-06-12 14:47:18.665599+08
344	销售经理驾驶仓数据分析看板 - 片段9 (00:36)	管理層可直觀查看。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	36.71	38.81	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.666263+08	2026-06-12 14:47:18.666265+08
345	销售经理驾驶仓数据分析看板 - 片段10 (00:39)	從集團、區域到品牌排名。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	39.01	41.71	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.666947+08	2026-06-12 14:47:18.66695+08
346	销售经理驾驶仓数据分析看板 - 片段11 (00:41)	多維度評估自電情況。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	41.71	44.11	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.667586+08	2026-06-12 14:47:18.667588+08
347	销售经理驾驶仓数据分析看板 - 片段12 (00:44)	排名為達圖將各模塊的關鍵指標匯聚。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	44.11	52.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.668211+08	2026-06-12 14:47:18.668214+08
348	销售经理驾驶仓数据分析看板 - 片段13 (00:52)	強弱向清晰可變。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	52.02	54.22	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.668822+08	2026-06-12 14:47:18.668824+08
349	销售经理驾驶仓数据分析看板 - 片段14 (00:54)	業績趨勢圖動態呈現關鍵指標的時間總是。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	54.22	58.62	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.669638+08	2026-06-12 14:47:18.669641+08
350	销售经理驾驶仓数据分析看板 - 片段15 (00:58)	直觀把握整體業績的起落規律與波動。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	58.62	63.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.670373+08	2026-06-12 14:47:18.670375+08
351	销售经理驾驶仓数据分析看板 - 片段16 (01:03)	快速識別改點,預判走向。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	63.02	65.72	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.671033+08	2026-06-12 14:47:18.671036+08
352	销售经理驾驶仓数据分析看板 - 片段17 (01:05)	毛利歷史注重圖將歷史數據可視化呈現。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	65.72	69.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.671685+08	2026-06-12 14:47:18.671687+08
353	销售经理驾驶仓数据分析看板 - 片段18 (01:09)	可查看總毛利和單周毛利。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	69.42	72.52	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.672248+08	2026-06-12 14:47:18.67225+08
354	销售经理驾驶仓数据分析看板 - 片段19 (01:12)	依表圖展示的是目標完成率。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	72.62	75.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.672788+08	2026-06-12 14:47:18.67279+08
355	销售经理驾驶仓数据分析看板 - 片段20 (01:15)	銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	75.42	81.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.673416+08	2026-06-12 14:47:18.673419+08
356	销售经理驾驶仓数据分析看板 - 片段21 (01:21)	點擊可穿透到個人業績。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	81.42	84.62	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.674128+08	2026-06-12 14:47:18.67413+08
357	销售经理驾驶仓数据分析看板 - 片段22 (01:24)	排行榜通過核心指標進行排序。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	84.62	91.76	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.674819+08	2026-06-12 14:47:18.674822+08
358	销售经理驾驶仓数据分析看板 - 片段23 (01:31)	可快速識別主力車型與短板車型。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	91.76	94.86	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.675645+08	2026-06-12 14:47:18.675648+08
359	销售经理驾驶仓数据分析看板 - 片段24 (01:34)	結合毛利分布圖,車系盈利畫像完整清晰。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	94.86	99.46	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.676355+08	2026-06-12 14:47:18.676358+08
360	销售经理驾驶仓数据分析看板 - 片段25 (01:39)	銷售顧問的訂單與交織目標由個人填寫。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	99.46	104.63	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.677089+08	2026-06-12 14:47:18.677091+08
361	销售经理驾驶仓数据分析看板 - 片段26 (01:44)	達成率在這個頁面查看。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	104.63	106.83	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.678007+08	2026-06-12 14:47:18.678009+08
362	销售经理驾驶仓数据分析看板 - 片段27 (01:46)	全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	106.93	112.93	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.678677+08	2026-06-12 14:47:18.678679+08
363	销售经理驾驶仓数据分析看板 - 片段28 (01:52)	駕駛艙將持續別待優化。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	112.93	115.93	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.679296+08	2026-06-12 14:47:18.679298+08
364	销售经理驾驶仓数据分析看板 - 片段29 (01:55)	我們會用更精準的數據動差,會業務增長持續負能。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f6e6653b0f7443f58b624404f6e97378.mp4	李管理		/uploads/f6e6653b0f7443f58b624404f6e97378.mp4	115.93	120.43	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:47:18.679942+08	2026-06-12 14:47:18.679944+08
365	销售顾问驾驶仓看板 - 片段1 (00:04)	打開數據可視化平台	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	4.02	6.32	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.631555+08	2026-06-12 14:52:05.631559+08
366	销售顾问驾驶仓看板 - 片段2 (00:06)	輸入帳號密碼點擊登錄	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	6.32	8.82	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.638951+08	2026-06-12 14:52:05.638958+08
367	销售顾问驾驶仓看板 - 片段3 (00:08)	進入銷售顧問看板介面	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	8.82	11.52	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.64074+08	2026-06-12 14:52:05.640744+08
368	销售顾问驾驶仓看板 - 片段4 (00:11)	可以選擇日報、夜報、年報三種查看方式	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	11.52	16.22	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.641728+08	2026-06-12 14:52:05.641732+08
369	销售顾问驾驶仓看板 - 片段5 (00:16)	也可以通過快捷鍵選擇查看週期	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	16.22	20.12	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.642697+08	2026-06-12 14:52:05.642699+08
370	销售顾问驾驶仓看板 - 片段6 (00:20)	查看客戶總數	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	20.12	22.12	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.643806+08	2026-06-12 14:52:05.643811+08
371	销售顾问驾驶仓看板 - 片段7 (00:22)	訂單數	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	22.12	23.52	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.644767+08	2026-06-12 14:52:05.64477+08
372	销售顾问驾驶仓看板 - 片段8 (00:23)	交車數	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	23.52	25.02	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.645446+08	2026-06-12 14:52:05.645449+08
373	销售顾问驾驶仓看板 - 片段9 (00:25)	以及轉化率、總毛利、單車毛利等關鍵數據	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	25.02	29.72	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.646158+08	2026-06-12 14:52:05.646161+08
374	销售顾问驾驶仓看板 - 片段10 (00:29)	在這個介面可以看到自己的毛利結構	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	29.72	33.72	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.64683+08	2026-06-12 14:52:05.646832+08
375	销售顾问驾驶仓看板 - 片段11 (00:33)	我們一眼就能看出利潤具體來自哪裡	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	33.92	37.42	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.647473+08	2026-06-12 14:52:05.647475+08
376	销售顾问驾驶仓看板 - 片段12 (00:37)	排名舉證從集團、區域、品牌到本店進行排名	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	37.42	41.92	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.648131+08	2026-06-12 14:52:05.648133+08
377	销售顾问驾驶仓看板 - 片段13 (00:41)	讓我們目標更清晰	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	41.92	43.92	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.648771+08	2026-06-12 14:52:05.648773+08
378	销售顾问驾驶仓看板 - 片段14 (00:43)	每項業務在訂單裡共項了多少利潤	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	43.92	47.02	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.649397+08	2026-06-12 14:52:05.649399+08
379	销售顾问驾驶仓看板 - 片段15 (00:47)	在這裡都可以看到明細	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	47.02	49.02	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.650018+08	2026-06-12 14:52:05.65002+08
380	销售顾问驾驶仓看板 - 片段16 (00:49)	這張雷達圖可以對比你在各項指標上的表現	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	49.02	55.2	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.650637+08	2026-06-12 14:52:05.65064+08
381	销售顾问驾驶仓看板 - 片段17 (00:55)	強弱項更為直觀	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	55.2	56.7	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.651265+08	2026-06-12 14:52:05.651267+08
382	销售顾问驾驶仓看板 - 片段18 (00:56)	明確下一步提升方向	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	56.7	58.7	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.651893+08	2026-06-12 14:52:05.651895+08
383	销售顾问驾驶仓看板 - 片段19 (00:58)	二季趨勢圖清晰呈現每個月的業績變化	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	58.7	66.09	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.652951+08	2026-06-12 14:52:05.652953+08
384	销售顾问驾驶仓看板 - 片段20 (01:06)	讓你看清成章軌跡	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	66.09	67.69	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.65365+08	2026-06-12 14:52:05.653652+08
385	销售顾问驾驶仓看板 - 片段21 (01:07)	即時把握節奏	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	67.69	68.89	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.65432+08	2026-06-12 14:52:05.654322+08
386	销售顾问驾驶仓看板 - 片段22 (01:08)	預判下一步目標	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	68.89	70.49	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.655195+08	2026-06-12 14:52:05.655197+08
387	销售顾问驾驶仓看板 - 片段23 (01:10)	毛利歷史圖記錄不同時間段的毛利表現	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	70.99	73.99	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.656337+08	2026-06-12 14:52:05.656341+08
388	销售顾问驾驶仓看板 - 片段24 (01:13)	可查看總毛利和單車毛利	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	73.99	76.49	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.658235+08	2026-06-12 14:52:05.658244+08
389	销售顾问驾驶仓看板 - 片段25 (01:16)	要圖展示的是目標完成率	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	76.49	83.92	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.659719+08	2026-06-12 14:52:05.659726+08
390	销售顾问驾驶仓看板 - 片段26 (01:25)	車系排行榜	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	85.42	86.42	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.661352+08	2026-06-12 14:52:05.661357+08
391	销售顾问驾驶仓看板 - 片段27 (01:26)	把你自己的客戶、訂單、交車和轉化率按車系拆開	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	86.42	90.72	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.662448+08	2026-06-12 14:52:05.662453+08
392	销售顾问驾驶仓看板 - 片段28 (01:30)	讓你清楚看到哪些車系是你的業績主力	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	90.72	93.92	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.663449+08	2026-06-12 14:52:05.663453+08
393	销售顾问驾驶仓看板 - 片段29 (01:33)	哪些車系還有挖掘空間	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	93.92	96.42	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.664348+08	2026-06-12 14:52:05.664352+08
394	销售顾问驾驶仓看板 - 片段30 (01:36)	目標完成情況	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	96.42	97.92	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.665314+08	2026-06-12 14:52:05.665322+08
395	销售顾问驾驶仓看板 - 片段31 (01:37)	是根據自己提交的訂單和交車目標	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	97.92	100.72	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.666846+08	2026-06-12 14:52:05.666854+08
396	销售顾问驾驶仓看板 - 片段32 (01:40)	展示實際達成率	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	100.72	102.22	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.667692+08	2026-06-12 14:52:05.667694+08
397	销售顾问驾驶仓看板 - 片段33 (01:42)	你可以看到哪些車系已經達標	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	102.22	104.62	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.668616+08	2026-06-12 14:52:05.668619+08
398	销售顾问驾驶仓看板 - 片段34 (01:44)	哪些還需要加把勁	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	104.62	106.32	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.669507+08	2026-06-12 14:52:05.669509+08
399	销售顾问驾驶仓看板 - 片段35 (01:47)	銷售顧問駕駛藏分手機端和電腦端	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	107.32	110.32	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.670286+08	2026-06-12 14:52:05.670287+08
400	销售顾问驾驶仓看板 - 片段36 (01:50)	雙端覆蓋	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	110.32	111.42	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.671012+08	2026-06-12 14:52:05.671014+08
401	销售顾问驾驶仓看板 - 片段37 (01:51)	我們會持續更新	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	111.42	113.12	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.672208+08	2026-06-12 14:52:05.672211+08
402	销售顾问驾驶仓看板 - 片段38 (01:53)	用數據提升效率放大你的能力	video	8	\N	sales	video	D:\\HqEvoAI\\uploads\\ec213804123948a09d2c123ffc1629fa.mp4	李管理		/uploads/ec213804123948a09d2c123ffc1629fa.mp4	113.12	115.92	批量导入,竞品对比分析	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:52:05.673172+08	2026-06-12 14:52:05.673175+08
403	销售顾问驾驶仓看板 - 片段1 (00:04)	打開數據可視化平台	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	4.02	6.32	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.268456+08	2026-06-12 14:53:26.268467+08
404	销售顾问驾驶仓看板 - 片段2 (00:06)	輸入帳號密碼點擊登錄	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	6.32	8.82	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.272189+08	2026-06-12 14:53:26.272192+08
405	销售顾问驾驶仓看板 - 片段3 (00:08)	進入銷售顧問看板介面	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	8.82	11.52	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.273118+08	2026-06-12 14:53:26.27312+08
406	销售顾问驾驶仓看板 - 片段4 (00:11)	可以選擇日報、夜報、年報三種查看方式	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	11.52	16.22	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.273879+08	2026-06-12 14:53:26.273882+08
407	销售顾问驾驶仓看板 - 片段5 (00:16)	也可以通過快捷鍵選擇查看週期	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	16.22	20.12	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.275105+08	2026-06-12 14:53:26.27511+08
408	销售顾问驾驶仓看板 - 片段6 (00:20)	查看客戶總數	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	20.12	22.12	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.276265+08	2026-06-12 14:53:26.27627+08
409	销售顾问驾驶仓看板 - 片段7 (00:22)	訂單數	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	22.12	23.52	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.279212+08	2026-06-12 14:53:26.279215+08
410	销售顾问驾驶仓看板 - 片段8 (00:23)	交車數	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	23.52	25.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.279917+08	2026-06-12 14:53:26.27992+08
411	销售顾问驾驶仓看板 - 片段9 (00:25)	以及轉化率、總毛利、單車毛利等關鍵數據	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	25.02	29.72	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.280592+08	2026-06-12 14:53:26.280594+08
412	销售顾问驾驶仓看板 - 片段10 (00:29)	在這個介面可以看到自己的毛利結構	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	29.72	33.72	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.2816+08	2026-06-12 14:53:26.281603+08
413	销售顾问驾驶仓看板 - 片段11 (00:33)	我們一眼就能看出利潤具體來自哪裡	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	33.92	37.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.282369+08	2026-06-12 14:53:26.282372+08
414	销售顾问驾驶仓看板 - 片段12 (00:37)	排名舉證從集團、區域、品牌到本店進行排名	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	37.42	41.92	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.283151+08	2026-06-12 14:53:26.283153+08
415	销售顾问驾驶仓看板 - 片段13 (00:41)	讓我們目標更清晰	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	41.92	43.92	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.28452+08	2026-06-12 14:53:26.284524+08
416	销售顾问驾驶仓看板 - 片段14 (00:43)	每項業務在訂單裡共項了多少利潤	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	43.92	47.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.285362+08	2026-06-12 14:53:26.285366+08
417	销售顾问驾驶仓看板 - 片段15 (00:47)	在這裡都可以看到明細	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	47.02	49.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.286129+08	2026-06-12 14:53:26.286132+08
418	销售顾问驾驶仓看板 - 片段16 (00:49)	這張雷達圖可以對比你在各項指標上的表現	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	49.02	55.2	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.286871+08	2026-06-12 14:53:26.286874+08
419	销售顾问驾驶仓看板 - 片段17 (00:55)	強弱項更為直觀	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	55.2	56.7	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.2876+08	2026-06-12 14:53:26.287604+08
420	销售顾问驾驶仓看板 - 片段18 (00:56)	明確下一步提升方向	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	56.7	58.7	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.288308+08	2026-06-12 14:53:26.288311+08
421	销售顾问驾驶仓看板 - 片段19 (00:58)	二季趨勢圖清晰呈現每個月的業績變化	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	58.7	66.09	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.288989+08	2026-06-12 14:53:26.288993+08
422	销售顾问驾驶仓看板 - 片段20 (01:06)	讓你看清成章軌跡	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	66.09	67.69	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.289686+08	2026-06-12 14:53:26.289689+08
423	销售顾问驾驶仓看板 - 片段21 (01:07)	即時把握節奏	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	67.69	68.89	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.290403+08	2026-06-12 14:53:26.290406+08
424	销售顾问驾驶仓看板 - 片段22 (01:08)	預判下一步目標	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	68.89	70.49	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.291351+08	2026-06-12 14:53:26.291355+08
425	销售顾问驾驶仓看板 - 片段23 (01:10)	毛利歷史圖記錄不同時間段的毛利表現	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	70.99	73.99	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.292282+08	2026-06-12 14:53:26.292284+08
426	销售顾问驾驶仓看板 - 片段24 (01:13)	可查看總毛利和單車毛利	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	73.99	76.49	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.293681+08	2026-06-12 14:53:26.29369+08
427	销售顾问驾驶仓看板 - 片段25 (01:16)	要圖展示的是目標完成率	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	76.49	83.92	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.295387+08	2026-06-12 14:53:26.295395+08
428	销售顾问驾驶仓看板 - 片段26 (01:25)	車系排行榜	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	85.42	86.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.297018+08	2026-06-12 14:53:26.297026+08
429	销售顾问驾驶仓看板 - 片段27 (01:26)	把你自己的客戶、訂單、交車和轉化率按車系拆開	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	86.42	90.72	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.298586+08	2026-06-12 14:53:26.298595+08
430	销售顾问驾驶仓看板 - 片段28 (01:30)	讓你清楚看到哪些車系是你的業績主力	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	90.72	93.92	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.300172+08	2026-06-12 14:53:26.300181+08
431	销售顾问驾驶仓看板 - 片段29 (01:33)	哪些車系還有挖掘空間	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	93.92	96.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.302003+08	2026-06-12 14:53:26.302012+08
432	销售顾问驾驶仓看板 - 片段30 (01:36)	目標完成情況	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	96.42	97.92	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.303599+08	2026-06-12 14:53:26.303606+08
433	销售顾问驾驶仓看板 - 片段31 (01:37)	是根據自己提交的訂單和交車目標	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	97.92	100.72	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.30514+08	2026-06-12 14:53:26.305151+08
434	销售顾问驾驶仓看板 - 片段32 (01:40)	展示實際達成率	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	100.72	102.22	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.306894+08	2026-06-12 14:53:26.306903+08
435	销售顾问驾驶仓看板 - 片段33 (01:42)	你可以看到哪些車系已經達標	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	102.22	104.62	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.30853+08	2026-06-12 14:53:26.308539+08
436	销售顾问驾驶仓看板 - 片段34 (01:44)	哪些還需要加把勁	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	104.62	106.32	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.310127+08	2026-06-12 14:53:26.310133+08
437	销售顾问驾驶仓看板 - 片段35 (01:47)	銷售顧問駕駛藏分手機端和電腦端	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	107.32	110.32	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.311364+08	2026-06-12 14:53:26.311368+08
438	销售顾问驾驶仓看板 - 片段36 (01:50)	雙端覆蓋	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	110.32	111.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.312374+08	2026-06-12 14:53:26.312378+08
439	销售顾问驾驶仓看板 - 片段37 (01:51)	我們會持續更新	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	111.42	113.12	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.31334+08	2026-06-12 14:53:26.313344+08
440	销售顾问驾驶仓看板 - 片段38 (01:53)	用數據提升效率放大你的能力	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\98c1f3550a584e8983da7bcd58834330.mp4	李管理		/uploads/98c1f3550a584e8983da7bcd58834330.mp4	113.12	115.92	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 14:53:26.314318+08	2026-06-12 14:53:26.314322+08
232	销售经理驾驶仓数据分析看板 - 片段1 (00:00)	[3s-8s] 銷售經理駕駛倉數據看板,手機和電腦端已同步上線。\n\n[8s-12s] 打開銷售經理數據可視化平台。\n\n[12s-15s] 進入銷售經理看板介面。\n\n[15s-18s] 點擊右上角。\n\n[18s-22s] 可選擇查看日報、月報、年報。\n\n[22s-25s] 也可以通過快捷按鈕選擇週期。\n\n[25s-30s] 關鍵數據指標可點擊穿透。\n\n[30s-37s] 毛利結構已拆分到具體業務模塊。\n\n[37s-39s] 管理層可直觀查看。\n\n[39s-42s] 從集團、區域到品牌排名。\n\n[42s-44s] 多維度評估自電情況。\n\n[44s-52s] 排名為達圖將各模塊的關鍵指標匯聚。\n\n[52s-54s] 強弱向清晰可變。\n\n[54s-59s] 業績趨勢圖動態呈現關鍵指標的時間總是。\n\n[59s-63s] 直觀把握整體業績的起落規律與波動。\n\n[63s-66s] 快速識別改點,預判走向。\n\n[66s-69s] 毛利歷史注重圖將歷史數據可視化呈現。\n\n[69s-73s] 可查看總毛利和單周毛利。\n\n[73s-75s] 依表圖展示的是目標完成率。\n\n[75s-81s] 銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。\n\n[81s-85s] 點擊可穿透到個人業績。\n\n[85s-92s] 排行榜通過核心指標進行排序。\n\n[92s-95s] 可快速識別主力車型與短板車型。\n\n[95s-99s] 結合毛利分布圖,車系盈利畫像完整清晰。\n\n[99s-105s] 銷售顧問的訂單與交織目標由個人填寫。\n\n[105s-107s] 達成率在這個頁面查看。\n\n[107s-113s] 全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。\n\n[113s-116s] 駕駛艙將持續別待優化。\n\n[116s-120s] 我們會用更精準的數據動差,會業務增長持續負能。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f9ffebba4b534fcda293429d3dc7a5e5.mp4	李管理		/uploads/f9ffebba4b534fcda293429d3dc7a5e5.mp4	0	60	批量导入,产品知识库	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 13:11:26.464605+08	2026-06-12 15:03:56.032258+08
233	销售经理驾驶仓数据分析看板 - 片段2 (01:00)	[3s-8s] 銷售經理駕駛艙數據看板,手機和電腦端已同步上線。\n\n[8s-12s] 打開銷售經理數據可視化平台。\n\n[12s-15s] 進入銷售經理看板介面。\n\n[15s-18s] 點擊右上角。\n\n[18s-22s] 可選擇查看日報、月報、年報。\n\n[22s-25s] 也可以通過快捷按鈕選擇週期。\n\n[25s-30s] 關鍵數據指標可點擊穿透。\n\n[30s-37s] 毛利結構已拆分到具體業務模塊。\n\n[37s-39s] 管理層可直觀查看。\n\n[39s-42s] 從集團、區域到品牌排名。\n\n[42s-44s] 多維度評估自電情況。\n\n[44s-52s] 排名為打圖將各模塊的關鍵指標匯聚。\n\n[52s-54s] 強弱向清晰可變。\n\n[54s-59s] 業績趨勢圖動態呈現關鍵指標的時間總是。\n\n[59s-63s] 直觀把握整體業績的起落規律與波動。\n\n[63s-66s] 快速識別改點,預判走向。\n\n[66s-69s] 毛利歷史注重圖將歷史數據可視化呈現。\n\n[69s-73s] 可查看總毛利和單周毛利。\n\n[73s-75s] 依表圖展示的是目標完成率。\n\n[75s-81s] 銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。\n\n[81s-85s] 點擊可穿透到個人業績。\n\n[85s-92s] 排行榜通過核心指標進行排序。\n\n[92s-95s] 可快速識別主力車型與短板車型。\n\n[95s-99s] 結合毛利分布圖,車系盈利畫像完整清晰。\n\n[99s-105s] 銷售顧問的訂單與交織目標由個人填寫。\n\n[105s-107s] 達成率在這個頁面查看。\n\n[107s-113s] 全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。\n\n[113s-116s] 駕駛艙將持續別待優化。\n\n[116s-121s] 我們會用更精準的數據動作,會業務增長持續負能。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\f9ffebba4b534fcda293429d3dc7a5e5.mp4	李管理		/uploads/f9ffebba4b534fcda293429d3dc7a5e5.mp4	60	120	批量导入,产品知识库	\N	\N	1	0	0	approved	2	\N	1	2026-06-12 13:11:26.474394+08	2026-06-12 15:19:53.128986+08
272	销售经理驾驶仓数据分析看板 - 片段1 (00:00)	[3s-8s] 銷售經理駕駛艙數據看板,手機和電腦端已同步上線。\n\n[8s-12s] 打開銷售經理數據可視化平台。\n\n[12s-15s] 進入銷售經理看板介面。\n\n[15s-18s] 點擊右上角。\n\n[18s-22s] 可選擇查看日報、月報、年報。\n\n[22s-25s] 也可以通過快捷按鈕選擇週期。\n\n[25s-30s] 關鍵數據指標可點擊穿透。\n\n[30s-37s] 毛利結構已拆分到具體業務模塊。\n\n[37s-39s] 管理層可直觀查看。\n\n[39s-42s] 從集團、區域到品牌排名。\n\n[42s-44s] 多維度評估自電情況。\n\n[44s-52s] 排名為打圖將各模塊的關鍵指標匯聚。\n\n[52s-54s] 強弱向清晰可變。\n\n[54s-59s] 業績趨勢圖動態呈現關鍵指標的時間總是。\n\n[59s-63s] 直觀把握整體業績的起落規律與波動。\n\n[63s-66s] 快速識別改點,預判走向。\n\n[66s-69s] 毛利歷史注重圖將歷史數據可視化呈現。\n\n[69s-73s] 可查看總毛利和單周毛利。\n\n[73s-75s] 依表圖展示的是目標完成率。\n\n[75s-81s] 銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。\n\n[81s-85s] 點擊可穿透到個人業績。\n\n[85s-92s] 排行榜通過核心指標進行排序。\n\n[92s-95s] 可快速識別主力車型與短板車型。\n\n[95s-99s] 結合毛利分布圖,車系盈利畫像完整清晰。\n\n[99s-105s] 銷售顧問的訂單與交織目標由個人填寫。\n\n[105s-107s] 達成率在這個頁面查看。\n\n[107s-113s] 全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。\n\n[113s-116s] 駕駛艙將持續別待優化。\n\n[116s-121s] 我們會用更精準的數據動作,會業務增長持續負能。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\576b35f88fe443e2bebed6e5992c2465.mp4	李管理		/uploads/576b35f88fe443e2bebed6e5992c2465.mp4	0	60	批量导入,产品知识库	\N	\N	1	0	0	approved	2	\N	1	2026-06-12 14:39:09.811754+08	2026-06-12 15:20:56.335077+08
275	销售经理驾驶仓数据分析看板 - 片段1 (00:00)	[3s-8s] 銷售經理駕駛艙數據看板,手機和電腦端已同步上線。\n\n[8s-12s] 打開銷售經理數據可視化平台。\n\n[12s-15s] 進入銷售經理看板介面。\n\n[15s-18s] 點擊右上角。\n\n[18s-22s] 可選擇查看日報、月報、年報。\n\n[22s-25s] 也可以通過快捷按鈕選擇週期。\n\n[25s-30s] 關鍵數據指標可點擊穿透。\n\n[30s-37s] 毛利結構已拆分到具體業務模塊。\n\n[37s-39s] 管理層可直觀查看。\n\n[39s-42s] 從集團、區域到品牌排名。\n\n[42s-44s] 多維度評估自電情況。\n\n[44s-52s] 排名為打圖將各模塊的關鍵指標匯聚。\n\n[52s-54s] 強弱向清晰可變。\n\n[54s-59s] 業績趨勢圖動態呈現關鍵指標的時間總是。\n\n[59s-63s] 直觀把握整體業績的起落規律與波動。\n\n[63s-66s] 快速識別改點,預判走向。\n\n[66s-69s] 毛利歷史注重圖將歷史數據可視化呈現。\n\n[69s-73s] 可查看總毛利和單周毛利。\n\n[73s-75s] 依表圖展示的是目標完成率。\n\n[75s-81s] 銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。\n\n[81s-85s] 點擊可穿透到個人業績。\n\n[85s-92s] 排行榜通過核心指標進行排序。\n\n[92s-95s] 可快速識別主力車型與短板車型。\n\n[95s-99s] 結合毛利分布圖,車系盈利畫像完整清晰。\n\n[99s-105s] 銷售顧問的訂單與交織目標由個人填寫。\n\n[105s-107s] 達成率在這個頁面查看。\n\n[107s-113s] 全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。\n\n[113s-116s] 駕駛艙將持續別待優化。\n\n[116s-121s] 我們會用更精準的數據動作,會業務增長持續負能。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\9d3243268adb4526bd391afbd499f7b4.mp4	李管理		/uploads/9d3243268adb4526bd391afbd499f7b4.mp4	0	60	批量导入,产品知识库	\N	\N	1	0	0	approved	2	\N	1	2026-06-12 14:41:27.188305+08	2026-06-12 15:22:10.685618+08
231	销售经理驾驶仓数据分析看板	[3s-8s] 銷售經理駕駛倉數據看板,手機和電腦端已同步上線。\n\n[8s-12s] 打開銷售經理數據可視化平台。\n\n[12s-15s] 進入銷售經理看板介面。\n\n[15s-18s] 點擊右上角。\n\n[18s-22s] 可選擇查看日報、月報、年報。\n\n[22s-25s] 也可以通過快捷按鈕選擇週期。\n\n[25s-30s] 關鍵數據指標可點擊穿透。\n\n[30s-37s] 毛利結構已拆分到具體業務模塊。\n\n[37s-39s] 管理層可直觀查看。\n\n[39s-42s] 從集團、區域到品牌排名。\n\n[42s-44s] 多維度評估自電情況。\n\n[44s-52s] 排名為達圖將各模塊的關鍵指標匯聚。\n\n[52s-54s] 強弱向清晰可變。\n\n[54s-59s] 業績趨勢圖動態呈現關鍵指標的時間總是。\n\n[59s-63s] 直觀把握整體業績的起落規律與波動。\n\n[63s-66s] 快速識別改點,預判走向。\n\n[66s-69s] 毛利歷史注重圖將歷史數據可視化呈現。\n\n[69s-73s] 可查看總毛利和單周毛利。\n\n[73s-75s] 依表圖展示的是目標完成率。\n\n[75s-81s] 銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。\n\n[81s-85s] 點擊可穿透到個人業績。\n\n[85s-92s] 排行榜通過核心指標進行排序。\n\n[92s-95s] 可快速識別主力車型與短板車型。\n\n[95s-99s] 結合毛利分布圖,車系盈利畫像完整清晰。\n\n[99s-105s] 銷售顧問的訂單與交織目標由個人填寫。\n\n[105s-107s] 達成率在這個頁面查看。\n\n[107s-113s] 全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。\n\n[113s-116s] 駕駛艙將持續別待優化。\n\n[116s-120s] 我們會用更精準的數據動差,會業務增長持續負能。	video	1	\N	public	video	D:\\HqEvoAI\\uploads\\4d06a30e68ef4a229ad1db2a0f1be7bb.mp4	李管理		/uploads/4d06a30e68ef4a229ad1db2a0f1be7bb.mp4	0	0	批量导入,公司制度与规范	\N	\N	1	0	0	approved	2	\N	1	2026-06-12 12:38:22.534169+08	2026-06-12 15:22:26.011805+08
273	销售经理驾驶仓数据分析看板 - 片段2 (01:00)	[3s-8s] 銷售經理駕駛艙數據看板,手機和電腦端已同步上線。\n\n[8s-12s] 打開銷售經理數據可視化平台。\n\n[12s-15s] 進入銷售經理看板介面。\n\n[15s-18s] 點擊右上角。\n\n[18s-22s] 可選擇查看日報、月報、年報。\n\n[22s-25s] 也可以通過快捷按鈕選擇週期。\n\n[25s-30s] 關鍵數據指標可點擊穿透。\n\n[30s-37s] 毛利結構已拆分到具體業務模塊。\n\n[37s-39s] 管理層可直觀查看。\n\n[39s-42s] 從集團、區域到品牌排名。\n\n[42s-44s] 多維度評估自電情況。\n\n[44s-52s] 排名為打圖將各模塊的關鍵指標匯聚。\n\n[52s-54s] 強弱向清晰可變。\n\n[54s-59s] 業績趨勢圖動態呈現關鍵指標的時間總是。\n\n[59s-63s] 直觀把握整體業績的起落規律與波動。\n\n[63s-66s] 快速識別改點,預判走向。\n\n[66s-69s] 毛利歷史注重圖將歷史數據可視化呈現。\n\n[69s-73s] 可查看總毛利和單周毛利。\n\n[73s-75s] 依表圖展示的是目標完成率。\n\n[75s-81s] 銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。\n\n[81s-85s] 點擊可穿透到個人業績。\n\n[85s-92s] 排行榜通過核心指標進行排序。\n\n[92s-95s] 可快速識別主力車型與短板車型。\n\n[95s-99s] 結合毛利分布圖,車系盈利畫像完整清晰。\n\n[99s-105s] 銷售顧問的訂單與交織目標由個人填寫。\n\n[105s-107s] 達成率在這個頁面查看。\n\n[107s-113s] 全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。\n\n[113s-116s] 駕駛艙將持續別待優化。\n\n[116s-121s] 我們會用更精準的數據動作,會業務增長持續負能。	video	7	\N	sales	video	D:\\HqEvoAI\\uploads\\576b35f88fe443e2bebed6e5992c2465.mp4	李管理		/uploads/576b35f88fe443e2bebed6e5992c2465.mp4	60	120	批量导入,产品知识库	\N	\N	1	0	0	approved	2	\N	1	2026-06-12 14:39:09.819356+08	2026-06-12 15:24:35.88201+08
441	操作手册-售后服务接待v2025.05	维修服务接待操作手册\nver 2025.05\n维修服务接待操作手册目录\n一、 工单录入 整体操作 步骤\n二、 工单 的新增与修改\n三、 添加 工时项目\n四、 工时项目派工\n五、 维修零件出库（仓管 员操作）\n六、 质检完工\n七、 优惠券\n八、 套餐 卡九、 延保\n十、 折扣\n十一、 推结算单\n十二、 维修财务结账（ 收银员 操作）\n十三、 新增客户\n十四、 客户 情况 情况\n十五、 工单 备注 备注\n十六、厂家优惠券\n操作入口： 05售后管理→05.01 维修服务接待一、工单录入 整体操作步骤\n\n操作入口：05售后管理→05.01维修服务接待二、工单的新增与修改（新增）\n注：有红点的项目是必填项\n操作 入口：05售后管理→05.01维修服务接待二、工单的新增与修改（修改）\n\n操作 入口：05售后管理→05.01维修服务接待\n二、工单的新增与修改（提取厂家工单）\n三、添加工时项目\n操作入口：05售后管理→05.01维修服务接待\n\n操作入口：05售后管理→05.01维修服务接待四、工时项目派工\n\n功能入口：05 售后管理→05.01维修零件出库五、维修零件出库（仓管员录入 工单耗材零件）\n\n操作 入口：05售后管理→05.01维修服务接待六、质检完工\n\n一、优惠券设置：\n1、在【02.07优惠券方案】中设置优惠券方案，内容包括券名称、发行量、面额等。 \n2、设置使用券的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n3、在总经理审核、财务审核生效后，方案才能用于发行优惠券。\n4、在【09.07优惠券管理】中，使用上面生效的优惠券方案发行（生\n成）优惠券。 \n5、步骤4中 发行的券赠送给客户，审核生效后即可在工单中使用（核销）。\n二、优惠券使用条件：\n1、工单 已质检完工。七、优惠券（使用说明）\n2、工单的工时项目，零件项目必须符合优惠券使用的限定范围。\n3、工单中必须有客户付费类的收费类型。（优惠券只能抵扣客户付费的金额）\n三、优惠券核销后：\n1、在工时或零件项目中新增一条编号前缀为"Vou"，金额为负数（核销金额）的记录，用于\n冲减客户付费的金额。\n2、优惠券状态变更为“已使用”，更新优惠券已抵用金额。\n3、工单使用优惠券抵扣后，必须先取消抵扣才能做质检反完工。\n四、取消优惠券核销抵扣：在优惠券核销窗口，选择要取消的券，点击"取消抵扣"按钮。\n功能入口： 05售后管理→05.0 1维修服务接待七、优惠券（优惠券核销）\n取消抵扣：选择要取消的优惠券，点”取消抵扣“按钮。\n操作 入口：05售后管理→05.01维修服务接待七、优惠券（核销后）\n\n一、套餐卡设置：\n  1、在【02.08套餐方案】中设置套餐的名称、套餐金额、有效天数、收费类型以及适用\n      车系等信息，其中车系如果为空则表示所有车系都可有。\n  2、设置套餐的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n 3、在【09.05套餐卡销售管理】中销售套餐或在新车订单、保单中赠送套餐。\n二、套餐的使用条件： \n 1、工时核销，只允许在在修工单中核销(确保所有的工时项目都完成派工)。\n 2、零件核销，须在要核销的\n套餐零件已出库，且工单已完工后(确保核销后出库件不变)。   \n3、套餐卡中项目剩余次数大于要核销的次数。\n三、套餐核销：\n 1、工时核销 ，在工单中新增一条工时，名称为要核销的 套餐工时项目，收费类型 设\n为\n         套餐收费类型。套餐卡中该工时的剩余次数减少一次。\n    2、零件核销，把工单中要核销零件的收费类型改为套餐的收费类型。套餐卡中该零件\n         的剩余次数更新为原剩余次数-工单对应零件出库数。\n四、取消套餐使用：修改工时或零件项目的收费类型，对于工时项目也可直接删除。八、套餐卡（说明）\n八、套餐卡（工时核销）\n功能入口： 05售后管理→ 05.0 1维修服务接待\n\n操作 入口：05售后管理→05.01维修服务接待八、套餐卡（零件核销）\n\n一、延保设置：\n      1、在【01.03基础数据】的“集团统一设置--售后--延 保类型” 中设置好 延保类型 和\n           对应的收费类型。 \n      2、在【02.09延保方案定义】中，新增延保方案，录入方案的 延保类型 ，名称、 适用\n           车名（车系）、价格、里程数、年限、保养次数、毛 利等等。\n      3、在【05.08延保销售管理】中录入延保销售，并收款结算。 销售录入 的客户车 所属\n           的车系必须是延保方案设置的车名（车系），否则无 法录入。\n二、延保使用：\n             录入已购买延保车辆的保养工单时，系统会弹出已购买延保的提示。延保车辆的\n       保养工单可以选择延保专用的收费类型，延保专用收费类型的 金额在结 算时对客 户免\n       费。\n（如果客户是购买延保后首次来店保养，系统会弹出起保窗口，要求进行起保操作。）\n      九、延保（说明）\n操作 入口：05售后管理→05.01维修服务接待九、延保（延保起保）\n\n操作 入口：05售后管理→05.01维修服务接待九、延保（使用延保）\n\n十、折扣（折扣 设置）\n功能入口：05 售后管理→05.0 1维修服务接待\n\n十、折扣（折扣 审批）\n功能入口：05 售后管理→05.01 维修服务接待\n\n十一、推结算单\n功能入口：05 售后管理→05.01维修服务接待\n 注：如付款方显示为空，需在【01.03基础数据】中设置付款方名称\n十二、 维修财务结账（收款员操作）\n功能入口：08 财务管理→08. 01.03维修财务结账\n\n操作 入口：05售后管理→05.01维修服务接待十三、新增客户\n\n功能入口： 05售后管理→05.0 1维修服务接待十四、客户情况/信息\n\n功能入口： 05售后管理→05.0 1维修服务接待十五、工单备注\n\n一、厂家优惠券设置：在【02.13厂家优惠券】中定义厂家优惠券的券名称，券类型，券  \n面值，收费类型，工种等项目。厂家优惠券定义统一设置，各分公司通用。\n二、厂家优惠券用于核销工时项目费用。\n三、厂家优惠券核销，在工时项目中增加编号为"Fac"的两条记录，两条记 录的金额 是券 \n面值的一正一负，收费类型分别是券定义的收费类型和工单的收费类型。十六、厂家优惠券（说明）\n操作 入口：05售后管理→05.01维修服务接待十六、厂家优惠券（优惠券使用）\n\n维修接待流程图\n\n维修服务接待操作手册\n㔃 ᶏ	text	29	\N	service	manual	D:\\HqEvoAI\\uploads\\05d075707db542128caf3832bf3e48e6.pdf	李管理	\N	\N	0	0	批量导入,会员服务管理	\N	\N	1	0	0	approved	\N	\N	1	2026-06-13 10:37:19.716353+08	2026-06-13 10:37:19.716356+08
442	操作手册-套餐卡	套餐卡操作手册\n\n套餐卡管理功能流程说明\n\n套餐卡方案制定\n业务基础资料→套餐方案\n\n套餐卡方案制定\n业务基础资料→套餐方案\n工时项目及材料材料定义。材料项目定义与工时项目的方案一致\n套餐卡销售管理\n市场管理→套餐卡销售管理\n\n套餐卡销售管理\n市场管理→套餐卡销售管理\n财务结算之后生效	text	29	\N	service	manual	D:\\HqEvoAI\\uploads\\402741ee86b34ebf9689e351d8b9bdf9.pdf	李管理	\N	\N	0	0	批量导入,会员服务管理	\N	\N	1	0	0	approved	\N	\N	1	2026-06-13 10:38:04.422756+08	2026-06-13 10:38:04.422762+08
443	附件2：《帝豪向上系列产品价值推介》 (1)	帝豪向上系列\n产品价值推介\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n每一代帝豪始终坚持向上精神，以实力打破合资垄断，引领国民轿车不断向上\n第1代帝豪\n以超高的品质和五星级安全\n向上突破自主品牌 8万级价格天花板\n第2代帝豪\nC-ECAP白金评价冠军\n向上突破自主品牌健康安全天花板\n第3代帝豪\n同级首个配备 LED大灯、液晶仪表\n向上突破自主品牌科技天花板第4代帝豪\nBMA全球模块化架构加持\n向上突破自主品牌品质天花板第5代帝豪\n新一代 BMA Evo 架构+千里浩瀚 H3 \n向上突破自主品牌智能天花板\n帝豪的向上精神\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n每一代帝豪都持续坚持“向上精神”\n不断突破极限，打破合资垄断\n十六载向上历程，收获全球 420万+用户信赖\n成就中国品牌家轿第一家族\n帝豪向上系列车型身披荣耀而来，传承向上精神\n助力帝豪冲刺 500万销量！\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n采用12~25μm 粒径的多种银元型铝粉， 光线下，泛着暖金色\n泽，金属微粒随角度流转，宛如星尘在不断闪烁、呼吸。\n每层色漆厚度误差控制在头发丝直径的 1/30，搭配 2K高光\n清漆，做到“十年如一日”，持久如新\n采用环保水性 B1B2涂装工艺喷涂，德国巴斯夫高耐候涂料\n漆面更炫彩、更高亮、更耐久、更环保全新外观车色 -荣耀金\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n全新主题内饰 -锦绣前橙\n以明亮而温润的色彩唤醒座舱氛围，从座椅到饰板，从缝线到纹理，每一处对蕴藏对未来的美好期许\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n帝豪向上系列\n目标人群 本地居住，家庭稳定的 30-40岁已婚已育首购男性用户为主\n冠军颜值\n（开创 A级轿车宽体低趴风时代）\n产品USP产品定位 全球品质冠军家轿\n自主：长安第二代 *动合资：轩*经典、朗逸 *锐 核心竞品\n3大\n核心卖点传播\nSlogan产品信息屋\n超强全球架构\nBMA全球模块化架构，操控好，空间大超低用车成本\n搭载1.5L直列四缸发动机，动力足，油耗低超强科技体验\n银河OS车机系统，屏幕大，响应快\n•流云飞瀑前格栅\n•上弦新月装饰设计\n•全新荣耀金车色\n•全新锦绣前橙主题内饰\n•“2宽2低”，塑造整车大气风范\n•1820mm 同级最宽车身\n•1.24同级最大宽高比\n•低重心设计：重心降低，跑起来更稳\n•低风阻设计： 0.27Cd同级最低风阻•1.5L直列四缸发动机\n•88kW同级最大功率\n•150N·m 同级最大扭矩\n•同级最强 20000N·m/deg 车身扭转刚\n度\n•高强度钢材使用量远超同级自主品牌\n•车顶激光焊接可承受自身 2.5倍重量的\n压力，国标仅为 1.5倍\n•26处智慧储物空间冠军架构\n（BMA 全新一代模块化架构）\n•5G+智造工厂“双零双百”\n•0偏差精致冲压\n•0污染绿色涂装\n•100%自动化雷霆焊装\n•100%大数据精益总装\n•中汽研可靠性管理流程认证\n•国内首款获得中汽研汽车可靠性管理\n流程认证的汽车冠军品质\n（5G+智造工厂“双零双百”）\n•12.3英寸中控屏\n•8.8英寸高清数字仪表\n•540°上帝之眼透明底盘\n•手机APP远程控制\n•智能语音交互\n•可见即可说\n•多条件语同音搜索\n•上下文跨场景对话\n•多轮连续对话冠军科技\n（家轿智能座舱天花板）\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n超宽车身造就帝豪 1500mm 同级\n最宽后排乘坐空间，乘坐更宽敞\n动感流畅的车身姿态，宽体低趴\n更显整车大气风范\n同级最低风阻系数\n 0.27Cd\n更好驾控、更省油\n车身重心降低\n 70mm\n，跑起来更稳冠军颜值 -宽体低趴引领者\n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞                                                                                                                                             \n                                    海南合众汽车销售有限公司_赵宇飞              	text	7	\N	sales	manual	D:\\HqEvoAI\\uploads\\e7b29b30eb1349069f3fe85392b1d452.pdf	李管理	\N	\N	0	0	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-13 10:38:52.334829+08	2026-06-13 10:38:52.334832+08
444	检查汽车轮胎漏气	检查汽车轮胎漏气，我们分三步，第一步。把轮胎卸下来，然后在轮胎表面上。涂上肥皂水，带泡泡的肥皂水，如果发现带泡泡的肥皂水有一个一个泡泡冒出，就说明那个位置有漏气。注意一定要把轮胎的所有面全部都用带泡泡的肥皂水沾到，才可以检查出来，否则是无法判断的，这点一定要特别注意好的。	text	22	\N	tech	experience	\N	赵技师	技术部	\N	0	0				1	0	0	pending	\N	\N	1	2026-06-13 14:56:16.165094+08	2026-06-13 14:56:16.1651+08
445	处理现场 客户情绪失控的场景	下面我说一下 处理现场 客户情绪失控的场景 我们应该怎么做 第一步 首先不要去跟客户理论 一定是要调整自己的心理状态 用一个非常缓慢 温和的状态 跟客人去交流 第二步 请他坐下 给他的倒杯水或者饮料 缓和一下他的情绪 第三步 咨询一下客户 刚才是为什么事情不满 第四步 听清楚客户的问题 马上去找 业务部门了解实际情况 叫客户稍等 第五步 三分钟之内 一定要回到现场 跟客户继续交流 最后一步 很关键 处理一个客户的情绪和矛盾 不能够换两个人 一定要一个人处理完	text	25	\N	service	experience	\N	陈客服	客服部	\N	0	0				1	0	0	pending	\N	\N	1	2026-06-13 14:59:02.283212+08	2026-06-13 14:59:02.283221+08
\.


--
-- Data for Name: learning_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.learning_records (id, user_id, knowledge_id, learn_type, duration_sec, score, created_at) FROM stdin;
1	3	1	test	0	0.00	2026-06-09 13:12:18.374593+08
2	3	6	view	45	0.00	2026-06-09 13:42:58.370568+08
3	3	1	view	8	0.00	2026-06-09 14:26:20.086298+08
4	3	1	test	0	0.00	2026-06-09 14:30:50.076977+08
5	3	1	test	0	0.00	2026-06-09 14:30:59.723106+08
6	3	1	test	0	100.00	2026-06-09 14:31:05.465408+08
7	3	1	test	0	100.00	2026-06-09 14:42:22.065178+08
8	4	1	test	0	0.00	2026-06-11 13:23:25.218435+08
9	4	1	test	0	100.00	2026-06-11 13:23:33.840179+08
10	4	1	test	0	0.00	2026-06-11 13:31:37.850715+08
11	4	1	test	0	0.00	2026-06-11 13:31:43.241683+08
12	4	1	test	0	0.00	2026-06-11 13:31:49.12788+08
13	4	1	test	0	100.00	2026-06-11 13:31:54.141011+08
14	4	1	test	0	100.00	2026-06-11 13:32:31.474796+08
15	4	1	test	0	100.00	2026-06-11 13:32:40.779733+08
16	4	1	test	0	100.00	2026-06-11 13:32:45.800243+08
17	4	1	test	0	0.00	2026-06-11 13:32:55.902911+08
18	4	1	test	0	0.00	2026-06-11 13:33:55.493276+08
19	4	1	test	0	0.00	2026-06-11 13:34:01.658005+08
20	4	1	test	0	100.00	2026-06-11 13:34:05.281074+08
21	4	1	test	0	0.00	2026-06-11 13:34:11.961771+08
22	4	1	test	0	0.00	2026-06-11 13:34:17.276513+08
23	4	1	test	0	0.00	2026-06-11 13:34:21.204507+08
24	4	1	test	0	0.00	2026-06-11 13:34:24.060686+08
25	4	1	test	0	100.00	2026-06-11 13:34:29.545461+08
26	4	1	test	0	100.00	2026-06-11 13:34:33.647259+08
27	4	1	test	0	100.00	2026-06-11 13:34:51.481907+08
28	4	1	test	0	0.00	2026-06-11 13:34:56.307127+08
29	5	1	test	0	100.00	2026-06-11 13:57:47.670111+08
30	5	1	test	0	100.00	2026-06-11 13:57:56.285336+08
31	5	1	test	0	100.00	2026-06-11 13:58:06.114605+08
32	5	1	test	0	100.00	2026-06-11 13:58:09.67839+08
33	5	1	test	0	100.00	2026-06-11 13:58:12.846186+08
34	5	1	test	0	100.00	2026-06-11 13:58:15.437686+08
35	5	1	test	0	0.00	2026-06-11 13:58:17.88586+08
36	4	2	test	0	0.00	2026-06-13 10:48:13.785551+08
37	4	2	test	0	0.00	2026-06-13 10:48:16.606143+08
38	4	233	test	0	100.00	2026-06-13 10:48:19.092611+08
39	4	2	test	0	0.00	2026-06-13 10:48:21.291869+08
40	4	2	test	0	0.00	2026-06-13 10:48:23.3646+08
41	4	2	test	0	0.00	2026-06-13 10:48:25.973357+08
42	3	1	test	0	100.00	2026-06-12 19:10:53.060211+08
43	3	7	test	0	0.00	2026-06-11 19:10:56.77425+08
44	3	15	test	0	100.00	2026-06-10 19:10:56.872393+08
45	4	2	test	0	0.00	2026-06-13 11:49:13.247287+08
46	4	2	test	0	0.00	2026-06-13 11:49:15.80045+08
47	4	2	test	0	100.00	2026-06-13 11:49:18.013661+08
48	4	2	test	0	100.00	2026-06-13 11:49:21.749176+08
49	4	2	test	0	0.00	2026-06-13 11:49:24.726831+08
50	4	2	test	0	0.00	2026-06-13 11:49:27.522361+08
51	4	2	test	0	0.00	2026-06-13 11:49:30.407413+08
52	4	2	test	0	0.00	2026-06-13 11:49:32.293711+08
53	4	2	test	0	100.00	2026-06-13 11:52:02.439593+08
54	4	2	test	0	0.00	2026-06-13 11:52:06.391348+08
55	4	2	test	0	100.00	2026-06-13 11:52:12.728773+08
56	4	2	test	0	0.00	2026-06-13 11:52:17.672734+08
57	4	2	test	0	0.00	2026-06-13 11:52:23.205101+08
58	4	2	test	0	100.00	2026-06-13 11:52:30.021779+08
\.


--
-- Data for Name: llm_providers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.llm_providers (id, name, provider_type, base_url, api_key, model_name, is_active, is_default, max_tokens, temperature, created_at, updated_at) FROM stdin;
3	智谱GLM	zhipu	https://open.bigmodel.cn/api/paas/v4		glm-4-flash	f	f	2048	0.7	2026-06-09 13:11:57.3239+08	2026-06-09 14:44:22.235587+08
4	月之暗面Kimi	kimi	https://api.moonshot.cn/v1		moonshot-v1-8k	f	f	2048	0.7	2026-06-09 13:11:57.323906+08	2026-06-09 14:44:22.235587+08
5	百川智能	baichuan	https://api.baichuan-ai.com/v1		Baichuan4	f	f	2048	0.7	2026-06-09 13:11:57.323912+08	2026-06-09 14:44:22.235587+08
6	讯飞星火	xfyun	https://spark-api-open.xf-yun.com/v1		generalv3.5	f	f	2048	0.7	2026-06-09 13:11:57.323918+08	2026-06-09 14:44:22.235587+08
7	硅基流动	siliconflow	https://api.siliconflow.cn/v1		Qwen/Qwen2.5-7B-Instruct	f	f	2048	0.7	2026-06-09 13:11:57.323924+08	2026-06-09 14:44:22.235587+08
8	Dify平台	dify	https://api.dify.ai/v1		chat-messages	f	f	2048	0.7	2026-06-09 13:11:57.32393+08	2026-06-09 14:44:22.235587+08
9	本地测试模型	custom	http://localhost:11434/v1		llama3	f	f	2048	0.7	2026-06-09 13:29:33.678378+08	2026-06-09 14:44:22.235587+08
1	通义千问	tongyi	https://dashscope.aliyuncs.com/compatible-mode/v1	gAAAAABqKCaSHVWXZ52jfyymTsFw80RHoc_xM7tqXZ0kH7Oup05GZixZ7z2r-V1ArzCXtoa3RbT_h0WWVNgqiAEjZI5XQoj6OJEqdYADTY7oCaKoZlWLB3nqZGpOaMM38YLz1bWCnaBR	qwen-plus	t	f	2048	0.7	2026-06-09 13:11:57.323878+08	2026-06-09 14:44:22.235587+08
2	DeepSeek	deepseek	https://api.deepseek.com/v1	gAAAAABqKCa-Ytg4zcoE3F2O2kp9oVG-9DYNqOpxjRmtj1OpXrZ2NvmPDyINW1mtoMH7eRIpO1a2FMtOU0NGlkpqVDt00B6pv1JspCWHYseiwdGwQ76QdGUL9ZWdkfX2JKMfVIVKfivm	deepseek-chat	t	t	2048	0.7	2026-06-09 13:11:57.323893+08	2026-06-09 14:44:22.241737+08
\.


--
-- Data for Name: position_capabilities; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.position_capabilities (id, "position", category_id) FROM stdin;
4	sales	1
5	sales	2
6	sales	3
7	sales	4
8	sales	5
9	sales	6
10	sales	7
11	sales	8
12	sales	9
13	sales	10
14	sales	11
15	sales	12
16	sales	13
17	sales	14
18	tech	15
19	tech	16
20	tech	17
21	tech	18
22	tech	19
23	tech	20
24	tech	21
25	tech	22
26	tech	1
27	tech	2
28	tech	3
29	tech	4
30	tech	5
31	tech	6
32	service	1
33	service	2
34	service	3
35	service	4
36	service	5
37	service	6
38	service	23
39	service	25
40	service	24
41	service	26
42	service	27
43	service	28
44	service	29
45	service	30
46	clerk	1
47	clerk	2
48	clerk	3
49	clerk	4
50	clerk	5
51	clerk	6
52	clerk	7
53	clerk	8
54	clerk	13
55	clerk	12
\.


--
-- Data for Name: skin_preferences; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.skin_preferences (id, user_id, skin_id, updated_at) FROM stdin;
1	1	1	2026-06-09 13:11:57.379588+08
4	4	1	2026-06-09 13:11:57.379605+08
5	5	1	2026-06-09 13:11:57.379608+08
6	6	1	2026-06-09 13:17:02.641818+08
3	3	3	2026-06-10 15:00:06.745775+08
2	2	2	2026-06-13 12:10:27.246328+08
\.


--
-- Data for Name: stores; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.stores (id, name, address, created_at) FROM stdin;
1	合群旗舰店	市中心主干道888号	2026-06-09 13:11:54.917475+08
2	合群城西店	城西开发区汽车城A区	2026-06-09 13:11:54.91748+08
\.


--
-- Data for Name: system_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.system_config (id, config_key, config_value, config_type, description, updated_at) FROM stdin;
2	points_approved	10	int	审核通过积分	2026-06-09 13:11:57.341294+08
3	points_useful	2	int	被标记有用积分	2026-06-09 13:11:57.341297+08
4	points_monthly_top5	50	int	月度TOP5积分	2026-06-09 13:11:57.3413+08
6	points_complete_course	3	int	完成课程积分	2026-06-09 13:11:57.341306+08
7	flywheel_view_threshold	5	int	低效经验浏览阈值(<N次)	2026-06-09 13:11:57.341308+08
8	flywheel_month_threshold	6	int	知识更新周期(月)	2026-06-09 13:11:57.341311+08
9	flywheel_useful_rate	0.7	float	有效经验有用率阈值	2026-06-09 13:11:57.341313+08
10	flywheel_low_useful_rate	0.3	float	待优化经验有用率阈值	2026-06-09 13:11:57.341315+08
1	points_submit	1	int	提交经验积分	2026-06-09 13:33:29.220917+08
5	points_daily_question	1	int	每次一题答对积分	2026-06-11 13:30:24.53068+08
11	asr_secret_id	gAAAAABqLW39xDgTnn0jjWj1UR40OHjCkmiNtmyW-WjFzJAJ9NF7LsxyUGWPrA2XllJAwWe_YDX-4rQwMWEPHUoncYKVKAxaVwZc7VeJ_ovVNCizK1LkseNjmyaFvrZIRc7XIxnlmQbP	encrypted	腾讯云ASR SecretId	2026-06-13 14:49:33.760766+08
12	asr_secret_key	gAAAAABqLW-ok8tqNul0E0FH1K-6K39CoUXIyh9P1-MGyCX9ITT2v_a39AfshcSGmi1hF8GWMQLrxUUCdgNt2RK2BhVY6_CwSOlle0yu4ZnKKLa7CWbDeclLGIpD2WMJYXgY2ltDj48D	encrypted	腾讯云ASR SecretKey	2026-06-13 14:56:40.077552+08
13	asr_provider	whisper	string	ASR引擎选择 tencent/whisper	2026-06-13 14:56:40.080506+08
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, username, real_name, password_hash, role, "position", dept_id, store_id, phone, avatar_url, status, created_at) FROM stdin;
1	boss	张总裁	$2b$12$PBe6iIha2LQTXXjTTv0mquppaD.Y2/XmEDkmlCtxJuBICrR/wHle.	boss	\N	\N	\N	\N	\N	1	2026-06-09 13:11:57.353243+08
2	admin	李管理	$2b$12$PkBEjrglAbyzkEH3jFImseCTPmpU76iVNieAn1dd7tzoha/6DJdGW	admin	\N	\N	\N	\N	\N	1	2026-06-09 13:11:57.353254+08
3	sales01	王销售	$2b$12$NfXgX/8sjSD4ZvaP0R3es.Yk9WpTjFZhVl2fRWczTomyF1tq64hHW	staff	sales	1	\N	\N	\N	1	2026-06-09 13:11:57.353257+08
4	tech01	赵技师	$2b$12$tycRM2obg1nu6P.RlPBYC.HyDdKTZVgo/l71HK7DPTzNGj1CWM.qe	staff	tech	2	\N	\N	\N	1	2026-06-09 13:11:57.35326+08
5	service01	陈客服	$2b$12$BuJibWCcVbb34QH9k5K9GOufYixQCLjz9je3Ef3Pq8jCbPnzi6xAC	staff	service	3	\N	\N	\N	1	2026-06-09 13:11:57.353264+08
6	test_user	测试员改名	$2b$12$uOKxrFcUpJys640R3YIYxO5hy139MDJML/a5u4aNp0Dd3O3xIea8C	staff	tech	\N	\N	13800001111	\N	1	2026-06-09 13:17:02.622538+08
\.


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 148, true);


--
-- Name: chat_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.chat_logs_id_seq', 46, true);


--
-- Name: daily_questions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_questions_id_seq', 194, true);


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.departments_id_seq', 3, true);


--
-- Name: exam_attempts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.exam_attempts_id_seq', 5, true);


--
-- Name: exam_papers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.exam_papers_id_seq', 3, true);


--
-- Name: exam_papers_questions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.exam_papers_questions_id_seq', 56, true);


--
-- Name: experience_points_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.experience_points_id_seq', 67, true);


--
-- Name: knowledge_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_categories_id_seq', 32, true);


--
-- Name: knowledge_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_entries_id_seq', 445, true);


--
-- Name: learning_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.learning_records_id_seq', 58, true);


--
-- Name: llm_providers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.llm_providers_id_seq', 9, true);


--
-- Name: position_capabilities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.position_capabilities_id_seq', 59, true);


--
-- Name: skin_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skin_preferences_id_seq', 6, true);


--
-- Name: stores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.stores_id_seq', 2, true);


--
-- Name: system_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.system_config_id_seq', 13, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 6, true);


--
-- Name: vector_index_map_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vector_index_map_id_seq', 1, false);


--
-- Name: voice_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.voice_messages_id_seq', 15, true);


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

\unrestrict UenSeeLQ9d7vD1H3Ua3tWdvGj517L1Q8fEwbgHXB9jWGZztZeNgDyB5OAPOHixg

