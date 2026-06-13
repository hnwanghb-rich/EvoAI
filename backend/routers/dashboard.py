"""
数据看板路由 —— 个人掌握度 / 首页仪表盘 / 团队 / 全局 / 飞轮
"""
import logging
from datetime import datetime, timedelta, date
from typing import Dict
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func, text, and_

from database import async_session
from models import (
    KnowledgeEntry, KnowledgeCategory, LearningRecord,
    ExperiencePoint, User, Department, ChatLog,
    DailyQuestion, ExamAttempt, ExamPaperQuestion,
    PositionCapability,
)
from schemas import ApiResponse
from auth import get_current_user, require_admin, require_boss
from recommendation import personalized_recommend
from cache import cache_get, cache_set

router = APIRouter()
logger = logging.getLogger(__name__)

POSITION_KB_MAP = {
    "sales": ["public", "sales"],
    "tech": ["public", "tech"],
    "service": ["public", "service"],
}

POSITIONS = ["sales", "tech", "service", "clerk"]


async def _calc_mastery_by_category(db, user_id: int, cat_ids: list[int]) -> Dict[int, dict]:
    """
    按知识分类计算用户掌握度（数据来源：每日一题答题 + 考试结果）
    返回 {category_id: {correct: int, total: int, mastery: float}}
    """
    result: Dict[int, dict] = {cid: {"correct": 0, "total": 0, "mastery": 0} for cid in cat_ids}

    # ---- 数据源1：每日一题答题结果 (learning_records with learn_type='test') ----
    if cat_ids:
        # 总答题数
        lr_total = await db.execute(
            select(
                KnowledgeEntry.category_id,
                func.count(LearningRecord.id),
            )
            .join(KnowledgeEntry, KnowledgeEntry.id == LearningRecord.knowledge_id)
            .where(
                LearningRecord.user_id == user_id,
                LearningRecord.learn_type == "test",
                KnowledgeEntry.category_id.in_(cat_ids),
            )
            .group_by(KnowledgeEntry.category_id)
        )
        for row in lr_total:
            cid, total = row[0], row[1] or 0
            result[cid]["total"] += total

        # 正确答题数（score >= 100 即为正确）
        lr_correct = await db.execute(
            select(
                KnowledgeEntry.category_id,
                func.count(LearningRecord.id),
            )
            .join(KnowledgeEntry, KnowledgeEntry.id == LearningRecord.knowledge_id)
            .where(
                LearningRecord.user_id == user_id,
                LearningRecord.learn_type == "test",
                LearningRecord.score >= 100,
                KnowledgeEntry.category_id.in_(cat_ids),
            )
            .group_by(KnowledgeEntry.category_id)
        )
        for row in lr_correct:
            cid, correct = row[0], row[1] or 0
            result[cid]["correct"] += correct

    # ---- 数据源2：考试答卷结果 (exam_attempts) ----
    # 获取用户所有已提交的答卷
    attempts = await db.execute(
        select(ExamAttempt).where(
            ExamAttempt.user_id == user_id,
            ExamAttempt.status == "submitted",
        )
    )
    attempts = attempts.scalars().all()

    if attempts:
        paper_ids = [a.paper_id for a in attempts]
        # 获取试卷题目 + 正确答案 + 分类
        pq_rows = await db.execute(
            select(
                ExamPaperQuestion.paper_id,
                DailyQuestion.id,
                DailyQuestion.answer,
                func.coalesce(DailyQuestion.category_id, KnowledgeEntry.category_id).label("cid"),
            )
            .join(DailyQuestion, DailyQuestion.id == ExamPaperQuestion.question_id)
            .outerjoin(KnowledgeEntry, KnowledgeEntry.id == DailyQuestion.related_knowledge_id)
            .where(ExamPaperQuestion.paper_id.in_(paper_ids))
        )

        # paper_id → [(qid, correct_answer, category_id), ...]
        paper_questions: Dict[int, list] = {}
        for row in pq_rows:
            pid, qid, ans, cid = row[0], row[1], row[2], row[3]
            if cid is None:
                continue
            paper_questions.setdefault(pid, []).append((qid, ans.strip().lower(), cid))

        # 逐份答卷判分
        for attempt in attempts:
            if attempt.paper_id not in paper_questions:
                continue
            user_answers = attempt.answers if isinstance(attempt.answers, dict) else {}
            for qid, correct_ans, cid in paper_questions[attempt.paper_id]:
                if cid not in result:
                    continue  # 不在该岗位的分类维度中，跳过
                user_ans = str(user_answers.get(str(qid), "")).strip().lower()
                is_correct = user_ans == correct_ans
                result[cid]["total"] += 1
                if is_correct:
                    result[cid]["correct"] += 1

    # 计算掌握度百分比
    for cid, v in result.items():
        v["mastery"] = round(v["correct"] / v["total"] * 100, 1) if v["total"] > 0 else 0

    return result


