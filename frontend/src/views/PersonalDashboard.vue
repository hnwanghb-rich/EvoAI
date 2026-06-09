<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import axios from 'axios'
import RadarChart from '@/components/RadarChart.vue'

const router = useRouter()
const auth = useAuthStore()

interface RadarItem { category_id: number; category_name: string; icon: string | null; mastery: number; learned: number; total: number; expected: number }
interface WeakItem { category_id: number; category_name: string; icon: string | null; mastery: number }
interface RecentItem { id: number; knowledge_id: number; learn_type: string; knowledge_title: string; created_at: string | null }

const loading = ref(true)
const overallMastery = ref(0)
const myPoints = ref(0)
const companyRank = ref(0)
const deptRank = ref(0)
const weekLearned = ref(0)
const weekDuration = ref(0)
const radarData = ref<RadarItem[]>([])
const weakAreas = ref<WeakItem[]>([])
const recentRecords = ref<RecentItem[]>([])

async function fetchDashboard() {
  try {
    const { data } = await axios.get('/api/dashboard/personal')
    const d = data.data
    overallMastery.value = d.overall_mastery
    myPoints.value = d.my_points
    companyRank.value = d.company_rank
    deptRank.value = d.dept_rank
    weekLearned.value = d.week_learned
    weekDuration.value = Math.round((d.week_duration_sec || 0) / 60)
    radarData.value = d.radar_data
    weakAreas.value = d.weak_areas
    recentRecords.value = d.recent_records
  } finally {
    loading.value = false
  }
}

function goKnowledge(id: number) { router.push(`/knowledge/${id}`) }
function goLearning() { router.push('/learning') }
function formatDuration(sec: number) {
  if (sec < 60) return sec + '秒'
  return Math.round(sec / 60) + '分钟'
}

onMounted(fetchDashboard)
</script>

<template>
  <div class="pd-page">
    <h2 class="page-title">个人知识看板</h2>

    <div v-if="loading" class="pd-loading">加载中...</div>

    <template v-else>
      <!-- 顶部卡片 -->
      <div class="pd-cards">
        <div class="pd-card card">
          <div class="pd-card-value">{{ overallMastery }}%</div>
          <div class="pd-card-label">总掌握度</div>
        </div>
        <div class="pd-card card">
          <div class="pd-card-value">{{ myPoints }}</div>
          <div class="pd-card-label">我的积分</div>
        </div>
        <div class="pd-card card">
          <div class="pd-card-value">#{{ companyRank }}</div>
          <div class="pd-card-label">全公司排名</div>
        </div>
        <div class="pd-card card">
          <div class="pd-card-value">#{{ deptRank }}</div>
          <div class="pd-card-label">本部门排名</div>
        </div>
        <div class="pd-card card">
          <div class="pd-card-value">{{ weekLearned }}条</div>
          <div class="pd-card-label">本周学习</div>
        </div>
        <div class="pd-card card">
          <div class="pd-card-value">{{ weekDuration }}分</div>
          <div class="pd-card-label">本周学习时长</div>
        </div>
      </div>

      <!-- 掌握度进度环 + 雷达图 -->
      <div class="pd-charts">
        <div class="pd-ring card">
          <h3>总掌握度</h3>
          <svg viewBox="0 0 120 120" class="ring-svg">
            <circle cx="60" cy="60" r="52" fill="none" stroke="var(--border)" stroke-width="8"/>
            <circle cx="60" cy="60" r="52" fill="none" stroke="var(--primary)" stroke-width="8"
              stroke-linecap="round"
              :stroke-dasharray="2 * Math.PI * 52"
              :stroke-dashoffset="2 * Math.PI * 52 * (1 - overallMastery / 100)"
              transform="rotate(-90 60 60)"
              style="transition: stroke-dashoffset 0.8s ease"/>
            <text x="60" y="58" text-anchor="middle" font-size="22" font-weight="bold" fill="var(--text-main)">{{ overallMastery }}%</text>
            <text x="60" y="76" text-anchor="middle" font-size="10" fill="var(--text-sub)">掌握度</text>
          </svg>
        </div>
        <div class="pd-radar card">
          <h3>分类掌握度雷达图</h3>
          <RadarChart :data="radarData" height="320px" />
        </div>
      </div>

      <!-- 薄弱领域 + 最近学习 -->
      <div class="pd-bottom">
        <div class="pd-weak card" v-if="weakAreas.length">
          <h3>📉 薄弱领域</h3>
          <div class="weak-list">
            <div v-for="w in weakAreas" :key="w.category_id" class="weak-item" @click="goLearning()">
              <span class="weak-icon">{{ w.icon || '📄' }}</span>
              <span class="weak-name">{{ w.category_name }}</span>
              <span class="weak-bar-bg">
                <span class="weak-bar" :style="{ width: w.mastery + '%' }"></span>
              </span>
              <span class="weak-pct" :style="{ color: 'var(--danger)' }">{{ w.mastery }}%</span>
            </div>
          </div>
        </div>

        <div class="pd-recent card" v-if="recentRecords.length">
          <h3>📝 最近学习</h3>
          <div class="recent-list">
            <div v-for="r in recentRecords.slice(0, 10)" :key="r.id" class="recent-item" @click="goKnowledge(r.knowledge_id)">
              <span class="recent-title">{{ r.knowledge_title }}</span>
              <span class="recent-date">{{ r.created_at?.slice(0, 10) }}</span>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.pd-page { max-width: 1100px; margin: 0 auto; }
