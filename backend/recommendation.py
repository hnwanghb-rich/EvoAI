"""
个性化推荐引擎 —— 基于掌握度 + 学习记录为用户推荐知识
"""
import logging
from datetime import datetime, timedelta
from sqlalchemy import select, func, and_

from database import async_session
from models import KnowledgeEntry, KnowledgeCategory, LearningRecord, User

logger = logging.getLogger(__name__)

POSITION_KB_MAP = {
    "sales": ["public", "sales"],
    "tech": ["public", "tech"],
    "service": ["public", "service"],
}


async def personalized_recommend(user: User, top_k: int = 5) -> list[dict]:
    """
    个性化推荐：输入 user + position → 输出推荐知识列表 + 推荐原因
    策略：
    1. 薄弱领域优先（掌握度最低分类的知识排在前面）
    2. 高价值知识（useful_count 高 or view_count 高）
    3. 排除已学过的知识
    """
    pos = user.position.value if user.position else "sales"
    allowed_kb = POSITION_KB_MAP.get(pos, ["public"])
    if user.role.value in ("admin", "boss"):
        allowed_kb = ["public", "sales", "tech", "service"]

    async with async_session() as db:
        # 1. 找出薄弱领域：各分类的掌握度
        cat_r = await db.execute(
            select(
                KnowledgeEntry.category_id,
                func.count(KnowledgeEntry.id),
                KnowledgeCategory.name,
                KnowledgeCategory.icon,
            )
            .join(KnowledgeCategory, KnowledgeCategory.id == KnowledgeEntry.category_id)
            .where(
                KnowledgeEntry.status == "approved",
                KnowledgeEntry.knowledge_base.in_(allowed_kb),
            )
            .group_by(KnowledgeEntry.category_id, KnowledgeCategory.name, KnowledgeCategory.icon)
        )
        cat_totals = {
            r[0]: {"name": r[2], "icon": r[3], "total": r[1]}
            for r in cat_r.all()
        }

        # 2. 用户已学分布
        learned_r = await db.execute(
            select(
                KnowledgeEntry.category_id,
                func.count(func.distinct(LearningRecord.knowledge_id)),
            )
            .join(KnowledgeEntry, KnowledgeEntry.id == LearningRecord.knowledge_id)
            .where(
                LearningRecord.user_id == user.id,
                KnowledgeEntry.knowledge_base.in_(allowed_kb),
            )
            .group_by(KnowledgeEntry.category_id)
        )
        learned_counts = {r[0]: r[1] for r in learned_r.all()}

        # 3. 薄弱分类 → 掌握度排序 (低→高)
        cat_mastery = []
        for cat_id, info in cat_totals.items():
            learned = learned_counts.get(cat_id, 0)
            mastery = round(learned / info["total"] * 100, 1) if info["total"] > 0 else 0
            cat_mastery.append((cat_id, mastery, info["name"]))

        cat_mastery.sort(key=lambda x: x[1])  # 升序：薄弱优先

        # 4. 用户已学知识 ID 集合
        learned_ids_r = await db.execute(
            select(LearningRecord.knowledge_id).where(LearningRecord.user_id == user.id)
        )
        learned_ids = set(r[0] for r in learned_ids_r.all())

        # 5. 从薄弱分类中选取推荐条目
        results = []
        seen = set()

        # 5a. 薄弱分类：每个分类取最多2条
        for cat_id, mastery, cat_name in cat_mastery[:4]:
            if mastery >= 80:  # 掌握度 >= 80% 不算薄弱
                continue
            rows = (await db.execute(
                select(KnowledgeEntry)
                .where(
                    KnowledgeEntry.category_id == cat_id,
                    KnowledgeEntry.status == "approved",
                    KnowledgeEntry.knowledge_base.in_(allowed_kb),
                    ~KnowledgeEntry.id.in_(learned_ids) if learned_ids else True,
                )
                .order_by(
                    KnowledgeEntry.useful_count.desc(),
                    KnowledgeEntry.view_count.desc(),
                )
                .limit(2)
            )).scalars().all()

            for entry in rows:
                if entry.id not in seen:
                    seen.add(entry.id)
                    results.append({
                        "id": entry.id,
                        "title": entry.title,
                        "content": entry.content[:150],
                        "car_brand": entry.car_brand,
                        "car_model": entry.car_model,
                        "knowledge_base": entry.knowledge_base.value,
                        "category_id": entry.category_id,
                        "view_count": entry.view_count,
                        "useful_count": entry.useful_count,
                        "reason": f"你的{cat_name}知识掌握度较低({mastery}%)，建议学习",
                        "reason_type": "weak",
                    })

        # 5b. 补充热门知识（未学过的）
        if len(results) < top_k:
            hot_rows = (await db.execute(
                select(KnowledgeEntry)
                .where(
                    KnowledgeEntry.status == "approved",
                    KnowledgeEntry.knowledge_base.in_(allowed_kb),
                    ~KnowledgeEntry.id.in_(learned_ids) if learned_ids else True,
                )
                .order_by(
                    KnowledgeEntry.view_count.desc(),
                    KnowledgeEntry.useful_count.desc(),
                )
                .limit(top_k * 2)
            )).scalars().all()

            for entry in hot_rows:
                if entry.id not in seen:
                    seen.add(entry.id)
                    results.append({
                        "id": entry.id,
                        "title": entry.title,
                        "content": entry.content[:150],
                        "car_brand": entry.car_brand,
                        "car_model": entry.car_model,
                        "knowledge_base": entry.knowledge_base.value,
                        "category_id": entry.category_id,
                        "view_count": entry.view_count,
                        "useful_count": entry.useful_count,
                        "reason": "热门知识，多数同事都在学习",
                        "reason_type": "hot",
                    })
                if len(results) >= top_k:
                    break

    return results[:top_k]


async def get_weak_category_ids(user: User) -> list[int]:
    """返回用户薄弱领域的分类 ID 列表（掌握度 < 50% 的）"""
    pos = user.position.value if user.position else "sales"
    allowed_kb = POSITION_KB_MAP.get(pos, ["public"])
    if user.role.value in ("admin", "boss"):
        allowed_kb = ["public", "sales", "tech", "service"]

    async with async_session() as db:
        cat_r = await db.execute(
            select(KnowledgeEntry.category_id, func.count(KnowledgeEntry.id))
            .where(
                KnowledgeEntry.status == "approved",
                KnowledgeEntry.knowledge_base.in_(allowed_kb),
            )
            .group_by(KnowledgeEntry.category_id)
        )
        cat_totals = {r[0]: r[1] for r in cat_r.all()}

        learned_r = await db.execute(
            select(KnowledgeEntry.category_id, func.count(func.distinct(LearningRecord.knowledge_id)))
            .join(KnowledgeEntry, KnowledgeEntry.id == LearningRecord.knowledge_id)
            .where(LearningRecord.user_id == user.id)
            .group_by(KnowledgeEntry.category_id)
        )
        learned = {r[0]: r[1] for r in learned_r.all()}

        weak_ids = []
        for cat_id, total in cat_totals.items():
            lc = learned.get(cat_id, 0)
            mastery = round(lc / total * 100, 1) if total > 0 else 100
            if mastery < 50:
                weak_ids.append(cat_id)

    return weak_ids