@router.get("/dashboard/home", response_model=ApiResponse)
async def home_dashboard(user: User = Depends(get_current_user)):
    """
    首页仪表盘 —— 按角色返回聚合数据
    - staff: 今日推送(个性化推荐) + 每日一题入口 + 学习进度 + 积分排名
    - admin: 待审核数量 + 本周沉淀 + 团队达标率 + 知识健康度 + 题库预警
    - boss: 四大核心指标 + 飞轮概况 + 预警区
    """
    # 缓存检查（每用户5分钟）
    cache_uid = f"dashboard_home:{user.id}"
    cached = await cache_get(cache_uid)
    if cached:
        return ApiResponse(data=cached)

    async with async_session() as db:
        base = {}

        # === 通用数据 ===
        # 知识总量
        total_r = await db.execute(
            select(func.count(KnowledgeEntry.id)).where(KnowledgeEntry.status == "approved")
        )
        base["knowledge_total"] = total_r.scalar() or 0

        if user.role.value in ("admin", "boss"):
            all_kb = ["public", "sales", "tech", "service"]
        else:
            pos = user.position.value if user.position else "sales"
            m = {"sales": ["public", "sales"], "tech": ["public", "tech"], "service": ["public", "service"]}
            all_kb = m.get(pos, ["public"])

        # 可见知识库内的知识量
        kb_total_r = await db.execute(
            select(func.count(KnowledgeEntry.id)).where(
                KnowledgeEntry.status == "approved",
                KnowledgeEntry.knowledge_base.in_(all_kb),
            )
        )
        base["kb_total"] = kb_total_r.scalar() or 0

        # === 职员首页 ===
        if user.role.value == "staff":
            # 个性化推荐 TOP-5（含推荐原因）
            recommends = await personalized_recommend(user, top_k=5)

            # 今日是否有每日一题
            from models import DailyQuestion
            today_q_r = await db.execute(
                select(func.count(DailyQuestion.id)).where(DailyQuestion.push_date == date.today())
            )
            has_today_question = (today_q_r.scalar() or 0) > 0

            # 本周学习
            week_start = datetime.utcnow() - timedelta(days=datetime.utcnow().weekday())
            week_r = await db.execute(
                select(
                    func.count(LearningRecord.id),
                    func.coalesce(func.sum(LearningRecord.duration_sec), 0),
                ).where(
                    LearningRecord.user_id == user.id,
                    LearningRecord.created_at >= week_start,
                )
            )
            wrow = week_r.one()
            week_learned = wrow[0] or 0
            week_duration = wrow[1] or 0

            # 积分排名
            my_pts = (await db.execute(
                select(func.coalesce(func.sum(ExperiencePoint.points), 0))
                .where(ExperiencePoint.user_id == user.id)
            )).scalar() or 0

            rank_r = await db.execute(text("""
                SELECT COUNT(*) + 1 FROM (
                    SELECT user_id, SUM(points) AS sp
                    FROM experience_points GROUP BY user_id
                    HAVING SUM(points) > :my
                ) h
            """), {"my": my_pts})
            my_rank = rank_r.scalar() or 1

            # 总掌握度（简版）
            cat_r = await db.execute(
                select(KnowledgeEntry.category_id, func.count(KnowledgeEntry.id))
                .where(KnowledgeEntry.status == "approved", KnowledgeEntry.knowledge_base.in_(all_kb))
                .group_by(KnowledgeEntry.category_id)
            )
            cat_totals = {r[0]: r[1] for r in cat_r.all()}
            learned_r = await db.execute(
                select(KnowledgeEntry.category_id, func.count(func.distinct(LearningRecord.knowledge_id)))
                .join(KnowledgeEntry, KnowledgeEntry.id == LearningRecord.knowledge_id)
                .where(LearningRecord.user_id == user.id)
                .group_by(KnowledgeEntry.category_id)
            )
            learned_c = {r[0]: r[1] for r in learned_r.all()}
            tl = sum(learned_c.values())
            ta = sum(cat_totals.values())
            mastery = round(tl / ta * 100, 1) if ta > 0 else 0

            data = {
                **base,
                "recommends": recommends,
                "has_today_question": has_today_question,
                "week_learned": week_learned,
                "week_duration_sec": week_duration,
                "my_points": my_pts,
                "my_rank": my_rank,
                "overall_mastery": mastery,
                "role_view": "staff",
            }

        # === 管理员首页 ===
        elif user.role.value == "admin":
            # 待审核
            pending_r = await db.execute(
                select(func.count(KnowledgeEntry.id)).where(KnowledgeEntry.status == "pending")
            )
            pending = pending_r.scalar() or 0

            # 本周经验沉淀（提交数）
            week_start = datetime.utcnow() - timedelta(days=datetime.utcnow().weekday())
            week_submit_r = await db.execute(
                select(func.count(ExperiencePoint.id)).where(
                    ExperiencePoint.action_type == "submit",
                    ExperiencePoint.created_at >= week_start,
                )
            )
            week_deposit = week_submit_r.scalar() or 0

            # 团队达标率（至少学过 1 条知识的用户占比）
            learned_users_r = await db.execute(
                select(func.count(func.distinct(LearningRecord.user_id)))
            )
            learned_users = learned_users_r.scalar() or 0
            total_users_r = await db.execute(
                select(func.count(User.id)).where(User.status == 1)
            )
            total_users = total_users_r.scalar() or 1
            learning_rate = round(learned_users / total_users * 100, 1)

            # 知识健康度（最近6个月新增比例）
            six_months = datetime.utcnow() - timedelta(days=180)
            recent_kr = await db.execute(
                select(func.count(KnowledgeEntry.id)).where(
                    KnowledgeEntry.status == "approved",
                    KnowledgeEntry.created_at >= six_months,
                )
            )
            recent_knowledge = recent_kr.scalar() or 0
            total_kr = await db.execute(
                select(func.count(KnowledgeEntry.id)).where(KnowledgeEntry.status == "approved")
            )
            total_k = total_kr.scalar() or 1
            knowledge_health = round(recent_knowledge / total_k * 100, 1)

            # 题库预警（题数不足10的分岗位统计）
            from models import DailyQuestion
            q_stats_r = await db.execute(
                select(DailyQuestion.target_position, func.count(DailyQuestion.id))
                .group_by(DailyQuestion.target_position)
            )
            q_stats = {r[0] or "public": r[1] for r in q_stats_r.all()}
            low_question_positions = [pos for pos, cnt in q_stats.items() if cnt < 10]

            data = {
                **base,
                "pending_count": pending,
                "week_deposit": week_deposit,
                "learning_rate": learning_rate,
                "knowledge_health": knowledge_health,
                "low_question_positions": low_question_positions,
                "role_view": "admin",
            }

        # === 老板首页 ===
        else:
            # 月新增
            month_start = datetime.utcnow().replace(day=1)
            month_new_r = await db.execute(
                select(func.count(KnowledgeEntry.id)).where(
                    KnowledgeEntry.status == "approved",
                    KnowledgeEntry.created_at >= month_start,
                )
            )
            month_new = month_new_r.scalar() or 0

            # 员工总数
            staff_c = (await db.execute(
                select(func.count(User.id)).where(User.status == 1)
            )).scalar() or 0

            # 飞轮简版数据
            month_deposit_r = await db.execute(
                select(func.count(ExperiencePoint.id)).where(
                    ExperiencePoint.action_type == "submit",
                    ExperiencePoint.created_at >= month_start,
                )
            )
            fly_deposit = month_deposit_r.scalar() or 0

            # 知识复用率
            total_chat = (await db.execute(select(func.count(ChatLog.id)))).scalar() or 0
            hit_chat = (await db.execute(
                select(func.count(ChatLog.id)).where(ChatLog.is_hit == 1)
            )).scalar() or 0
            reuse = round(hit_chat / total_chat * 100, 1) if total_chat > 0 else 0

            # 连续30天无沉淀部门
            dead_day = datetime.utcnow() - timedelta(days=30)
            dept_r = await db.execute(select(Department.id, Department.name))
            dead_depts = []
            for did, dname in dept_r.all():
                cnt = (await db.execute(
                    select(func.count(ExperiencePoint.id)).join(
                        User, User.id == ExperiencePoint.user_id
                    ).where(
                        User.dept_id == did,
                        ExperiencePoint.action_type == "submit",
                        ExperiencePoint.created_at >= dead_day,
                    )
                )).scalar() or 0
                if cnt == 0:
                    dead_depts.append({"id": did, "name": dname})

            data = {
                **base,
                "month_new": month_new,
                "staff_count": staff_c,
                "flywheel_deposit": fly_deposit,
                "flywheel_reuse_rate": reuse,
                "dead_departments": dead_depts,
                "role_view": "boss",
            }

    # 写入缓存（5分钟）
    await cache_set(cache_uid, data, 300)
    return ApiResponse(data=data)


