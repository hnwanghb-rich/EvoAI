"""
审核路由 —— 待审核列表 / 通过(自动积分) / 驳回 / 历史 / AI拆分试题 / 试题入库
"""
import os, json, logging, hashlib, base64, uuid, tempfile
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from datetime import datetime
from cryptography.fernet import Fernet

from database import async_session
from models import (
    KnowledgeEntry, ExperiencePoint, User, DailyQuestion,
    LLMProvider, EntryStatusEnum, PointActionEnum,
)
from schemas import ApiResponse, RejectRequest, BatchQuestionImport
from auth import get_current_user, require_admin
from routers.logs import audit_log
from routers.questions import _call_llm_batch_generate
from config import LLM_ENCRYPTION_KEY

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/review/pending", response_model=ApiResponse)
async def pending_list(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
):
    """待审核列表（status=pending）"""
    async with async_session() as db:
        total_r = await db.execute(
            select(func.count(KnowledgeEntry.id)).where(KnowledgeEntry.status == "pending")
        )
        total = total_r.scalar() or 0

        rows_r = await db.execute(
            select(KnowledgeEntry)
            .where(KnowledgeEntry.status == "pending")
            .order_by(KnowledgeEntry.created_at.asc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        entries = rows_r.scalars().all()

        items = []
        for e in entries:
            items.append({
                "id": e.id, "title": e.title, "content": e.content,
                "knowledge_base": e.knowledge_base.value,
                "source_type": e.source_type.value,
                "source_person": e.source_person,
                "source_dept": e.source_dept,
                "tags": e.tags,
                "created_at": e.created_at.isoformat() if e.created_at else None,
            })
    return ApiResponse(data={"items": items, "total": total, "page": page, "page_size": page_size})


@router.post("/review/{entry_id}/approve", response_model=ApiResponse)
async def approve_knowledge(
    entry_id: int,
    user: User = Depends(require_admin),
):
    """审核通过：status → approved，给提交者 +10 积分"""
    async with async_session() as db:
        result = await db.execute(
            select(KnowledgeEntry).where(KnowledgeEntry.id == entry_id)
        )
        entry = result.scalar_one_or_none()
        if not entry:
            raise HTTPException(status_code=404, detail="知识不存在")
        if entry.status != EntryStatusEnum.pending:
            raise HTTPException(status_code=400, detail="该知识不是待审核状态")

        entry.status = EntryStatusEnum.approved
        entry.auditor_id = user.id
        entry.updated_at = datetime.utcnow()

        # 查找提交人
        if entry.source_person:
            sub_r = await db.execute(
                select(User.id).where(User.real_name == entry.source_person)
            )
            sub = sub_r.scalar_one_or_none()
            if sub:
                db.add(ExperiencePoint(
                    user_id=sub,
                    knowledge_id=entry.id,
                    points=10,
                    action_type=PointActionEnum.approved,
                ))

        await db.commit()
    # 审计日志
    import asyncio
    asyncio.ensure_future(audit_log(
        user.id, user.username, "review_approve", "knowledge_entry", entry_id,
        f"通过审核: {entry.title[:100]}",
    ))
    return ApiResponse(msg="审核通过，提交者 +10 积分")


@router.post("/review/{entry_id}/reject", response_model=ApiResponse)
async def reject_knowledge(
    entry_id: int,
    body: RejectRequest,
    user: User = Depends(require_admin),
):
    """驳回：status → rejected，记录驳回原因，不给积分"""
    async with async_session() as db:
        result = await db.execute(
            select(KnowledgeEntry).where(KnowledgeEntry.id == entry_id)
        )
        entry = result.scalar_one_or_none()
        if not entry:
            raise HTTPException(status_code=404, detail="知识不存在")

        entry.status = EntryStatusEnum.rejected
        entry.audit_comment = body.audit_comment
        entry.auditor_id = user.id
        entry.updated_at = datetime.utcnow()
        await db.commit()
    import asyncio
    asyncio.ensure_future(audit_log(
        user.id, user.username, "review_reject", "knowledge_entry", entry_id,
        f"驳回: {entry.title[:100]} | 原因: {body.audit_comment[:100]}",
    ))
    return ApiResponse(msg="已驳回")


@router.post("/review/{entry_id}/ai-split-questions", response_model=ApiResponse)
async def ai_split_questions(
    entry_id: int,
    _admin: User = Depends(require_admin),
):
    """AI拆分试题：从审核中心的经验数据中，调用AI拆解生成试题草稿（不入库）"""
    async with async_session() as db:
        result = await db.execute(
            select(KnowledgeEntry).where(KnowledgeEntry.id == entry_id)
        )
        entry = result.scalar_one_or_none()
        if not entry:
            raise HTTPException(status_code=404, detail="知识不存在")

        # 获取默认LLM
        llm_r = await db.execute(
            select(LLMProvider).where(
                LLMProvider.is_active == True,
                LLMProvider.is_default == True,
            )
        )
        llm = llm_r.scalar_one_or_none()

        if not llm or not llm.api_key:
            return ApiResponse(code=400, data={"drafts": []}, msg="LLM未配置，请先配置AI模型")

        # 从 knowledge_base 推导 target_position
        kb = entry.knowledge_base.value if entry.knowledge_base else ""
        target_position = kb if kb in ("sales", "tech", "service") else ""

        # 如果是视频/音频类型且内容为空 → 先调 ASR 提取文字
        content_for_ai = entry.content or ""
        if entry.content_type and entry.content_type.value in ("video", "audio"):
            # 内容长度不足 → 说明是占位文本，需要 ASR
            if not content_for_ai.strip() or len(content_for_ai) < 100:
                logger.info(f"视频/音频内容为空，尝试 ASR 转写: entry_id={entry_id}")
                audio_text = await _asr_transcribe_entry(entry)
                if audio_text:
                    content_for_ai = audio_text
                    logger.info(f"ASR 转写成功，获得 {len(content_for_ai)} 字符")

        drafts = await _call_llm_batch_generate(llm, content_for_ai, target_position)

        if not drafts:
            return ApiResponse(code=400, data={"drafts": []}, msg="AI拆分失败，请检查LLM配置或重试")

    # 注入知识条目关联信息，确保入库后答题能关联到 LearningRecord
    for d in drafts:
        d["related_knowledge_id"] = entry_id
        if entry.category_id:
            d["category_id"] = entry.category_id

    return ApiResponse(data={
        "entry_id": entry_id,
        "drafts": drafts,
        "count": len(drafts),
    }, msg=f"AI已生成 {len(drafts)} 道题目草稿，请复核后入库")


@router.get("/review/history", response_model=ApiResponse)
async def review_history(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
):
    """审核历史（已审核的条目）"""
    async with async_session() as db:
        total_r = await db.execute(
            select(func.count(KnowledgeEntry.id)).where(
                KnowledgeEntry.status.in_(["approved", "rejected"])
            )
        )
        total = total_r.scalar() or 0

        rows_r = await db.execute(
            select(KnowledgeEntry)
            .where(KnowledgeEntry.status.in_(["approved", "rejected"]))
            .order_by(KnowledgeEntry.updated_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        entries = rows_r.scalars().all()

        items = []
        for e in entries:
            items.append({
                "id": e.id, "title": e.title,
                "status": e.status.value,
                "audit_comment": e.audit_comment,
                "source_person": e.source_person,
                "updated_at": e.updated_at.isoformat() if e.updated_at else None,
            })
    return ApiResponse(data={"items": items, "total": total, "page": page, "page_size": page_size})


# ============================================================
# ASR 转写辅助（审核中心 AI 拆分视频/音频时调用）
# ============================================================

async def _asr_transcribe_entry(entry) -> str:
    """对视频/音频知识条目执行 ASR 转写，返回文字内容"""
    source_path = entry.source_file_path
    if not source_path or not os.path.isfile(source_path):
        logger.warning(f"视频源文件不存在: {source_path}")
        return ""

    logger.info(f"审核中心 ASR: 开始处理 {os.path.basename(source_path)}")
    audio_path = os.path.join(tempfile.gettempdir(), f"review_asr_{uuid.uuid4().hex[:8]}.mp3")
    try:
        from video_processor import (
            _extract_audio_async, _transcribe_with_timestamps,
        )
        await _extract_audio_async(source_path, audio_path)
        segments = await _transcribe_with_timestamps(audio_path)

        if segments:
            text = "\n\n".join(
                f"[{seg['start']:.0f}s-{seg['end']:.0f}s] {seg['text']}"
                for seg in segments
            )
            # 更新 entry content，避免下次重复转写
            try:
                async with async_session() as db:
                    from sqlalchemy import update
                    await db.execute(
                        update(KnowledgeEntry)
                        .where(KnowledgeEntry.id == entry.id)
                        .values(content=text[:10000])
                    )
                    await db.commit()
                    logger.info(f"审核中心 ASR: entry_id={entry.id} 内容已更新 {len(text)} 字符")
            except Exception as e:
                logger.warning(f"更新 entry content 失败: {e}")
            return text

        logger.warning("审核中心 ASR: 转写返回空结果")
    except Exception as e:
        logger.warning(f"审核中心 ASR 失败: {e}")
        if "ffmpeg" in str(e).lower() or "未安装" in str(e):
            raise HTTPException(status_code=400, detail="ffmpeg 未安装，无法处理视频文件")
    finally:
        if os.path.isfile(audio_path):
            try: os.remove(audio_path)
            except: pass

    return ""
