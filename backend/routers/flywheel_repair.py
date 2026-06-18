"""
维修飞轮·故障案例 (FW-06)
- 提交故障案例 → AI 抽「现象/故障码/排查/根因/方案/配件」→ 落 knowledge_entries(tech,pending)
- 安全红线：新能源高压/制动系统标记 safety_critical=true，审核时提示技术总监二次签核
- 案例检索：按故障码/车型/现象关键词
- 🔌 一次修复率：需 repair_orders_import 数据，无数据时占位
- 不修改现有 chat.py / knowledge.py
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

SAFETY_KEYWORDS = ["高压", "新能源", "动力电池", "制动", "刹车", "ABS", "ESP", "安全气囊", "转向"]

EXTRACT_PROMPT = """你是汽车4S店维修知识萃取助手。
用户将提供一段故障维修描述，请提取以下字段并严格以 JSON 格式返回，不要输出其他内容：
{
  "title": "故障标题（简洁，30字以内，格式：车型+现象）",
  "symptom": "故障现象（客户描述或实测现象）",
  "fault_code": "故障码（如无填空字符串）",
  "diagnosis": "排查步骤（简要描述）",
  "root_cause": "根本原因",
  "solution": "维修方案",
  "parts": "更换配件（如无填空字符串）",
  "safety_flag": false
}
如果涉及高压系统、动力电池、制动/刹车/ABS/ESP、安全气囊、转向等安全关键系统，将 safety_flag 设为 true。"""


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
        logger.warning(f"FW-06 LLM 调用失败: {e}")
    return None


def _detect_safety(text_content: str) -> bool:
    return any(kw in text_content for kw in SAFETY_KEYWORDS)


@router.post("/flywheel/repair/case", response_model=ApiResponse)
async def repair_case_submit(
    content: str = Query(..., max_length=3000),
    car_brand: str = Query(..., max_length=50),
    car_model: str = Query(..., max_length=100),
    current_user: User = Depends(get_current_user),
):
    """提交故障案例：AI 抽六要素 → knowledge_entries(tech, pending)"""
    if not content.strip():
        raise HTTPException(status_code=400, detail="案例内容不能为空")
    if not car_brand.strip() or not car_model.strip():
        raise HTTPException(status_code=400, detail="车型品牌和车型为必填项（维修知识必须带车型）")

    extracted = await _llm_extract(content)

    # 安全红线检测：AI 判定 OR 关键词兜底
    safety_flag = False
    if extracted:
        safety_flag = bool(extracted.get("safety_flag", False))
    if not safety_flag:
        safety_flag = _detect_safety(content)

    if extracted:
        title = extracted.get("title") or f"{car_model} 故障案例"
        body = (
            f"**车型**：{car_brand} {car_model}\n\n"
            f"**故障现象**：{extracted.get('symptom', '')}\n\n"
            f"**故障码**：{extracted.get('fault_code', '—')}\n\n"
            f"**排查步骤**：{extracted.get('diagnosis', '')}\n\n"
            f"**根本原因**：{extracted.get('root_cause', '')}\n\n"
            f"**维修方案**：{extracted.get('solution', '')}\n\n"
            f"**更换配件**：{extracted.get('parts', '—')}"
        )
        tags = ",".join(filter(None, [
            car_brand, car_model,
            extracted.get("fault_code", ""),
            "安全关键" if safety_flag else "",
            "故障案例",
        ]))
    else:
        title = f"{car_model} 故障案例"
        body = content
        tags = ",".join(filter(None, [car_brand, car_model, "故障案例"]))

    async with async_session() as db:
        cat = (await db.execute(text("""
            SELECT id FROM knowledge_categories
            WHERE knowledge_base = 'tech' AND is_active = true
            ORDER BY sort_order LIMIT 1
        """))).scalar()

        result = await db.execute(text("""
            INSERT INTO knowledge_entries
                (title, content, knowledge_base, source_type, source_person,
                 category_id, car_brand, car_model, tags,
                 safety_critical, status, version, created_at, updated_at)
            VALUES
                (:title, :body, 'tech', 'experience', :person,
                 :cat, :brand, :cmodel, :tags,
                 :safety, 'pending', 1, NOW(), NOW())
            RETURNING id
        """), {
            "title": title, "body": body,
            "person": current_user.real_name or current_user.username,
            "cat": cat, "brand": car_brand, "cmodel": car_model, "tags": tags,
            "safety": safety_flag,
        })
        entry_id = result.scalar()
        await db.commit()

    import asyncio
    asyncio.ensure_future(audit_log(
        current_user.id, current_user.username,
        "flywheel_repair_case", "knowledge_entry", entry_id,
        f"{'[安全关键]' if safety_flag else ''}提交故障案例: {title[:80]}",
    ))
    return ApiResponse(data={
        "id": entry_id,
        "title": title,
        "safety_critical": safety_flag,
        "ai_extracted": extracted is not None,
        "extracted": extracted,
    }, msg="案例已提交" + ("【⚠️ 安全关键，需技术总监二次签核】" if safety_flag else "，等待审核"))


@router.get("/flywheel/repair/search", response_model=ApiResponse)
async def repair_search(
    q: str = Query("", max_length=200),
    car_brand: str = Query("", max_length=50),
    car_model: str = Query("", max_length=100),
    fault_code: str = Query("", max_length=50),
    _user: User = Depends(get_current_user),
):
    """故障案例检索：按故障码/车型/现象关键词"""
    async with async_session() as db:
        conds = ["knowledge_base = 'tech'", "status = 'approved'"]
        params: dict = {}

        if car_brand:
            conds.append("car_brand ILIKE :brand")
            params["brand"] = f"%{car_brand}%"
        if car_model:
            conds.append("car_model ILIKE :cmodel")
            params["cmodel"] = f"%{car_model}%"
        if fault_code:
            conds.append("(tags ILIKE :fc OR content ILIKE :fc2)")
            params["fc"] = f"%{fault_code}%"
            params["fc2"] = f"%{fault_code}%"
        if q:
            conds.append("(title ILIKE :q OR content ILIKE :q2)")
            params["q"] = f"%{q}%"
            params["q2"] = f"%{q}%"

        sql = f"""
            SELECT id, title, car_brand, car_model, tags,
                   safety_critical, useful_count, view_count,
                   LEFT(content, 300) AS preview, created_at
            FROM knowledge_entries
            WHERE {' AND '.join(conds)}
            ORDER BY useful_count DESC, created_at DESC
            LIMIT 30
        """
        rows = (await db.execute(text(sql), params)).all()

        items = [{
            "id": r[0], "title": r[1],
            "car_brand": r[2], "car_model": r[3], "tags": r[4],
            "safety_critical": r[5] or False,
            "useful_count": r[6] or 0,
            "view_count": r[7] or 0,
            "preview": r[8],
            "created_at": r[9].isoformat() if r[9] else None,
        } for r in rows]

    return ApiResponse(data={"items": items, "total": len(items)})


@router.get("/flywheel/repair/fix-rate", response_model=ApiResponse)
async def repair_fix_rate(_admin: User = Depends(require_admin)):
    """🔌 一次修复率分析（需 repair_orders_import 数据）"""
    async with async_session() as db:
        exists = (await db.execute(text("""
            SELECT EXISTS(
                SELECT 1 FROM information_schema.tables
                WHERE table_name = 'repair_orders_import'
            )
        """))).scalar()

        if not exists:
            return ApiResponse(data={
                "connected": False,
                "message": "🔌 本模块需要导入 DMS 工单数据。请联系 IT 对接 DMS 系统或上传工单 Excel。故障案例沉淀与检索功能不受影响，可正常使用。",
            })

        cnt = (await db.execute(text("SELECT COUNT(*) FROM repair_orders_import"))).scalar() or 0
        if cnt == 0:
            return ApiResponse(data={
                "connected": False,
                "message": "🔌 repair_orders_import 表存在但暂无数据，请上传 DMS 工单 Excel。",
            })

    return ApiResponse(data={"connected": True, "total_orders": cnt})
