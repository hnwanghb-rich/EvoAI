--
-- PostgreSQL database dump
--

\restrict mLeDUSe8mzXTGPHXxtZ4ic2xrwZvzdVa4KD2CY2waca7t4ouhNVrTtkrBlJysbX

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
-- Name: cross_line_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cross_line_tasks (
    id integer NOT NULL,
    source_entry_id integer,
    source_line character varying(20) NOT NULL,
    target_line character varying(20) NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    priority smallint DEFAULT 2,
    created_by integer,
    note text,
    resolve_note text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    resolved_at timestamp with time zone
);


--
-- Name: cross_line_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cross_line_tasks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cross_line_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cross_line_tasks_id_seq OWNED BY public.cross_line_tasks.id;


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
    category_id integer,
    tags character varying(500),
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
    user_id integer NOT NULL,
    paper_id integer NOT NULL,
    answers jsonb DEFAULT '{}'::jsonb,
    score integer DEFAULT 0 NOT NULL,
    total_questions integer DEFAULT 0 NOT NULL,
    correct_count integer DEFAULT 0 NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    submitted_at timestamp with time zone,
    status character varying(20) DEFAULT 'started'::character varying NOT NULL
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
    target_type character varying(20) DEFAULT 'all'::character varying NOT NULL,
    target_value character varying(50),
    time_mode character varying(20) DEFAULT 'anytime'::character varying NOT NULL,
    start_time timestamp with time zone,
    end_time timestamp with time zone,
    duration_minutes integer DEFAULT 60 NOT NULL,
    total_questions integer DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
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
    paper_id integer NOT NULL,
    question_id integer NOT NULL,
    sort_order integer NOT NULL
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
    expire_at timestamp with time zone,
    last_reviewed_at timestamp with time zone,
    gross_margin_impact character varying(20),
    safety_critical boolean DEFAULT false,
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
-- Name: knowledge_gaps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_gaps (
    id integer NOT NULL,
    question text NOT NULL,
    hit_count integer DEFAULT 0,
    target_kb character varying(20),
    suggest_category_id integer,
    status character varying(20) DEFAULT 'assigned'::character varying,
    assignee_id integer,
    related_knowledge_id integer,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    closed_at timestamp with time zone
);


