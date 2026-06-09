"""
混合检索 —— 关键词(tsvector) + 语义向量(pgvector) + RRF 融合排序
pgvector 不可用时优雅降级为纯关键词检索
"""
import logging
from sqlalchemy import select, text, func

from database import async_session
from models import KnowledgeEntry

logger = logging.getLogger(__name__)

# RRF 常数
RRF_K = 60


async def hybrid_search(
    query: str,
    knowledge_bases: list[str],
    top_k: int = 5,
) -> list[dict]:
    """
    混合检索入口：
    1. 关键词检索（tsvector）→ Top-20
    2. 语义向量检索（pgvector cosine）→ Top-20（不可用时跳过）
    3. RRF 融合排序 → Top-K
    """
    results = {}

    async with async_session() as db:
        # ---- 第1路：关键词检索 ----
        kw_results = await _keyword_search(db, query, knowledge_bases, limit=20)
        for i, row in enumerate(kw_results):
            kid = row[0]
            score = _normalize_score(row[3], 1.0) if len(row) > 3 and row[3] else 1.0
            if kid not in results:
                results[kid] = {"id": kid, "title": row[1], "content": row[2],
                                "kw_score": score, "vec_score": 0, "rrf": 0}
            results[kid]["rrf"] += 1.0 / (RRF_K + i + 1)

        # ---- 第2路：语义向量检索（尝试）----
        vec_results = await _vector_search(db, query, knowledge_bases, limit=20)
        for i, row in enumerate(vec_results):
            kid = row[0]
            sim = row[3] if len(row) > 3 and row[3] else 0.5
            if kid not in results:
                results[kid] = {"id": kid, "title": row[1], "content": row[2],
                                "kw_score": 0, "vec_score": sim, "rrf": 0}
            results[kid]["rrf"] += 1.0 / (RRF_K + i + 1)

    # RRF 排序 → Top-K
    ranked = sorted(results.values(), key=lambda x: x["rrf"], reverse=True)
    return ranked[:top_k]


async def _keyword_search(db, query: str, kbs: list[str], limit: int = 20) -> list:
    """PostgreSQL tsvector 全文搜索 + ILIKE 回退（中文兼容）"""
    from sqlalchemy import or_
    clean = query.strip().replace("'", "''")[:150]

    # 策略1：尝试 tsvector（英文/已分词中文可用）
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

    # 策略2：ILIKE 模糊匹配
    # 中文无分词 → 用多级粒度片段做 OR 匹配（全量 + 中英拆分 + n-gram）
    import re
    conditions = []
    # 2a. 全量匹配
    if len(clean) > 1:
        conditions.append(KnowledgeEntry.title.ilike(f"%{clean}%"))
        conditions.append(KnowledgeEntry.content.ilike(f"%{clean}%"))
    # 2b. 中英混合拆分："星瑞L6的续航" → ["星瑞", "L6", "的续航"]
    for t in re.split(r'[\s,，。/、！？：:]+', clean):
        parts = re.split(r'([a-zA-Z0-9]+)', t)
        for p in parts:
            if len(p) >= 2 and p != clean:
                conditions.append(KnowledgeEntry.title.ilike(f"%{p}%"))
                conditions.append(KnowledgeEntry.content.ilike(f"%{p}%"))
    # 2c. 中文 3-gram, 4-gram（比2-gram更具体，避免过度匹配）
    chars = re.sub(r'[a-zA-Z0-9\s,，。/、！？：:]+', '', clean)
    for n in (3, 4):
        for i in range(len(chars) - n + 1):
            gram = chars[i:i+n]
            conditions.append(KnowledgeEntry.title.ilike(f"%{gram}%"))
            conditions.append(KnowledgeEntry.content.ilike(f"%{gram}%"))

    conditions = list(dict.fromkeys(conditions))[:24]  # 去重+限制

    stmt = select(KnowledgeEntry.id, KnowledgeEntry.title, KnowledgeEntry.content).where(
        KnowledgeEntry.status == "approved",
        KnowledgeEntry.knowledge_base.in_(kbs),
        or_(*conditions) if conditions else True,
    )
    result = await db.execute(stmt.limit(limit))
    return [(r[0], r[1], r[2], 0.6) for r in result.fetchall()]


async def _vector_search(db, query: str, kbs: list[str], limit: int = 20) -> list:
    """pgvector 余弦相似度搜索（不可用时返回空列表）"""
    try:
        # 检查 embedding 列是否存在
        check_sql = text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'knowledge_entries' AND column_name = 'embedding'
        """)
        result = await db.execute(check_sql)
        if not result.fetchone():
            logger.info("pgvector embedding 列不存在，跳过语义检索")
            return []

        # 检查是否有 embedding 数据
        count_sql = text("SELECT COUNT(*) FROM knowledge_entries WHERE embedding IS NOT NULL")
        result = await db.execute(count_sql)
        if (result.scalar() or 0) == 0:
            logger.info("无 embedding 数据，跳过语义检索")
            return []

        # embedding 存在但本地无 embedding API，返回空
        # TODO: Day 12 后续接入 embedding API 生成查询向量
        logger.info("语义检索就绪但无 embedding API，降级为纯关键词")
        return []

    except Exception as e:
        logger.info(f"语义检索不可用（正常降级）: {e}")
        return []


def _normalize_score(val, default=1.0) -> float:
    """分数归一化到 0~1"""
    try:
        return min(max(float(val), 0), 1)
    except (ValueError, TypeError):
        return default
