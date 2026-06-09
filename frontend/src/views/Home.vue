<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useChatStore } from '@/stores/chat'
import axios from 'axios'

const router = useRouter()
const auth = useAuthStore()
const chat = useChatStore()

interface RecommendItem {
  id: number; title: string; content: string
  car_brand: string | null; car_model: string | null
  knowledge_base: string; category_id: number
  view_count: number; useful_count: number
  reason: string; reason_type: string
}
interface HomeData {
  role_view?: string
  // staff
  recommends?: RecommendItem[]
  has_today_question?: boolean
  week_learned?: number; week_duration_sec?: number
  my_points?: number; my_rank?: number
  overall_mastery?: number
  // admin
  pending_count?: number; week_deposit?: number
  learning_rate?: number; knowledge_health?: number
  low_question_positions?: string[]
  member_count?: number
  // boss
  month_new?: number; staff_count?: number
  flywheel_deposit?: number; flywheel_reuse_rate?: number
  dead_departments?: { id: number; name: string }[]
  knowledge_total?: number; kb_total?: number
}

const data = ref<HomeData>({})
const loading = ref(true)

async function fetchHome() {
  try {
    const r = await axios.get('/api/dashboard/home')
    data.value = r.data.data
  } finally {
    loading.value = false
  }
}

function callAneng() { chat.open = true }
function goKnowledge(id: number) { router.push(`/knowledge/${id}`) }
function reasonLabel(r: RecommendItem): string { return r.reason }
function reasonIcon(t: string): string {
  return t === 'weak' ? '📖' : t === 'hot' ? '🔥' : '💡'
}
function formatDuration(sec: number): string {
  if (sec < 60) return sec + '秒'
  return Math.round(sec / 60) + '分钟'
}

const posLabels: Record<string, string> = { sales: '销售', tech: '技术', service: '客服' }

onMounted(fetchHome)
</script>

