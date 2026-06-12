"""
SQLAlchemy ORM 模型 —— 全部14张表（audit_logs 用原生SQL，不建ORM）
每个 Enum 先定义 Python enum，再用 SQLAlchemy Enum 映射到 PG 自定义类型

Python 3.14 兼容：自引用 relationship 不用 Mapped[] 包装
"""
import enum
from datetime import datetime
from typing import Optional, List

from sqlalchemy import (
    Enum, JSON, ForeignKey, String, Text, Integer, SmallInteger,
    BigInteger, Float, Boolean, DateTime, CheckConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


# ============================================================
# Python Enum 定义（与 PG 自定义类型对应）
# ============================================================

class UserRoleEnum(str, enum.Enum):
    boss = "boss"
    admin = "admin"
    staff = "staff"


class UserPositionEnum(str, enum.Enum):
    sales = "sales"
    tech = "tech"
    service = "service"
    clerk = "clerk"


class KnowledgeBaseEnum(str, enum.Enum):
    public = "public"
    sales = "sales"
    tech = "tech"
    service = "service"


class ContentTypeEnum(str, enum.Enum):
    text = "text"
    video = "video"
    audio = "audio"
    image = "image"


class SourceTypeEnum(str, enum.Enum):
    manual = "manual"
    experience = "experience"
    exam = "exam"
    policy = "policy"
    video = "video"
    audio = "audio"


class EntryStatusEnum(str, enum.Enum):
    draft = "draft"
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
    archived = "archived"


class PointActionEnum(str, enum.Enum):
    submit = "submit"
    approved = "approved"
    used = "used"


class TranscriptStatusEnum(str, enum.Enum):
    pending = "pending"
    done = "done"
    failed = "failed"


class QuestionTypeEnum(str, enum.Enum):
    single_choice = "single_choice"
    multi_choice = "multi_choice"
    true_false = "true_false"
    fill_blank = "fill_blank"


class LLMProviderTypeEnum(str, enum.Enum):
    tongyi = "tongyi"
    deepseek = "deepseek"
    zhipu = "zhipu"
    kimi = "kimi"
    baichuan = "baichuan"
    xfyun = "xfyun"
    siliconflow = "siliconflow"
    dify = "dify"
    custom = "custom"


# ============================================================
# ORM 模型（14张表）
# ============================================================

class Department(Base):
    __tablename__ = "departments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    parent_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("departments.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    # 自引用：避开 Python 3.14 Mapped[Optional["Department"]] bug
    parent = relationship("Department", remote_side="Department.id", backref="children")


class Store(Base):
    __tablename__ = "stores"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    address: Mapped[Optional[str]] = mapped_column(String(300), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    real_name: Mapped[str] = mapped_column(String(50), nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRoleEnum] = mapped_column(
        Enum(UserRoleEnum, name="user_role_enum", create_type=False),
        default=UserRoleEnum.staff
    )
    position: Mapped[Optional[UserPositionEnum]] = mapped_column(
        Enum(UserPositionEnum, name="user_position_enum", create_type=False),
        nullable=True
    )
    dept_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("departments.id", ondelete="SET NULL"), nullable=True
    )
    store_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("stores.id", ondelete="SET NULL"), nullable=True
    )
    phone: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    avatar_url: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    status: Mapped[int] = mapped_column(SmallInteger, default=1, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    dept = relationship("Department")
    store = relationship("Store")


class KnowledgeCategory(Base):
    __tablename__ = "knowledge_categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    parent_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("knowledge_categories.id", ondelete="SET NULL"), nullable=True
    )
    knowledge_base: Mapped[KnowledgeBaseEnum] = mapped_column(
        Enum(KnowledgeBaseEnum, name="knowledge_base_enum", create_type=False),
        nullable=False
    )
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    icon: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    description: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    # 自引用：避开 Python 3.14 Mapped[Optional["KnowledgeCategory"]] bug
    parent = relationship(
        "KnowledgeCategory", remote_side="KnowledgeCategory.id", backref="children"
    )


class KnowledgeEntry(Base):
    __tablename__ = "knowledge_entries"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    content: Mapped[str] = mapped_column(Text, default="", nullable=False)
    content_type: Mapped[ContentTypeEnum] = mapped_column(
        Enum(ContentTypeEnum, name="content_type_enum", create_type=False),
        default=ContentTypeEnum.text
    )
    category_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("knowledge_categories.id", ondelete="RESTRICT"), nullable=False
    )
    sub_category: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    knowledge_base: Mapped[KnowledgeBaseEnum] = mapped_column(
        Enum(KnowledgeBaseEnum, name="knowledge_base_enum", create_type=False),
        nullable=False
    )
    source_type: Mapped[SourceTypeEnum] = mapped_column(
        Enum(SourceTypeEnum, name="source_type_enum", create_type=False),
        default=SourceTypeEnum.manual
    )
    source_file_path: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    source_person: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    source_dept: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    media_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    media_start_sec: Mapped[Optional[float]] = mapped_column(Float, default=0)
    media_end_sec: Mapped[Optional[float]] = mapped_column(Float, default=0)
    tags: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    car_brand: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    car_model: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    difficulty_level: Mapped[int] = mapped_column(SmallInteger, default=1)
    view_count: Mapped[int] = mapped_column(Integer, default=0)
    useful_count: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[EntryStatusEnum] = mapped_column(
        Enum(EntryStatusEnum, name="entry_status_enum", create_type=False),
        default=EntryStatusEnum.draft
    )
    auditor_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    audit_comment: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    version: Mapped[int] = mapped_column(Integer, default=1)
    # embedding 字段在 pgvector 扩展可用时通过 init.sql 添加
    # ORM 不管理此字段，避免 pgvector 不可用时 INSERT 失败
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow
    )

    category = relationship("KnowledgeCategory")
    auditor = relationship("User")
    __table_args__ = (
        CheckConstraint("difficulty_level BETWEEN 1 AND 5", name="ck_ke_difficulty"),
    )