.page-title { font-size: 20px; margin-bottom: 16px; color: var(--text-main); }
.pd-loading { text-align: center; padding: 60px; color: var(--text-sub); }

/* 顶部指标卡片 */
.pd-cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 12px;
  margin-bottom: 16px;
}
.pd-card { text-align: center; padding: 16px 12px; }
.pd-card-value { font-size: 28px; font-weight: 700; color: var(--primary); }
.pd-card-label { font-size: 12px; color: var(--text-sub); margin-top: 4px; }

/* 图表区 */
.pd-charts { display: flex; gap: 16px; margin-bottom: 16px; }
.pd-ring { flex: 0 0 280px; text-align: center; }
.pd-ring h3 { font-size: 14px; margin-bottom: 10px; color: var(--text-sub); }
.ring-svg { width: 140px; height: 140px; }
.pd-radar { flex: 1; min-width: 0; }
.pd-radar h3 { font-size: 14px; margin-bottom: 10px; color: var(--text-sub); }

/* 底部两栏 */
.pd-bottom { display: flex; gap: 16px; }
.pd-weak { flex: 1; }
.pd-recent { flex: 1; }
.pd-weak h3, .pd-recent h3 { font-size: 14px; margin-bottom: 12px; color: var(--text-main); }

.weak-list { display: flex; flex-direction: column; gap: 10px; }
.weak-item { display: flex; align-items: center; gap: 8px; cursor: pointer; }
.weak-icon { font-size: 16px; width: 24px; }
.weak-name { font-size: 13px; width: 100px; flex-shrink: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.weak-bar-bg { flex: 1; height: 8px; background: var(--bg-main); border-radius: 4px; overflow: hidden; }
.weak-bar { height: 100%; background: var(--danger); border-radius: 4px; transition: width 0.5s; }
.weak-pct { font-size: 12px; font-weight: 600; width: 36px; text-align: right; }

.recent-list { display: flex; flex-direction: column; gap: 6px; }
.recent-item { display: flex; justify-content: space-between; align-items: center; padding: 6px 0; border-bottom: 1px solid var(--border); cursor: pointer; font-size: 13px; }
.recent-item:hover { color: var(--primary); }
.recent-title { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.recent-date { font-size: 11px; color: var(--text-sub); flex-shrink: 0; margin-left: 8px; }

@media (max-width: 768px) {
  .pd-cards { grid-template-columns: repeat(3, 1fr); }
  .pd-card-value { font-size: 22px; }
  .pd-charts { flex-direction: column; }
  .pd-ring { flex: none; }
  .pd-bottom { flex-direction: column; }
}
</style>
