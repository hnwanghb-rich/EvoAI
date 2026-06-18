"""
销售飞轮·赢单复盘台 (FW-05)
- 提交赢单复盘 → AI 拆「异议/话术/车型」→ 落 knowledge_entries(pending)
- 话术墙：已通过的销售经验列表
- 🔌 成交转化分析：需 sales_deals_import 有数据，无数据时占位提示
- 不修改现有 chat.py / knowledge.py
"""
import json
import logging
import httpx
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text, select

from database import async_session
from models import User, KnowledgeCategory
from schemas import ApiResponse
from auth import get_current_user, require_admin
from routers.logs import audit_log

logger = logging.getLogger(__name__)
router = APIRouter()

# ── 轻量 LLM 调用（不 import chat.py，避免循环依赖）──────────────────────
async def _llm_extract(prompt: str, content: str) -> dict | None:
    """调默认 LLM，返回解析后的 dict；失败返回 None"""
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
                        {"role": "system", "content": prompt},
                        {"role": "user", "content": content},
                    ],
                    "temperature": float(llm[3] or 0.3),
                    "max_tokens": int(llm[4] or 1024),
                },
            )
            resp.raise_for_status()
            text_out = resp.json()["choices"][0]["message"]["content"]
            # 尝试解析 JSON
            start = text_out.find("{")
            end = text_out.rfind("}") + 1
            if start >= 0 and end > start:
                return json.loads(text_out[start:end])
    except Exception as e:
        logger.warning(f"FW-05 LLM 调用失败: {e}")
    return None


EXTRACT_PROMPT = """你是汽车4S店销售知识萃取助手。
用户将提供一段赢单复盘描述，请提取以下字段并严格以 JSON 格式返回，不要输出其他内容：
{
  "title": "话术标题（简洁，20字以内）",
  "objection": "客户异议（核心卡点）",
  "tactic": "应对话术（关键应对方式）",
  "car_model": "适用车型（如不确定填空字符串）",
  "competitor": "涉及竞品（如无填空字符串）",
  "summary": "完整话术正文（200字以内，结构化描述）"
}"""


# ── 接口 ──────────────────────────────────────────────────────────────────

@router.post("/flywheel/sales/win-review", response_model=ApiResponse)
async def win_review_submit(
    content: str = Query(..., max_length=3000),
    car_brand: str = Query("", max_length=50),
    car_model: str = Query("", max_length=100),
    current_user: User = Depends(get_current_user),
):
    """提交赢单复盘：AI 拆解 → 草稿写入 knowledge_entries(pending)"""
    if not content.strip():
        raise HTTPException(status_code=400, detail="复盘内容不能为空")

    # AI 拆解
    extracted = await _llm_extract(EXTRACT_PROMPT, content)

    if extracted:
        title = extracted.get("title") or content[:30]
        body = (
            f"**客户异议**：{extracted.get('objection', '')}\n\n"
            f"**应对话术**：{extracted.get('tactic', '')}\n\n"
            f"**完整描述**：{extracted.get('summary', content)}"
        )
        car_model_final = extracted.get("car_model") or car_model
        tags = ",".join(filter(None, [
            car_brand, car_model_final,
            extracted.get("competitor", ""),
            "赢单话术",
        ]))
    else:
        title = content[:30] + ("…" if len(content) > 30 else "")
        body = content
        car_model_final = car_model
        tags = ",".join(filter(None, [car_brand, car_model, "赢单话术"]))

    async with async_session() as db:
        # 查销售分类（第一个销售库分类兜底）
        cat = (await db.execute(text("""
            SELECT id FROM knowledge_categories
            WHERE knowledge_base = 'sales' AND is_active = true
            ORDER BY sort_order LIMIT 1
        """))).scalar()

        result = await db.execute(text("""
            INSERT INTO knowledge_entries
                (title, content, knowledge_base, source_type, source_person,
                 category_id, car_brand, car_model, tags, status,
                 version, created_at, updated_at)
            VALUES
                (:title, :body, 'sales', 'experience', :person,
                 :cat, :brand, :cmodel, :tags, 'pending',
                 1, NOW(), NOW())
            RETURNING id
        """), {
            "title": title, "body": body, "person": current_user.real_name or current_user.username,
            "cat": cat, "brand": car_brand, "cmodel": car_model_final, "tags": tags,
        })
        entry_id = result.scalar()
        await db.commit()

    import asyncio
    asyncio.ensure_future(audit_log(
        current_user.id, current_user.username,
        "flywheel_sales_win_review", "knowledge_entry", entry_id,
        f"提交赢单复盘: {title[:80]}",
    ))
    return ApiResponse(data={
        "id": entry_id,
        "title": title,
        "ai_extracted": extracted is not None,
        "extracted": extracted,
    }, msg="复盘已提交，等待审核后进入话术墙")