class ExperiencePoint(Base):
    __tablename__ = "experience_points"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    knowledge_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("knowledge_entries.id", ondelete="SET NULL"), nullable=True
    )
    points: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    action_type: Mapped[PointActionEnum] = mapped_column(
        Enum(PointActionEnum, name="point_action_enum", create_type=False),
        nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    user = relationship("User")


class LearningRecord(Base):
    __tablename__ = "learning_records"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    knowledge_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("knowledge_entries.id", ondelete="CASCADE"), nullable=False
    )
    learn_type: Mapped[str] = mapped_column(String(20), default="view", nullable=False)
    duration_sec: Mapped[int] = mapped_column(Integer, default=0)
    score: Mapped[Optional[float]] = mapped_column(Float(asdecimal=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    user = relationship("User")
    knowledge = relationship("KnowledgeEntry")


class VoiceMessage(Base):
    __tablename__ = "voice_messages"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    audio_path: Mapped[str] = mapped_column(String(500), nullable=False)
    transcript: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    transcript_status: Mapped[TranscriptStatusEnum] = mapped_column(
        Enum(TranscriptStatusEnum, name="transcript_status_enum", create_type=False),
        default=TranscriptStatusEnum.pending
    )
    related_knowledge_id: Mapped[Optional[int]] = mapped_column(
        BigInteger, ForeignKey("knowledge_entries.id", ondelete="SET NULL"), nullable=True
    )
    tags: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    user = relationship("User")


class VectorIndexMap(Base):
    __tablename__ = "vector_index_map"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    knowledge_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("knowledge_entries.id", ondelete="CASCADE"), nullable=False
    )
    chunk_index: Mapped[int] = mapped_column(Integer, default=0)
    chunk_text: Mapped[str] = mapped_column(Text, nullable=False)
    embedding_model: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    vector_store_id: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)


class DailyQuestion(Base):
    __tablename__ = "daily_questions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    question_type: Mapped[QuestionTypeEnum] = mapped_column(
        Enum(QuestionTypeEnum, name="question_type_enum", create_type=False),
        default=QuestionTypeEnum.single_choice
    )
    question_content: Mapped[str] = mapped_column(Text, nullable=False)
    options: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    answer: Mapped[str] = mapped_column(Text, nullable=False)
    explanation: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    target_position: Mapped[Optional[UserPositionEnum]] = mapped_column(
        Enum(UserPositionEnum, name="user_position_enum", create_type=False),
        nullable=True
    )
    difficulty_level: Mapped[int] = mapped_column(SmallInteger, default=1)
    related_knowledge_id: Mapped[Optional[int]] = mapped_column(
        BigInteger, ForeignKey("knowledge_entries.id", ondelete="SET NULL"), nullable=True
    )
    category_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("knowledge_categories.id", ondelete="SET NULL"), nullable=True
    )
    tags: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    push_date: Mapped[Optional[datetime]] = mapped_column(nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    __table_args__ = (
        CheckConstraint("difficulty_level BETWEEN 1 AND 5", name="ck_dq_difficulty"),
    )


class ChatLog(Base):
    __tablename__ = "chat_logs"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    question: Mapped[str] = mapped_column(Text, nullable=False)
    answer: Mapped[str] = mapped_column(Text, default="", nullable=False)
    references_json: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    is_satisfied: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)
    is_hit: Mapped[int] = mapped_column(SmallInteger, default=1)
    response_time_ms: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    user = relationship("User")


class SkinPreference(Base):
    __tablename__ = "skin_preferences"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    skin_id: Mapped[int] = mapped_column(SmallInteger, default=1, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow
    )

    user = relationship("User")
    __table_args__ = (
        CheckConstraint("skin_id BETWEEN 1 AND 8", name="ck_sp_skin"),
    )


class LLMProvider(Base):
    __tablename__ = "llm_providers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    provider_type: Mapped[LLMProviderTypeEnum] = mapped_column(
        Enum(LLMProviderTypeEnum, name="llm_provider_type_enum", create_type=False),
        nullable=False
    )
    base_url: Mapped[str] = mapped_column(String(500), nullable=False)
    api_key: Mapped[str] = mapped_column(String(500), default="", nullable=False)
    model_name: Mapped[str] = mapped_column(String(100), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    max_tokens: Mapped[int] = mapped_column(Integer, default=2048)
    temperature: Mapped[float] = mapped_column(Float, default=0.7)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow
    )


class SystemConfig(Base):
    __tablename__ = "system_config"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    config_key: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    config_value: Mapped[str] = mapped_column(Text, nullable=False)
    config_type: Mapped[str] = mapped_column(String(20), default="string", nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow
    )
