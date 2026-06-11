"""
混合检索 —— 关键词(tsvector) + ILIKE中文降级 + 置信度评分
"""
import logging
import re
from sqlalchemy import select, text, or_

from database import async_session
from models import KnowledgeEntry

logger = logging.getLogger(__name__)

RRF_K = 60
# 置信度阈值：RRF 分数 >= 此值认为知识库匹配有效
CONFIDENCE_THRESHOLD = 0.008


async def hybrid_search(
    query: str,
    knowledge_bases: list[str],
    top_k: int = 5,
) -> list[dict]:
    """
    返回: [{id, title, content, kw_score, vec_score, rrf, confidence}]
    """
    results = {}
    ngram_count = _query_ngram_count(query)

    async with async_session() as db:
        # 第1路：关键词检索
        kw_results = await _keyword_search(db, query, knowledge_bases, limit=20)
        for i, row in enumerate(kw_results):
            kid = row[0]
            score = _normalize_score(row[3], 1.0) if len(row) > 3 and row[3] else 1.0
            if kid not in results:
                results[kid] = {"id": kid, "title": row[1], "content": row[2],
                                "kw_score": score, "vec_score": 0, "rrf": 0}
            results[kid]["rrf"] += 1.0 / (RRF_K + i + 1)

        # 第2路：语义向量（不可用时跳过）
        vec_results = await _vector_search(db, query, knowledge_bases, limit=20)
        for i, row in enumerate(vec_results):
            kid = row[0]
            sim = row[3] if len(row) > 3 and row[3] else 0.5
            if kid not in results:
                results[kid] = {"id": kid, "title": row[1], "content": row[2],
                                "kw_score": 0, "vec_score": sim, "rrf": 0}
            results[kid]["rrf"] += 1.0 / (RRF_K + i + 1)

    # 置信度 = RRF 归一化 × 排名加权
    max_rrf = max((r["rrf"] for r in results.values()), default=0.001)
    for r in results.values():
        # 计算每条结果的置信度: RRF相对值 × 关键词命中度
        relative_rrf = r["rrf"] / max(max_rrf, 0.001)
        kw_bonus = min(r.get("kw_score", 0), 1.0)
        r["confidence"] = round(relative_rrf * 0.7 + kw_bonus * 0.3, 4)

    ranked = sorted(results.values(), key=lambda x: x["rrf"], reverse=True)
    return ranked[:top_k]


def _query_ngram_count(query: str) -> int:
    """计算查询的 n-gram 数量（用于匹配度评估）"""
    chars = re.sub(r'[a-zA-Z0-9\s,，。/、！？：:]+', '', query)
    count = 0
    for n in (3, 4):
        count += max(0, len(chars) - n + 1)
    return max(count, 1)


async def _keyword_search(db, query: str, kbs: list[str], limit: int = 20) -> list:
    from sqlalchemy import or_
    clean = query.strip().replace("'", "''")[:150]

    try:
        sql = text("""
            SELECT id, title, content,
                   ts_rank(
                       to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(content,'')),
                       plainto_tsquery('simple', :q)
                   ) AS kw_score
            FROM knowledge_entries
            WHERE status = 'approved'
              AND knowledge_base = ANY(:kbs)
              AND to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(content,''))
                  @@ plainto_tsquery('simple', :q)
            ORDER BY kw_score DESC
            LIMIT :lim
        """)
        result = await db.execute(sql, {"q": clean, "kbs": kbs, "lim": limit})
        rows = result.fetchall()
        if rows:
            return rows
    except Exception as e:
        logger.warning(f"tsvector检索异常: {e}")

    # ILIKE 降级
    conditions = []
    if len(clean) > 1:
        conditions.append(KnowledgeEntry.title.ilike(f"%{clean}%"))
        conditions.append(KnowledgeEntry.content.ilike(f"%{clean}%"))
    for t in re.split(r'[\s,，。/、！？：:]+', clean):
        parts = re.split(r'([a-zA-Z0-9]+)', t)
        for p in parts:
            if len(p) >= 2 and p != clean:
                conditions.append(KnowledgeEntry.title.ilike(f"%{p}%"))
                conditions.append(KnowledgeEntry.content.ilike(f"%{p}%"))
    chars = re.sub(r'[a-zA-Z0-9\s,，。/、！？：:]+', '', clean)
    for n in (3, 4):
        for i in range(len(chars) - n + 1):
            gram = chars[i:i+n]
            conditions.append(KnowledgeEntry.title.ilike(f"%{gram}%"))
            conditions.append(KnowledgeEntry.content.ilike(f"%{gram}%"))

    conditions = list(dict.fromkeys(conditions))[:24]

    # 打分：匹配到的条件数越多分越高
    matched = len(conditions)
    score = min(matched / max(_query_ngram_count(query) * 3, 1), 1.0)

    stmt = select(KnowledgeEntry.id, KnowledgeEntry.title, KnowledgeEntry.content).where(
        KnowledgeEntry.status == "approved",
        KnowledgeEntry.knowledge_base.in_(kbs),
        or_(*conditions) if conditions else True,
    )
    result = await db.execute(stmt.limit(limit))
    return [(r[0], r[1], r[2], score) for r in result.fetchall()]


async def _vector_search(db, query: str, kbs: list[str], limit: int = 20) -> list:
    try:
        check_sql = text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'knowledge_entries' AND column_name = 'embedding'
        """)
        result = await db.execute(check_sql)
        if not result.fetchone():
            return []
        count_sql = text("SELECT COUNT(*) FROM knowledge_entries WHERE embedding IS NOT NULL")
        result = await db.execute(count_sql)
        if (result.scalar() or 0) == 0:
            return []
        return []
    except Exception as e:
        logger.info(f"语义检索不可用: {e}")
        return []


def _normalize_score(val, default=1.0) -> float:
    try:
        return min(max(float(val), 0), 1)
    except (ValueError, TypeError):
        return default