@router.get("/dashboard/personal", response_model=ApiResponse)
async def personal_dashboard(user: User = Depends(get_current_user)):
    """个人知识掌握度看板 —— 数据源：考试结果 + 每日一题答题"""
    pos = user.position.value if user.position else "sales"
    allowed_kb = POSITION_KB_MAP.get(pos, ["public"])
    if user.role.value in ("admin", "boss"):
        allowed_kb = ["public", "sales", "tech", "service"]

    async with async_session() as db:
        # 1. 从 position_capabilities 获取该岗位应掌握的分类
        pos_cat_ids = []
        if user.position:
            pc_r = await db.execute(
                select(PositionCapability.category_id).where(
                    PositionCapability.position == user.position.value,
                )
            )
            pos_cat_ids = [r[0] for r in pc_r.all()]

        # 如果岗位能力未配置，回退到 knowledge_base 方式
        if not pos_cat_ids:
            pos = user.position.value if user.position else "sales"
            allowed_kb = POSITION_KB_MAP.get(pos, ["public"])
            if user.role.value in ("admin", "boss"):
                allowed_kb = ["public", "sales", "tech", "service"]
            kb_cat_r = await db.execute(
                select(KnowledgeCategory.id).where(
                    KnowledgeCategory.knowledge_base.in_(allowed_kb),
                )
            )
            pos_cat_ids = [r[0] for r in kb_cat_r.all()]

        # 2. 获取这些分类的详情（含无知识条目的）
        cat_rows = await db.execute(
            select(
                KnowledgeCategory.id,
                KnowledgeCategory.name,
                KnowledgeCategory.icon,
                KnowledgeCategory.description,
                KnowledgeCategory.knowledge_base,
                func.coalesce(func.count(KnowledgeEntry.id), 0).label("total"),
            )
            .outerjoin(KnowledgeEntry, and_(
                KnowledgeEntry.category_id == KnowledgeCategory.id,
                KnowledgeEntry.status == "approved",
            ))
            .where(KnowledgeCategory.id.in_(pos_cat_ids) if pos_cat_ids else True)
            .group_by(KnowledgeCategory.id, KnowledgeCategory.name, KnowledgeCategory.icon, KnowledgeCategory.description, KnowledgeCategory.knowledge_base)
            .order_by(KnowledgeCategory.sort_order)
        )
        cat_info = {}
        all_cat_ids = []
        for r in cat_rows.all():
            cid, name, icon, desc, kb, total = r[0], r[1], r[2], r[3], r[4], r[5]
            # 所有岗位配置的分类都显示，不因 total=0 过滤
            cat_info[cid] = {"name": name, "icon": icon, "description": desc, "total": total}
            all_cat_ids.append(cid)

        # 2. 计算每分类掌握度（考试 + 每日一题）
        mastery_map = await _calc_mastery_by_category(db, user.id, all_cat_ids)

        # 3. 雷达图数据
        radar_data = []
        for cid, info in cat_info.items():
            m = mastery_map.get(cid, {"correct": 0, "total": 0, "mastery": 0})
            radar_data.append({
                "category_id": cid,
                "category_name": info["name"],
                "icon": info["icon"],
                "description": info.get("description") or "",
                "mastery": m["mastery"],
                "learned": m["correct"],          # 已做对题目数
                "total": m["total"],              # 应完成题目数（总答题数）
                "expected": 80,
            })
        radar_data.sort(key=lambda x: x["mastery"])
        weak_areas = [d for d in radar_data if d["total"] > 0][:3]  # 薄弱的 = 有数据但掌握度低的
        if not weak_areas:
            weak_areas = radar_data[:3]

        # 总掌握度 = 各分类掌握度加权平均
        total_correct = sum(mastery_map.get(cid, {}).get("correct", 0) for cid in all_cat_ids)
        total_answered = sum(mastery_map.get(cid, {}).get("total", 0) for cid in all_cat_ids)
        overall_mastery = round(total_correct / total_answered * 100, 1) if total_answered > 0 else 0

        # 4. 积分 + 排名
        points_r = await db.execute(
            select(func.coalesce(func.sum(ExperiencePoint.points), 0))
            .where(ExperiencePoint.user_id == user.id)
        )
        my_points = points_r.scalar() or 0

        rank_sql = text("""
            SELECT COUNT(*) + 1 FROM (
                SELECT user_id, SUM(points) AS sp
                FROM experience_points
                GROUP BY user_id
                HAVING SUM(points) > :my
            ) AS higher
        """)
        rank_r = await db.execute(rank_sql, {"my": my_points})
        company_rank = rank_r.scalar() or 1

        dept_rank = company_rank
        if user.dept_id:
            dept_sql = text("""
                SELECT COUNT(*) + 1 FROM (
                    SELECT ep.user_id, SUM(ep.points) AS sp
                    FROM experience_points ep
                    JOIN users u ON u.id = ep.user_id
                    WHERE u.dept_id = :did
                    GROUP BY ep.user_id
                    HAVING SUM(ep.points) > :my
                ) AS higher
            """)
            dr = await db.execute(dept_sql, {"did": user.dept_id, "my": my_points})
            dept_rank = dr.scalar() or 1

        # 5. 本周统计
        week_start = datetime.utcnow() - timedelta(days=datetime.utcnow().weekday())
        week_r = await db.execute(
            select(
                func.count(LearningRecord.id),
                func.coalesce(func.sum(LearningRecord.duration_sec), 0),
            )
            .where(
                LearningRecord.user_id == user.id,
                LearningRecord.created_at >= week_start,
            )
        )
        row = week_r.one()
        week_learned, week_duration = row[0] or 0, row[1] or 0

        # 6. 最近学习/考试记录
        recent_r = await db.execute(
            select(
                LearningRecord.id, LearningRecord.knowledge_id,
                LearningRecord.learn_type, KnowledgeEntry.title,
                LearningRecord.created_at,
            )
            .join(KnowledgeEntry, KnowledgeEntry.id == LearningRecord.knowledge_id, isouter=True)
            .where(LearningRecord.user_id == user.id)
            .order_by(LearningRecord.created_at.desc())
            .limit(10)
        )
        recent = [
            {
                "id": r[0], "knowledge_id": r[1], "learn_type": r[2],
                "knowledge_title": r[3] or "", "created_at": r[4].isoformat() if r[4] else None,
            }
            for r in recent_r.all()
        ]

        data = {
            "overall_mastery": overall_mastery,
            "my_points": my_points,
            "company_rank": company_rank,
            "dept_rank": dept_rank,
            "week_learned": week_learned,
            "week_duration_sec": week_duration,
            "radar_data": radar_data,
            "weak_areas": weak_areas,
            "recent_records": recent,
        }
    return ApiResponse(data=data)