--
-- Name: knowledge_gaps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_gaps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_gaps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_gaps_id_seq OWNED BY public.knowledge_gaps.id;


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
-- Name: sales_deals_import; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_deals_import (
    id integer NOT NULL,
    deal_date date,
    car_brand character varying(50),
    car_model character varying(100),
    deal_price numeric(12,2),
    gross_margin numeric(12,2),
    consultant_name character varying(50),
    consultant_id integer,
    knowledge_id integer,
    source_file character varying(200),
    imported_by integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: sales_deals_import_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sales_deals_import_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sales_deals_import_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sales_deals_import_id_seq OWNED BY public.sales_deals_import.id;


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
-- Name: cross_line_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cross_line_tasks ALTER COLUMN id SET DEFAULT nextval('public.cross_line_tasks_id_seq'::regclass);


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
-- Name: knowledge_gaps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_gaps ALTER COLUMN id SET DEFAULT nextval('public.knowledge_gaps_id_seq'::regclass);


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
-- Name: sales_deals_import id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_deals_import ALTER COLUMN id SET DEFAULT nextval('public.sales_deals_import_id_seq'::regclass);


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
1	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-10 13:13:19.458001+08
2	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-11 04:18:13.396459+08
3	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 01:57:08.342027+08
4	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-12 02:43:12.800707+08
5	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-12 02:51:49.775439+08
6	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 02:55:33.964228+08
7	2	admin	review_approve	knowledge_entry	12	通过审核: 贴膜销售策略	127.0.0.1	2026-06-12 02:55:41.833195+08
8	2	admin	review_approve	knowledge_entry	13	通过审核: 换大众车机油	127.0.0.1	2026-06-12 02:55:44.223561+08
9	2	admin	review_reject	knowledge_entry	11	驳回: 车辆保险销售三步法 | 原因: 没什么用	127.0.0.1	2026-06-12 02:55:59.369652+08
10	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-12 03:56:39.350976+08
11	5	service01	login	user	5	陈客服 登录系统	127.0.0.1	2026-06-12 04:58:07.422864+08
12	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 05:05:00.591816+08
13	2	admin	review_approve	knowledge_entry	14	通过审核: 车主维修发脾气处理经验	127.0.0.1	2026-06-12 05:19:04.053855+08
14	2	admin	review_approve	knowledge_entry	15	通过审核: 长期保养汽车的客户赠品	127.0.0.1	2026-06-12 05:35:05.339865+08
15	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 07:37:53.43576+08
16	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 07:38:45.119647+08
17	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 07:39:10.61162+08
18	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 07:39:31.720604+08
19	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 07:40:34.118906+08
20	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 07:47:11.955681+08
21	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 07:53:06.082775+08
22	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 08:57:44.732369+08
23	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-12 10:48:39.365697+08
24	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 10:50:21.567901+08
25	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 10:52:53.293642+08
26	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 10:53:10.499743+08
27	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-12 10:55:01.82741+08
28	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-14 05:41:53.797373+08
29	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-14 05:57:50.358353+08
30	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-14 06:05:42.387277+08
31	5	service01	login	user	5	陈客服 登录系统	127.0.0.1	2026-06-14 06:06:46.650476+08
32	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-14 06:08:39.641506+08
33	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-14 06:10:35.685086+08
34	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-14 06:31:17.129582+08
35	3	sales01	login	user	3	王销售 登录系统	127.0.0.1	2026-06-18 01:33:49.165407+08
36	5	service01	login	user	5	陈客服 登录系统	127.0.0.1	2026-06-18 01:38:15.577143+08
37	4	tech01	login	user	4	赵技师 登录系统	127.0.0.1	2026-06-18 01:42:22.00109+08
38	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-18 02:11:38.147993+08
39	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-18 05:10:00.917156+08
40	2	admin	flywheel_gap_assign	knowledge_gap	1	指派知识缺口: ��˾����ҵ�Ļ�������⣬�ж�����	127.0.0.1	2026-06-18 05:10:39.793121+08
41	2	admin	flywheel_gap_close	knowledge_gap	1	关闭知识缺口: ��˾����ҵ�Ļ�������⣬�ж�����	127.0.0.1	2026-06-18 05:10:48.137581+08
42	2	admin	flywheel_expiry_set	knowledge_entry	1	设置保质期 30 天: 星瑞L6产品核心卖点	127.0.0.1	2026-06-18 05:28:38.078783+08
43	2	admin	flywheel_expiry_renew	knowledge_entry	1	续期 180 天 v2: 星瑞L6产品核心卖点	127.0.0.1	2026-06-18 05:28:38.726052+08
44	2	admin	flywheel_expiry_archive	knowledge_entry	1	归档过期知识: 星瑞L6产品核心卖点	127.0.0.1	2026-06-18 05:29:35.428201+08
45	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-18 05:53:45.552321+08
46	2	admin	flywheel_sales_win_review	knowledge_entry	127	提交赢单复盘: 测试话术	127.0.0.1	2026-06-18 05:54:48.87388+08
47	2	admin	flywheel_repair_case	knowledge_entry	128	[安全关键]提交故障案例: 别克君越刹车异响，制动盘片磨损	127.0.0.1	2026-06-18 06:03:46.668152+08
48	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-18 06:12:50.268155+08
49	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-18 06:13:06.779776+08
50	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-18 06:14:08.098873+08
51	2	admin	flywheel_service_complaint	knowledge_entry	129	提交投诉记录[根因:sales]: 销售承诺优惠未兑现引发投诉	127.0.0.1	2026-06-18 06:14:11.042785+08
52	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-18 06:15:38.422644+08
53	2	admin	flywheel_service_complaint	knowledge_entry	130	提交投诉记录[根因:sales]: 销售承诺赠品未兑现投诉	127.0.0.1	2026-06-18 06:15:41.277821+08
54	2	admin	flywheel_service_dispatch	knowledge_entry	130	派发跨线任务→sales: 销售承诺赠品未兑现投诉 | ���۹�������ѵ��ŵ�淶	127.0.0.1	2026-06-18 06:15:41.581895+08
55	2	admin	login	user	2	李管理 登录系统	127.0.0.1	2026-06-18 06:17:44.85767+08
56	2	admin	flywheel_service_complaint	knowledge_entry	131	提交投诉记录[根因:pdi]: 交车PDI未做导致车辆划痕投诉	127.0.0.1	2026-06-18 06:23:23.087456+08
57	2	admin	flywheel_service_dispatch	cross_line_task	1	派发跨线任务→pdi: 交车PDI未做导致车辆划痕投诉 | PDI����������	127.0.0.1	2026-06-18 06:23:23.415049+08
58	2	admin	crossline_accept	cross_line_task	1	接收跨线任务: 【客服投诉整改】交车PDI未做导致车辆划痕投诉	127.0.0.1	2026-06-18 06:23:23.9944+08
60	2	admin	crossline_close	cross_line_task	1	关闭跨线任务: 【客服投诉整改】交车PDI未做导致车辆划痕投诉	127.0.0.1	2026-06-18 06:23:24.594071+08
59	2	admin	crossline_resolve	cross_line_task	1	处理跨线任务: 【客服投诉整改】交车PDI未做导致车辆划痕投诉 | ��Ҫ��PDI����������ѵȫԱ�����ӽ���ǰ����嵥ǩ�ֻ���	127.0.0.1	2026-06-18 06:23:24.291369+08
\.


--
-- Data for Name: chat_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chat_logs (id, user_id, question, answer, references_json, is_satisfied, is_hit, response_time_ms, created_at) FROM stdin;
1	2	你是谁	抱歉，我在知识库中没有找到与您问题相关的信息。建议您联系部门主管或等待知识库更新。\n\n还有什么不清楚的地方？	[]	\N	0	45	2026-06-10 13:13:48.545627+08
2	5	你好	你好，陈客服。我是阿能，合群汽车集团的数字老师。有什么需要帮助的吗？	[]	\N	0	1923	2026-06-18 01:41:10.093707+08
3	5	公司的企业文化相关试题，有多少题	根据系统数据，题库共 87 道题目。但未检索到具体“企业文化”类别的试题数量。\n\n以下为通用知识回答，非企业知识库内容：建议你通过系统题库的筛选或分类功能查看企业文化相关试题的具体数量。\n\n还有什么不清楚的地方？	[]	\N	0	2122	2026-06-18 01:41:39.875681+08
\.


--
-- Data for Name: cross_line_tasks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cross_line_tasks (id, source_entry_id, source_line, target_line, title, description, status, priority, created_by, note, resolve_note, created_at, updated_at, resolved_at) FROM stdin;
1	131	service	pdi	【客服投诉整改】交车PDI未做导致车辆划痕投诉	来源投诉记录 #131，根因归属：PDI/交车问题	closed	2	2	PDI����������	��Ҫ��PDI����������ѵȫԱ�����ӽ���ǰ����嵥ǩ�ֻ���	2026-06-18 14:23:23.397643+08	2026-06-18 14:23:24.591434+08	2026-06-18 14:23:24.282058+08
\.


--
-- Data for Name: daily_questions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_questions (id, question_type, question_content, options, answer, explanation, target_position, difficulty_level, related_knowledge_id, push_date, created_at, category_id, tags) FROM stdin;
82	single_choice	趋势图主要用来展示什么？	{"A": "目标完成率", "B": "每个月的业绩变化", "C": "毛利表现", "D": "车系排名"}	B	文档说趋势图清晰呈现每个月的业绩变化，让你看清成长轨迹。	\N	2	\N	2026-06-14	2026-06-12 10:42:25.812664+08	1	\N
2	single_choice	星瑞L6的整车质保政策是？	{"A": "3年/10万公里", "B": "4年/12万公里", "C": "5年/15万公里", "D": "6年/20万公里"}	C	整车5年/15万公里，三电系统终身质保（首任车主）。	sales	2	\N	2026-06-14	2026-06-10 13:04:45.762401+08	7	\N
50	single_choice	以下哪个选项不是维修服务接待操作手册中提到的操作入口？	{"A": "05售后管理→05.01维修服务接待", "B": "08财务管理→08.01.03维修财务结账", "C": "02.07优惠券方案", "D": "09.07优惠券管理"}	C	根据手册内容，02.07优惠券方案不是作为操作入口提及的，而是作为设置优惠券方案的步骤之一。	\N	3	\N	2026-06-18	2026-06-12 02:41:03.334218+08	1	\N
30	single_choice	客户回访的最佳频次是？	{"A": "每天一次", "B": "保养后7-15天", "C": "每年一次", "D": "从不回访"}	B	保养后7-15天回访可有效了解客户满意度和发现潜在问题。	service	2	\N	2026-06-14	2026-06-10 13:04:45.762435+08	23	\N
1	single_choice	星瑞L6的CLTC综合续航里程是多少？	{"A": "800km", "B": "1000km", "C": "1200km", "D": "1500km"}	C	星瑞L6 CLTC综合续航1200km，纯电续航200km。	sales	1	\N	2026-06-12	2026-06-10 13:04:45.762398+08	7	\N
36	single_choice	套餐卡方案制定的核心步骤是什么？	{"A": "业务基础资料→套餐方案", "B": "财务结算→套餐方案", "C": "市场管理→套餐方案", "D": "工时项目→套餐方案"}	A	根据文档中的说明，套餐卡方案制定的核心步骤是业务基础资料到套餐方案，因此选项A是正确的。	\N	1	\N	2026-06-18	2026-06-12 02:29:58.906428+08	29	\N
31	single_choice	合群汽车集团的消防器材点检频率是？	{"A": "每月15日", "B": "每季度一次", "C": "每年一次", "D": "不定期"}	A	每月15日进行消防器材点检，填写检查记录。	\N	1	\N	2026-06-12	2026-06-10 13:04:45.762436+08	1	\N
46	single_choice	套餐卡设置中，哪个信息设置是不需要的，因为不设置表示不限制使用范围？	{"A": "套餐金额", "B": "工时项目范围", "C": "适用车系", "D": "有效天数"}	B	根据手册内容，套餐卡设置中，不设置工时项目范围表示不限制券的使用范围。	\N	3	\N	2026-06-18	2026-06-12 02:41:03.334213+08	1	\N
3	true_false	销售顾问可以对客户承诺三电系统终身质保适用于所有车主。	null	false	三电系统终身质保仅适用于首任车主。	sales	1	\N	2026-06-12	2026-06-10 13:04:45.762402+08	7	\N
37	single_choice	工时项目和材料项目在套餐卡中的关系是什么？	{"A": "工时项目和材料项目是独立的", "B": "工时项目包含材料项目", "C": "材料项目包含工时项目", "D": "工时项目及材料项目定义一致"}	D	文档中提到工时项目及材料材料定义，材料项目定义与工时项目的方案一致，说明工时项目和材料项目在套餐卡中的定义是一致的。	\N	2	\N	2026-06-14	2026-06-12 02:29:58.906432+08	7	\N
48	single_choice	在维修服务接待操作手册中，折扣的审批功能入口在哪个模块？	{"A": "05售后管理", "B": "08财务管理", "C": "02.07优惠券方案", "D": "09.07优惠券管理"}	A	根据手册内容，折扣审批的功能入口在05售后管理→05.01维修服务接待的折扣设置中。	\N	2	\N	2026-06-14	2026-06-12 02:41:03.334215+08	1	\N
32	true_false	车间内可以吸烟，但需在指定区域。	null	false	严禁在车间内吸烟或使用明火，这是消防安全强制规定。	\N	1	\N	2026-06-12	2026-06-10 13:04:45.762437+08	1	\N
33	single_choice	安全事故发生后，应在多长时间内向安全主管报告？	{"A": "15分钟内", "B": "1小时内", "C": "24小时内", "D": "72小时内"}	A	发生安全事故后，15分钟内向安全主管报告。	\N	1	\N	2026-06-12	2026-06-10 13:04:45.762438+08	1	\N
34	single_choice	合群汽车集团的企业愿景核心是？	{"A": "利润第一", "B": "知识驱动、全员成长", "C": "快速发展", "D": "削减成本"}	B	合群汽车集团以知识驱动飞轮、全员能力提升为企业成长的核心战略。	\N	1	\N	2026-06-12	2026-06-10 13:04:45.762439+08	1	\N
35	true_false	全员消防演练应每季度进行一次。	null	true	每季度进行一次全员消防演练是集团安全管理制度的要求。	\N	1	\N	2026-06-12	2026-06-10 13:04:45.762441+08	1	\N
43	single_choice	维修服务接待操作手册中，维修零件出库（仓管员操作）的工单耗材零件入口在哪里？	{"A": "05售后管理→05.01维修服务接待", "B": "05售后管理→05.02维修零件入库", "C": "08财务管理→08.01.03维修财务结账", "D": "02.07优惠券方案"}	A	根据手册内容，维修零件出库（仓管员录入工单耗材零件）的操作入口位于05售后管理→05.01维修服务接待。	\N	2	\N	2026-06-14	2026-06-12 02:41:03.334209+08	1	\N
45	single_choice	使用优惠券核销后，工单中的记录编号前缀应为下列哪个？	{"A": "Vou", "B": "Fac", "C": "Cou", "D": "Dou"}	A	根据手册内容，使用优惠券核销后，在工时或零件项目中新增一条编号前缀为'Vou'的记录，用于冲减客户付费的金额。	\N	2	\N	2026-06-14	2026-06-12 02:41:03.334211+08	1	\N
53	single_choice	从车主投诉开始，客服人员应该在多长时间内向车主反馈正在处理？	{"A": "10分钟内", "B": "15分钟内", "C": "5分钟内", "D": "30分钟内"}	C	文档第三条明确要求5分钟内亲自向车主说正在处理，避免车主等待焦虑。	\N	2	\N	2026-06-14	2026-06-12 05:19:03.995377+08	1	\N
77	single_choice	登录数据可失化平台后，默认进入哪个界面？	{"A": "销售顾问看板", "B": "车系排行榜", "C": "毛利历史图", "D": "目标完成情况"}	A	根据文档，输入账号密码登录后，进入销售顾问看板界面。	\N	1	\N	2026-06-12	2026-06-12 10:42:25.812622+08	7	\N
78	single_choice	在销售顾问看板中，以下哪种不是数据查看方式？	{"A": "日报", "B": "月报", "C": "年报", "D": "周报"}	D	文档中明确提到可以选择日报、月报、年报三种查看方式，未提及周报。	\N	1	\N	2026-06-12	2026-06-12 10:42:25.812652+08	7	\N
74	single_choice	销售顾问的订单与交车目标由谁填写？	{"A": "销售经理", "B": "个人", "C": "系统自动生成", "D": "客户"}	B	文档说明“销售顾问的订单与交车目标由个人填写”。	\N	2	\N	2026-06-14	2026-06-12 10:40:51.529684+08	1	\N
6	single_choice	试驾过程中，销售顾问首先应该做什么？	{"A": "直接让客户上高速", "B": "讲解试驾路线和安全注意事项", "C": "让客户自行驾驶", "D": "播放音乐"}	B	试驾前必须先讲解路线和安全注意事项，确保客户了解操作。	sales	1	\N	2026-06-12	2026-06-10 13:04:45.762406+08	7	\N
56	single_choice	在车主情绪稳定几分钟后，客服人员应该怎么做？	{"A": "直接给出最终解决方案", "B": "再去一趟维修部，然后告知实情", "C": "让车主自己决定后续步骤", "D": "结束这次处理流程"}	B	文档第五条要求情绪稳定后，再去维修部获取信息，然后告知车主实情。	\N	2	\N	2026-06-14	2026-06-12 05:19:03.995381+08	1	\N
4	single_choice	销售过程中，遇到客户提出超出权限的价格折扣要求，应该？	{"A": "直接拒绝", "B": "请示销售经理", "C": "自行降价", "D": "忽略客户"}	B	超出权限的价格折扣应请示销售经理，由管理层决策。	sales	2	\N	2026-06-14	2026-06-10 13:04:45.762403+08	7	\N
5	single_choice	下列哪项属于合群汽车集团金融按揭方案的特色？	{"A": "仅合作一家银行", "B": "支持多渠道银行按揭", "C": "不提供金融服务", "D": "仅支持全款购车"}	B	集团支持多渠道银行按揭方案，为客户提供灵活金融选择。	sales	2	\N	2026-06-14	2026-06-10 13:04:45.762405+08	7	\N
7	multi_choice	以下哪些是星瑞L6的智能座舱功能？（多选）	{"A": "15.6英寸中控屏", "B": "语音控制", "C": "手势识别", "D": "全自动驾驶"}	ABC	星瑞L6支持15.6英寸中控屏、语音控制、手势识别，但无全自动驾驶。	sales	3	\N	\N	2026-06-10 13:04:45.762407+08	7	\N
8	single_choice	客户跟进管理中，首次接触后应在多长时间内进行回访？	{"A": "1小时内", "B": "24小时内", "C": "3天内", "D": "1周内"}	B	客户首次接触后建议24小时内回访，保持沟通热度。	sales	2	\N	2026-06-14	2026-06-10 13:04:45.762408+08	7	\N
10	single_choice	与比亚迪汉DM-i对比，星瑞L6的差异化优势是什么？	{"A": "更低功率", "B": "更高功率和更长整车质保", "C": "更低续航", "D": "更少安全气囊"}	B	星瑞L6综合功率230kW，高于汉DM-i；整车质保5年/15万公里也更长。	sales	3	\N	\N	2026-06-10 13:04:45.76241+08	7	\N
26	single_choice	保险理赔服务中，客服需要协助客户准备哪些材料？	{"A": "仅驾驶证", "B": "事故证明+定损单+驾驶证+行驶证", "C": "仅发票", "D": "仅身份证"}	B	保险理赔需要事故证明、定损单、驾驶证、行驶证等全套材料。	service	2	\N	2026-06-14	2026-06-10 13:04:45.76243+08	23	\N
55	single_choice	客服人员第一次去维修部回来后，应该怎么跟车主说？	{"A": "直接告知维修部的具体意见", "B": "说正在处理，稍后告知情况", "C": "让车主耐心等待，不用再问", "D": "表示问题无法解决"}	B	文档第三条要求第一次反馈时只说正在处理，先安抚车主情绪，而不是直接给出详细意见。	\N	3	\N	2026-06-18	2026-06-12 05:19:03.99538+08	1	\N
76	single_choice	驾驶舱未来将持续优化，目的是什么？	{"A": "增加更多广告", "B": "用更精准的数据洞察为业务增长赋能", "C": "减少功能", "D": "提高系统速度"}	B	文档最后提到“用更精准的数据洞察，为业务增长持续赋能”。	\N	3	\N	2026-06-18	2026-06-12 10:40:51.529688+08	7	\N
11	single_choice	国六B发动机怠速抖动时，常见的故障码是什么？	{"A": "P0101", "B": "P0300", "C": "P0500", "D": "P0700"}	B	P0300(随机失火)和P0171(混合气过稀)是国六B怠速抖动常见故障码。	tech	3	\N	2026-06-18	2026-06-10 13:04:45.762411+08	15	\N
13	single_choice	发动机怠速时燃油压力应为多少？	{"A": "200-250kPa", "B": "350-400kPa", "C": "500-600kPa", "D": "700-800kPa"}	B	怠速时燃油压力应为350-400kPa。	tech	3	\N	2026-06-18	2026-06-10 13:04:45.762413+08	15	\N
16	single_choice	新能源车维修中，高压系统断电后需等待多久才能操作？	{"A": "1分钟", "B": "5分钟", "C": "至少10分钟", "D": "立即操作"}	C	高压系统断电后需等待至少10分钟，确保电容放电完毕，方可操作。	tech	3	\N	2026-06-18	2026-06-10 13:04:45.762417+08	15	\N
15	single_choice	国六B车型碳罐电磁阀常见故障是什么？	{"A": "完全堵塞", "B": "卡滞在常开位置", "C": "电路短路", "D": "物理断裂"}	B	国六B车型碳罐电磁阀容易卡滞在常开位置，导致混合气过稀。	tech	4	\N	2026-06-18	2026-06-10 13:04:45.762416+08	15	\N
27	single_choice	续保业务技巧中，最佳续保时机是什么时候？	{"A": "保险到期后", "B": "保险到期前30天", "C": "保险到期前1天", "D": "任意时间"}	B	保险到期前30天是最佳续保时机，给客户充足的比较和考虑时间。	service	2	\N	2026-06-14	2026-06-10 13:04:45.762431+08	23	\N
28	multi_choice	以下哪些属于会员服务的权益？（多选）	{"A": "优先预约", "B": "消费积分兑换", "C": "免费年度检测", "D": "免费购车"}	ABC	会员通常享有优先预约、消费积分兑换和免费年度检测等权益。	service	2	\N	2026-06-14	2026-06-10 13:04:45.762432+08	23	\N
14	true_false	举升机操作可以单人完成，无需两人协作。	null	false	举升机操作必须两人协作，严禁单人操作，这是安全生产规范要求。	tech	1	\N	2026-06-12	2026-06-10 13:04:45.762414+08	15	\N
9	true_false	二手车评估只看外观和里程数即可定价。	null	false	二手车评估需综合考虑品牌、车型、车龄、里程、事故维修记录等多维因素。	sales	1	\N	2026-06-12	2026-06-10 13:04:45.762409+08	7	\N
18	true_false	电气设备检修前不需要断开电源，只需告知同事即可。	null	false	电气设备检修前必须断开电源并挂警示牌，这是安全生产强制要求。	tech	1	\N	2026-06-12	2026-06-10 13:04:45.762419+08	15	\N
20	single_choice	废机油应如何处理？	{"A": "倒入下水道", "B": "卖给废品站", "C": "交由合规危废处置单位", "D": "混入生活垃圾"}	C	废机油属于危险废物，必须交由合规处置单位处理。	tech	1	\N	2026-06-12	2026-06-10 13:04:45.762421+08	15	\N
12	single_choice	国六B发动机火花塞的标准间隙是多少？	{"A": "0.5-0.6mm", "B": "0.7-0.8mm", "C": "1.0-1.2mm", "D": "1.5mm以上"}	B	国六B发动机对火花塞间隙要求更严，标准0.7-0.8mm。	tech	2	\N	2026-06-12	2026-06-10 13:04:45.762412+08	15	\N
17	single_choice	钣金喷漆工艺中，底漆的主要作用是什么？	{"A": "美观", "B": "防锈和增加面漆附着力", "C": "遮瑕", "D": "增加重量"}	B	底漆主要起防锈作用并为面漆提供良好的附着基础。	tech	2	\N	2026-06-14	2026-06-10 13:04:45.762418+08	15	\N
19	multi_choice	以下哪些是故障诊断的基本步骤？（多选）	{"A": "读取故障码", "B": "目视检查", "C": "直接更换全部零件", "D": "使用诊断仪检查数据流"}	ABD	故障诊断步骤包括读取故障码、目视检查和数据流分析，不应盲目更换零件。	tech	2	\N	2026-06-14	2026-06-10 13:04:45.76242+08	15	\N
21	single_choice	客户投诉'听-认-行'三步法中，第一步是什么？	{"A": "行动解决", "B": "耐心倾听", "C": "马上解释", "D": "直接拒绝"}	B	三步法第一步是耐心倾听，让客户完整表达不满。	service	1	\N	2026-06-14	2026-06-10 13:04:45.762422+08	23	\N
22	single_choice	处理客户投诉时，以下哪种话术是共情式表达的体现？	{"A": "这是你的问题", "B": "我完全理解您现在的心情", "C": "您说得不对", "D": "您去找我们领导"}	B	共情话术如'我完全理解您现在的心情'能有效缓解客户情绪。	service	1	\N	2026-06-14	2026-06-10 13:04:45.762423+08	23	\N
24	true_false	客户投诉处理时，应该先解释原因，再倾听客户诉求。	null	false	应先倾听客户诉求，认可情绪后再解释和处理，不可急于解释。	service	1	\N	2026-06-14	2026-06-10 13:04:45.762426+08	23	\N
25	single_choice	预约保养接待流程中，客户到店后首先应？	{"A": "让客户自己找车位", "B": "引导停车并接待登记", "C": "让客户等待", "D": "直接开进车间"}	B	客户到店后首先应引导停车并完成接待登记。	service	1	\N	2026-06-14	2026-06-10 13:04:45.762427+08	23	\N
23	single_choice	客户投诉后，客服应在多长时间内给予回复？	{"A": "24小时内", "B": "30分钟内", "C": "3天内", "D": "1周内"}	B	应给出明确时间承诺：'我会在30分钟内给您回复'。	service	2	\N	2026-06-14	2026-06-10 13:04:45.762424+08	23	\N
38	single_choice	套餐卡销售管理的生效条件是什么？	{"A": "业务基础资料完成后立即生效", "B": "财务结算之后生效", "C": "市场管理之后生效", "D": "工时项目定义后生效"}	B	根据文档中的信息，套餐卡销售管理需要在财务结算之后才能生效，因此选项B是正确的。	\N	2	\N	2026-06-14	2026-06-12 02:29:58.906433+08	7	\N
39	single_choice	以下哪个不是套餐卡操作手册中提到的步骤？	{"A": "市场管理→套餐卡销售管理", "B": "工时项目定义", "C": "财务结算", "D": "客户反馈收集"}	D	根据文档提供的信息，A、B、C都是文档中提及的步骤，而客户反馈收集在文档中并未提及，因此选项D是不正确的步骤。	\N	2	\N	2026-06-14	2026-06-12 02:29:58.906435+08	7	\N
40	single_choice	套餐卡方案制定中，业务基础资料和套餐方案之间的关系是什么？	{"A": "业务基础资料是套餐方案的一部分", "B": "套餐方案完全独立于业务基础资料", "C": "业务基础资料是制定套餐方案的依据", "D": "业务基础资料和套餐方案没有直接联系"}	C	根据文档中套餐卡方案制定的流程说明，业务基础资料是制定套餐方案的依据，即业务基础资料是套餐方案的基础，因此选项C是正确的。	\N	1	\N	2026-06-12	2026-06-12 02:29:58.906436+08	7	\N
41	single_choice	维修服务接待操作手册中，工单录入的整体操作步骤位于哪个模块？	{"A": "01基础数据", "B": "05售后管理", "C": "08财务管理", "D": "02.13厂家优惠券"}	B	根据手册目录，工单录入的整体操作步骤位于05售后管理模块下的05.01维修服务接待。	\N	1	\N	2026-06-12	2026-06-12 02:41:03.334204+08	7	\N
42	single_choice	在维修服务接待操作手册中，添加工时项目的入口是什么？	{"A": "05售后管理→05.02维修零件入库", "B": "05售后管理→05.01维修服务接待", "C": "02.07优惠券方案", "D": "09.07优惠券管理"}	B	根据手册内容，添加工时项目的入口是05售后管理→05.01维修服务接待。	\N	1	\N	2026-06-12	2026-06-12 02:41:03.334207+08	7	\N
29	true_false	配件仓储管理可以采用先进先出原则降低库存损耗。	null	true	先进先出(FIFO)原则可有效降低配件库存损耗和管理成本。	service	1	\N	2026-06-14	2026-06-10 13:04:45.762434+08	23	\N
44	single_choice	优惠券设置中，哪个步骤是在总经理审核、财务审核生效后进行的？	{"A": "设置优惠券方案", "B": "发行优惠券", "C": "核销优惠券", "D": "取消优惠券核销抵扣"}	B	根据手册内容，优惠券设置中，发行优惠券是在总经理审核、财务审核生效后进行的步骤。	\N	2	\N	2026-06-14	2026-06-12 02:41:03.33421+08	1	\N
47	single_choice	延保设置中，哪个步骤是在【05.08延保销售管理】中进行的？	{"A": "设置延保类型", "B": "新增延保方案", "C": "录入延保销售", "D": "设置延保专用收费类型"}	C	根据手册内容，延保销售管理中录入延保销售，并收款结算。	\N	2	\N	2026-06-14	2026-06-12 02:41:03.334214+08	1	\N
59	single_choice	客服人员在第一次与车主沟通时，除了说正在处理，还应该建议车主做什么？	{"A": "先喝杯茶", "B": "联系其他部门", "C": "填写投诉表单", "D": "等待电话通知"}	A	文档第三条提到，在说正在处理的同时，建议车主先喝杯茶，以进一步安抚情绪。	\N	2	\N	2026-06-14	2026-06-12 05:19:03.995385+08	1	\N
63	single_choice	根据文档，面对年轻女性客户时，客服应优先考虑赠送什么类型的礼物？	{"A": "汽车保养券", "B": "毛绒小挂件", "C": "儿童玩具", "D": "生日蛋糕券"}	B	文档最后一条明确指出“年轻女性，可考虑毛绒小挂件”，这是针对该客户群体的特定建议。	\N	1	\N	2026-06-12	2026-06-12 05:35:05.291875+08	1	\N
64	single_choice	销售经理驾驶舱数据看板支持哪两种设备同步上线？	{"A": "手机和电脑端", "B": "平板和电脑端", "C": "手机和平板端", "D": "电视和手机端"}	A	文档明确指出“销售经理驾驶舱数据看板，手机和电脑端已同步上线”。	\N	1	\N	2026-06-12	2026-06-12 10:40:51.52966+08	1	\N
52	single_choice	车主情绪安抚后，客服人员下一步应该做什么？	{"A": "直接告诉车主最终处理结果", "B": "去维修部门咨询情况", "C": "让车主自己联系维修部", "D": "先向领导汇报"}	B	文档第二条指示马上去维修部门咨询，这是获取信息的关键步骤。	\N	1	\N	2026-06-12	2026-06-12 05:19:03.995375+08	1	\N
66	single_choice	销售经理看板从哪些维度评估自电情况？	{"A": "品牌和车型", "B": "集团、区域到品牌排名", "C": "销售顾问和客户", "D": "时间和地区"}	B	文档提到“从集团、区域到品牌排名，多维度评估自电情况”。	\N	2	\N	2026-06-14	2026-06-12 10:40:51.529667+08	1	\N
71	single_choice	排行榜通过什么进行排序？	{"A": "字母顺序", "B": "核心指标", "C": "随机顺序", "D": "入职时间"}	B	文档说明“排行榜通过核心指标进行排序”。	\N	2	\N	2026-06-14	2026-06-12 10:40:51.529678+08	1	\N
51	single_choice	在处理车主投诉时，第一步应该选择什么样的同事来接待？	{"A": "技术最熟练的同事", "B": "面善、情商高的同事", "C": "资历最老的同事", "D": "年轻有活力的同事"}	B	文档第一条明确要求找面善、情商高的同事先安抚情绪，强调情绪安抚的重要性。	\N	1	\N	2026-06-12	2026-06-12 05:19:03.99537+08	1	\N
54	single_choice	在处理车主投诉过程中，为什么要求必须同一个人跑全程？	{"A": "为了提高工作效率", "B": "为了减少沟通成本", "C": "避免车主因换人而情绪失控", "D": "方便记录处理过程"}	C	文档第四条指出，换人容易导致车主情绪爆炸，因此需要专人负责全程。	\N	2	\N	2026-06-14	2026-06-12 05:19:03.995378+08	1	\N
61	single_choice	根据文档，客服在了解客户家庭情况后，赠送礼品时应优先考虑什么？	{"A": "客户本人喜好", "B": "客户的孩子", "C": "客户的配偶", "D": "客户父母的健康"}	B	文档明确指出“礼物以孩子为先”，强调优先考虑客户的孩子，而非其他家庭成员或客户本人。	\N	1	\N	2026-06-12	2026-06-12 05:35:05.291869+08	1	\N
62	single_choice	根据文档，赠品选择的核心策略是什么？	{"A": "选择昂贵的礼品以显示诚意", "B": "选择实用且体积大的礼物", "C": "尽量选择能引发二次消费或引流的赠品，否则就用小而精的礼物", "D": "只赠送与汽车相关的配件"}	C	文档提到“赠品最好可以引来2次消费，或者引流，否则就用小而精的礼物”，说明核心策略是优先考虑能带来后续效益的赠品，否则选择小巧精致的礼物。	\N	2	\N	2026-06-14	2026-06-12 05:35:05.291873+08	1	\N
65	single_choice	销售经理看板中，关键数据指标支持什么功能以便深入分析？	{"A": "截图保存", "B": "点击穿透", "C": "语音播报", "D": "自动刷新"}	B	文档说明“关键数据指标可点击穿透”，允许用户深入查看细节。	\N	2	\N	2026-06-14	2026-06-12 10:40:51.529665+08	1	\N
68	single_choice	毛利历史柱状图可以查看哪些数据？	{"A": "总毛利和单周毛利", "B": "月毛利和年毛利", "C": "各车型毛利", "D": "销售顾问毛利"}	A	文档说明“毛利历史注重图将历史数据可视化呈现，可查看总毛利和单周毛利”。	\N	2	\N	2026-06-14	2026-06-12 10:40:51.529672+08	1	\N
69	single_choice	销售顾问排行榜包含哪些数据？	{"A": "姓名和年龄", "B": "目标、客户转化率、贡献率等", "C": "工号和部门", "D": "成交金额和利润"}	B	文档说明“销售顾问排行榜，包含了目标、客户转化率、贡献率等数据”。	\N	2	\N	2026-06-14	2026-06-12 10:40:51.529674+08	1	\N
70	single_choice	点击销售顾问排行榜中的个人业绩可以做什么？	{"A": "查看详细资料", "B": "穿透到个人业绩", "C": "发送消息", "D": "修改排名"}	B	文档指出“点击可穿透到个人业绩”。	\N	2	\N	2026-06-14	2026-06-12 10:40:51.529676+08	1	\N
72	single_choice	通过排行榜可以快速识别什么？	{"A": "热销车型", "B": "主力车型与短板车型", "C": "客户群体", "D": "销售策略"}	B	文档提到“可快速识别主力车型与短板车型”。	\N	2	\N	2026-06-14	2026-06-12 10:40:51.52968+08	1	\N
84	single_choice	要图展示的是什么数据？	{"A": "业绩变化", "B": "毛利结构", "C": "目标完成率", "D": "车系排名"}	C	文档明确指出要图展示的是目标完成率。	\N	2	\N	2026-06-14	2026-06-12 10:42:25.812692+08	1	\N
86	single_choice	目标完成情况是根据什么展示实际达成率？	{"A": "个人设定的目标", "B": "集团分配的任务", "C": "历史平均数据", "D": "客户满意度"}	A	文档说目标完成情况是根据自己提交的订单和交车目标展示实际达成率。	\N	2	\N	2026-06-14	2026-06-12 10:42:25.8127+08	1	\N
75	single_choice	全车系目标完成情况展示什么对比数据？	{"A": "实际业绩与目标值", "B": "不同车系的销量", "C": "毛利与成本", "D": "客户满意度与转化率"}	A	文档指出“全车系目标完成情况，展示各车系的实际业绩与目标值的对比数据”。	\N	2	\N	2026-06-14	2026-06-12 10:40:51.529686+08	1	\N
79	single_choice	以下哪项不是销售顾问看板中可查看的关键数据？	{"A": "客户总数", "B": "订单数", "C": "库存数量", "D": "转化率"}	C	文档列出客户总数、订单数、交车数、转化率、总毛利、单车毛利等关键数据，库存数量未提及。	\N	2	\N	2026-06-14	2026-06-12 10:42:25.812657+08	1	\N
58	single_choice	以下哪项不符合合群汽车集团客服处理投诉的流程？	{"A": "先安抚情绪", "B": "5分钟内反馈正在处理", "C": "让不同同事分别对接不同的环节", "D": "情绪稳定后再告知实情"}	C	文档明确要求专人跑全程，换人容易激化矛盾，因此让不同同事对接不符合流程。	\N	3	\N	2026-06-18	2026-06-12 05:19:03.995383+08	1	\N
60	single_choice	在整个投诉处理流程中，客服人员最需要避免的行为是什么？	{"A": "主动询问维修部意见", "B": "更换对接人员", "C": "多次往返维修部", "D": "分步告知处理进展"}	B	文档强调换人容易引发车主情绪失控，这是最需要避免的行为。	\N	3	\N	2026-06-18	2026-06-12 05:19:03.995386+08	1	\N
67	single_choice	排名雷达图在销售经理看板中的作用是什么？	{"A": "展示业绩趋势", "B": "将各模块关键指标汇聚，强弱项清晰可变", "C": "显示目标完成率", "D": "列出销售顾问排行"}	B	文档说明“排名雷达图将各模块的關鍵指標匯聚，強弱向清晰可變”。	\N	3	\N	2026-06-18	2026-06-12 10:40:51.529669+08	1	\N
57	single_choice	如果维修部门给出的意见是负面的，客服人员应该如何处理？	{"A": "直接转达维修部的意见", "B": "先按流程安抚，再分步告知", "C": "隐瞒信息，避免车主生气", "D": "让维修部直接联系车主"}	B	文档强调先安抚再逐步告知实情，即使意见负面也要按流程分步处理，避免车主情绪爆发。	\N	4	\N	2026-06-18	2026-06-12 05:19:03.995382+08	1	\N
87	single_choice	销售顾问价实仓支持哪些终端？	{"A": "手机端和电脑端", "B": "平板和手机", "C": "电视和电脑", "D": "仅电脑端"}	A	文档提到销售顾问价实仓分手机端和电脑端，双端覆盖。	\N	1	\N	2026-06-14	2026-06-12 10:42:25.812702+08	1	\N
73	single_choice	结合什么图表可以形成完整的车系盈利画像？	{"A": "业绩趋势图", "B": "毛利分布图", "C": "排名雷达图", "D": "仪表图"}	B	文档指出“结合毛利分布图，车系盈利画像完整清晰”。	\N	2	\N	2026-06-14	2026-06-12 10:40:51.529682+08	1	\N
49	single_choice	厂家优惠券用于核销工时项目费用时，在工时项目中增加的记录编号为多少？	{"A": "Vou", "B": "Fac", "C": "Cou", "D": "Dou"}	B	根据手册内容，厂家优惠券核销时，在工时项目中增加编号为'Fac'的两条记录。	\N	2	\N	2026-06-14	2026-06-12 02:41:03.334216+08	1	\N
80	single_choice	排名举证是从哪些层级进行排名？	{"A": "集团、区域、品牌、本店", "B": "全国、省份、城市、门店", "C": "品牌、车型、价格、颜色", "D": "销售、经理、总监、老板"}	A	文档明确指出排名举证从集团、区域、品牌到本店进行排名。	\N	2	\N	2026-06-18	2026-06-12 10:42:25.812659+08	1	\N
81	single_choice	哪种图表可以对比你在各项指标上的表现，明确强弱项？	{"A": "趋势图", "B": "围打图", "C": "毛利历史图", "D": "车系排行榜"}	B	文档描述围打图可以对比各项指标表现，让强弱项更直观。	\N	2	\N	2026-06-18	2026-06-12 10:42:25.812661+08	1	\N
83	single_choice	毛利历史图可以查看哪些内容？	{"A": "总毛利和单车毛利", "B": "客户数和订单数", "C": "转化率和交车数", "D": "目标完成率"}	A	文档提到毛利历史图记录不同时间段的毛利表现，可查看总毛利和单车毛利。	\N	2	\N	2026-06-18	2026-06-12 10:42:25.812666+08	1	\N
85	single_choice	车系排行榜可以帮你了解什么？	{"A": "哪些车系是业绩主力", "B": "所有车型的库存情况", "C": "竞争对手的销售数据", "D": "车辆维修记录"}	A	文档说明车系排行榜让你清楚看到哪些车系是业绩主力，哪些还有挖掘空间。	\N	2	\N	2026-06-18	2026-06-12 10:42:25.812697+08	1	\N
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.departments (id, name, parent_id, created_at) FROM stdin;
1	销售部	\N	2026-06-10 13:04:44.4106+08
2	技术部	\N	2026-06-10 13:04:44.410604+08
3	客服部	\N	2026-06-10 13:04:44.410606+08
\.


--
-- Data for Name: exam_attempts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.exam_attempts (id, user_id, paper_id, answers, score, total_questions, correct_count, started_at, submitted_at, status) FROM stdin;
1	4	2	{"11": "C", "12": "A", "13": "B", "14": "false", "15": "B", "16": "B", "17": "B", "18": "true", "19": "B,A,D", "20": "C"}	50	10	5	2026-06-14 06:10:48.958237+08	2026-06-14 14:11:32.849582+08	submitted
2	4	1	{"5": "B", "8": "B", "14": "false", "20": "C", "32": "false", "33": "B", "36": "C", "37": "B", "40": "D", "41": "C", "46": "C", "48": "C", "52": "B", "55": "B", "56": "B", "72": "B", "75": "D", "79": "C", "81": "B", "83": "A"}	60	20	12	2026-06-14 06:11:36.714919+08	2026-06-14 14:12:48.471103+08	submitted
3	3	3	{"1": "C", "2": "B", "3": "false", "4": "B", "5": "C", "6": "B", "7": "B,C", "8": "C", "9": "false", "10": "B"}	60	10	6	2026-06-14 06:32:00.75607+08	2026-06-14 14:32:37.185083+08	submitted
4	3	1	{"5": "C", "8": "C", "14": "false", "20": "C", "32": "false", "33": "C", "36": "B", "37": "B", "40": "C", "41": "B", "46": "A", "48": "C", "52": "C", "55": "B", "56": "B", "72": "B", "75": "C", "79": "D", "81": "C", "83": "D"}	40	20	8	2026-06-14 06:32:40.483574+08	2026-06-14 14:33:14.910516+08	submitted
\.


--
-- Data for Name: exam_papers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.exam_papers (id, title, target_type, target_value, time_mode, start_time, end_time, duration_minutes, total_questions, status, created_by, created_at, updated_at) FROM stdin;
1	随机抽查	all	\N	anytime	\N	\N	60	20	active	2	2026-06-14 06:09:25.727631+08	2026-06-14 06:09:25.727634+08
2	技术岗位知识能力抽查	position	tech	anytime	\N	\N	60	10	active	2	2026-06-14 06:09:57.480998+08	2026-06-14 06:09:57.481001+08
3	销售岗位业务知识能力抽查	position	sales	anytime	\N	\N	60	10	active	2	2026-06-14 06:10:21.958909+08	2026-06-14 06:10:21.958912+08
\.


--
-- Data for Name: exam_papers_questions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.exam_papers_questions (id, paper_id, question_id, sort_order) FROM stdin;
1	1	56	1
2	1	20	2
3	1	14	3
4	1	5	4
5	1	37	5
6	1	33	6
7	1	81	7
8	1	72	8
9	1	52	9
10	1	55	10
11	1	48	11
12	1	36	12
13	1	40	13
14	1	83	14
15	1	41	15
16	1	46	16
17	1	75	17
18	1	79	18
19	1	8	19
20	1	32	20
21	2	12	1
22	2	20	2
23	2	13	3
24	2	17	4
25	2	14	5
26	2	15	6
27	2	11	7
28	2	18	8
29	2	16	9
30	2	19	10
31	3	4	1
32	3	6	2
33	3	10	3
34	3	2	4
35	3	3	5
36	3	8	6
37	3	1	7
38	3	9	8
39	3	7	9
40	3	5	10
\.


--
-- Data for Name: experience_points; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.experience_points (id, user_id, knowledge_id, points, action_type, created_at) FROM stdin;
1	3	11	1	submit	2026-06-12 02:45:12.505309+08
2	3	12	1	submit	2026-06-12 02:46:31.187721+08
3	3	\N	1	submit	2026-06-12 02:50:22.818644+08
4	3	\N	1	submit	2026-06-12 02:50:30.880935+08
5	3	\N	1	submit	2026-06-12 02:50:33.28747+08
6	3	\N	1	submit	2026-06-12 02:50:35.577299+08
7	4	\N	1	submit	2026-06-12 02:52:02.747096+08
8	4	\N	1	submit	2026-06-12 02:52:04.944997+08
9	4	\N	1	submit	2026-06-12 02:52:11.58518+08
10	4	\N	1	submit	2026-06-12 02:52:17.762113+08
11	4	13	1	submit	2026-06-12 02:54:26.681129+08
12	3	12	10	approved	2026-06-12 02:55:41.827725+08
13	4	13	10	approved	2026-06-12 02:55:44.21106+08
14	5	14	1	submit	2026-06-12 05:01:34.194497+08
15	5	15	1	submit	2026-06-12 05:04:45.75773+08
16	5	14	10	approved	2026-06-12 05:19:04.045188+08
17	5	15	10	approved	2026-06-12 05:35:05.326198+08
18	3	\N	1	submit	2026-06-12 10:49:25.138768+08
19	3	\N	1	submit	2026-06-12 10:49:37.810331+08
20	3	\N	1	submit	2026-06-12 10:49:48.181646+08
21	3	\N	1	submit	2026-06-14 05:58:11.539982+08
22	4	\N	1	submit	2026-06-14 06:06:06.020303+08
23	4	\N	1	submit	2026-06-14 06:06:08.180336+08
24	4	\N	1	submit	2026-06-14 06:06:22.41215+08
25	5	\N	1	submit	2026-06-14 06:07:24.084148+08
26	5	\N	1	submit	2026-06-14 06:07:28.380659+08
27	5	\N	1	submit	2026-06-14 06:07:36.67777+08
28	5	\N	1	submit	2026-06-14 06:07:39.19552+08
29	5	\N	1	submit	2026-06-14 06:07:44.260175+08
30	5	\N	1	submit	2026-06-14 06:08:10.228121+08
31	5	\N	1	submit	2026-06-14 06:08:23.028036+08
32	3	\N	1	submit	2026-06-14 06:35:34.511084+08
33	3	\N	1	submit	2026-06-14 06:35:41.679713+08
34	3	\N	1	submit	2026-06-14 06:35:51.134475+08
35	5	\N	1	submit	2026-06-18 01:38:42.314809+08
36	5	\N	1	submit	2026-06-18 01:38:46.865303+08
37	5	\N	1	submit	2026-06-18 01:38:57.432051+08
38	5	\N	1	submit	2026-06-18 01:39:04.618805+08
39	4	\N	1	submit	2026-06-18 01:42:27.801453+08
40	4	\N	1	submit	2026-06-18 01:43:04.296706+08
41	4	\N	1	submit	2026-06-18 01:43:07.240526+08
42	4	\N	1	submit	2026-06-18 01:43:09.96238+08
43	4	\N	1	submit	2026-06-18 02:11:17.72816+08
44	4	\N	1	submit	2026-06-18 02:11:21.007537+08
45	4	\N	1	submit	2026-06-18 02:11:25.31945+08
46	2	117	2	used	2026-06-18 07:30:51.230454+08
\.


--
-- Data for Name: knowledge_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_categories (id, name, parent_id, knowledge_base, sort_order, icon, created_at, description, is_active) FROM stdin;
1	公司制度与规范	\N	public	1	▤	2026-06-10 13:04:44.422255+08	考勤、报销、用车、办公等公司内部管理制度与流程规范	t
2	企业文化与价值观	\N	public	2	⊟	2026-06-10 13:04:44.422258+08	集团使命愿景、核心价值观、服务理念与企业文化宣导	t
3	安全生产与消防	\N	public	3	△	2026-06-10 13:04:44.422259+08	车间安全操作、消防应急、危化品管理、职业病防护等安全知识	t
4	通用商务礼仪	\N	public	4	⇄	2026-06-10 13:04:44.422261+08	客户接待礼仪、电话沟通规范、职业形象与行为准则	t
5	IT系统操作指南	\N	public	5	⌘	2026-06-10 13:04:44.422262+08	DMS系统、OA办公、企业微信、邮件等信息化工具使用教程	t
6	法律法规合规	\N	public	6	☐	2026-06-10 13:04:44.422263+08	汽车三包法、消费者权益保护、个人信息保护、反商业贿赂等法规	t
7	产品知识库	\N	sales	1	◈	2026-06-10 13:04:44.422264+08	在售车型参数配置、核心卖点、产品定位及目标客群分析	t
8	竞品对比分析	\N	sales	2	◱	2026-06-10 13:04:44.422265+08	同级别竞品车型优劣势对比、攻防话术与差异化卖点提炼	t
9	销售话术技巧	\N	sales	3	◎	2026-06-10 13:04:44.422266+08	展厅接待、需求挖掘、试驾引导、异议处理及逼单成交的实战话术	t
10	价格谈判策略	\N	sales	4	◇	2026-06-10 13:04:44.422267+08	报价策略、优惠政策组合、金融方案推荐、赠品谈判与价格异议化解	t
11	客户跟进管理	\N	sales	5	✎	2026-06-10 13:04:44.422269+08	潜客分级跟进、战败客户分析、老客户转介绍及客户生命周期管理	t
12	金融按揭方案	\N	sales	6	⊕	2026-06-10 13:04:44.42227+08	银行/厂家金融产品对比、按揭计算、征信预审及放款流程指导	t
13	二手车评估	\N	sales	7	↺	2026-06-10 13:04:44.422271+08	二手车检测评估方法、置换话术、残值预估与二手车销售策略	t
14	试驾流程标准	\N	sales	8	▷	2026-06-10 13:04:44.422272+08	试驾路线规划、动态体验引导、安全注意事项及试驾后促单流程	t
15	发动机系统维修	\N	tech	1	⚙	2026-06-10 13:04:44.422273+08	涵盖发动机机械、燃油供给、进排气、冷却润滑系统的诊断与维修技术	t
16	变速箱维修技术	\N	tech	2	⊗	2026-06-10 13:04:44.422274+08	MT/AT/CVT/DCT各类型变速箱的工作原理、常见故障与维修工艺	t
17	电气电子系统	\N	tech	3	▲	2026-06-10 13:04:44.422275+08	车载网络、灯光仪表、舒适电子、ADAS辅助驾驶系统的诊断与编程	t
18	空调暖风系统	\N	tech	4	✦	2026-06-10 13:04:44.422276+08	制冷循环原理、压缩机/蒸发器检修、自动空调控制逻辑及故障排查	t
19	底盘悬挂转向	\N	tech	5	◉	2026-06-10 13:04:44.422277+08	悬挂系统、转向机、制动系统、轮胎四轮定位的检查调整与维修	t
20	新能源车维修	\N	tech	6	⊞	2026-06-10 13:04:44.422278+08	三电系统(电池/电机/电控)维修、高压安全操作、充电系统诊断与均衡维护	t
21	钣金喷漆工艺	\N	tech	7	◫	2026-06-10 13:04:44.422279+08	车身钣金修复、漆面处理、涂装工艺流程及色彩调配技术	t
22	故障诊断方法	\N	tech	8	⊘	2026-06-10 13:04:44.42228+08	故障码读取分析、数据流判断、示波器使用、异响定位及疑难故障排查思路	t
23	预约接待流程	\N	service	1	◷	2026-06-10 13:04:44.422281+08	客户预约管理、到店接待、环车检查、工单开单及交车流程标准	t
24	保养服务标准	\N	service	2	⌖	2026-06-10 13:04:44.422283+08	各车型保养周期、保养项目标准、油液规格及保养提醒话术	t
25	客户投诉处理	\N	service	3	◁	2026-06-10 13:04:44.422284+08	投诉分类分级、情绪安抚技巧、快速响应机制及投诉闭环处理流程	t
26	保险理赔服务	\N	service	4	≡	2026-06-10 13:04:44.422285+08	车险定损流程、理赔资料指导、保险公司对接及事故车维修跟进	t
27	续保业务技巧	\N	service	5	↻	2026-06-10 13:04:44.422286+08	续保客户筛选、保险产品对比推荐、续保话术及套餐组合策略	t
28	客户回访规范	\N	service	6	☏	2026-06-10 13:04:44.422287+08	售后三日回访、保养到期提醒、满意度调研及客户关怀活动标准	t
29	会员服务管理	\N	service	7	◆	2026-06-10 13:04:44.422288+08	会员权益体系、积分规则、会员日活动策划及VIP客户专属服务标准	t
30	配件仓储管理	\N	service	8	□	2026-06-10 13:04:44.422289+08	配件入库出库流程、库存预警、常用件备货策略及呆滞件处理规范	t
\.


--
-- Data for Name: knowledge_entries; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_entries (id, title, content, content_type, category_id, sub_category, knowledge_base, source_type, source_file_path, source_person, source_dept, media_url, media_start_sec, media_end_sec, tags, car_brand, car_model, difficulty_level, view_count, useful_count, status, auditor_id, audit_comment, version, created_at, updated_at, expire_at, last_reviewed_at, gross_margin_impact, safety_critical) FROM stdin;
2	国六B排放发动机怠速抖动故障诊断	故障现象：国六B排放标准车辆，冷启动后怠速不稳，转速波动±150rpm，伴随轻微抖动。\n\n诊断步骤：\n1. **读取故障码**：使用诊断仪读取ECU，常见故障码P0300(随机失火)、P0171(混合气过稀)\n2. **检查火花塞**：国六B发动机对火花塞间隙要求更严，标准0.7-0.8mm，超过0.9mm需更换\n3. **检查燃油系统**：测量燃油压力，怠速时应为350-400kPa\n4. **检查碳罐电磁阀**：国六B车型碳罐电磁阀容易卡滞在常开位置，导致混合气过稀\n5. **检查进气系统**：曲轴箱通风PCV阀、进气歧管密封\n\n典型维修案例：星瑞X5 SUV，行驶3万公里，怠速抖动。最终确认碳罐电磁阀故障，更换后问题解决。维修时间约1.5小时，材料费240元。	text	22	\N	tech	experience	\N	赵技师	技术部	\N	0	0	怠速抖动,国六B,碳罐电磁阀,故障诊断	星瑞	X5	4	89	23	approved	\N	\N	1	2026-06-10 13:04:45.742016+08	2026-06-10 13:04:45.742017+08	\N	\N	\N	f
4	合群汽车集团安全生产规范（2025版）	**合群汽车集团安全生产管理制度（2025年修订版）**\n\n一、车间安全\n1. 维修作业必须佩戴防护用具（安全帽、防护手套、护目镜）\n2. 举升机操作必须两人协作，严禁单人操作\n3. 电气设备检修前必须断开电源并挂警示牌\n4. 油品、涂料等易燃物品存放于专用防爆柜\n\n二、消防管理\n1. 每月15日进行消防器材点检，填写检查记录\n2. 严禁在车间内吸烟或使用明火\n3. 消防通道时刻保持畅通，禁止堆放杂物\n4. 每季度进行一次全员消防演练\n\n三、事故报告\n1. 发生安全事故后，15分钟内向安全主管报告\n2. 事故现场保护，不得擅自破坏\n3. 72小时内提交书面事故分析报告\n4. 隐瞒不报者按集团纪律处分条例处理\n\n四、环保要求\n1. 废机油、废电池等危废交由合规处置单位处理\n2. 烤漆房废气处理设备每月维护一次\n3. 噪音超标区域必须佩戴耳塞	text	3	\N	public	policy	\N	李管理	销售部	\N	0	0	安全生产,消防,管理制度,2025版	\N	\N	1	312	8	approved	\N	\N	1	2026-06-10 13:04:45.742021+08	2026-06-10 13:04:45.742022+08	\N	\N	\N	f
3	客户投诉三步骤化解法	面对客户投诉，客服人员应遵循"听-认-行"三步法：\n\n**第一步：倾听（2-3分钟）**\n- 保持耐心，不打岔，让客户完整表达不满\n- 使用积极倾听话术："嗯，我明白了""请您继续说"\n- 注意记录关键信息：订单号、车牌号、投诉核心问题\n\n**第二步：认可情绪（1分钟）**\n- 共情话术："我完全理解您现在的心情，换作是我也会很着急"\n- 不要急于解释或推卸，先让客户感受到被重视\n- 确认问题："让我确认一下，您的主要问题是……对吗？"\n\n**第三步：行动承诺（1分钟）**\n- 给出明确时间承诺："我会在30分钟内给您回复"\n- 告知具体处理方案："我们会安排技师重新检查"\n- 留下联系方式，确保客户能找到您\n\n典型案例：客户因保养时间过长投诉，客服使用三步法，从最初要求退款的对抗转为接受补偿方案（免费下次保养），客户后续续保率达85%。	text	25	\N	service	experience	\N	陈客服	客服部	\N	0	0	投诉处理,客服话术,客户关系	\N	\N	2	157	31	approved	\N	\N	1	2026-06-10 13:04:45.742018+08	2026-06-11 04:20:05.875001+08	\N	\N	\N	f
5	f1a943f2d79f41c5ab5bb198f469b06f	[2025]合群总部-日常-董办-001号 密级：重要普通\n1/2主题词：关于全员服务意识倡议书通知\n文件发送：董办、各子公司、各直营店、各部门 文件抄送:无\n发文单位：集团总经理办公室 发文日期：2025年02月28日\n存档部门：集团总经理办公室人事行政部\n关于全员提升服务意识倡议书的通知\n集团各品牌、各直营店、各部门：\n在近期的巡店检查工作中，我们发现集团旗下各店的整体服务意识与服务质\n量存在诸多问题。用户投诉频发，不接听用户电话、服务态度恶劣等现象频繁出\n现，这不仅严重损害了用户的利益，也对集团的品牌形象造成了负面影响。\n服务是企业立足市场的根本，为了重塑集团及各品牌的服务口碑，提升客户\n满意度，现向全体员工发出以下倡议：\n1、全员必须重视并提升服务意识：从董事长到每一位基层员工，都要深刻认\n识到服务的重要性，主动提升服务态度与服务效率；\n2、加强内部监督：全体员工以及中层管理干部需相互监督，一旦发现服务意\n识淡薄、服务质量未达标的行为，要及时指出并督促整改；\n3、落实责任追究：针对服务态度恶劣、效率低下等不符合服务标准的行为，\n无论涉及基层员工还是中层干部，集团将严肃追究个人及其直属领导责任。对于\n情节特别严重、造成恶劣影响的，除追究责任外还将予以辞退处理。\n现再次公布“集团董事长办公室投诉监督组”联系方式，欢迎全体员工进行\n监督投诉，并提出批评与建议。同时，要求各品牌、各店务必在早会或夕会时，\n向全体员工进行宣贯。让我们齐心协力，为用户提供最优质的产品和服务。\n特此通知！\n[2025]合群总部-日常-董办-001号 密级：重要普通\n2/2附：集团董事长办公室投诉监督组联系方式\n组长：邢益宝13907640169（微信同号）\n组员：黄兴军13907558401（微信同号）\n向海霞18689860279（微信同号）\n邓铭洲15109875321（微信同号）\n王诗葵13807636392（微信同号）\n签发：	text	25	\N	service	manual	D:\\HQEvoAI\\uploads\\d9b78f3f3ef14b56abf1833732c182f4.pdf	李管理	\N	\N	0	0	批量导入,客户投诉处理	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 02:04:20.25407+08	2026-06-12 02:04:20.254074+08	\N	\N	\N	f
1	星瑞L6产品核心卖点	星瑞L6作为合群汽车集团旗舰新能源轿车，核心卖点包括：\n1. **续航里程**：CLTC综合续航1200km，纯电续航200km\n2. **智能座舱**：搭载15.6英寸中控屏，支持语音控制、手势识别\n3. **安全配置**：L2+级智能驾驶辅助，全车6气囊\n4. **动力系统**：1.5T混动专用发动机 + 前置电机，综合功率230kW\n5. **质保政策**：整车5年/15万公里，三电系统终身质保（首任车主）\n\n销售话术要点：重点强调续航和质保这两个差异化优势，与比亚迪汉DM-i对比突出了更高功率和更长整车质保。	text	7	\N	sales	manual	\N	李管理	销售部	\N	0	0	星瑞L6,产品卖点,新能源,轿车	星瑞	L6	2	128	15	archived	\N	\N	2	2026-06-10 13:04:45.742011+08	2026-06-18 13:29:35.418429+08	2026-12-15 05:28:38.718098+08	2026-06-18 13:28:38.716238+08	\N	f
6	d9b78f3f3ef14b56abf1833732c182f4	[2025]合群总部-日常-董办-001号 密级：重要普通\n1/2主题词：关于全员服务意识倡议书通知\n文件发送：董办、各子公司、各直营店、各部门 文件抄送:无\n发文单位：集团总经理办公室 发文日期：2025年02月28日\n存档部门：集团总经理办公室人事行政部\n关于全员提升服务意识倡议书的通知\n集团各品牌、各直营店、各部门：\n在近期的巡店检查工作中，我们发现集团旗下各店的整体服务意识与服务质\n量存在诸多问题。用户投诉频发，不接听用户电话、服务态度恶劣等现象频繁出\n现，这不仅严重损害了用户的利益，也对集团的品牌形象造成了负面影响。\n服务是企业立足市场的根本，为了重塑集团及各品牌的服务口碑，提升客户\n满意度，现向全体员工发出以下倡议：\n1、全员必须重视并提升服务意识：从董事长到每一位基层员工，都要深刻认\n识到服务的重要性，主动提升服务态度与服务效率；\n2、加强内部监督：全体员工以及中层管理干部需相互监督，一旦发现服务意\n识淡薄、服务质量未达标的行为，要及时指出并督促整改；\n3、落实责任追究：针对服务态度恶劣、效率低下等不符合服务标准的行为，\n无论涉及基层员工还是中层干部，集团将严肃追究个人及其直属领导责任。对于\n情节特别严重、造成恶劣影响的，除追究责任外还将予以辞退处理。\n现再次公布“集团董事长办公室投诉监督组”联系方式，欢迎全体员工进行\n监督投诉，并提出批评与建议。同时，要求各品牌、各店务必在早会或夕会时，\n向全体员工进行宣贯。让我们齐心协力，为用户提供最优质的产品和服务。\n特此通知！\n[2025]合群总部-日常-董办-001号 密级：重要普通\n2/2附：集团董事长办公室投诉监督组联系方式\n组长：邢益宝13907640169（微信同号）\n组员：黄兴军13907558401（微信同号）\n向海霞18689860279（微信同号）\n邓铭洲15109875321（微信同号）\n王诗葵13807636392（微信同号）\n签发：	text	25	\N	service	manual	D:\\HQEvoAI\\uploads\\1d3e123e2c97446dbeefe58ed6b2a58a.pdf	李管理	\N	\N	0	0	批量导入,客户投诉处理	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 02:05:58.390553+08	2026-06-12 02:05:58.390556+08	\N	\N	\N	f
7	操作手册-售后服务接待v2025.05	维修服务接待操作手册\nver 2025.05\n维修服务接待操作手册目录\n一、 工单录入 整体操作 步骤\n二、 工单 的新增与修改\n三、 添加 工时项目\n四、 工时项目派工\n五、 维修零件出库（仓管 员操作）\n六、 质检完工\n七、 优惠券\n八、 套餐 卡九、 延保\n十、 折扣\n十一、 推结算单\n十二、 维修财务结账（ 收银员 操作）\n十三、 新增客户\n十四、 客户 情况 情况\n十五、 工单 备注 备注\n十六、厂家优惠券\n操作入口： 05售后管理→05.01 维修服务接待一、工单录入 整体操作步骤\n\n操作入口：05售后管理→05.01维修服务接待二、工单的新增与修改（新增）\n注：有红点的项目是必填项\n操作 入口：05售后管理→05.01维修服务接待二、工单的新增与修改（修改）\n\n操作 入口：05售后管理→05.01维修服务接待\n二、工单的新增与修改（提取厂家工单）\n三、添加工时项目\n操作入口：05售后管理→05.01维修服务接待\n\n操作入口：05售后管理→05.01维修服务接待四、工时项目派工\n\n功能入口：05 售后管理→05.01维修零件出库五、维修零件出库（仓管员录入 工单耗材零件）\n\n操作 入口：05售后管理→05.01维修服务接待六、质检完工\n\n一、优惠券设置：\n1、在【02.07优惠券方案】中设置优惠券方案，内容包括券名称、发行量、面额等。 \n2、设置使用券的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n3、在总经理审核、财务审核生效后，方案才能用于发行优惠券。\n4、在【09.07优惠券管理】中，使用上面生效的优惠券方案发行（生\n成）优惠券。 \n5、步骤4中 发行的券赠送给客户，审核生效后即可在工单中使用（核销）。\n二、优惠券使用条件：\n1、工单 已质检完工。七、优惠券（使用说明）\n2、工单的工时项目，零件项目必须符合优惠券使用的限定范围。\n3、工单中必须有客户付费类的收费类型。（优惠券只能抵扣客户付费的金额）\n三、优惠券核销后：\n1、在工时或零件项目中新增一条编号前缀为"Vou"，金额为负数（核销金额）的记录，用于\n冲减客户付费的金额。\n2、优惠券状态变更为“已使用”，更新优惠券已抵用金额。\n3、工单使用优惠券抵扣后，必须先取消抵扣才能做质检反完工。\n四、取消优惠券核销抵扣：在优惠券核销窗口，选择要取消的券，点击"取消抵扣"按钮。\n功能入口： 05售后管理→05.0 1维修服务接待七、优惠券（优惠券核销）\n取消抵扣：选择要取消的优惠券，点”取消抵扣“按钮。\n操作 入口：05售后管理→05.01维修服务接待七、优惠券（核销后）\n\n一、套餐卡设置：\n  1、在【02.08套餐方案】中设置套餐的名称、套餐金额、有效天数、收费类型以及适用\n      车系等信息，其中车系如果为空则表示所有车系都可有。\n  2、设置套餐的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n 3、在【09.05套餐卡销售管理】中销售套餐或在新车订单、保单中赠送套餐。\n二、套餐的使用条件： \n 1、工时核销，只允许在在修工单中核销(确保所有的工时项目都完成派工)。\n 2、零件核销，须在要核销的\n套餐零件已出库，且工单已完工后(确保核销后出库件不变)。   \n3、套餐卡中项目剩余次数大于要核销的次数。\n三、套餐核销：\n 1、工时核销 ，在工单中新增一条工时，名称为要核销的 套餐工时项目，收费类型 设\n为\n         套餐收费类型。套餐卡中该工时的剩余次数减少一次。\n    2、零件核销，把工单中要核销零件的收费类型改为套餐的收费类型。套餐卡中该零件\n         的剩余次数更新为原剩余次数-工单对应零件出库数。\n四、取消套餐使用：修改工时或零件项目的收费类型，对于工时项目也可直接删除。八、套餐卡（说明）\n八、套餐卡（工时核销）\n功能入口： 05售后管理→ 05.0 1维修服务接待\n\n操作 入口：05售后管理→05.01维修服务接待八、套餐卡（零件核销）\n\n一、延保设置：\n      1、在【01.03基础数据】的“集团统一设置--售后--延 保类型” 中设置好 延保类型 和\n           对应的收费类型。 \n      2、在【02.09延保方案定义】中，新增延保方案，录入方案的 延保类型 ，名称、 适用\n           车名（车系）、价格、里程数、年限、保养次数、毛 利等等。\n      3、在【05.08延保销售管理】中录入延保销售，并收款结算。 销售录入 的客户车 所属\n           的车系必须是延保方案设置的车名（车系），否则无 法录入。\n二、延保使用：\n             录入已购买延保车辆的保养工单时，系统会弹出已购买延保的提示。延保车辆的\n       保养工单可以选择延保专用的收费类型，延保专用收费类型的 金额在结 算时对客 户免\n       费。\n（如果客户是购买延保后首次来店保养，系统会弹出起保窗口，要求进行起保操作。）\n      九、延保（说明）\n操作 入口：05售后管理→05.01维修服务接待九、延保（延保起保）\n\n操作 入口：05售后管理→05.01维修服务接待九、延保（使用延保）\n\n十、折扣（折扣 设置）\n功能入口：05 售后管理→05.0 1维修服务接待\n\n十、折扣（折扣 审批）\n功能入口：05 售后管理→05.01 维修服务接待\n\n十一、推结算单\n功能入口：05 售后管理→05.01维修服务接待\n 注：如付款方显示为空，需在【01.03基础数据】中设置付款方名称\n十二、 维修财务结账（收款员操作）\n功能入口：08 财务管理→08. 01.03维修财务结账\n\n操作 入口：05售后管理→05.01维修服务接待十三、新增客户\n\n功能入口： 05售后管理→05.0 1维修服务接待十四、客户情况/信息\n\n功能入口： 05售后管理→05.0 1维修服务接待十五、工单备注\n\n一、厂家优惠券设置：在【02.13厂家优惠券】中定义厂家优惠券的券名称，券类型，券  \n面值，收费类型，工种等项目。厂家优惠券定义统一设置，各分公司通用。\n二、厂家优惠券用于核销工时项目费用。\n三、厂家优惠券核销，在工时项目中增加编号为"Fac"的两条记录，两条记 录的金额 是券 \n面值的一正一负，收费类型分别是券定义的收费类型和工单的收费类型。十六、厂家优惠券（说明）\n操作 入口：05售后管理→05.01维修服务接待十六、厂家优惠券（优惠券使用）\n\n维修接待流程图\n\n维修服务接待操作手册\n㔃 ᶏ	text	29	\N	service	manual	D:\\HQEvoAI\\uploads\\746706503bec43fc9cbe275f30fe80c1.pdf	李管理	\N	\N	0	0	批量导入,会员服务管理	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 02:26:35.594777+08	2026-06-12 02:26:35.594781+08	\N	\N	\N	f
8	操作手册-套餐卡	套餐卡操作手册\n\n套餐卡管理功能流程说明\n\n套餐卡方案制定\n业务基础资料→套餐方案\n\n套餐卡方案制定\n业务基础资料→套餐方案\n工时项目及材料材料定义。材料项目定义与工时项目的方案一致\n套餐卡销售管理\n市场管理→套餐卡销售管理\n\n套餐卡销售管理\n市场管理→套餐卡销售管理\n财务结算之后生效	text	29	\N	service	manual	D:\\HQEvoAI\\uploads\\6a22132182014a2f90c8f69be72830b2.pdf	李管理	\N	\N	0	0	批量导入,会员服务管理	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 02:29:27.995133+08	2026-06-12 02:29:27.995137+08	\N	\N	\N	f
9	操作手册-售后服务接待v2025.05	维修服务接待操作手册\nver 2025.05\n维修服务接待操作手册目录\n一、 工单录入 整体操作 步骤\n二、 工单 的新增与修改\n三、 添加 工时项目\n四、 工时项目派工\n五、 维修零件出库（仓管 员操作）\n六、 质检完工\n七、 优惠券\n八、 套餐 卡九、 延保\n十、 折扣\n十一、 推结算单\n十二、 维修财务结账（ 收银员 操作）\n十三、 新增客户\n十四、 客户 情况 情况\n十五、 工单 备注 备注\n十六、厂家优惠券\n操作入口： 05售后管理→05.01 维修服务接待一、工单录入 整体操作步骤\n\n操作入口：05售后管理→05.01维修服务接待二、工单的新增与修改（新增）\n注：有红点的项目是必填项\n操作 入口：05售后管理→05.01维修服务接待二、工单的新增与修改（修改）\n\n操作 入口：05售后管理→05.01维修服务接待\n二、工单的新增与修改（提取厂家工单）\n三、添加工时项目\n操作入口：05售后管理→05.01维修服务接待\n\n操作入口：05售后管理→05.01维修服务接待四、工时项目派工\n\n功能入口：05 售后管理→05.01维修零件出库五、维修零件出库（仓管员录入 工单耗材零件）\n\n操作 入口：05售后管理→05.01维修服务接待六、质检完工\n\n一、优惠券设置：\n1、在【02.07优惠券方案】中设置优惠券方案，内容包括券名称、发行量、面额等。 \n2、设置使用券的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n3、在总经理审核、财务审核生效后，方案才能用于发行优惠券。\n4、在【09.07优惠券管理】中，使用上面生效的优惠券方案发行（生\n成）优惠券。 \n5、步骤4中 发行的券赠送给客户，审核生效后即可在工单中使用（核销）。\n二、优惠券使用条件：\n1、工单 已质检完工。七、优惠券（使用说明）\n2、工单的工时项目，零件项目必须符合优惠券使用的限定范围。\n3、工单中必须有客户付费类的收费类型。（优惠券只能抵扣客户付费的金额）\n三、优惠券核销后：\n1、在工时或零件项目中新增一条编号前缀为"Vou"，金额为负数（核销金额）的记录，用于\n冲减客户付费的金额。\n2、优惠券状态变更为“已使用”，更新优惠券已抵用金额。\n3、工单使用优惠券抵扣后，必须先取消抵扣才能做质检反完工。\n四、取消优惠券核销抵扣：在优惠券核销窗口，选择要取消的券，点击"取消抵扣"按钮。\n功能入口： 05售后管理→05.0 1维修服务接待七、优惠券（优惠券核销）\n取消抵扣：选择要取消的优惠券，点”取消抵扣“按钮。\n操作 入口：05售后管理→05.01维修服务接待七、优惠券（核销后）\n\n一、套餐卡设置：\n  1、在【02.08套餐方案】中设置套餐的名称、套餐金额、有效天数、收费类型以及适用\n      车系等信息，其中车系如果为空则表示所有车系都可有。\n  2、设置套餐的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n 3、在【09.05套餐卡销售管理】中销售套餐或在新车订单、保单中赠送套餐。\n二、套餐的使用条件： \n 1、工时核销，只允许在在修工单中核销(确保所有的工时项目都完成派工)。\n 2、零件核销，须在要核销的\n套餐零件已出库，且工单已完工后(确保核销后出库件不变)。   \n3、套餐卡中项目剩余次数大于要核销的次数。\n三、套餐核销：\n 1、工时核销 ，在工单中新增一条工时，名称为要核销的 套餐工时项目，收费类型 设\n为\n         套餐收费类型。套餐卡中该工时的剩余次数减少一次。\n    2、零件核销，把工单中要核销零件的收费类型改为套餐的收费类型。套餐卡中该零件\n         的剩余次数更新为原剩余次数-工单对应零件出库数。\n四、取消套餐使用：修改工时或零件项目的收费类型，对于工时项目也可直接删除。八、套餐卡（说明）\n八、套餐卡（工时核销）\n功能入口： 05售后管理→ 05.0 1维修服务接待\n\n操作 入口：05售后管理→05.01维修服务接待八、套餐卡（零件核销）\n\n一、延保设置：\n      1、在【01.03基础数据】的“集团统一设置--售后--延 保类型” 中设置好 延保类型 和\n           对应的收费类型。 \n      2、在【02.09延保方案定义】中，新增延保方案，录入方案的 延保类型 ，名称、 适用\n           车名（车系）、价格、里程数、年限、保养次数、毛 利等等。\n      3、在【05.08延保销售管理】中录入延保销售，并收款结算。 销售录入 的客户车 所属\n           的车系必须是延保方案设置的车名（车系），否则无 法录入。\n二、延保使用：\n             录入已购买延保车辆的保养工单时，系统会弹出已购买延保的提示。延保车辆的\n       保养工单可以选择延保专用的收费类型，延保专用收费类型的 金额在结 算时对客 户免\n       费。\n（如果客户是购买延保后首次来店保养，系统会弹出起保窗口，要求进行起保操作。）\n      九、延保（说明）\n操作 入口：05售后管理→05.01维修服务接待九、延保（延保起保）\n\n操作 入口：05售后管理→05.01维修服务接待九、延保（使用延保）\n\n十、折扣（折扣 设置）\n功能入口：05 售后管理→05.0 1维修服务接待\n\n十、折扣（折扣 审批）\n功能入口：05 售后管理→05.01 维修服务接待\n\n十一、推结算单\n功能入口：05 售后管理→05.01维修服务接待\n 注：如付款方显示为空，需在【01.03基础数据】中设置付款方名称\n十二、 维修财务结账（收款员操作）\n功能入口：08 财务管理→08. 01.03维修财务结账\n\n操作 入口：05售后管理→05.01维修服务接待十三、新增客户\n\n功能入口： 05售后管理→05.0 1维修服务接待十四、客户情况/信息\n\n功能入口： 05售后管理→05.0 1维修服务接待十五、工单备注\n\n一、厂家优惠券设置：在【02.13厂家优惠券】中定义厂家优惠券的券名称，券类型，券  \n面值，收费类型，工种等项目。厂家优惠券定义统一设置，各分公司通用。\n二、厂家优惠券用于核销工时项目费用。\n三、厂家优惠券核销，在工时项目中增加编号为"Fac"的两条记录，两条记 录的金额 是券 \n面值的一正一负，收费类型分别是券定义的收费类型和工单的收费类型。十六、厂家优惠券（说明）\n操作 入口：05售后管理→05.01维修服务接待十六、厂家优惠券（优惠券使用）\n\n维修接待流程图\n\n维修服务接待操作手册\n㔃 ᶏ	text	29	\N	service	manual	D:\\HQEvoAI\\uploads\\687e641fe6e94eb6968387f29c9c5ee0.pdf	李管理	\N	\N	0	0	批量导入,会员服务管理	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 02:30:07.660515+08	2026-06-12 02:30:07.660518+08	\N	\N	\N	f
10	操作手册-售后服务接待v2025.05	维修服务接待操作手册\nver 2025.05\n维修服务接待操作手册目录\n一、 工单录入 整体操作 步骤\n二、 工单 的新增与修改\n三、 添加 工时项目\n四、 工时项目派工\n五、 维修零件出库（仓管 员操作）\n六、 质检完工\n七、 优惠券\n八、 套餐 卡九、 延保\n十、 折扣\n十一、 推结算单\n十二、 维修财务结账（ 收银员 操作）\n十三、 新增客户\n十四、 客户 情况 情况\n十五、 工单 备注 备注\n十六、厂家优惠券\n操作入口： 05售后管理→05.01 维修服务接待一、工单录入 整体操作步骤\n\n操作入口：05售后管理→05.01维修服务接待二、工单的新增与修改（新增）\n注：有红点的项目是必填项\n操作 入口：05售后管理→05.01维修服务接待二、工单的新增与修改（修改）\n\n操作 入口：05售后管理→05.01维修服务接待\n二、工单的新增与修改（提取厂家工单）\n三、添加工时项目\n操作入口：05售后管理→05.01维修服务接待\n\n操作入口：05售后管理→05.01维修服务接待四、工时项目派工\n\n功能入口：05 售后管理→05.01维修零件出库五、维修零件出库（仓管员录入 工单耗材零件）\n\n操作 入口：05售后管理→05.01维修服务接待六、质检完工\n\n一、优惠券设置：\n1、在【02.07优惠券方案】中设置优惠券方案，内容包括券名称、发行量、面额等。 \n2、设置使用券的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n3、在总经理审核、财务审核生效后，方案才能用于发行优惠券。\n4、在【09.07优惠券管理】中，使用上面生效的优惠券方案发行（生\n成）优惠券。 \n5、步骤4中 发行的券赠送给客户，审核生效后即可在工单中使用（核销）。\n二、优惠券使用条件：\n1、工单 已质检完工。七、优惠券（使用说明）\n2、工单的工时项目，零件项目必须符合优惠券使用的限定范围。\n3、工单中必须有客户付费类的收费类型。（优惠券只能抵扣客户付费的金额）\n三、优惠券核销后：\n1、在工时或零件项目中新增一条编号前缀为"Vou"，金额为负数（核销金额）的记录，用于\n冲减客户付费的金额。\n2、优惠券状态变更为“已使用”，更新优惠券已抵用金额。\n3、工单使用优惠券抵扣后，必须先取消抵扣才能做质检反完工。\n四、取消优惠券核销抵扣：在优惠券核销窗口，选择要取消的券，点击"取消抵扣"按钮。\n功能入口： 05售后管理→05.0 1维修服务接待七、优惠券（优惠券核销）\n取消抵扣：选择要取消的优惠券，点”取消抵扣“按钮。\n操作 入口：05售后管理→05.01维修服务接待七、优惠券（核销后）\n\n一、套餐卡设置：\n  1、在【02.08套餐方案】中设置套餐的名称、套餐金额、有效天数、收费类型以及适用\n      车系等信息，其中车系如果为空则表示所有车系都可有。\n  2、设置套餐的工时项目和零件项目范围，如不设置则表示不限制券的使用范围。\n 3、在【09.05套餐卡销售管理】中销售套餐或在新车订单、保单中赠送套餐。\n二、套餐的使用条件： \n 1、工时核销，只允许在在修工单中核销(确保所有的工时项目都完成派工)。\n 2、零件核销，须在要核销的\n套餐零件已出库，且工单已完工后(确保核销后出库件不变)。   \n3、套餐卡中项目剩余次数大于要核销的次数。\n三、套餐核销：\n 1、工时核销 ，在工单中新增一条工时，名称为要核销的 套餐工时项目，收费类型 设\n为\n         套餐收费类型。套餐卡中该工时的剩余次数减少一次。\n    2、零件核销，把工单中要核销零件的收费类型改为套餐的收费类型。套餐卡中该零件\n         的剩余次数更新为原剩余次数-工单对应零件出库数。\n四、取消套餐使用：修改工时或零件项目的收费类型，对于工时项目也可直接删除。八、套餐卡（说明）\n八、套餐卡（工时核销）\n功能入口： 05售后管理→ 05.0 1维修服务接待\n\n操作 入口：05售后管理→05.01维修服务接待八、套餐卡（零件核销）\n\n一、延保设置：\n      1、在【01.03基础数据】的“集团统一设置--售后--延 保类型” 中设置好 延保类型 和\n           对应的收费类型。 \n      2、在【02.09延保方案定义】中，新增延保方案，录入方案的 延保类型 ，名称、 适用\n           车名（车系）、价格、里程数、年限、保养次数、毛 利等等。\n      3、在【05.08延保销售管理】中录入延保销售，并收款结算。 销售录入 的客户车 所属\n           的车系必须是延保方案设置的车名（车系），否则无 法录入。\n二、延保使用：\n             录入已购买延保车辆的保养工单时，系统会弹出已购买延保的提示。延保车辆的\n       保养工单可以选择延保专用的收费类型，延保专用收费类型的 金额在结 算时对客 户免\n       费。\n（如果客户是购买延保后首次来店保养，系统会弹出起保窗口，要求进行起保操作。）\n      九、延保（说明）\n操作 入口：05售后管理→05.01维修服务接待九、延保（延保起保）\n\n操作 入口：05售后管理→05.01维修服务接待九、延保（使用延保）\n\n十、折扣（折扣 设置）\n功能入口：05 售后管理→05.0 1维修服务接待\n\n十、折扣（折扣 审批）\n功能入口：05 售后管理→05.01 维修服务接待\n\n十一、推结算单\n功能入口：05 售后管理→05.01维修服务接待\n 注：如付款方显示为空，需在【01.03基础数据】中设置付款方名称\n十二、 维修财务结账（收款员操作）\n功能入口：08 财务管理→08. 01.03维修财务结账\n\n操作 入口：05售后管理→05.01维修服务接待十三、新增客户\n\n功能入口： 05售后管理→05.0 1维修服务接待十四、客户情况/信息\n\n功能入口： 05售后管理→05.0 1维修服务接待十五、工单备注\n\n一、厂家优惠券设置：在【02.13厂家优惠券】中定义厂家优惠券的券名称，券类型，券  \n面值，收费类型，工种等项目。厂家优惠券定义统一设置，各分公司通用。\n二、厂家优惠券用于核销工时项目费用。\n三、厂家优惠券核销，在工时项目中增加编号为"Fac"的两条记录，两条记 录的金额 是券 \n面值的一正一负，收费类型分别是券定义的收费类型和工单的收费类型。十六、厂家优惠券（说明）\n操作 入口：05售后管理→05.01维修服务接待十六、厂家优惠券（优惠券使用）\n\n维修接待流程图\n\n维修服务接待操作手册\n㔃 ᶏ	text	29	\N	service	manual	D:\\HQEvoAI\\uploads\\98f8c7f0b5764166bc743a916a15bb31.pdf	李管理	\N	\N	0	0	批量导入,会员服务管理	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 02:40:21.078866+08	2026-06-12 02:40:21.078869+08	\N	\N	\N	f
12	贴膜销售策略	1-好车推荐高端----匹配\n2-中等车推荐高端-----有面子\n3-低端车推荐中端----高性价比	text	10	\N	sales	experience	\N	王销售	销售部	\N	0	0				1	0	0	approved	2	\N	1	2026-06-12 02:46:31.186621+08	2026-06-12 02:55:41.823379+08	\N	\N	\N	f
13	换大众车机油	1-自然放机油后，用压力枪吹几遍\n2-新机油放少量，页漏掉\n3-最后放全量机油	text	15	\N	tech	experience	\N	赵技师	技术部	\N	0	0	换机油			1	0	0	approved	2	\N	1	2026-06-12 02:54:26.671916+08	2026-06-12 02:55:44.206208+08	\N	\N	\N	f
11	车辆保险销售三步法	快速找出用户的需求，全保，还是只卖基础险。\n然后，告知店里的服务。	text	9	\N	sales	experience	\N	王销售	销售部	\N	0	0				1	0	0	rejected	2	没什么用	1	2026-06-12 02:45:12.502484+08	2026-06-12 02:55:59.362022+08	\N	\N	\N	f
14	车主维修发脾气处理经验	1-找面善、情商高的同事，先安抚情绪\n2-马上去维修部门，咨询一下。\n3-无论维修部什么意见，5分钟内，亲自向车主说，正在处理，一会告知处理情况，先喝杯茶。\n4-必须是1个人跑全程，不能换人，换人车主容易炸雷。\n5-车主情绪稳定几分钟后，再去一趟维修部，回来告知实情。	text	25	\N	service	experience	\N	陈客服	客服部	\N	0	0				1	0	0	approved	2	\N	1	2026-06-12 05:01:34.170798+08	2026-06-12 05:19:04.039576+08	\N	\N	\N	f
15	长期保养汽车的客户赠品	1-了解客户家庭情况，孩子多大，男女？礼物以孩子为先\n2-客户生日，到店，可送生日小礼品\n3-赠品最好可以引来2次消费，或者引流，否则就用小而精的礼物。\n4-年轻女性，可考虑毛绒小挂件。	text	29	\N	service	experience	\N	陈客服	客服部	\N	0	0				1	0	0	approved	2	\N	1	2026-06-12 05:04:45.75652+08	2026-06-12 05:35:05.317852+08	\N	\N	\N	f
17	销售经理驾驶仓数据分析看板 - 片段1 (00:00)	[视频片段 00:00 - 01:00] 此内容为视频转写片段，请管理员填写文字内容。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\4e8a932bd352478485752f74c1f63718.mp4	李管理		/uploads/4e8a932bd352478485752f74c1f63718.mp4	0	60	批量导入,公司制度与规范	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 09:18:17.77507+08	2026-06-12 11:26:53.110849+08	\N	\N	\N	f
49	销售经理驾驶仓数据分析看板 - 片段1 (00:02)	銷售經理駕駛艙數據看板,手機和電腦端已同步上線。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	2.9	8.3	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.347028+08	2026-06-12 10:37:44.347033+08	\N	\N	\N	f
50	销售经理驾驶仓数据分析看板 - 片段2 (00:08)	打開銷售經理數據可視化平台。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	8.3	12.3	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.34892+08	2026-06-12 10:37:44.348924+08	\N	\N	\N	f
51	销售经理驾驶仓数据分析看板 - 片段3 (00:12)	進入銷售經理看板介面。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	12.3	14.8	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.349796+08	2026-06-12 10:37:44.349799+08	\N	\N	\N	f
52	销售经理驾驶仓数据分析看板 - 片段4 (00:14)	點擊右上角。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	14.8	18.07	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.350594+08	2026-06-12 10:37:44.350597+08	\N	\N	\N	f
53	销售经理驾驶仓数据分析看板 - 片段5 (00:18)	可選擇查看日報、月報、年報。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	18.07	21.67	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.351759+08	2026-06-12 10:37:44.351774+08	\N	\N	\N	f
54	销售经理驾驶仓数据分析看板 - 片段6 (00:21)	也可以通過快捷按鈕選擇週期。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	21.67	24.77	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.352843+08	2026-06-12 10:37:44.352847+08	\N	\N	\N	f
55	销售经理驾驶仓数据分析看板 - 片段7 (00:24)	關鍵數據指標可點擊穿透。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	24.77	29.93	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.353667+08	2026-06-12 10:37:44.353671+08	\N	\N	\N	f
56	销售经理驾驶仓数据分析看板 - 片段8 (00:29)	毛利結構已拆分到具體業務模塊。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	29.93	36.71	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.354458+08	2026-06-12 10:37:44.354461+08	\N	\N	\N	f
57	销售经理驾驶仓数据分析看板 - 片段9 (00:36)	管理層可直觀查看。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	36.71	38.81	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.355237+08	2026-06-12 10:37:44.35524+08	\N	\N	\N	f
58	销售经理驾驶仓数据分析看板 - 片段10 (00:38)	從集團、區域到品牌排名。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	38.91	41.71	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.356015+08	2026-06-12 10:37:44.356018+08	\N	\N	\N	f
59	销售经理驾驶仓数据分析看板 - 片段11 (00:41)	多維度評估自電情況。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	41.71	44.11	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.356762+08	2026-06-12 10:37:44.356766+08	\N	\N	\N	f
60	销售经理驾驶仓数据分析看板 - 片段12 (00:44)	排名為達圖將各模塊的關鍵指標匯聚。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	44.11	52.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.357527+08	2026-06-12 10:37:44.35753+08	\N	\N	\N	f
61	销售经理驾驶仓数据分析看板 - 片段13 (00:52)	強弱向清晰可變。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	52.02	54.22	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.358306+08	2026-06-12 10:37:44.35831+08	\N	\N	\N	f
62	销售经理驾驶仓数据分析看板 - 片段14 (00:54)	業績趨勢圖動態呈現關鍵指標的時間總是。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	54.22	58.62	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.35907+08	2026-06-12 10:37:44.359073+08	\N	\N	\N	f
63	销售经理驾驶仓数据分析看板 - 片段15 (00:58)	直觀把握整體業績的起落規律與波動。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	58.62	63.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.359834+08	2026-06-12 10:37:44.359837+08	\N	\N	\N	f
64	销售经理驾驶仓数据分析看板 - 片段16 (01:03)	快速識別改點,預判走向。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	63.02	65.72	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.360585+08	2026-06-12 10:37:44.360588+08	\N	\N	\N	f
65	销售经理驾驶仓数据分析看板 - 片段17 (01:05)	毛利歷史注重圖將歷史數據可視化呈現。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	65.72	69.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.361339+08	2026-06-12 10:37:44.361342+08	\N	\N	\N	f
66	销售经理驾驶仓数据分析看板 - 片段18 (01:09)	可查看總毛利和單周毛利。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	69.42	72.52	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.362636+08	2026-06-12 10:37:44.36264+08	\N	\N	\N	f
67	销售经理驾驶仓数据分析看板 - 片段19 (01:12)	依表圖展示的是目標完成率。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	72.62	75.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.363657+08	2026-06-12 10:37:44.363661+08	\N	\N	\N	f
68	销售经理驾驶仓数据分析看板 - 片段20 (01:15)	銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	75.42	81.42	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.364516+08	2026-06-12 10:37:44.36452+08	\N	\N	\N	f
69	销售经理驾驶仓数据分析看板 - 片段21 (01:21)	點擊可穿透到個人業績。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	81.42	84.62	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.365371+08	2026-06-12 10:37:44.365374+08	\N	\N	\N	f
70	销售经理驾驶仓数据分析看板 - 片段22 (01:24)	排行榜通過核心指標進行排序。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	84.62	91.76	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.366157+08	2026-06-12 10:37:44.366161+08	\N	\N	\N	f
71	销售经理驾驶仓数据分析看板 - 片段23 (01:31)	可快速識別主力車型與短板車型。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	91.76	94.96	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.367088+08	2026-06-12 10:37:44.367093+08	\N	\N	\N	f
72	销售经理驾驶仓数据分析看板 - 片段24 (01:34)	結合毛利分布圖,車系盈利畫像完整清晰。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	94.96	99.46	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.368269+08	2026-06-12 10:37:44.368273+08	\N	\N	\N	f
73	销售经理驾驶仓数据分析看板 - 片段25 (01:39)	銷售顧問的訂單與交車目標由個人填寫。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	99.46	104.63	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.369333+08	2026-06-12 10:37:44.369337+08	\N	\N	\N	f
74	销售经理驾驶仓数据分析看板 - 片段26 (01:44)	達成率在這個頁面查看。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	104.63	106.83	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.370184+08	2026-06-12 10:37:44.370188+08	\N	\N	\N	f
75	销售经理驾驶仓数据分析看板 - 片段27 (01:46)	全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	106.93	112.93	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.37099+08	2026-06-12 10:37:44.370993+08	\N	\N	\N	f
76	销售经理驾驶仓数据分析看板 - 片段28 (01:52)	駕駛艙將持續別帶優化。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	112.93	115.93	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.371803+08	2026-06-12 10:37:44.371806+08	\N	\N	\N	f
77	销售经理驾驶仓数据分析看板 - 片段29 (01:55)	我們會用更精準的數據動差,會業務增長持續負能。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\c61cbf8cc01749eab8f6c1a28116bec5.mp4	李管理		/uploads/c61cbf8cc01749eab8f6c1a28116bec5.mp4	115.93	120.43	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:37:44.372614+08	2026-06-12 10:37:44.372617+08	\N	\N	\N	f
78	销售顾问驾驶仓看板 - 片段1 (00:04)	打开数据可失化平台,输入账号密码点击登录,进入销售顾问看板界面。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	4.02	11.22	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.480624+08	2026-06-12 10:41:52.480629+08	\N	\N	\N	f
79	销售顾问驾驶仓看板 - 片段2 (00:11)	可以选择日报、月报、年报,三种查看方式。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	11.22	16.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.483373+08	2026-06-12 10:41:52.483377+08	\N	\N	\N	f
80	销售顾问驾驶仓看板 - 片段3 (00:16)	也可以通过快捷键选择查看周期。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	16.02	20.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.484453+08	2026-06-12 10:41:52.484457+08	\N	\N	\N	f
81	销售顾问驾驶仓看板 - 片段4 (00:20)	查看客户总数、订单数、交车数、	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	20.02	25.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.485364+08	2026-06-12 10:41:52.485368+08	\N	\N	\N	f
82	销售顾问驾驶仓看板 - 片段5 (00:25)	以及转化率、总毛利、单车毛利等关键数据。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	25.02	29.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.486222+08	2026-06-12 10:41:52.486225+08	\N	\N	\N	f
83	销售顾问驾驶仓看板 - 片段6 (00:29)	在这个界面可以看到自己的毛利结构。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	29.02	33.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.48701+08	2026-06-12 10:41:52.487013+08	\N	\N	\N	f
84	销售顾问驾驶仓看板 - 片段7 (00:34)	我们一眼就能看出利润具体来自哪里。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	34.02	38.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.487787+08	2026-06-12 10:41:52.487791+08	\N	\N	\N	f
85	销售顾问驾驶仓看板 - 片段8 (00:38)	排名举证从集团、区域、品牌到本店进行排名,让我们目标更清晰。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	38.02	44.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.48855+08	2026-06-12 10:41:52.488553+08	\N	\N	\N	f
86	销售顾问驾驶仓看板 - 片段9 (00:44)	每项业务在订单里共项了多少利润,在这里都可以看到明信。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	44.02	49.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.489322+08	2026-06-12 10:41:52.489325+08	\N	\N	\N	f
87	销售顾问驾驶仓看板 - 片段10 (00:49)	这张围打图可以对比你在各项指标上的表现,强弱项更为直观,明确下一步提升方向。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	49.02	58.8	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.490088+08	2026-06-12 10:41:52.490092+08	\N	\N	\N	f
88	销售顾问驾驶仓看板 - 片段11 (00:58)	这季趋势图清晰呈现每个月的业绩变化,让你看清成章轨迹,及时把握节奏,预判下一步目标。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	58.8	70.09	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.490842+08	2026-06-12 10:41:52.490846+08	\N	\N	\N	f
89	销售顾问驾驶仓看板 - 片段12 (01:10)	毛利历史图记录不同时间段的毛利表现,可查看总毛利和单车毛利。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	70.09	76.09	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.491597+08	2026-06-12 10:41:52.4916+08	\N	\N	\N	f
90	销售顾问驾驶仓看板 - 片段13 (01:16)	要图展示的是目标完成率。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	76.09	84.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.492358+08	2026-06-12 10:41:52.492362+08	\N	\N	\N	f
91	销售顾问驾驶仓看板 - 片段14 (01:24)	车系排行榜把你自己的客户、订单、交车和转化率按车系拆开。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	84.02	90.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.49332+08	2026-06-12 10:41:52.493324+08	\N	\N	\N	f
92	销售顾问驾驶仓看板 - 片段15 (01:30)	让你清楚看到哪些车系是你的业绩主力,哪些车系还有挖掘空间。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	90.02	96.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.494266+08	2026-06-12 10:41:52.49427+08	\N	\N	\N	f
93	销售顾问驾驶仓看板 - 片段16 (01:36)	目标完成情况是根据自己提交的订单和交车目标展示实际达成率。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	96.02	102.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.49507+08	2026-06-12 10:41:52.495074+08	\N	\N	\N	f
94	销售顾问驾驶仓看板 - 片段17 (01:42)	你可以看到哪些车系已经达标,哪些还是要加把劲。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	102.02	106.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.495866+08	2026-06-12 10:41:52.495869+08	\N	\N	\N	f
95	销售顾问驾驶仓看板 - 片段18 (01:47)	销售顾问价实仓分手机灯和电脑端,爽得覆盖。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	107.02	111.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.498127+08	2026-06-12 10:41:52.498131+08	\N	\N	\N	f
96	销售顾问驾驶仓看板 - 片段19 (01:51)	我们会持续更新,用数据提升效率,放大你的能力。	video	7	\N	sales	video	D:\\HQEvoAI\\uploads\\b3922c199c7e48e5893304d68fe7951a.mp4	李管理		/uploads/b3922c199c7e48e5893304d68fe7951a.mp4	111.02	116.02	批量导入,产品知识库	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:41:52.499941+08	2026-06-12 10:41:52.499945+08	\N	\N	\N	f
16	销售经理驾驶仓数据分析看板	视频文件：7a6ae32af5824d9599d6cba51208cf3a.mp4	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\7a6ae32af5824d9599d6cba51208cf3a.mp4	李管理		/uploads/7a6ae32af5824d9599d6cba51208cf3a.mp4	0	0	批量导入,公司制度与规范	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 09:13:37.910825+08	2026-06-12 10:50:55.779964+08	\N	\N	\N	f
100	销售经理驾驶仓数据分析看板 - 片段4 (00:14)	點擊右上角。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	14.8	18.07	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.347274+08	2026-06-12 10:53:54.347277+08	\N	\N	\N	f
101	销售经理驾驶仓数据分析看板 - 片段5 (00:18)	可選擇查看日報、月報、年報。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	18.07	21.67	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.34814+08	2026-06-12 10:53:54.348144+08	\N	\N	\N	f
103	销售经理驾驶仓数据分析看板 - 片段7 (00:24)	關鍵數據指標可點擊穿透。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	24.77	29.93	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.349831+08	2026-06-12 10:53:54.349835+08	\N	\N	\N	f
104	销售经理驾驶仓数据分析看板 - 片段8 (00:29)	毛利結構已拆分到具體業務模塊。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	29.93	36.71	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.350598+08	2026-06-12 10:53:54.350601+08	\N	\N	\N	f
105	销售经理驾驶仓数据分析看板 - 片段9 (00:36)	管理層可直觀查看。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	36.71	38.81	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.351357+08	2026-06-12 10:53:54.35136+08	\N	\N	\N	f
106	销售经理驾驶仓数据分析看板 - 片段10 (00:38)	從集團、區域到品牌排名。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	38.91	41.71	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.352111+08	2026-06-12 10:53:54.352114+08	\N	\N	\N	f
107	销售经理驾驶仓数据分析看板 - 片段11 (00:41)	多維度評估自電情況。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	41.71	44.11	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.352862+08	2026-06-12 10:53:54.352865+08	\N	\N	\N	f
108	销售经理驾驶仓数据分析看板 - 片段12 (00:44)	排名為達圖將各模塊的關鍵指標匯聚。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	44.11	52.02	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.35362+08	2026-06-12 10:53:54.353624+08	\N	\N	\N	f
109	销售经理驾驶仓数据分析看板 - 片段13 (00:52)	強弱向清晰可變。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	52.02	54.22	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.354372+08	2026-06-12 10:53:54.354376+08	\N	\N	\N	f
110	销售经理驾驶仓数据分析看板 - 片段14 (00:54)	業績趨勢圖動態呈現關鍵指標的時間總是。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	54.22	58.62	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.355124+08	2026-06-12 10:53:54.355128+08	\N	\N	\N	f
111	销售经理驾驶仓数据分析看板 - 片段15 (00:58)	直觀把握整體業績的起落規律與波動。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	58.62	63.02	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.355861+08	2026-06-12 10:53:54.355864+08	\N	\N	\N	f
112	销售经理驾驶仓数据分析看板 - 片段16 (01:03)	快速識別改點,預判走向。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	63.02	65.72	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.356959+08	2026-06-12 10:53:54.356963+08	\N	\N	\N	f
113	销售经理驾驶仓数据分析看板 - 片段17 (01:05)	毛利歷史注重圖將歷史數據可視化呈現。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	65.72	69.42	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.357812+08	2026-06-12 10:53:54.357815+08	\N	\N	\N	f
114	销售经理驾驶仓数据分析看板 - 片段18 (01:09)	可查看總毛利和單周毛利。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	69.42	72.52	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.358592+08	2026-06-12 10:53:54.358596+08	\N	\N	\N	f
99	销售经理驾驶仓数据分析看板 - 片段3 (00:12)	進入銷售經理看板介面。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	12.3	14.8	批量导入,公司制度与规范	\N	\N	1	1	0	approved	\N	\N	1	2026-06-12 10:53:54.346422+08	2026-06-18 07:30:57.894879+08	\N	\N	\N	f
98	销售经理驾驶仓数据分析看板 - 片段2 (00:08)	打開銷售經理數據可視化平台。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	8.3	12.3	批量导入,公司制度与规范	\N	\N	1	1	0	approved	\N	\N	1	2026-06-12 10:53:54.345485+08	2026-06-18 07:30:58.824608+08	\N	\N	\N	f
102	销售经理驾驶仓数据分析看板 - 片段6 (00:21)	也可以通過快捷按鈕選擇週期。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	21.67	24.77	批量导入,公司制度与规范	\N	\N	1	1	0	approved	\N	\N	1	2026-06-12 10:53:54.348989+08	2026-06-18 07:31:01.290972+08	\N	\N	\N	f
115	销售经理驾驶仓数据分析看板 - 片段19 (01:12)	依表圖展示的是目標完成率。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	72.62	75.42	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.359401+08	2026-06-12 10:53:54.359404+08	\N	\N	\N	f
116	销售经理驾驶仓数据分析看板 - 片段20 (01:15)	銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	75.42	81.42	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.360382+08	2026-06-12 10:53:54.360385+08	\N	\N	\N	f
118	销售经理驾驶仓数据分析看板 - 片段22 (01:24)	排行榜通過核心指標進行排序。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	84.62	91.76	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.361933+08	2026-06-12 10:53:54.361936+08	\N	\N	\N	f
119	销售经理驾驶仓数据分析看板 - 片段23 (01:31)	可快速識別主力車型與短板車型。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	91.76	94.96	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.362725+08	2026-06-12 10:53:54.362728+08	\N	\N	\N	f
120	销售经理驾驶仓数据分析看板 - 片段24 (01:34)	結合毛利分布圖,車系盈利畫像完整清晰。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	94.96	99.46	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.363501+08	2026-06-12 10:53:54.363504+08	\N	\N	\N	f
121	销售经理驾驶仓数据分析看板 - 片段25 (01:39)	銷售顧問的訂單與交車目標由個人填寫。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	99.46	104.63	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.364318+08	2026-06-12 10:53:54.364322+08	\N	\N	\N	f
122	销售经理驾驶仓数据分析看板 - 片段26 (01:44)	達成率在這個頁面查看。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	104.63	106.83	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.365087+08	2026-06-12 10:53:54.365091+08	\N	\N	\N	f
123	销售经理驾驶仓数据分析看板 - 片段27 (01:46)	全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	106.93	112.93	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.365868+08	2026-06-12 10:53:54.365873+08	\N	\N	\N	f
124	销售经理驾驶仓数据分析看板 - 片段28 (01:52)	駕駛艙將持續別帶優化。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	112.93	115.93	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.366626+08	2026-06-12 10:53:54.36663+08	\N	\N	\N	f
125	销售经理驾驶仓数据分析看板 - 片段29 (01:55)	我們會用更精準的數據動差,會業務增長持續負能。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	115.93	120.43	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:53:54.367375+08	2026-06-12 10:53:54.367379+08	\N	\N	\N	f
126	销售经理驾驶仓数据分析看板	视频文件：0c85258598364e5e89ecdca9c7bdd3cf.mp4	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\0c85258598364e5e89ecdca9c7bdd3cf.mp4	李管理		/uploads/0c85258598364e5e89ecdca9c7bdd3cf.mp4	0	0	批量导入,公司制度与规范	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 10:55:02.396761+08	2026-06-12 10:55:02.396769+08	\N	\N	\N	f
18	销售经理驾驶仓数据分析看板 - 片段2 (01:00)	[视频片段 01:00 - 02:00] 此内容为视频转写片段，请管理员填写文字内容。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\4e8a932bd352478485752f74c1f63718.mp4	李管理		/uploads/4e8a932bd352478485752f74c1f63718.mp4	60	120	批量导入,公司制度与规范	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 09:18:17.784503+08	2026-06-12 11:26:53.110853+08	\N	\N	\N	f
19	销售经理驾驶仓数据分析看板 - 片段3 (02:00)	[视频片段 02:00 - 02:03] 此内容为视频转写片段，请管理员填写文字内容。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\4e8a932bd352478485752f74c1f63718.mp4	李管理		/uploads/4e8a932bd352478485752f74c1f63718.mp4	120	123.971375	批量导入,公司制度与规范	\N	\N	1	0	0	pending	\N	\N	1	2026-06-12 09:18:17.785841+08	2026-06-12 11:26:53.110855+08	\N	\N	\N	f
20	销售经理驾驶仓数据分析看板 - 片段1 (00:02)	銷售經理駕駛艙數據看板,手機和電腦端已同步上線。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	2.9	8.3	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:20.973736+08	2026-06-12 11:26:53.110856+08	\N	\N	\N	f
21	销售经理驾驶仓数据分析看板 - 片段2 (00:08)	打開銷售經理數據可視化平台。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	8.3	12.3	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:20.983913+08	2026-06-12 11:26:53.110858+08	\N	\N	\N	f
22	销售经理驾驶仓数据分析看板 - 片段3 (00:12)	進入銷售經理看板介面。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	12.3	14.8	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:20.984947+08	2026-06-12 11:26:53.110859+08	\N	\N	\N	f
23	销售经理驾驶仓数据分析看板 - 片段4 (00:14)	點擊右上角。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	14.8	18.07	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:20.985884+08	2026-06-12 11:26:53.11086+08	\N	\N	\N	f
24	销售经理驾驶仓数据分析看板 - 片段5 (00:18)	可選擇查看日報、月報、年報。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	18.07	21.67	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:20.986757+08	2026-06-12 11:26:53.110861+08	\N	\N	\N	f
25	销售经理驾驶仓数据分析看板 - 片段6 (00:21)	也可以通過快捷按鈕選擇週期。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	21.67	24.77	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:20.987679+08	2026-06-12 11:26:53.110862+08	\N	\N	\N	f
26	销售经理驾驶仓数据分析看板 - 片段7 (00:24)	關鍵數據指標可點擊穿透。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	24.77	29.93	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:20.992409+08	2026-06-12 11:26:53.110863+08	\N	\N	\N	f
27	销售经理驾驶仓数据分析看板 - 片段8 (00:29)	毛利結構已拆分到具體業務模塊。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	29.93	36.71	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:20.993267+08	2026-06-12 11:26:53.110864+08	\N	\N	\N	f
28	销售经理驾驶仓数据分析看板 - 片段9 (00:36)	管理層可直觀查看。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	36.71	38.81	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:20.994787+08	2026-06-12 11:26:53.110865+08	\N	\N	\N	f
29	销售经理驾驶仓数据分析看板 - 片段10 (00:38)	從集團、區域到品牌排名。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	38.91	41.71	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:20.999431+08	2026-06-12 11:26:53.110866+08	\N	\N	\N	f
30	销售经理驾驶仓数据分析看板 - 片段11 (00:41)	多維度評估自電情況。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	41.71	44.11	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.000349+08	2026-06-12 11:26:53.110868+08	\N	\N	\N	f
31	销售经理驾驶仓数据分析看板 - 片段12 (00:44)	排名為達圖將各模塊的關鍵指標匯聚。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	44.11	52.02	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.001168+08	2026-06-12 11:26:53.110869+08	\N	\N	\N	f
32	销售经理驾驶仓数据分析看板 - 片段13 (00:52)	強弱向清晰可變。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	52.02	54.22	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.001957+08	2026-06-12 11:26:53.11087+08	\N	\N	\N	f
33	销售经理驾驶仓数据分析看板 - 片段14 (00:54)	業績趨勢圖動態呈現關鍵指標的時間總是。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	54.22	58.62	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.002762+08	2026-06-12 11:26:53.110871+08	\N	\N	\N	f
34	销售经理驾驶仓数据分析看板 - 片段15 (00:58)	直觀把握整體業績的起落規律與波動。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	58.62	63.02	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.00354+08	2026-06-12 11:26:53.110872+08	\N	\N	\N	f
35	销售经理驾驶仓数据分析看板 - 片段16 (01:03)	快速識別改點,預判走向。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	63.02	65.72	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.004348+08	2026-06-12 11:26:53.110873+08	\N	\N	\N	f
36	销售经理驾驶仓数据分析看板 - 片段17 (01:05)	毛利歷史注重圖將歷史數據可視化呈現。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	65.72	69.42	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.005137+08	2026-06-12 11:26:53.110874+08	\N	\N	\N	f
37	销售经理驾驶仓数据分析看板 - 片段18 (01:09)	可查看總毛利和單周毛利。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	69.42	72.52	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.005902+08	2026-06-12 11:26:53.110875+08	\N	\N	\N	f
38	销售经理驾驶仓数据分析看板 - 片段19 (01:12)	依表圖展示的是目標完成率。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	72.62	75.42	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.006691+08	2026-06-12 11:26:53.110876+08	\N	\N	\N	f
39	销售经理驾驶仓数据分析看板 - 片段20 (01:15)	銷售顧問排行榜,包含了目標、客戶轉化率、貢獻率等數據。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	75.42	81.42	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.007494+08	2026-06-12 11:26:53.110877+08	\N	\N	\N	f
40	销售经理驾驶仓数据分析看板 - 片段21 (01:21)	點擊可穿透到個人業績。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	81.42	84.62	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.008259+08	2026-06-12 11:26:53.110878+08	\N	\N	\N	f
41	销售经理驾驶仓数据分析看板 - 片段22 (01:24)	排行榜通過核心指標進行排序。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	84.62	91.76	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.009032+08	2026-06-12 11:26:53.110879+08	\N	\N	\N	f
42	销售经理驾驶仓数据分析看板 - 片段23 (01:31)	可快速識別主力車型與短板車型。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	91.76	94.96	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.010135+08	2026-06-12 11:26:53.11088+08	\N	\N	\N	f
43	销售经理驾驶仓数据分析看板 - 片段24 (01:34)	結合毛利分布圖,車系盈利畫像完整清晰。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	94.96	99.46	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.011638+08	2026-06-12 11:26:53.110882+08	\N	\N	\N	f
44	销售经理驾驶仓数据分析看板 - 片段25 (01:39)	銷售顧問的訂單與交車目標由個人填寫。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	99.46	104.63	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.01297+08	2026-06-12 11:26:53.110883+08	\N	\N	\N	f
45	销售经理驾驶仓数据分析看板 - 片段26 (01:44)	達成率在這個頁面查看。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	104.63	106.83	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.013993+08	2026-06-12 11:26:53.110884+08	\N	\N	\N	f
46	销售经理驾驶仓数据分析看板 - 片段27 (01:46)	全車系目標完成情況,展示各車系的實際業績與目標值的對比數據。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	106.93	112.93	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.014987+08	2026-06-12 11:26:53.110885+08	\N	\N	\N	f
47	销售经理驾驶仓数据分析看板 - 片段28 (01:52)	駕駛艙將持續別帶優化。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	112.93	115.93	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.016034+08	2026-06-12 11:26:53.110886+08	\N	\N	\N	f
48	销售经理驾驶仓数据分析看板 - 片段29 (01:55)	我們會用更精準的數據動差,會業務增長持續負能。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\d3789a887931462fb2705d5bd412783c.mp4	李管理		/uploads/d3789a887931462fb2705d5bd412783c.mp4	115.93	120.43	批量导入,公司制度与规范	\N	\N	1	0	0	approved	\N	\N	1	2026-06-12 10:15:21.017346+08	2026-06-12 11:26:53.110887+08	\N	\N	\N	f
127	测试话术	**客户异议**：测试异议\n\n**应对话术**：测试应对\n\n**完整描述**：这是一个测试话术示例。	text	7	\N	sales	experience	\N	李管理	\N	\N	0	0	赢单话术			1	0	0	pending	\N	\N	1	2026-06-18 13:54:48.844721+08	2026-06-18 13:54:48.844721+08	\N	\N	\N	f
128	别克君越刹车异响，制动盘片磨损	**车型**：���� ����L\n\n**故障现象**：客户反映刹车异常，检查发现制动盘和刹车片磨损严重\n\n**故障码**：\n\n**排查步骤**：检查制动系统，发现前轮制动盘和刹车片磨损至极限\n\n**根本原因**：制动盘和刹车片过度磨损\n\n**维修方案**：更换前轮制动盘和刹车片\n\n**更换配件**：前制动盘，前刹车片	text	15	\N	tech	experience	\N	李管理	\N	\N	0	0	����,����L,安全关键,故障案例	����	����L	1	0	0	pending	\N	\N	1	2026-06-18 14:03:46.63616+08	2026-06-18 14:03:46.63616+08	\N	\N	\N	t
129	销售承诺优惠未兑现引发投诉	**投诉类型**：价格纠纷\n\n**客户诉求**：要求按承诺的8000元优惠执行或退车\n\n**安抚话术**：销售经理道歉并补偿2000元精品券\n\n**处理流程**：客户投诉后，销售经理核实情况并致歉，提出补偿方案，客户最终接受\n\n**处理结果**：客户接受2000元精品券补偿，纠纷解决\n\n**根因归属**：销售过度承诺	text	23	\N	service	experience	\N	李管理	\N	\N	0	0	价格纠纷,销售过度承诺,投诉处理	\N	\N	1	0	0	pending	\N	\N	1	2026-06-18 14:14:11.003469+08	2026-06-18 14:14:11.003469+08	\N	\N	\N	f
130	销售承诺赠品未兑现投诉	**投诉类型**：价格纠纷\n\n**客户诉求**：要求兑现销售承诺的赠品（贴膜）\n\n**安抚话术**：向客户致歉并解释沟通误会，承诺补发赠品\n\n**处理流程**：销售经理与客户协商，核实承诺后补发贴膜\n\n**处理结果**：补发贴膜，客户接受并满意\n\n**根因归属**：销售过度承诺	text	23	\N	service	experience	\N	李管理	\N	\N	0	0	价格纠纷,销售过度承诺,投诉处理	\N	\N	1	0	0	pending	\N	\N	1	2026-06-18 14:15:41.269806+08	2026-06-18 14:15:41.269806+08	\N	\N	\N	f
131	交车PDI未做导致车辆划痕投诉	**投诉类型**：交车问题\n\n**客户诉求**：要求免费处理划痕并道歉\n\n**安抚话术**：向客户道歉并承诺免费处理\n\n**处理流程**：确认PDI遗漏，安排免费修复并致歉\n\n**处理结果**：客户接受道歉和处理方案\n\n**根因归属**：PDI/交车问题	text	23	\N	service	experience	\N	李管理	\N	\N	0	0	交车问题,PDI/交车问题,投诉处理	\N	\N	1	0	0	pending	\N	\N	1	2026-06-18 14:23:23.075917+08	2026-06-18 14:23:23.075917+08	\N	\N	\N	f
117	销售经理驾驶仓数据分析看板 - 片段21 (01:21)	點擊可穿透到個人業績。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	81.42	84.62	批量导入,公司制度与规范	\N	\N	1	1	1	approved	\N	\N	1	2026-06-12 10:53:54.361179+08	2026-06-18 07:30:51.226527+08	\N	\N	\N	f
97	销售经理驾驶仓数据分析看板 - 片段1 (00:02)	銷售經理駕駛艙數據看板,手機和電腦端已同步上線。	video	1	\N	public	video	D:\\HQEvoAI\\uploads\\484d9275b28147aa921c25142f202f77.mp4	李管理		/uploads/484d9275b28147aa921c25142f202f77.mp4	2.9	8.3	批量导入,公司制度与规范	\N	\N	1	1	0	approved	\N	\N	1	2026-06-12 10:53:54.343068+08	2026-06-18 07:30:57.371869+08	\N	\N	\N	f
\.


--
-- Data for Name: knowledge_gaps; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_gaps (id, question, hit_count, target_kb, suggest_category_id, status, assignee_id, related_knowledge_id, created_by, created_at, closed_at) FROM stdin;
1	��˾����ҵ�Ļ�������⣬�ж�����	0	sales	\N	closed	2	\N	2	2026-06-18 05:10:39.78426+08	2026-06-18 05:10:48.129315+08
\.


--
-- Data for Name: learning_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.learning_records (id, user_id, knowledge_id, learn_type, duration_sec, score, created_at) FROM stdin;
1	2	3	view	30	0.00	2026-06-11 04:20:35.883767+08
2	3	1	test	0	100.00	2026-06-12 02:50:22.82727+08
3	3	1	test	0	0.00	2026-06-12 02:50:25.822479+08
4	3	1	test	0	0.00	2026-06-12 02:50:28.647922+08
5	3	1	test	0	100.00	2026-06-12 02:50:30.881789+08
6	3	1	test	0	100.00	2026-06-12 02:50:33.288073+08
7	3	1	test	0	100.00	2026-06-12 02:50:35.578248+08
8	3	1	test	0	0.00	2026-06-12 02:50:37.613582+08
9	4	1	test	0	100.00	2026-06-12 02:52:02.754644+08
10	4	1	test	0	100.00	2026-06-12 02:52:04.945646+08
11	4	1	test	0	0.00	2026-06-12 02:52:07.28839+08
12	4	1	test	0	0.00	2026-06-12 02:52:09.671168+08
13	4	1	test	0	100.00	2026-06-12 02:52:11.58584+08
14	4	1	test	0	0.00	2026-06-12 02:52:13.520449+08
15	4	1	test	0	0.00	2026-06-12 02:52:15.848912+08
16	4	1	test	0	100.00	2026-06-12 02:52:17.763092+08
17	3	1	test	0	100.00	2026-06-12 10:49:25.148166+08
18	3	1	test	0	100.00	2026-06-12 10:49:37.819214+08
19	3	1	test	0	0.00	2026-06-12 10:49:44.261565+08
20	3	1	test	0	100.00	2026-06-12 10:49:48.183084+08
21	3	1	test	0	0.00	2026-06-12 10:49:51.443762+08
22	3	1	test	0	0.00	2026-06-12 10:49:53.870494+08
23	3	1	test	0	0.00	2026-06-12 10:49:57.044295+08
24	3	1	test	0	0.00	2026-06-14 05:58:03.198836+08
25	3	1	test	0	0.00	2026-06-14 05:58:05.87033+08
26	3	1	test	0	0.00	2026-06-14 05:58:07.964843+08
27	3	1	test	0	0.00	2026-06-14 05:58:09.797355+08
28	3	1	test	0	100.00	2026-06-14 05:58:11.541434+08
29	3	1	test	0	0.00	2026-06-14 05:58:13.652731+08
30	3	1	test	0	0.00	2026-06-14 05:58:15.411771+08
31	3	1	test	0	0.00	2026-06-14 05:58:17.581154+08
32	3	1	test	0	0.00	2026-06-14 05:58:19.267962+08
33	4	2	test	0	0.00	2026-06-14 06:05:58.198628+08
34	4	2	test	0	0.00	2026-06-14 06:06:00.325148+08
35	4	1	test	0	0.00	2026-06-14 06:06:02.277943+08
36	4	1	test	0	0.00	2026-06-14 06:06:04.204677+08
37	4	1	test	0	100.00	2026-06-14 06:06:06.027392+08
38	4	1	test	0	100.00	2026-06-14 06:06:08.186884+08
39	4	1	test	0	0.00	2026-06-14 06:06:10.396376+08
40	4	1	test	0	0.00	2026-06-14 06:06:12.780129+08
41	4	1	test	0	0.00	2026-06-14 06:06:14.532441+08
42	4	1	test	0	0.00	2026-06-14 06:06:16.435375+08
43	4	1	test	0	0.00	2026-06-14 06:06:18.860569+08
44	4	1	test	0	0.00	2026-06-14 06:06:20.538713+08
45	4	1	test	0	100.00	2026-06-14 06:06:22.418552+08
46	5	3	test	0	100.00	2026-06-14 06:07:24.085173+08
47	5	3	test	0	100.00	2026-06-14 06:07:28.381426+08
48	5	3	test	0	0.00	2026-06-14 06:07:30.899725+08
49	5	3	test	0	100.00	2026-06-14 06:07:36.678525+08
50	5	3	test	0	100.00	2026-06-14 06:07:39.196183+08
51	5	3	test	0	100.00	2026-06-14 06:07:44.26097+08
52	5	3	test	0	100.00	2026-06-14 06:08:10.228802+08
53	5	3	test	0	0.00	2026-06-14 06:08:12.732425+08
54	5	3	test	0	0.00	2026-06-14 06:08:14.683782+08
55	5	1	test	0	0.00	2026-06-14 06:08:18.180006+08
56	5	1	test	0	0.00	2026-06-14 06:08:20.523838+08
57	5	1	test	0	100.00	2026-06-14 06:08:23.028708+08
58	3	97	test	0	100.00	2026-06-14 06:35:34.518227+08
59	3	97	test	0	100.00	2026-06-14 06:35:41.68699+08
60	3	97	test	0	0.00	2026-06-14 06:35:45.653827+08
61	3	97	test	0	0.00	2026-06-14 06:35:48.932341+08
62	3	97	test	0	100.00	2026-06-14 06:35:51.135454+08
63	5	97	test	0	0.00	2026-06-18 01:38:31.31929+08
64	5	97	test	0	0.00	2026-06-18 01:38:35.507937+08
65	5	97	test	0	100.00	2026-06-18 01:38:42.322324+08
66	5	97	test	0	100.00	2026-06-18 01:38:46.876104+08
67	5	97	test	0	0.00	2026-06-18 01:38:50.497911+08
68	5	97	test	0	0.00	2026-06-18 01:38:53.231798+08
69	5	1	test	0	0.00	2026-06-18 01:38:55.311908+08
70	5	97	test	0	100.00	2026-06-18 01:38:57.441178+08
71	5	97	test	0	0.00	2026-06-18 01:38:59.969622+08
72	5	97	test	0	0.00	2026-06-18 01:39:02.817505+08
73	5	97	test	0	100.00	2026-06-18 01:39:04.619627+08
74	4	13	test	0	100.00	2026-06-18 01:42:27.802133+08
75	4	13	test	0	0.00	2026-06-18 01:42:36.056573+08
76	4	13	test	0	0.00	2026-06-18 01:42:40.625245+08
77	4	13	test	0	0.00	2026-06-18 01:42:43.664701+08
78	4	7	test	0	0.00	2026-06-18 01:42:49.935854+08
79	4	7	test	0	0.00	2026-06-18 01:42:52.409108+08
80	4	7	test	0	0.00	2026-06-18 01:42:54.680869+08
81	4	7	test	0	0.00	2026-06-18 01:42:56.858945+08
82	4	7	test	0	0.00	2026-06-18 01:42:59.600339+08
83	4	7	test	0	0.00	2026-06-18 01:43:01.648333+08
84	4	7	test	0	100.00	2026-06-18 01:43:04.29738+08
85	4	7	test	0	100.00	2026-06-18 01:43:07.241244+08
86	4	7	test	0	100.00	2026-06-18 01:43:09.963187+08
87	4	7	test	0	0.00	2026-06-18 01:43:12.576844+08
88	4	7	test	0	0.00	2026-06-18 01:43:14.985049+08
89	4	7	test	0	0.00	2026-06-18 01:43:16.857415+08
90	4	7	test	0	0.00	2026-06-18 01:43:18.624527+08
91	4	7	test	0	0.00	2026-06-18 01:43:20.872327+08
92	4	7	test	0	0.00	2026-06-18 01:43:23.185785+08
93	4	7	test	0	0.00	2026-06-18 01:43:25.15979+08
94	4	7	test	0	0.00	2026-06-18 01:43:26.777822+08
95	4	7	test	0	0.00	2026-06-18 01:43:29.585286+08
96	4	7	test	0	0.00	2026-06-18 01:43:33.128688+08
97	4	7	test	0	0.00	2026-06-18 01:43:34.967138+08
98	4	7	test	0	0.00	2026-06-18 01:43:37.096336+08
99	4	7	test	0	0.00	2026-06-18 01:43:39.808616+08
100	4	7	test	0	0.00	2026-06-18 01:43:42.016705+08
101	4	7	test	0	0.00	2026-06-18 01:43:44.47238+08
102	4	7	test	0	0.00	2026-06-18 01:43:47.160429+08
103	4	7	test	0	0.00	2026-06-18 01:43:49.58376+08
104	4	7	test	0	0.00	2026-06-18 02:11:11.239291+08
105	4	7	test	0	0.00	2026-06-18 02:11:13.286103+08
106	4	7	test	0	100.00	2026-06-18 02:11:17.728859+08
107	4	7	test	0	100.00	2026-06-18 02:11:21.008454+08
108	4	7	test	0	100.00	2026-06-18 02:11:25.320104+08
109	2	99	view	0	0.00	2026-06-18 07:30:57.944426+08
110	2	102	view	2	0.00	2026-06-18 07:31:03.239058+08
\.


--
-- Data for Name: llm_providers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.llm_providers (id, name, provider_type, base_url, api_key, model_name, is_active, is_default, max_tokens, temperature, created_at, updated_at) FROM stdin;
3	智谱GLM	zhipu	https://open.bigmodel.cn/api/paas/v4		glm-4-flash	f	f	2048	0.7	2026-06-10 13:04:45.702358+08	2026-06-12 02:41:41.199908+08
5	百川智能	baichuan	https://api.baichuan-ai.com/v1		Baichuan4	f	f	2048	0.7	2026-06-10 13:04:45.702364+08	2026-06-12 02:41:41.199908+08
6	讯飞星火	xfyun	https://spark-api-open.xf-yun.com/v1		generalv3.5	f	f	2048	0.7	2026-06-10 13:04:45.702366+08	2026-06-12 02:41:41.199908+08
7	硅基流动	siliconflow	https://api.siliconflow.cn/v1		Qwen/Qwen2.5-7B-Instruct	f	f	2048	0.7	2026-06-10 13:04:45.702369+08	2026-06-12 02:41:41.199908+08
8	Dify平台	dify	https://api.dify.ai/v1		chat-messages	f	f	2048	0.7	2026-06-10 13:04:45.702371+08	2026-06-12 02:41:41.199908+08
4	月之暗面Kimi	kimi	https://api.moonshot.cn/v1	gAAAAABqK2lwEt87cpBumzaHV6jAV-ovjG-67oBwREzAdRPqcHIyZonvZnXmUwN204jWwkrZJs8UKhfHrqoLk-RFZXJbTScDpuR7DbHCyPhIKqwn-zOfl7XHZdH_qs26deTFrp582ciekviFjMp7K-rQw7tB4tPk6Q==	moonshot-v1-8k	t	f	2048	0.7	2026-06-10 13:04:45.702361+08	2026-06-12 02:41:41.199908+08
2	DeepSeek	deepseek	https://api.deepseek.com/v1	gAAAAABqK2lD_TbaW-LYGqVZjQnrrDFHxi4DyJ7Fxb7jF-Rtt4jqQx-vgHYqq8fdHy-gwFgsfFYM68e63TxuzvLYUqke4-zvsnb2YfrxLDLTfy5fueTytNjBwRaKqgq1IMTVn_qv3vMh	deepseek-chat	t	t	2048	0.7	2026-06-10 13:04:45.702355+08	2026-06-12 02:41:41.203508+08
1	通义千问	tongyi	https://dashscope.aliyuncs.com/compatible-mode/v1	gAAAAABqK3H9bIq7qqwBGUaP2ht8EkosLxo_4mnCCrYDeN_16_tlEW2xox0WNFQsxipd9_934vZK7v990CDKq12B0q15Ef8YBYKmtqHENGVVYgWvuG1ogWCBG8Xhpb1vvIaJoF4Co-UI	qwen-plus	f	f	2048	0.7	2026-06-10 13:04:45.70235+08	2026-06-12 02:42:05.443123+08
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
-- Data for Name: sales_deals_import; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sales_deals_import (id, deal_date, car_brand, car_model, deal_price, gross_margin, consultant_name, consultant_id, knowledge_id, source_file, imported_by, created_at) FROM stdin;
\.


--
-- Data for Name: skin_preferences; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.skin_preferences (id, user_id, skin_id, updated_at) FROM stdin;
1	1	1	2026-06-10 13:04:45.731731+08
3	3	1	2026-06-10 13:04:45.731736+08
4	4	1	2026-06-10 13:04:45.731737+08
5	5	1	2026-06-10 13:04:45.731738+08
2	2	2	2026-06-18 06:37:06.880956+08
\.


--
-- Data for Name: stores; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.stores (id, name, address, created_at) FROM stdin;
1	合群旗舰店	市中心主干道888号	2026-06-10 13:04:44.415644+08
2	合群城西店	城西开发区汽车城A区	2026-06-10 13:04:44.415648+08
\.


--
-- Data for Name: system_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.system_config (id, config_key, config_value, config_type, description, updated_at) FROM stdin;
1	points_submit	1	int	提交经验积分	2026-06-10 13:04:45.71091+08
2	points_approved	10	int	审核通过积分	2026-06-10 13:04:45.710913+08
3	points_useful	2	int	被标记有用积分	2026-06-10 13:04:45.710914+08
4	points_monthly_top5	50	int	月度TOP5积分	2026-06-10 13:04:45.710915+08
5	points_daily_question	1	int	每日一题答对积分	2026-06-10 13:04:45.710916+08
6	points_complete_course	3	int	完成课程积分	2026-06-10 13:04:45.710917+08
7	flywheel_view_threshold	5	int	低效经验浏览阈值(<N次)	2026-06-10 13:04:45.710918+08
8	flywheel_month_threshold	6	int	知识更新周期(月)	2026-06-10 13:04:45.710919+08
9	flywheel_useful_rate	0.7	float	有效经验有用率阈值	2026-06-10 13:04:45.71092+08
10	flywheel_low_useful_rate	0.3	float	待优化经验有用率阈值	2026-06-10 13:04:45.710921+08
11	asr_provider	whisper	string	ASR engine: whisper(local) or tencent(cloud)	2026-06-14 14:45:15.25373+08
12	asr_secret_id	gAAAAABqLW39xDgTnn0jjWj1UR40OHjCkmiNtmyW-WjFzJAJ9NF7LsxyUGWPrA2XllJAwWe_YDX-4rQwMWEPHUoncYKVKAxaVwZc7VeJ_ovVNCizK1LkseNjmyaFvrZIRc7XIxnlmQbP	encrypted	Tencent Cloud ASR SecretId	2026-06-14 14:48:30.765506+08
13	asr_secret_key	gAAAAABqLW-ok8tqNul0E0FH1K-6K39CoUXIyh9P1-MGyCX9ITT2v_a39AfshcSGmi1hF8GWMQLrxUUCdgNt2RK2BhVY6_CwSOlle0yu4ZnKKLa7CWbDeclLGIpD2WMJYXgY2ltDj48D	encrypted	Tencent Cloud ASR SecretKey	2026-06-14 14:48:30.771257+08
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, username, real_name, password_hash, role, "position", dept_id, store_id, phone, avatar_url, status, created_at) FROM stdin;
1	boss	张总裁	$2b$12$Khl2ZgnHeOSNNsIuRPdrrucIztkbRzDcJdjAj7wt852kS7KJsIr1a	boss	\N	\N	\N	\N	\N	1	2026-06-10 13:04:45.715873+08
2	admin	李管理	$2b$12$44QX5sviAIsx.v8H6tplCeKuLtmu1r.QduYg1d7S49zyZMtopJ.7u	admin	\N	\N	\N	\N	\N	1	2026-06-10 13:04:45.715876+08
3	sales01	王销售	$2b$12$YJv7JeLNtwapU0J19.Ghx.TFMXWCd92C1ODtdJAq5OCuUnLIutkG.	staff	sales	1	\N	\N	\N	1	2026-06-10 13:04:45.715877+08
4	tech01	赵技师	$2b$12$Dr7VD9pkhNHn8rj7bgmoBeb.nnwOtr44vVyJaDwgnKWZODzuzkGOe	staff	tech	2	\N	\N	\N	1	2026-06-10 13:04:45.715878+08
5	service01	陈客服	$2b$12$/1z7Tmd42eUHcEWMXdSpyeeyUt.ekplWqpbqfuF3kzzDMJxMnRFAi	staff	service	3	\N	\N	\N	1	2026-06-10 13:04:45.71588+08
\.


