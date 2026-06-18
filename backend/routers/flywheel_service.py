"""
客服飞轮·投诉根因回流台 (FW-07)
- 提交投诉处理记录 → AI 抽「类型/诉求/话术/流程/结果/根因归属」→ knowledge_entries(service,pending)
- dispatch：根因非客服自身时派跨线任务 —— 占位，FW-08 建表后补写
- 🔌 满意度回访：需外部数据，无数据时占位
- 不修改现有代码
"""
import json
import logging
import httpx
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text

from database import async_session
from models import User
from schemas import ApiResponse
from auth import get_current_user, require_admin
from routers.logs import audit_log

logger = logging.getLogger(__name__)
router = APIRouter()

ROOT_CAUSE_LABELS = {
    "service": "客服自身",
    "sales": "销售过度承诺",
    "tech": "维修质量问题",
    "pdi": "PDI/交车问题",
    "factory": "厂家/产品问题",
}

EXTRACT_PROMPT = """你是汽车4S店客服知识萃取助手。
用户将提供一段投诉处理记录，请提取以下字段并严格以 JSON 格式返回，不要输出其他内容：
{
  "title": "投诉标题（简洁，30字以内）",
  "complaint_type": "投诉类型（价格纠纷/维修质量/服务态度/交车问题/产品缺陷/其他）",
  "demand": "客户诉求（核心要求）",
  "appease_tactic": "安抚话术（关键应对方式）",
  "process": "处理流程（简要描述）",
  "result": "处理结果",
  "root_cause": "根因归属，只能是以下之一：service/sales/tech/pdi/factory"
}
根因判断逻辑：
- 销售话术夸大、价格承诺兑现不了 → sales
- 维修没修好、二次进厂 → tech
- 交车时未做PDI、车辆状态问题 → pdi
- 车辆本身设计/质量问题 → factory
- 客服流程、服务态度问题 → service"""


async def _llm_extract(content: str) -> dict | None:
    async with async_session() as db:
        llm = (await db.execute(text("""
            SELECT base_url, api_key, model_name, temperature, max_tokens
            FROM llm_providers WHERE is_active = true AND is_default = true LIMIT 1
        """))).first()
    if not llm or not llm[1]:
        return None
    from routers.chat import _decrypt_api_key
    api_key = _decrypt_api_key(llm[1])
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                f"{llm[0]}/chat/completions",
                headers={"Authorization": f"Bearer {api_key}"},
                json={
                    "model": llm[2],
                    "messages": [
                        {"role": "system", "content": EXTRACT_PROMPT},
                        {"role": "user", "content": content},
                    ],
                    "temperature": float(llm[3] or 0.3),
                    "max_tokens": int(llm[4] or 1024),
                },
            )
            resp.raise_for_status()
            text_out = resp.json()["choices"][0]["message"]["content"]
            start = text_out.find("{")
            end = text_out.rfind("}") + 1
            if start >= 0 and end > start:
                return json.loads(text_out[start:end])
    except Exception as e:
        logger.warning(f"FW-07 LLM 调用失败: {e}")
    return None


@router.post("/flywheel/service/complaint", response_model=ApiResponse)
async def complaint_submit(
    content: str = Query(..., max_length=3000),
    current_user: User = Depends(get_current_user),
):
    """提交投诉处理记录：AI 抽六要素 → knowledge_entries(service, pending)"""
    if not content.strip():
        raise HTTPException(status_code=400, detail="投诉内容不能为空")

    extracted = await _llm_extract(content)

    if extracted:
        title = extracted.get("title") or content[:30]
        root_cause = extracted.get("root_cause", "service")
        if root_cause not in ROOT_CAUSE_LABELS:
            root_cause = "service"
        body = (
            f"**投诉类型**：{extracted.get('complaint_type', '')}\n\n"
            f"**客户诉求**：{extracted.get('demand', '')}\n\n"
            f"**安抚话术**：{extracted.get('appease_tactic', '')}\n\n"
            f"**处理流程**：{extracted.get('process', '')}\n\n"
            f"**处理结果**：{extracted.get('result', '')}\n\n"
            f"**根因归属**：{ROOT_CAUSE_LABELS.get(root_cause, root_cause)}"
        )
        tags = ",".join(filter(None, [
            extracted.get("complaint_type", ""),
            ROOT_CAUSE_LABELS.get(root_cause, ""),
            "投诉处理",
        ]))
    else:
        title = content[:30] + ("…" if len(content) > 30 else "")
        body = content
        root_cause = "service"
        tags = "投诉处理"

    async with async_session() as db:
        cat = (await db.execute(text("""
            SELECT id FROM knowledge_categories
            WHERE knowledge_base = 'service' AND is_active = true
            ORDER BY sort_order LIMIT 1
        """))).scalar()

        result = await db.execute(text("""
            INSERT INTO knowledge_entries
                (title, content, knowledge_base, source_type, source_person,
                 category_id, tags, status, version, created_at, updated_at)
            VALUES
                (:title, :body, 'service', 'experience', :person,
                 :cat, :tags, 'pending', 1, NOW(), NOW())
            RETURNING id
        """), {
            "title": title, "body": body,
            "person": current_user.real_name or current_user.username,
            "cat": cat, "tags": tags,
        })
        entry_id = result.scalar()
        await db.commit()

    import asyncio
    asyncio.ensure_future(audit_log(
        current_user.id, current_user.username,
        "flywheel_service_complaint", "knowledge_entry", entry_id,
        f"提交投诉记录[根因:{root_cause}]: {title[:80]}",
    ))
    return ApiResponse(data={
        "id": entry_id,
        "title": title,
        "root_cause": root_cause,
        "root_cause_label": ROOT_CAUSE_LABELS.get(root_cause, root_cause),
        "need_dispatch": root_cause != "service",
        "ai_extracted": extracted is not None,
        "extracted": extracted,
    }, msg="投诉记录已提交，等待审核")


