"""
飞轮运营总览 (FW-02) —— 全环指标聚合
势能 / 转速 / 加速度 / 摩擦力 / 北极星（命中满意率）
全部从现有表实时聚合，不建新表。
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


@router.get("/flywheel/metrics/summary", response_model=ApiResponse)
async def metrics_summary(_admin: User = Depends(require_admin)):
    """飞轮四象限指标 + 北极星"""
    async with async_session() as db:

        # ── 北极星：近30天命中满意率 ──────────────────────────────
        star_row = (await db.execute(text("""
            SELECT
                COUNT(*) FILTER (WHERE is_hit = 1 AND (is_satisfied IS NULL OR is_satisfied = 1))
                    AS hit_ok,
                COUNT(*) AS total
            FROM chat_logs
            WHERE created_at >= NOW() - INTERVAL '30 days'
        """))).first()
        star_total = star_row[1] or 0
        star_hit = star_row[0] or 0
        north_star = round(star_hit / star_total * 100, 1) if star_total > 0 else None

        # ── 势能：各知识库 approved 存量 ────────────────────────────
        kb_rows = (await db.execute(text("""
            SELECT knowledge_base, COUNT(*) AS cnt
            FROM knowledge_entries
            WHERE status = 'approved'
            GROUP BY knowledge_base
        """))).all()
        kb_map = {str(r[0].value if hasattr(r[0], 'value') else r[0]): r[1] for r in kb_rows}
        total_approved = sum(kb_map.values())

        # ── 转速：近30天命中率 + useful_count 合计 ───────────────────
        hit_row = (await db.execute(text("""
            SELECT
                COUNT(*) FILTER (WHERE is_hit = 1) AS hits,
                COUNT(*) AS total
            FROM chat_logs
            WHERE created_at >= NOW() - INTERVAL '30 days'
        """))).first()
        hit_total = hit_row[1] or 0
        hit_ok = hit_row[0] or 0
        hit_rate_30d = round(hit_ok / hit_total * 100, 1) if hit_total > 0 else None

        useful_row = (await db.execute(text("""
            SELECT COALESCE(SUM(useful_count), 0)
            FROM knowledge_entries
            WHERE status = 'approved'
        """))).scalar()

        # ── 加速度：本周新沉淀 + 近30天缺口闭合数 ────────────────────
        new_exp_row = (await db.execute(text("""
            SELECT COUNT(*) FROM knowledge_entries
            WHERE source_type = 'experience'
              AND created_at >= date_trunc('week', NOW())
        """))).scalar() or 0

        gap_closed_row = (await db.execute(text("""
            SELECT COUNT(*) FROM knowledge_gaps
            WHERE status = 'closed'
              AND closed_at >= NOW() - INTERVAL '30 days'
        """))).scalar() or 0

        gap_open_row = (await db.execute(text("""
            SELECT COUNT(*) FROM knowledge_gaps WHERE status = 'assigned'
        """))).scalar() or 0

        # ── 摩擦力：expire_at 依赖 FW-04，未上线显示 null ────────────
        friction = {
            "expired_count": None,
            "note": "知识时效中心(FW-04)启用后将显示过期未复审数量",
        }

        # ── 近7天北极星趋势（按天）────────────────────────────────
        trend_rows = (await db.execute(text("""
            SELECT
                DATE(created_at AT TIME ZONE 'Asia/Shanghai') AS day,
                COUNT(*) FILTER (WHERE is_hit = 1) AS hits,
                COUNT(*) AS total
            FROM chat_logs
            WHERE created_at >= NOW() - INTERVAL '7 days'
            GROUP BY 1
            ORDER BY 1
        """))).all()
        trend = [{
            "day": str(r[0]),
            "hit_rate": round(r[1] / r[2] * 100, 1) if r[2] > 0 else 0,
            "total": r[2],
        } for r in trend_rows]

        # ── 高频未命中TOP5（近30天）────────────────────────────────
        miss_rows = (await db.execute(text("""
            SELECT question, COUNT(*) AS cnt
            FROM chat_logs
            WHERE is_hit = 0
              AND created_at >= NOW() - INTERVAL '30 days'
            GROUP BY question
            ORDER BY cnt DESC
            LIMIT 5
        """))).all()
        top_miss = [{"question": r[0], "count": r[1]} for r in miss_rows]

    return ApiResponse(data={
        "north_star": {
            "hit_satisfied_rate": north_star,
            "total_30d": star_total,
            "label": "近30天命中满意率",
        },
        "momentum": {
            "total_approved": total_approved,
            "by_kb": kb_map,
            "label": "知识势能（有效条目）",
        },
        "velocity": {
            "hit_rate_30d": hit_rate_30d,
            "hit_total_30d": hit_total,
            "useful_total": int(useful_row or 0),
            "label": "飞轮转速（复用频率）",
        },
        "acceleration": {
            "new_experience_this_week": int(new_exp_row),
            "gaps_closed_30d": int(gap_closed_row),
            "gaps_open": int(gap_open_row),
            "label": "进化加速度",
        },
        "friction": friction,
        "trend_7d": trend,
        "top_miss_30d": top_miss,
    })