--
-- Data for Name: vector_index_map; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vector_index_map (id, knowledge_id, chunk_index, chunk_text, embedding_model, vector_store_id, created_at) FROM stdin;
\.


--
-- Data for Name: voice_messages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.voice_messages (id, user_id, audio_path, transcript, transcript_status, related_knowledge_id, tags, created_at) FROM stdin;
\.


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 60, true);


--
-- Name: chat_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.chat_logs_id_seq', 3, true);


--
-- Name: cross_line_tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cross_line_tasks_id_seq', 1, true);


--
-- Name: daily_questions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_questions_id_seq', 87, true);


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.departments_id_seq', 3, true);


--
-- Name: exam_attempts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.exam_attempts_id_seq', 4, true);


--
-- Name: exam_papers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.exam_papers_id_seq', 3, true);


--
-- Name: exam_papers_questions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.exam_papers_questions_id_seq', 40, true);


--
-- Name: experience_points_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.experience_points_id_seq', 46, true);


--
-- Name: knowledge_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_categories_id_seq', 30, true);


--
-- Name: knowledge_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_entries_id_seq', 131, true);


--
-- Name: knowledge_gaps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_gaps_id_seq', 1, true);


--
-- Name: learning_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.learning_records_id_seq', 110, true);


--
-- Name: llm_providers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.llm_providers_id_seq', 8, true);