@router.post("/flywheel/service/{entry_id}/dispatch", response_model=ApiResponse)
async def complaint_dispatch(
    entry_id: int,
    target_line: str = Query(..., regex="^(sales|tech|pdi|factory)$"),
    note: str = Query("", max_length=500),
    admin: User = Depends(require_admin),
):
    """派发跨线整改任务 → 写入 cross_line_tasks"""
    async with async_session() as db:
        row = (await db.execute(
            text("SELECT id, title FROM knowledge_entries WHERE id = :id"),
            {"id": entry_id},
        )).first()
        if not row:
            raise HTTPException(status_code=404, detail="投诉记录不存在")

        result = await db.execute(text("""
            INSERT INTO cross_line_tasks
                (source_entry_id, source_line, target_line, title, description,
                 status, priority, created_by, note, created_at, updated_at)
            VALUES
                (:entry_id, 'service', :target_line, :title, :description,
                 'pending', 2, :creator, :note, NOW(), NOW())
            RETURNING id
        """), {
            "entry_id": entry_id,
            "target_line": target_line,
            "title": f"【客服投诉整改】{row[1][:80]}",
            "description": f"来源投诉记录 #{entry_id}，根因归属：{ROOT_CAUSE_LABELS.get(target_line, target_line)}",
            "creator": admin.id,
            "note": note,
        })
        task_id = result.scalar()
        await db.commit()

    import asyncio
    asyncio.ensure_future(audit_log(
        admin.id, admin.username,
        "flywheel_service_dispatch", "cross_line_task", task_id,
        f"派发跨线任务→{target_line}: {row[1][:80]} | {note[:100]}",
    ))
    return ApiResponse(data={
        "task_id": task_id,
        "entry_id": entry_id,
        "target_line": target_line,
        "target_label": ROOT_CAUSE_LABELS.get(target_line, target_line),
        "status": "pending",
    }, msg=f"整改任务已派发给{ROOT_CAUSE_LABELS.get(target_line, target_line)}")


@router.get("/flywheel/service/list", response_model=ApiResponse)
async def complaint_list(
    _user: User = Depends(get_current_user),
):
    """已沉淀的投诉处理记录列表（已通过的）"""
    async with async_session() as db:
        rows = (await db.execute(text("""
            SELECT id, title, tags, source_person, useful_count, created_at,
                   LEFT(content, 200) AS preview
            FROM knowledge_entries
            WHERE knowledge_base = 'service'
              AND source_type = 'experience'
              AND status = 'approved'
            ORDER BY created_at DESC
            LIMIT 50
        """))).all()

        items = [{
            "id": r[0], "title": r[1], "tags": r[2],
            "source_person": r[3], "useful_count": r[4] or 0,
            "created_at": r[5].isoformat() if r[5] else None,
            "preview": r[6],
        } for r in rows]

    return ApiResponse(data={"items": items, "total": len(items)})


@router.get("/flywheel/service/satisfaction", response_model=ApiResponse)
async def service_satisfaction(_admin: User = Depends(require_admin)):
    """🔌 满意度回访数据（需对接回访系统）"""
    return ApiResponse(data={
        "connected": False,
        "message": "🔌 满意度回访分需对接回访系统。未对接时，投诉沉淀与跨线派发功能完整可用，满意度指标显示待对接。",
    })