<template>
  <div class="home-page">
    <h2 class="page-title">
      {{ auth.user?.real_name }}，{{ new Date().getHours() < 12 ? '上午好' : new Date().getHours() < 18 ? '下午好' : '晚上好' }}！
    </h2>
    <div v-if="loading" class="home-loading">加载中...</div>

    <template v-else>
      <!-- ========== 职员首页 ========== -->
      <template v-if="data.role_view === 'staff'">
        <!-- 召唤阿能 -->
        <div class="home-aneng card" @click="callAneng">
          <div class="aneng-prompt">
            <span class="aneng-big">🤖</span>
            <div>
              <h3>遇到问题？问问阿能</h3>
              <p>点击此处或右下角按钮，24小时在线解答</p>
            </div>
          </div>
          <span class="aneng-arrow">→</span>
        </div>

        <!-- 今日个性化推荐 -->
        <div class="section" v-if="data.recommends && data.recommends.length">
          <div class="section-head">
            <h3>🎯 今日知识推送</h3>
            <span class="section-sub">根据你的学习情况智能推荐</span>
          </div>
          <div class="recommend-list">
            <div
              v-for="rec in data.recommends" :key="rec.id"
              class="rec-card card"
              @click="goKnowledge(rec.id)"
            >
              <div class="rec-reason">
                <span class="rec-icon">{{ reasonIcon(rec.reason_type) }}</span>
                <span class="rec-tag" :class="'tag-' + rec.reason_type">{{ rec.reason }}</span>
              </div>
              <h4 class="rec-title">{{ rec.title }}</h4>
              <p class="rec-desc">{{ rec.content }}</p>
              <div class="rec-meta">
                <span v-if="rec.car_brand">🚗 {{ rec.car_brand }}{{ rec.car_model ? ' ' + rec.car_model : '' }}</span>
                <span>👁 {{ rec.view_count }}</span>
                <span>👍 {{ rec.useful_count }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 学习进度 + 快捷入口 -->
        <div class="staff-grid">
          <div class="staff-stats card">
            <h4>📊 学习概览</h4>
            <div class="stat-row">
              <div class="stat-item">
                <span class="stat-val">{{ data.overall_mastery ?? 0 }}%</span>
                <span class="stat-lbl">总掌握度</span>
              </div>
              <div class="stat-item">
                <span class="stat-val">{{ data.my_points ?? 0 }}</span>
                <span class="stat-lbl">我的积分</span>
              </div>
              <div class="stat-item">
                <span class="stat-val">#{{ data.my_rank ?? '--' }}</span>
                <span class="stat-lbl">排名</span>
              </div>
            </div>
            <div class="stat-row" style="margin-top:8px">
              <span class="stat-sm">本周学习 <b>{{ data.week_learned ?? 0 }}</b> 条</span>
              <span class="stat-sm">时长 <b>{{ formatDuration(data.week_duration_sec ?? 0) }}</b></span>
            </div>
          </div>

          <div class="staff-actions">
            <div class="home-card card" @click="router.push('/question')">
              <span class="hc-icon">❓</span>
              <span class="hc-title">每日一题</span>
              <span class="hc-desc" :style="{ color: data.has_today_question ? 'var(--success)' : 'var(--text-sub)' }">
                {{ data.has_today_question ? '待完成' : '今日已完成' }}
              </span>
            </div>
            <div class="home-card card" @click="router.push('/personal-dashboard')">
              <span class="hc-icon">📊</span>
              <span class="hc-title">个人看板</span>
              <span class="hc-desc">雷达图+薄弱</span>
            </div>
            <div class="home-card card" @click="router.push('/submit-experience')">
              <span class="hc-icon">✏️</span>
              <span class="hc-title">提交经验</span>
              <span class="hc-desc">分享即+积分</span>
            </div>
            <div class="home-card card" @click="router.push('/learning')">
              <span class="hc-icon">🎓</span>
              <span class="hc-title">学习中心</span>
              <span class="hc-desc">课程+错题</span>
            </div>
          </div>
        </div>
      </template>

      <!-- ========== 管理员首页 ========== -->
      <template v-else-if="data.role_view === 'admin'">
        <!-- 管理概览数字卡 -->
        <div class="admin-kpis">
          <div class="admin-kpi card" :class="{ alert: (data.pending_count ?? 0) > 0 }" @click="router.push('/review')">
            <span class="akpi-num" :style="{ color: (data.pending_count ?? 0) > 0 ? 'var(--danger)' : 'var(--text-sub)' }">{{ data.pending_count ?? 0 }}</span>
            <span class="akpi-label">待审核</span>
          </div>
          <div class="admin-kpi card" @click="router.push('/review')">
            <span class="akpi-num">{{ data.week_deposit ?? 0 }}</span>
            <span class="akpi-label">本周经验沉淀</span>
          </div>
          <div class="admin-kpi card" @click="router.push('/team-dashboard')">
            <span class="akpi-num">{{ data.learning_rate ?? 0 }}%</span>
            <span class="akpi-label">团队学习达标率</span>
          </div>
          <div class="admin-kpi card" @click="router.push('/knowledge-manage')">
            <span class="akpi-num">{{ data.knowledge_health ?? 0 }}%</span>
            <span class="akpi-label">知识库健康度</span>
          </div>
        </div>

        <!-- 题库预警 -->
        <div class="card admin-alert" v-if="data.low_question_positions && data.low_question_positions.length" @click="router.push('/exam-manage')">
          <h4>⚡ 题库预警</h4>
          <p><b>{{ data.low_question_positions.map(p => posLabels[p] || p).join('、') }}</b> 岗位题目不足10道，建议补充</p>
        </div>

        <!-- 快捷入口 -->
        <div class="home-cards">
          <div class="home-card card" @click="router.push('/review')" :style="{ borderColor: (data.pending_count ?? 0) > 0 ? 'var(--danger)' : 'var(--border)' }">
            <span class="hc-icon">✅</span>
            <span class="hc-title">审核中心</span>
            <span class="hc-num" :style="{ color: (data.pending_count ?? 0) > 0 ? 'var(--danger)' : 'var(--text-sub)' }">{{ data.pending_count ?? 0 }}</span>
          </div>
          <div class="home-card card" @click="router.push('/team-dashboard')">
            <span class="hc-icon">👥</span>
            <span class="hc-title">团队看板</span>
            <span class="hc-num">{{ data.learning_rate ?? '--' }}%</span>
          </div>
          <div class="home-card card" @click="router.push('/knowledge-manage')">
            <span class="hc-icon">📚</span>
            <span class="hc-title">知识管理</span>
            <span class="hc-desc">{{ data.kb_total ?? 0 }} 条</span>
          </div>
          <div class="home-card card" @click="router.push('/exam-manage')">
            <span class="hc-icon">📝</span>
            <span class="hc-title">题库管理</span>
            <span class="hc-desc" :class="{ warn: (data.low_question_positions?.length ?? 0) > 0 }">
              {{ data.low_question_positions?.length ? '待补充' : '正常' }}
            </span>
          </div>
          <div class="home-card card" @click="router.push('/user-manage')">
            <span class="hc-icon">👨‍👩‍👧</span>
            <span class="hc-title">用户管理</span>
            <span class="hc-desc">{{ data.member_count ?? '--' }} 人</span>
          </div>
          <div class="home-card card" @click="router.push('/llm-settings')">
            <span class="hc-icon">🤖</span>
            <span class="hc-title">LLM配置</span>
            <span class="hc-desc">AI引擎</span>
          </div>
        </div>
      </template>

      <!-- ========== 老板首页 ========== -->
      <template v-else-if="data.role_view === 'boss'">
        <div class="home-kpis">
          <div class="home-kpi card" @click="router.push('/bi-board')">
            <span class="hkpi-num">{{ data.knowledge_total ?? 0 }}</span>
            <span class="hkpi-label">知识总量</span>
          </div>
          <div class="home-kpi card">
            <span class="hkpi-num">+{{ data.month_new ?? 0 }}</span>
            <span class="hkpi-label">月新增</span>
          </div>
          <div class="home-kpi card">
            <span class="hkpi-num">{{ data.staff_count ?? 0 }}</span>
            <span class="hkpi-label">员工总数</span>
          </div>
          <div class="home-kpi card">
            <span class="hkpi-num">{{ data.flywheel_reuse_rate ?? 0 }}%</span>
            <span class="hkpi-label">知识复用率</span>
          </div>
        </div>

        <!-- 预警 -->
        <div class="card boss-alert" v-if="data.dead_departments && data.dead_departments.length" @click="router.push('/team-dashboard')">
          <h4>⚡ 长期无沉淀部门（30天）</h4>
          <p>
            <span v-for="d in data.dead_departments" :key="d.id" class="alert-tag">{{ d.name }}</span>
          </p>
        </div>

        <div class="home-cards">
          <div class="home-card card" @click="router.push('/bi-board')">
            <span class="hc-icon">📈</span>
            <span class="hc-title">BI大屏</span>
            <span class="hc-desc">全屏数据</span>
          </div>
          <div class="home-card card" @click="router.push('/team-dashboard')">
            <span class="hc-icon">👥</span>
            <span class="hc-title">团队看板</span>
            <span class="hc-desc">部门掌握度</span>
          </div>
          <div class="home-card card" @click="router.push('/knowledge')">
            <span class="hc-icon">📚</span>
            <span class="hc-title">知识库</span>
            <span class="hc-desc">浏览搜索</span>
          </div>
          <div class="home-card card" @click="router.push('/profile')">
            <span class="hc-icon">👤</span>
            <span class="hc-title">个人中心</span>
            <span class="hc-desc">积分排名</span>
          </div>
        </div>
      </template>
    </template>
  </div>
</template>

<style scoped>
.home-page { max-width: 900px; margin: 0 auto; }
.page-title { font-size: 20px; margin-bottom: 20px; color: var(--text-main); }
.home-loading { text-align: center; padding: 60px; color: var(--text-sub); }

/* 通用 */
.section { margin-bottom: 20px; }
.section-head { display: flex; align-items: baseline; gap: 12px; margin-bottom: 12px; }
.section-head h3 { font-size: 16px; margin: 0; color: var(--text-main); }
.section-sub { font-size: 12px; color: var(--text-sub); }

/* === 职员：召唤阿能 === */
.home-aneng {
  padding: 20px 24px; margin-bottom: 20px;
  cursor: pointer; display: flex; justify-content: space-between; align-items: center;
  transition: box-shadow 0.15s;
  background: var(--banner-bg, linear-gradient(135deg, #C0403B, #D46864, #E8824A));
  border: none; color: #fff;
}
.home-aneng:hover { box-shadow: 0 6px 24px rgba(0,0,0,0.15); }
.aneng-prompt { display: flex; align-items: center; gap: 16px; }
.aneng-big { font-size: 40px; }
.aneng-prompt h3 { margin: 0; font-size: 16px; color: #fff; }
.aneng-prompt p { margin: 4px 0 0; font-size: 13px; opacity: 0.85; }
.aneng-arrow { font-size: 24px; opacity: 0.6; }

/* === 职员：推荐卡片 === */
.recommend-list { display: flex; flex-direction: column; gap: 10px; margin-bottom: 20px; }
.rec-card { padding: 14px 16px; cursor: pointer; transition: border-color 0.15s; }
.rec-card:hover { border-color: var(--primary); }
.rec-reason { display: flex; align-items: center; gap: 6px; margin-bottom: 6px; }
.rec-icon { font-size: 14px; }
.rec-tag {
  display: inline-block; padding: 2px 10px; border-radius: 10px; font-size: 12px;
  font-weight: 600;
}
.tag-weak { background: rgba(192,64,59,0.1); color: var(--danger); border: 1px solid rgba(192,64,59,0.3); }
.tag-hot { background: rgba(232,130,74,0.1); color: var(--accent); border: 1px solid rgba(232,130,74,0.3); }
.rec-title { font-size: 15px; margin: 0 0 6px; color: var(--text-main); }
.rec-desc {
  font-size: 13px; color: var(--text-sub); line-height: 1.5;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}
.rec-meta { display: flex; gap: 14px; margin-top: 8px; font-size: 12px; color: var(--text-sub); }

/* === 职员：学习统计 === */
.staff-grid { display: flex; gap: 16px; }
.staff-stats { flex: 1; padding: 16px; min-width: 0; }
.staff-stats h4 { font-size: 14px; margin: 0 0 12px; color: var(--text-main); }
.stat-row { display: flex; gap: 16px; }
.stat-item { flex: 1; text-align: center; }
.stat-val { display: block; font-size: 22px; font-weight: 700; color: var(--primary); }
.stat-lbl { font-size: 11px; color: var(--text-sub); }
.stat-sm { font-size: 12px; color: var(--text-sub); }
.staff-actions { display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; flex: 1; }

/* === 管理员 === */
.admin-kpis { display: flex; gap: 12px; margin-bottom: 16px; }
.admin-kpi { flex: 1; text-align: center; padding: 16px 12px; cursor: pointer; }
.admin-kpi.alert { border-color: var(--danger); }
.akpi-num { display: block; font-size: 28px; font-weight: 700; }
.akpi-label { display: block; font-size: 11px; color: var(--text-sub); margin-top: 4px; }
.admin-alert { margin-bottom: 16px; padding: 14px; cursor: pointer; border-color: rgba(192,64,59,0.3); }
.admin-alert h4 { font-size: 14px; margin: 0 0 6px; color: var(--danger); }
.admin-alert p { font-size: 13px; margin: 0; color: var(--text-main); }

/* === 老板 === */
.boss-alert { margin-bottom: 16px; padding: 14px; cursor: pointer; border-color: rgba(232,130,74,0.3); }
.boss-alert h4 { font-size: 14px; margin: 0 0 8px; color: var(--accent); }
.alert-tag {
  display: inline-block; padding: 3px 12px; margin: 3px; border-radius: 12px;
  background: rgba(232,130,74,0.1); color: var(--accent); font-size: 12px; font-weight: 600;
}

/* 入口卡片 */
.home-cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(170px, 1fr)); gap: 10px; }
.home-card { padding: 20px 14px; text-align: center; cursor: pointer; transition: border-color 0.15s, transform 0.1s; }
.home-card:hover { border-color: var(--primary); transform: translateY(-2px); }
.hc-icon { display: block; font-size: 28px; margin-bottom: 8px; }
.hc-title { display: block; font-size: 14px; font-weight: 600; color: var(--text-main); }
.hc-desc { display: block; font-size: 12px; color: var(--text-sub); margin-top: 4px; }
.hc-desc.warn { color: var(--danger); }
.hc-num { display: block; font-size: 24px; font-weight: 700; color: var(--primary); margin-top: 4px; }

/* 老板KPI */
.home-kpis { display: flex; gap: 12px; margin-bottom: 16px; }
.home-kpi { flex: 1; text-align: center; padding: 20px 16px; cursor: pointer; }
.hkpi-num { display: block; font-size: 32px; font-weight: 700; color: var(--primary); }
.hkpi-label { display: block; font-size: 12px; color: var(--text-sub); margin-top: 4px; }

@media (max-width: 768px) {
  .home-cards { grid-template-columns: repeat(2, 1fr); }
  .home-kpis, .admin-kpis { flex-wrap: wrap; }
  .home-kpi, .admin-kpi { flex: 1 1 40%; }
  .staff-grid { flex-direction: column; }
  .staff-actions { grid-template-columns: repeat(2, 1fr); }
}
</style>