@router.get("/flywheel/sales/wall", response_model=ApiResponse)
async def sales_wall(
    car_brand: str = Query("", max_length=50),
    car_model: str = Query("", max_length=100),
    _user: User = Depends(get_current_user),
):
    """赢单话术墙：已通过的销售经验"""
    async with async_session() as db:
        conds = ["knowledge_base = 'sales'", "status = 'approved'", "source_type = 'experience'"]
        params: dict = {}
        if car_brand:
            conds.append("(car_brand ILIKE :brand OR tags ILIKE :brand_t)")
            params["brand"] = f"%{car_brand}%"
            params["brand_t"] = f"%{car_brand}%"
        if car_model:
            conds.append("(car_model ILIKE :cmodel OR tags ILIKE :cmodel_t)")
            params["cmodel"] = f"%{car_model}%"
            params["cmodel_t"] = f"%{car_model}%"

        sql = f"""
            SELECT id, title, content, car_brand, car_model, tags,
                   source_person, useful_count, view_count, created_at
            FROM knowledge_entries
            WHERE {' AND '.join(conds)}
            ORDER BY useful_count DESC, created_at DESC
            LIMIT 50
        """
        rows = (await db.execute(text(sql), params)).all()

        items = [{
            "id": r[0], "title": r[1],
            "content_preview": (r[2] or "")[:200],
            "car_brand": r[3], "car_model": r[4], "tags": r[5],
            "source_person": r[6],
            "useful_count": r[7] or 0,
            "view_count": r[8] or 0,
            "created_at": r[9].isoformat() if r[9] else None,
        } for r in rows]

    return ApiResponse(data={"items": items, "total": len(items)})


@router.get("/flywheel/sales/conversion", response_model=ApiResponse)
async def sales_conversion(_admin: User = Depends(require_admin)):
    """🔌 成交转化分析（需 sales_deals_import 有数据）"""
    async with async_session() as db:
        cnt = (await db.execute(text("SELECT COUNT(*) FROM sales_deals_import"))).scalar() or 0
        if cnt == 0:
            return ApiResponse(data={
                "connected": False,
                "message": "🔌 本模块需要导入成交数据。请在数据导入功能上传成交单 Excel，或联系 IT 对接 CRM 系统。话术沉淀功能不受影响，可正常使用。",
            })

        rows = (await db.execute(text("""
            SELECT sd.knowledge_id, ke.title,
                   COUNT(sd.id) AS deal_count,
                   AVG(sd.gross_margin) AS avg_margin
            FROM sales_deals_import sd
            JOIN knowledge_entries ke ON ke.id = sd.knowledge_id
            WHERE sd.knowledge_id IS NOT NULL
            GROUP BY sd.knowledge_id, ke.title
            ORDER BY deal_count DESC
            LIMIT 20
        """))).all()

        items = [{
            "knowledge_id": r[0], "title": r[1],
            "deal_count": r[2],
            "avg_margin": round(float(r[3]), 2) if r[3] else None,
        } for r in rows]

    return ApiResponse(data={"connected": True, "items": items, "total_deals": cnt})
