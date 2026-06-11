"""
知识条目路由 —— 列表(岗位隔离) / 热门 / 最新 / 详情 / 管理CRUD / 经验提交
注意：固定路径路由必须在 {entry_id} 路径参数路由之前注册
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, or_

from database import async_session
from models import KnowledgeEntry, KnowledgeCategory, ExperiencePoint, Department
from schemas import ApiResponse, KnowledgeCreate, KnowledgeUpdate
from auth import get_current_user, require_admin
from models import User, EntryStatusEnum, PointActionEnum, SourceTypeEnum

router = APIRouter()

# 岗位 → 知识库可见映射
POSITION_KB_MAP = {
    "sales": ["public", "sales"],
    "tech": ["public", "tech"],
    "service": ["public", "service"],
}


def _kb_filter(user: User) -> list[str]:
    """根据用户角色和岗位返回可见知识库列表"""
    if user.role.value in ("admin", "boss"):
        return ["public", "sales", "tech", "service"]
    pos = user.position.value if user.position else "sales"
    return POSITION_KB_MAP.get(pos, ["public"])


# ============================================================
# 固定路径路由（必须在 {entry_id} 之前！）
# ============================================================

@router.get("/knowledge/unified", response_model=ApiResponse)
async def unified_search(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    keyword: str = Query("", max_length=200),
    category_id: int = Query(0),
    knowledge_base: str = Query("", max_length=20),
    item_type: str = Query("all", max_length=20),
    user: User = Depends(get_current_user),
):
    """
    统一搜索：知识条目 + 每日试题
    item_type: all | knowledge | question
    """
    allowed_kb = _kb_filter(user)
    results = []
    total = 0

    async with async_session() as db:
        # === 知识条目 ===
        if item_type in ("all", "knowledge"):
            q = select(
                KnowledgeEntry.id, KnowledgeEntry.title,
                KnowledgeEntry.content, KnowledgeEntry.knowledge_base,
                KnowledgeEntry.category_id, KnowledgeEntry.view_count,
                KnowledgeEntry.useful_count, KnowledgeEntry.tags,
                KnowledgeEntry.car_brand, KnowledgeEntry.car_model,
                KnowledgeEntry.difficulty_level, KnowledgeEntry.created_at,
            ).where(
                KnowledgeEntry.status == "approved",
                KnowledgeEntry.knowledge_base.in_(allowed_kb),
            )
            cq = select(func.count(KnowledgeEntry.id)).where(
                KnowledgeEntry.status == "approved",
                KnowledgeEntry.knowledge_base.in_(allowed_kb),
            )
            if keyword:
                like = f"%{keyword}%"
                kf = or_(KnowledgeEntry.title.ilike(like), KnowledgeEntry.content.ilike(like), KnowledgeEntry.tags.ilike(like))
                q = q.where(kf); cq = cq.where(kf)
            if category_id > 0:
                q = q.where(KnowledgeEntry.category_id == category_id)
                cq = cq.where(KnowledgeEntry.category_id == category_id)
            if knowledge_base and knowledge_base in allowed_kb:
                q = q.where(KnowledgeEntry.knowledge_base == knowledge_base)
                cq = cq.where(KnowledgeEntry.knowledge_base == knowledge_base)

            ke_total = (await db.execute(cq)).scalar() or 0
            ke_rows = (await db.execute(q.order_by(KnowledgeEntry.created_at.desc()).limit(page_size).offset((page-1)*page_size))).all()
            for r in ke_rows:
                results.append({
                    "id": r[0], "title": r[1], "content": (r[2] or "")[:150],
                    "knowledge_base": r[3], "category_id": r[4],
                    "view_count": r[5], "useful_count": r[6], "tags": r[7],
                    "car_brand": r[8], "car_model": r[9],
                    "difficulty_level": r[10],
                    "created_at": r[11].isoformat() if r[11] else None,
                    "item_type": "knowledge",
                })
            total += ke_total

        # === 试题 ===
        if item_type in ("all", "question"):
            from models import DailyQuestion as DQ
            qq = select(
                DQ.id, DQ.question_content,
                DQ.question_type, DQ.target_position,
                DQ.category_id, DQ.difficulty_level,
                DQ.tags, DQ.created_at,
            )
            c2 = select(func.count(DQ.id))
            if keyword:
                like = f"%{keyword}%"
                qq = qq.where(DQ.question_content.ilike(like))
                c2 = c2.where(DQ.question_content.ilike(like))
            if category_id > 0:
                qq = qq.where(DQ.category_id == category_id)
                c2 = c2.where(DQ.category_id == category_id)
            if knowledge_base:
                # 试题没有 knowledge_base，按 target_position 近似匹配
                # 查询该 kb 下的分类 ID，然后匹配 questions 的 category_id
                cat_ids_r = await db.execute(
                    select(KnowledgeCategory.id).where(KnowledgeCategory.knowledge_base == knowledge_base)
                )
                cat_ids = [r[0] for r in cat_ids_r]
                if cat_ids:
                    qq = qq.where(DQ.category_id.in_(cat_ids))
                    c2 = c2.where(DQ.category_id.in_(cat_ids))
                else:
                    qq = qq.where(DQ.id == -1)  # 无匹配时返回空
                    c2 = c2.where(DQ.id == -1)

            q_total = (await db.execute(c2)).scalar() or 0
            q_rows = (await db.execute(qq.order_by(DQ.created_at.desc()).limit(page_size).offset((page-1)*page_size))).all()
            for r in q_rows:
                qt_val = r[2]
                qt_str = qt_val.value if hasattr(qt_val, 'value') else str(qt_val)
                results.append({
                    "id": r[0], "title": str(r[1])[:100],
                    "content": str(r[1])[:150],
                    "knowledge_base": "public",
                    "category_id": r[4],
                    "view_count": 0,
                    "question_type": qt_str,
                    "target_position": r[3],
                    "difficulty_level": r[5] or 1,
                    "tags": r[6],
                    "created_at": r[7].isoformat() if r[7] else None,
                    "item_type": "question",
                })
            total += q_total

    # 按时间排序并分页
    results.sort(key=lambda x: x.get("created_at") or "", reverse=True)
    results = results[:page_size]

    return ApiResponse(data={"items": results, "total": total, "page": page, "page_size": page_size})


@router.get("/knowledge/hot", response_model=ApiResponse)
async def hot_knowledge(user: User = Depends(get_current_user)):
    """热门知识 TOP10"""
    allowed_kb = _kb_filter(user)
    async with async_session() as db:
        rows = (await db.execute(
            select(KnowledgeEntry.id, KnowledgeEntry.title, KnowledgeEntry.view_count, KnowledgeEntry.knowledge_base)
            .where(KnowledgeEntry.status == "approved", KnowledgeEntry.knowledge_base.in_(allowed_kb))
            .order_by(KnowledgeEntry.view_count.desc())
            .limit(10)
        )).all()
        items = [{"id": r[0], "title": r[1], "view_count": r[2], "knowledge_base": r[3]} for r in rows]
    return ApiResponse(data=items)


@router.get("/knowledge/latest", response_model=ApiResponse)
async def latest_knowledge(user: User = Depends(get_current_user)):
    """最新知识 TOP10"""
    allowed_kb = _kb_filter(user)
    async with async_session() as db:
        rows = (await db.execute(
            select(KnowledgeEntry.id, KnowledgeEntry.title, KnowledgeEntry.car_brand, KnowledgeEntry.created_at, KnowledgeEntry.knowledge_base)
            .where(KnowledgeEntry.status == "approved", KnowledgeEntry.knowledge_base.in_(allowed_kb))
            .order_by(KnowledgeEntry.created_at.desc())
            .limit(10)
        )).all()
        items = [{"id": r[0], "title": r[1], "car_brand": r[2],
                  "created_at": r[3].isoformat() if r[3] else None, "knowledge_base": r[4]} for r in rows]
    return ApiResponse(data=items)


# ============================================================
# 职员端 —— 列表 + 详情
# ============================================================

@router.get("/knowledge", response_model=ApiResponse)
async def list_knowledge(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    keyword: str = Query("", max_length=200),
    category_id: int = Query(0),
    knowledge_base: str = Query("", max_length=20),
    car_brand: str = Query("", max_length=50),
    sort_by: str = Query("created_at"),
    user: User = Depends(get_current_user),
):
    """知识列表（分页/搜索/筛选）+ 职员岗位自动隔离"""
    allowed_kb = _kb_filter(user)

    async with async_session() as db:
        q = select(KnowledgeEntry).where(
            KnowledgeEntry.status == "approved",
            KnowledgeEntry.knowledge_base.in_(allowed_kb),
        )
        count_q = select(func.count(KnowledgeEntry.id)).where(
            KnowledgeEntry.status == "approved",
            KnowledgeEntry.knowledge_base.in_(allowed_kb),
        )
        if keyword:
            like = f"%{keyword}%"
            kf = or_(KnowledgeEntry.title.ilike(like), KnowledgeEntry.content.ilike(like), KnowledgeEntry.tags.ilike(like))
            q = q.where(kf)
            count_q = count_q.where(kf)
        if category_id > 0:
            q = q.where(KnowledgeEntry.category_id == category_id)
            count_q = count_q.where(KnowledgeEntry.category_id == category_id)
        if knowledge_base and knowledge_base in allowed_kb:
            q = q.where(KnowledgeEntry.knowledge_base == knowledge_base)
            count_q = count_q.where(KnowledgeEntry.knowledge_base == knowledge_base)
        if car_brand:
            q = q.where(KnowledgeEntry.car_brand == car_brand)
            count_q = count_q.where(KnowledgeEntry.car_brand == car_brand)

        sort_map = {
            "created_at": KnowledgeEntry.created_at.desc(),
            "view_count": KnowledgeEntry.view_count.desc(),
            "useful_count": KnowledgeEntry.useful_count.desc(),
            "title": KnowledgeEntry.title.asc(),
        }
        order = sort_map.get(sort_by, KnowledgeEntry.created_at.desc())

        total = (await db.execute(count_q)).scalar() or 0
        rows = (await db.execute(
            q.order_by(order).offset((page - 1) * page_size).limit(page_size)
        )).scalars().all()

        items = [_entry_summary(k) for k in rows]
    return ApiResponse(data={"items": items, "total": total, "page": page, "page_size": page_size})


@router.get("/knowledge/{entry_id}", response_model=ApiResponse)
async def get_knowledge_detail(entry_id: int, user: User = Depends(get_current_user)):
    """知识详情 + 浏览计数 + 相关推荐"""
    allowed_kb = _kb_filter(user)

    async with async_session() as db:
        result = await db.execute(
            select(KnowledgeEntry).where(
                KnowledgeEntry.id == entry_id,
                KnowledgeEntry.status == "approved",
                KnowledgeEntry.knowledge_base.in_(allowed_kb),
            )
        )
        entry = result.scalar_one_or_none()
        if not entry:
            raise HTTPException(status_code=404, detail="知识不存在或无权查看")

        entry.view_count = (entry.view_count or 0) + 1

        cat_result = await db.execute(
            select(KnowledgeCategory.name).where(KnowledgeCategory.id == entry.category_id)
        )
        cat_name = cat_result.scalar_one_or_none()

        related_result = await db.execute(
            select(KnowledgeEntry.id, KnowledgeEntry.title)
            .where(
                KnowledgeEntry.category_id == entry.category_id,
                KnowledgeEntry.status == "approved",
                KnowledgeEntry.id != entry.id,
                KnowledgeEntry.knowledge_base.in_(allowed_kb),
            )
            .order_by(KnowledgeEntry.view_count.desc())
            .limit(5)
        )
        related = [{"id": r[0], "title": r[1]} for r in related_result.all()]

        await db.commit()

        data = {
            "id": entry.id, "title": entry.title, "content": entry.content,
            "content_type": entry.content_type.value,
            "category_id": entry.category_id, "category_name": cat_name,
            "knowledge_base": entry.knowledge_base.value,
            "source_type": entry.source_type.value,
            "source_person": entry.source_person, "source_dept": entry.source_dept,
            "media_url": entry.media_url,
            "media_start_sec": entry.media_start_sec, "media_end_sec": entry.media_end_sec,
            "tags": entry.tags, "car_brand": entry.car_brand, "car_model": entry.car_model,
            "difficulty_level": entry.difficulty_level,
            "view_count": entry.view_count, "useful_count": entry.useful_count,
            "status": entry.status.value, "version": entry.version,
            "created_at": entry.created_at.isoformat() if entry.created_at else None,
            "updated_at": entry.updated_at.isoformat() if entry.updated_at else None,
            "related": related,
        }
    return ApiResponse(data=data)


# ============================================================
# 管理员端 —— CRUD
# ============================================================

@router.post("/knowledge", response_model=ApiResponse)
async def create_knowledge(body: KnowledgeCreate, user: User = Depends(require_admin)):
    """管理员：新增知识"""
    async with async_session() as db:
        entry = KnowledgeEntry(
            title=body.title, content=body.content, content_type=body.content_type,
            category_id=body.category_id, knowledge_base=body.knowledge_base,
            source_type=body.source_type, tags=body.tags,
            car_brand=body.car_brand, car_model=body.car_model,
            difficulty_level=body.difficulty_level, status=EntryStatusEnum.approved,
            source_person=user.real_name,
        )
        db.add(entry)
        await db.commit()
        await db.refresh(entry)
    return ApiResponse(data={"id": entry.id}, msg="知识创建成功")


@router.put("/knowledge/{entry_id}", response_model=ApiResponse)
async def update_knowledge(entry_id: int, body: KnowledgeUpdate, _admin: User = Depends(require_admin)):
    """管理员：编辑知识"""
    async with async_session() as db:
        result = await db.execute(select(KnowledgeEntry).where(KnowledgeEntry.id == entry_id))
        entry = result.scalar_one_or_none()
        if not entry:
            raise HTTPException(status_code=404, detail="知识不存在")
        for field in ["title", "content", "category_id", "knowledge_base", "tags", "car_brand", "car_model", "difficulty_level"]:
            val = getattr(body, field, None)
            if val is not None:
                setattr(entry, field, val)
        await db.commit()
    return ApiResponse(msg="知识已更新")


@router.put("/knowledge/{entry_id}/status", response_model=ApiResponse)
async def change_status(entry_id: int, _admin: User = Depends(require_admin), status: str = Query("", max_length=20)):
    """管理员：变更知识状态"""
    async with async_session() as db:
        result = await db.execute(select(KnowledgeEntry).where(KnowledgeEntry.id == entry_id))
        entry = result.scalar_one_or_none()
        if not entry:
            raise HTTPException(status_code=404, detail="知识不存在")
        if status not in {"draft", "pending", "approved", "rejected", "archived"}:
            raise HTTPException(status_code=400, detail=f"无效状态：{status}")
        entry.status = status
        await db.commit()
    return ApiResponse(msg="状态已变更")


@router.delete("/knowledge/{entry_id}", response_model=ApiResponse)
async def archive_knowledge(entry_id: int, _admin: User = Depends(require_admin)):
    """软删除"""
    async with async_session() as db:
        result = await db.execute(select(KnowledgeEntry).where(KnowledgeEntry.id == entry_id))
        entry = result.scalar_one_or_none()
        if not entry:
            raise HTTPException(status_code=404, detail="知识不存在")
        entry.status = EntryStatusEnum.archived
        await db.commit()
    return ApiResponse(msg="知识已归档")


# ============================================================
# 职员端 —— 经验提交 + 有用标记
# ============================================================

@router.post("/knowledge/submit-experience", response_model=ApiResponse)
async def submit_experience(body: KnowledgeCreate, user: User = Depends(get_current_user)):
    """职员：提交经验 → status='pending', +1 积分"""
    async with async_session() as db:
        # 查部门名（user.dept 是 lazy load，session 已关闭）
        dname = None
        if user.dept_id:
            dept_r = await db.execute(
                select(Department.name).where(Department.id == user.dept_id)
            )
            dname = dept_r.scalar_one_or_none()

        entry = KnowledgeEntry(
            title=body.title,
            content=body.content,
            content_type=body.content_type,
            category_id=body.category_id,
            knowledge_base=body.knowledge_base,
            source_type=SourceTypeEnum.experience,
            tags=body.tags,
            car_brand=body.car_brand,
            car_model=body.car_model,
            difficulty_level=body.difficulty_level,
            status=EntryStatusEnum.pending,
            source_person=user.real_name,
            source_dept=dname,
        )
        db.add(entry)
        await db.flush()

        # +1 提交积分
        db.add(ExperiencePoint(
            user_id=user.id,
            knowledge_id=entry.id,
            points=1,
            action_type=PointActionEnum.submit,
        ))
        await db.commit()
        await db.refresh(entry)
    return ApiResponse(data={"id": entry.id}, msg="经验已提交，等待审核")


@router.post("/knowledge/{entry_id}/useful", response_model=ApiResponse)
async def mark_useful(entry_id: int, user: User = Depends(get_current_user)):
    """标记有用 → useful_count +1, 提交者 +2 积分"""
    async with async_session() as db:
        result = await db.execute(select(KnowledgeEntry).where(KnowledgeEntry.id == entry_id))
        entry = result.scalar_one_or_none()
        if not entry:
            raise HTTPException(status_code=404, detail="知识不存在")

        entry.useful_count = (entry.useful_count or 0) + 1

        # 给提交人 +2 积分
        if entry.source_person:
            sub_r = await db.execute(
                select(User.id).where(User.real_name == entry.source_person)
            )
            sub = sub_r.scalar_one_or_none()
            if sub:
                db.add(ExperiencePoint(
                    user_id=sub,
                    knowledge_id=entry.id,
                    points=2,
                    action_type=PointActionEnum.used,
                ))
        await db.commit()
    return ApiResponse(data={"useful_count": entry.useful_count}, msg="已标记有用")


# ============================================================
# Day 16: 视频片段查询
# ============================================================

@router.get("/knowledge/{entry_id}/clips", response_model=ApiResponse)
async def get_video_clips(
    entry_id: int,
    user: User = Depends(get_current_user),
):
    """查询与某知识条目关联的视频片段（同源文件的其他分段）"""
    allowed_kb = _kb_filter(user)

    async with async_session() as db:
        # 查源条目
        result = await db.execute(
            select(KnowledgeEntry).where(KnowledgeEntry.id == entry_id)
        )
        entry = result.scalar_one_or_none()
        if not entry:
            raise HTTPException(status_code=404, detail="知识不存在")

        # 如果是视频类且有源文件，找出同源的所有片段
        clips = []
        if entry.source_file_path and entry.content_type.value in ("video", "audio"):
            clip_r = await db.execute(
                select(
                    KnowledgeEntry.id, KnowledgeEntry.title,
                    KnowledgeEntry.media_start_sec, KnowledgeEntry.media_end_sec,
                )
                .where(
                    KnowledgeEntry.source_file_path == entry.source_file_path,
                    KnowledgeEntry.id != entry.id,
                    KnowledgeEntry.status == "approved",
                )
                .order_by(KnowledgeEntry.media_start_sec)
            )
            clips = [
                {"id": r[0], "title": r[1], "start": r[2], "end": r[3]}
                for r in clip_r.all()
            ]

    return ApiResponse(data={
        "current": {
            "id": entry.id, "title": entry.title,
            "media_url": entry.media_url,
            "media_start_sec": entry.media_start_sec,
            "media_end_sec": entry.media_end_sec,
        },
        "clips": clips,
    })


# ============================================================
# 内部
# ============================================================

def _entry_summary(k: KnowledgeEntry) -> dict:
    return {
        "id": k.id, "title": k.title,
        "content": (k.content or "")[:200] + ("..." if len(k.content or "") > 200 else ""),
        "content_type": k.content_type.value,
        "category_id": k.category_id, "knowledge_base": k.knowledge_base.value,
        "source_type": k.source_type.value, "source_person": k.source_person,
        "tags": k.tags, "car_brand": k.car_brand, "car_model": k.car_model,
        "difficulty_level": k.difficulty_level,
        "view_count": k.view_count, "useful_count": k.useful_count,
        "status": k.status.value if k.status else "approved",
        "created_at": k.created_at.isoformat() if k.created_at else None,
        "updated_at": k.updated_at.isoformat() if k.updated_at else None,
    }