# ============================================================
# Day 9: 团队看板
# ============================================================

@router.get("/dashboard/team", response_model=ApiResponse)
async def team_dashboard(
    dept_id: int = Query(0),
    position: str = Query(""),
    user: User = Depends(require_admin),
):
    """团队看板 —— 按岗位聚合 + 考试/每日一题数据源，position=空则全公司"""
    async with async_session() as db:
        # 按岗位筛选员工
        if position and position in POSITIONS:
            users_q = select(User).where(
                User.status == 1,
                User.position == position,
            )
        else:
            users_q = select(User).where(User.status == 1)
        all_users_r = await db.execute(users_q)
        all_users = all_users_r.scalars().all()
        all_mids = [u.id for u in all_users]
        member_count = len(all_users)

        # 员工ID → 岗位名
        user_pos: Dict[int, str] = {u.id: u.position.value if u.position else "" for u in all_users}

        # 部门名（取第一个部门兜底）
        dept_name = "全公司"
        if user.dept_id:
            dr = await db.execute(select(Department.name).where(Department.id == user.dept_id))
            dept_name = dr.scalar_one_or_none() or "全公司"

        # 全部分类
        cat_rows = await db.execute(
            select(
                KnowledgeCategory.id,
                KnowledgeCategory.name,
                KnowledgeCategory.icon,
                KnowledgeCategory.description,
                func.count(KnowledgeEntry.id).label("total"),
            )
            .outerjoin(KnowledgeEntry, and_(
                KnowledgeEntry.category_id == KnowledgeCategory.id,
                KnowledgeEntry.status == "approved",
            ))
            .group_by(KnowledgeCategory.id, KnowledgeCategory.name, KnowledgeCategory.icon, KnowledgeCategory.description)
            .order_by(KnowledgeCategory.sort_order)
        )
        cat_info = {}
        all_cat_ids = []
        for r in cat_rows.all():
            cid, name, icon, desc, total = r[0], r[1], r[2], r[3], r[4]
            if total > 0:
                cat_info[cid] = {"name": name, "icon": icon, "description": desc, "total": total}
                all_cat_ids.append(cid)

        # 聚合每个员工每分类的掌握度 → 再聚合为团队
        cat_agg: Dict[int, dict] = {cid: {"correct": 0, "total_answered": 0, "user_count": 0} for cid in all_cat_ids}
        for uid in all_mids:
            member_mastery = await _calc_mastery_by_category(db, uid, all_cat_ids)
            for cid, v in member_mastery.items():
                if v["total"] > 0:  # 该员工在这个分类有答题数据
                    cat_agg[cid]["correct"] += v["correct"]
                    cat_agg[cid]["total_answered"] += v["total"]
                    cat_agg[cid]["user_count"] += 1

        # 雷达图
        radar_data = []
        for cid, info in cat_info.items():
            agg = cat_agg[cid]
            mastery = round(agg["correct"] / agg["total_answered"] * 100, 1) if agg["total_answered"] > 0 else 0
            radar_data.append({
                "category_id": cid,
                "category_name": info["name"],
                "icon": info["icon"],
                "description": info.get("description") or "",
                "mastery": mastery,
                "total": agg["total_answered"],  # 答题总数
                "users": agg["user_count"],       # 参与人数
                "expected": 80,
            })
        radar_data.sort(key=lambda x: x["mastery"])
        weak_areas = [d for d in radar_data if d["total"] > 0][:3]
        if not weak_areas:
            weak_areas = radar_data[:3]

        all_correct = sum(v["correct"] for v in cat_agg.values())
        all_answered = sum(v["total_answered"] for v in cat_agg.values())
        team_mastery = round(all_correct / all_answered * 100, 1) if all_answered > 0 else 0

        # 成员排行榜（按积分）
        member_rank = []
        for u in all_users:
            pr = await db.execute(
                select(func.coalesce(func.sum(ExperiencePoint.points), 0))
                .where(ExperiencePoint.user_id == u.id)
            )
            pts = pr.scalar() or 0
            member_rank.append({
                "user_id": u.id,
                "real_name": u.real_name,
                "position": user_pos.get(u.id, ""),
                "points": pts,
            })
        member_rank.sort(key=lambda x: x["points"], reverse=True)

        # 本月新增学习条目总数
        month_start = datetime.utcnow().replace(day=1)
        month_learned_r = await db.execute(
            select(func.count(LearningRecord.id)).where(
                LearningRecord.user_id.in_(all_mids) if all_mids else [0],
                LearningRecord.created_at >= month_start,
            )
        )
        month_learned = month_learned_r.scalar() or 0

        data = {
            "dept_name": dept_name,
            "dept_id": user.dept_id or 0,
            "member_count": member_count,
            "team_mastery": team_mastery,
            "month_new_learned": month_learned,
            "radar_data": radar_data,
            "weak_areas": weak_areas,
            "member_rank": member_rank,
        }
    return ApiResponse(data=data)