--
-- Name: position_capabilities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.position_capabilities_id_seq', 55, true);


--
-- Name: sales_deals_import_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sales_deals_import_id_seq', 1, false);


--
-- Name: skin_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skin_preferences_id_seq', 5, true);


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

SELECT pg_catalog.setval('public.users_id_seq', 5, true);


--
-- Name: vector_index_map_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vector_index_map_id_seq', 1, false);


--
-- Name: voice_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.voice_messages_id_seq', 1, false);


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
-- Name: cross_line_tasks cross_line_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cross_line_tasks
    ADD CONSTRAINT cross_line_tasks_pkey PRIMARY KEY (id);


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
-- Name: knowledge_gaps knowledge_gaps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_gaps
    ADD CONSTRAINT knowledge_gaps_pkey PRIMARY KEY (id);


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
-- Name: sales_deals_import sales_deals_import_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_deals_import
    ADD CONSTRAINT sales_deals_import_pkey PRIMARY KEY (id);


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
-- Name: cross_line_tasks cross_line_tasks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cross_line_tasks
    ADD CONSTRAINT cross_line_tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: cross_line_tasks cross_line_tasks_source_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cross_line_tasks
    ADD CONSTRAINT cross_line_tasks_source_entry_id_fkey FOREIGN KEY (source_entry_id) REFERENCES public.knowledge_entries(id) ON DELETE SET NULL;


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
-- Name: knowledge_gaps knowledge_gaps_assignee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_gaps
    ADD CONSTRAINT knowledge_gaps_assignee_id_fkey FOREIGN KEY (assignee_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: knowledge_gaps knowledge_gaps_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_gaps
    ADD CONSTRAINT knowledge_gaps_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: knowledge_gaps knowledge_gaps_related_knowledge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_gaps
    ADD CONSTRAINT knowledge_gaps_related_knowledge_id_fkey FOREIGN KEY (related_knowledge_id) REFERENCES public.knowledge_entries(id) ON DELETE SET NULL;


--
-- Name: knowledge_gaps knowledge_gaps_suggest_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_gaps
    ADD CONSTRAINT knowledge_gaps_suggest_category_id_fkey FOREIGN KEY (suggest_category_id) REFERENCES public.knowledge_categories(id) ON DELETE SET NULL;


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
-- Name: sales_deals_import sales_deals_import_consultant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_deals_import
    ADD CONSTRAINT sales_deals_import_consultant_id_fkey FOREIGN KEY (consultant_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: sales_deals_import sales_deals_import_imported_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_deals_import
    ADD CONSTRAINT sales_deals_import_imported_by_fkey FOREIGN KEY (imported_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: sales_deals_import sales_deals_import_knowledge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_deals_import
    ADD CONSTRAINT sales_deals_import_knowledge_id_fkey FOREIGN KEY (knowledge_id) REFERENCES public.knowledge_entries(id) ON DELETE SET NULL;


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
-- PostgreSQL database dump complete
--

\unrestrict mLeDUSe8mzXTGPHXxtZ4ic2xrwZvzdVa4KD2CY2waca7t4ouhNVrTtkrBlJysbX

