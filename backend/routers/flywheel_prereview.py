"""
AI 预审查重台 (FW-03) —— pending 知识查重/冲突预检
向量索引未就绪时退化为 Python 端字符级 trigram 相似度。
不修改审核中心，仅做"建议"标签，最终裁决权在审核人。
"""
import logging
from fastapi import APIRouter, Depends
from sqlalchemy import text

from database import async_session
from models import User
from schemas import ApiResponse
from auth import require_admin

logger = logging.getLogger(__name__)
router = APIRouter()

KB_LABEL = {"public": "公共", "sales": "销售", "tech": "技术", "service": "客服"}
STATUS_LABEL = {"pending": "待审核", "approved": "已通过", "rejected": "已驳回", "archived": "已归档"}


def _trigram_similarity(a: str, b: str) -> float:
    """字符级 3-gram Jaccard 相似度（替代 pg_trgm）"""
    if not a or not b:
        return 0.0
    def trigrams(s: str):
        s = s.lower().strip()
        return set(s[i:i+3] for i in range(max(1, len(s) - 2)))
    ta, tb = trigrams(a), trigrams(b)
    union = ta | tb
    if not union:
        return 0.0
    return round(len(ta & tb) / len(union), 3)


def _label(sim: float) -> str:
    if sim >= 0.6:
        return "疑似重复"
    if sim >= 0.35:
        return "高度相关"
    return "轻度相关"


@router.get("/flywheel/prereview/list", response_model=ApiResponse)
async def prereview_list(_admin: User = Depends(require_admin)):
    """待审核知识列表（带 AI 预审标签摘要）"""
    async with async_session() as db:
        rows = (await db.execute(text("""
            SELECT id, title, tags, knowledge_base, source_person, created_at
            FROM knowledge_entries
            WHERE status = 'pending'
            ORDER BY created_at DESC
        """))).all()

        items = []
        for r in rows:
            items.append({
                "id": r[0],
                "title": r[1],
                "tags": r[2],
                "knowledge_base": str(r[3].value if hasattr(r[3], 'value') else r[3]),
                "kb_label": KB_LABEL.get(str(r[3].value if hasattr(r[3], 'value') else r[3]), str(r[3])),
                "source_person": r[4],
                "created_at": r[5].isoformat() if r[5] else None,
            })

    return ApiResponse(data={"items": items, "total": len(items)})


@router.get("/flywheel/prereview/check/{entry_id}", response_model=ApiResponse)
async def prereview_check(entry_id: int, _admin: User = Depends(require_admin)):
    """对一条 pending 知识做查重预检，返回相似度列表"""
    async with async_session() as db:
        # 被检条目
        target = (await db.execute(text("""
            SELECT id, title, content, tags, knowledge_base
            FROM knowledge_entries WHERE id = :id
        """), {"id": entry_id})).first()

        if not target:
            from fastapi import HTTPException
            raise HTTPException(status_code=404, detail="条目不存在")

        t_id, t_title, t_content, t_tags, t_kb = target
        t_kb_str = str(t_kb.value if hasattr(t_kb, 'value') else t_kb)

        # 同知识库已通过的条目（取标题 + 前200字内容，不全量拉避免内存问题）
        candidates = (await db.execute(text("""
            SELECT id, title, LEFT(content, 200) AS snippet, tags
            FROM knowledge_entries
            WHERE status = 'approved'
              AND knowledge_base = :kb
              AND id != :id
            ORDER BY created_at DESC
            LIMIT 200
        """), {"kb": t_kb_str, "id": t_id})).all()

        results = []
        for c in candidates:
            title_sim = _trigram_similarity(t_title, c[1])
            content_sim = _trigram_similarity((t_content or "")[:200], c[2] or "")
            tag_sim = _trigram_similarity(t_tags or "", c[3] or "")
            # 加权综合分：标题权重最高
            combined = round(title_sim * 0.6 + content_sim * 0.3 + tag_sim * 0.1, 3)
            if combined < 0.2:
                continue
            results.append({
                "candidate_id": c[0],
                "candidate_title": c[1],
                "title_sim": title_sim,
                "content_sim": content_sim,
                "combined_sim": combined,
                "label": _label(combined),
            })

        results.sort(key=lambda x: x["combined_sim"], reverse=True)
        top = results[:10]

        # 预审判定
        verdict = "clean"
        if any(r["combined_sim"] >= 0.6 for r in top):
            verdict = "duplicate"
        elif any(r["combined_sim"] >= 0.35 for r in top):
            verdict = "related"

        VERDICT_LABEL = {"clean": "无明显重复", "related": "高度相关（建议确认）", "duplicate": "疑似重复（建议合并或驳回）"}

    return ApiResponse(data={
        "entry_id": t_id,
        "title": t_title,
        "knowledge_base": t_kb_str,
        "verdict": verdict,
        "verdict_label": VERDICT_LABEL[verdict],
        "similar_count": len(top),
        "similar": top,
        "note": "相似度基于字符级 trigram，向量索引就绪后将切换为语义相似度。AI 结果仅供参考，最终裁决权在审核人。",
    })