# ============================================================
# Day 9: 集团BI大屏（老板专属）
# ============================================================

@router.get("/dashboard/global", response_model=ApiResponse)
async def global_dashboard(_user: User = Depends(require_boss)):
    """集团全景数据"""
    async with async_session() as db:
        # 知识总量（approved）
        total_r = await db.execute(
            select(func.count(KnowledgeEntry.id)).where(KnowledgeEntry.status == "approved")
        )
        knowledge_total = total_r.scalar() or 0

        # 月新增
        month_start = datetime.utcnow().replace(day=1)
        month_new_r = await db.execute(
            select(func.count(KnowledgeEntry.id)).where(
                KnowledgeEntry.status == "approved",
                KnowledgeEntry.created_at >= month_start,
            )
        )
        month_new = month_new_r.scalar() or 0

        # 员工总数
        staff_r = await db.execute(select(func.count(User.id)).where(User.status == 1))
        staff_count = staff_r.scalar() or 0

        # 四大知识库占比
        kb_r = await db.execute(
            select(KnowledgeEntry.knowledge_base, func.count(KnowledgeEntry.id))
            .where(KnowledgeEntry.status == "approved")
            .group_by(KnowledgeEntry.knowledge_base)
        )
        kb_ratio = [{"name": r[0], "count": r[1]} for r in kb_r.all()]

        # 月度增长趋势（近6个月）
        trend = []
        for i in range(5, -1, -1):
            m = datetime.utcnow().month - i
            y = datetime.utcnow().year
            if m <= 0:
                m += 12
                y -= 1
            ms = datetime(y, m, 1)
            me = datetime(y + (m // 12), (m % 12) + 1, 1) if m < 12 else datetime(y + 1, 1, 1)
            cnt_r = await db.execute(
                select(func.count(KnowledgeEntry.id)).where(
                    KnowledgeEntry.created_at >= ms,
                    KnowledgeEntry.created_at < me,
                    KnowledgeEntry.status == "approved",
                )
            )
            trend.append({"month": f"{y}-{m:02d}", "count": cnt_r.scalar() or 0})

        # 飞轮数据
        fly = await _flywheel_data(db)

        data = {
            "knowledge_total": knowledge_total,
            "month_new": month_new,
            "staff_count": staff_count,
            "kb_ratio": kb_ratio,
            "trend": trend,
            **fly,
        }
    return ApiResponse(data=data)


@router.get("/dashboard/flywheel", response_model=ApiResponse)
async def flywheel(_user: User = Depends(require_admin)):
    """飞轮运转指标"""
    async with async_session() as db:
        data = await _flywheel_data(db)
    return ApiResponse(data=data)


async def _flywheel_data(db):
    """飞轮运转数据（内部调用）"""
    # 月新沉淀（本月经验提交数）
    month_start = datetime.utcnow().replace(day=1)
    month_submit_r = await db.execute(
        select(func.count(ExperiencePoint.id)).where(
            ExperiencePoint.action_type == "submit",
            ExperiencePoint.created_at >= month_start,
        )
    )
    month_deposit = month_submit_r.scalar() or 0

    # 迭代率（本月归档数 / 总 approved 数）
    month_archived_r = await db.execute(
        select(func.count(KnowledgeEntry.id)).where(
            KnowledgeEntry.status == "archived",
            KnowledgeEntry.updated_at >= month_start,
        )
    )
    month_archived = month_archived_r.scalar() or 0
    total_approved_r = await db.execute(
        select(func.count(KnowledgeEntry.id)).where(KnowledgeEntry.status == "approved")
    )
    total_approved = total_approved_r.scalar() or 1
    iteration_rate = round(month_archived / total_approved * 100, 1)

    # 复用率（对话命中率）
    total_chat_r = await db.execute(select(func.count(ChatLog.id)))
    total_chat = total_chat_r.scalar() or 0
    hit_chat_r = await db.execute(
        select(func.count(ChatLog.id)).where(ChatLog.is_hit == 1)
    )
    hit_chat = hit_chat_r.scalar() or 0
    reuse_rate = round(hit_chat / total_chat * 100, 1) if total_chat > 0 else 0

    # 经验贡献 TOP10
    top_r = await db.execute(
        select(
            User.real_name,
            func.sum(ExperiencePoint.points),
            User.position,
        )
        .join(User, User.id == ExperiencePoint.user_id)
        .where(ExperiencePoint.action_type.in_(["submit", "approved"]))
        .group_by(User.id, User.real_name, User.position)
        .order_by(func.sum(ExperiencePoint.points).desc())
        .limit(10)
    )
    top10 = [{"name": r[0] or "", "points": r[1] or 0, "position": r[2] or ""} for r in top_r.all()]

    # 连续30天无沉淀的部门
    dead_day = datetime.utcnow() - timedelta(days=30)
    all_depts_r = await db.execute(select(Department.id, Department.name))
    all_depts = all_depts_r.all()
    dead_depts = []
    for did, dname in all_depts:
        # 该部门近30天提交数
        cnt_r = await db.execute(
            select(func.count(ExperiencePoint.id)).join(
                User, User.id == ExperiencePoint.user_id
            ).where(
                User.dept_id == did,
                ExperiencePoint.action_type == "submit",
                ExperiencePoint.created_at >= dead_day,
            )
        )
        if (cnt_r.scalar() or 0) == 0:
            dead_depts.append({"dept_id": did, "dept_name": dname})

    # 高频未命中 TOP5（is_hit=0 的问题聚类）
    no_hit_r = await db.execute(
        select(ChatLog.question, func.count(ChatLog.id))
        .where(ChatLog.is_hit == 0)
        .group_by(ChatLog.question)
        .order_by(func.count(ChatLog.id).desc())
        .limit(5)
    )
    no_hit_top5 = [{"question": r[0], "count": r[1]} for r in no_hit_r.all()]

    return {
        "flywheel_deposit": month_deposit,
        "flywheel_iteration_rate": iteration_rate,
        "flywheel_reuse_rate": reuse_rate,
        "top10_contributors": top10,
        "dead_departments": dead_depts,
        "no_hit_top5": no_hit_top5,
    }
