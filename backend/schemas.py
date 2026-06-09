"""
Pydantic 请求/响应模型
"""
from datetime import datetime
from typing import Optional, Any
from pydantic import BaseModel, Field


# ============================================================
# 通用
# ============================================================

class ApiResponse(BaseModel):
    code: int = 0
    data: Any = None
    msg: str = "ok"


class PageParams(BaseModel):
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    keyword: Optional[str] = None


# ============================================================
# 登录/用户
# ============================================================

class LoginRequest(BaseModel):
    username: str = Field(..., min_length=1, max_length=50)
    password: str = Field(..., min_length=1)


class LoginResponse(BaseModel):
    token: str
    user_id: int
    username: str
    real_name: str
    role: str
    position: Optional[str] = None
    skin_id: int = 1


class UserInfo(BaseModel):
    id: int
    username: str
    real_name: str
    role: str
    position: Optional[str] = None
    dept_id: Optional[int] = None
    store_id: Optional[int] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    status: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class UserCreate(BaseModel):
    username: str = Field(..., min_length=1, max_length=50)
    real_name: str = Field(..., min_length=1, max_length=50)
    password: str = Field(..., min_length=1, max_length=100)
    role: str = "staff"
    position: Optional[str] = None
    dept_id: Optional[int] = None
    store_id: Optional[int] = None
    phone: Optional[str] = None


class UserUpdate(BaseModel):
    real_name: Optional[str] = None
    password: Optional[str] = None
    role: Optional[str] = None
    position: Optional[str] = None
    dept_id: Optional[int] = None
    store_id: Optional[int] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None


class SkinUpdate(BaseModel):
    skin_id: int = Field(..., ge=1, le=8)


# ============================================================
# 知识分类
# ============================================================

class CategoryOut(BaseModel):
    id: int
    name: str
    parent_id: Optional[int] = None
    knowledge_base: str
    sort_order: int
    icon: Optional[str] = None
    children: list["CategoryOut"] = []

    class Config:
        from_attributes = True


# ============================================================
# 知识条目
# ============================================================

class KnowledgeCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str = ""
    content_type: str = "text"
    category_id: int
    knowledge_base: str
    source_type: str = "manual"
    tags: Optional[str] = None
    car_brand: Optional[str] = None
    car_model: Optional[str] = None
    difficulty_level: int = 1


class KnowledgeUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    category_id: Optional[int] = None
    knowledge_base: Optional[str] = None
    tags: Optional[str] = None
    car_brand: Optional[str] = None
    car_model: Optional[str] = None
    difficulty_level: Optional[int] = None


class KnowledgeOut(BaseModel):
    id: int
    title: str
    content: str
    content_type: str
    category_id: int
    knowledge_base: str
    source_type: str
    source_person: Optional[str] = None
    source_dept: Optional[str] = None
    tags: Optional[str] = None
    car_brand: Optional[str] = None
    car_model: Optional[str] = None
    difficulty_level: int
    view_count: int
    useful_count: int
    status: str
    version: int
    media_url: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ============================================================
# 审核
# ============================================================

class RejectRequest(BaseModel):
    audit_comment: str = Field(..., min_length=1, max_length=500)


# ============================================================
# LLM 配置
# ============================================================

class LLMProviderUpdate(BaseModel):
    name: Optional[str] = None
    base_url: Optional[str] = None
    api_key: Optional[str] = None
    model_name: Optional[str] = None
    is_active: Optional[bool] = None
    max_tokens: Optional[int] = None
    temperature: Optional[float] = None


class LLMProviderCreate(BaseModel):
    name: str
    provider_type: str = "custom"
    base_url: str
    api_key: str = ""
    model_name: str


# ============================================================
# 系统设置
# ============================================================

class SettingUpdate(BaseModel):
    config_key: str
    config_value: str
