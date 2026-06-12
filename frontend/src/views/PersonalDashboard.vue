<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import axios from 'axios'
import RadarChart from '@/components/RadarChart.vue'

const router = useRouter()
const auth = useAuthStore()

interface RadarItem { category_id: number; category_name: string; icon: string | null; description: string; mastery: number; learned: number; total: number; expected: number }
interface WeakItem { category_id: number; category_name: string; icon: string | null; mastery: number }
interface RecentItem { id: number; knowledge_id: number; learn_type: string; knowledge_title: string; created_at: string | null }

const loading = ref(true)
const overallMastery = ref(0)
const myPoints = ref(0)
const companyRank = ref(0)
const deptRank = ref(0)
const weekLearned = ref(0)
const weekDuration = ref(0)
const allRadarData = ref<RadarItem[]>([])
const weakAreas = ref<WeakItem[]>([])
const recentRecords = ref<RecentItem[]>([])
const showDimPanel = ref(false)

// 维度选择
const selectedCats = ref<Set<number>>(new Set())

// 上次保存的维度选择 key
const DIM_STORAGE_KEY = 'radar_dimensions_' + (auth.user?.id || 'anon')

function loadSavedDims() {
  try {
    const raw = localStorage.getItem(DIM_STORAGE_KEY)
    if (raw) return new Set(JSON.parse(raw) as number[])
  } catch { return null }
  return null
}
function saveDims() {
  localStorage.setItem(DIM_STORAGE_KEY, JSON.stringify([...selectedCats.value]))
}

const radarData = computed(() =>
  allRadarData.value.filter(d => selectedCats.value.has(d.category_id))
)

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
    allRadarData.value = d.radar_data
    weakAreas.value = d.weak_areas
    recentRecords.value = d.recent_records

    // 恢复上次维度选择，否则默认选薄弱前5个
    const saved = loadSavedDims()
    if (saved && saved.size > 0 && allRadarData.value.some(d => saved.has(d.category_id))) {
      selectedCats.value = saved
    } else {
      // 默认：掌握度最低的5个
      const sorted = [...allRadarData.value].sort((a, b) => a.mastery - b.mastery)
      selectedCats.value = new Set(sorted.slice(0, 5).map(d => d.category_id))
    }
  } finally {
    loading.value = false
  }
}

function toggleCategory(catId: number) {
  const s = new Set(selectedCats.value)
  if (s.has(catId)) { if (s.size > 1) s.delete(catId) }
  else s.add(catId)
  selectedCats.value = s
  saveDims()
}

function selectTopN(n: number) {
  const sorted = [...allRadarData.value].sort((a, b) => a.mastery - b.mastery)
  selectedCats.value = new Set(sorted.slice(0, Math.min(n, sorted.length)).map(d => d.category_id))
  saveDims()
}

function goKnowledge(id: number) { router.push(`/knowledge/${id}`) }
function goLearning() { router.push('/learning') }
function formatDuration(sec: number) { return sec < 60 ? sec + '秒' : Math.round(sec / 60) + '分钟' }

onMounted(fetchDashboard)
</script>

<template>
  <div class="pd-page">
    <h2 class="page-title">个人知识看板</h2>

    <div v-if="loading" class="pd-loading">加载中...</div>

    <template v-else>
      <!-- 顶部指标卡 -->
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

      <!-- 掌握度环 + 雷达 + 维度选择 -->
      <div class="pd-charts">
        <!-- 环 -->
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

        <!-- 雷达图 -->
        <div class="pd-radar card">
          <h3>分类掌握度雷达图（{{ radarData.length }} 个维度）</h3>
          <RadarChart v-if="radarData.length" :data="radarData" height="380px" />
          <div v-else class="pd-no-dim">请从右侧选择至少一个维度</div>
        </div>

        <!-- 维度选择面板 -->
        <div class="pd-dims card">
          <div class="dims-head">
            <h3>🖊 可选维度</h3>
            <div class="dims-quick">
              <span class="dim-link" @click="selectTopN(3)">前3</span>
              <span class="dim-link" @click="selectTopN(5)">前5</span>
              <span class="dim-link" @click="selectTopN(8)">前8</span>
              <span class="dim-link" @click="selectTopN(allRadarData.length)">全部</span>
            </div>
          </div>
          <p class="dims-hint">勾选要展示的维度，雷达图实时更新。系统自动保存你的选择。</p>
          <div class="dims-list">
            <label v-for="d in allRadarData" :key="d.category_id" class="dim-item"
              :class="{ checked: selectedCats.has(d.category_id) }">
              <input type="checkbox" :checked="selectedCats.has(d.category_id)" @change="toggleCategory(d.category_id)" />
              <span class="dim-icon">{{ d.icon || '📄' }}</span>
              <span class="dim-name">{{ d.category_name }}</span>
              <span class="dim-bar-bg">
                <span class="dim-bar" :style="{ width: d.mastery + '%', background: d.mastery < 40 ? 'var(--danger)' : d.mastery < 70 ? 'var(--accent)' : 'var(--success)' }"></span>
              </span>
              <span class="dim-pct">{{ d.mastery }}%</span>
            </label>
          </div>
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
.pd-page { max-width: 1200px; margin: 0 auto; }
.page-title { font-size: 20px; margin-bottom: 16px; color: var(--text-main); }
.pd-loading { text-align: center; padding: 60px; color: var(--text-sub); }

.pd-cards { display: grid; grid-template-columns: repeat(6, 1fr); gap: 10px; margin-bottom: 16px; }
.pd-card { text-align: center; padding: 14px 10px; }
.pd-card-value { font-size: 24px; font-weight: 700; color: var(--primary); }
.pd-card-label { font-size: 11px; color: var(--text-sub); margin-top: 4px; }

/* 图表+维度三栏 */
.pd-charts { display: flex; gap: 14px; margin-bottom: 16px; }
.pd-ring { flex: 0 0 200px; text-align: center; padding: 14px 10px; }
.pd-ring h3 { font-size: 13px; margin-bottom: 8px; color: var(--text-sub); }
.ring-svg { width: 120px; height: 120px; }
.pd-radar { flex: 1; min-width: 0; }
.pd-radar h3 { font-size: 13px; margin-bottom: 8px; color: var(--text-sub); }
.pd-no-dim { text-align: center; padding: 60px 20px; color: var(--text-sub); font-size: 14px; }

/* 维度面板 */
.pd-dims { flex: 0 0 280px; padding: 12px 14px; max-height: 460px; display: flex; flex-direction: column; }
.dims-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
.dims-head h3 { font-size: 13px; margin: 0; color: var(--text-main); }
.dims-quick { display: flex; gap: 4px; }
.dim-link { padding: 2px 8px; border-radius: 10px; font-size: 11px; background: var(--bg-main); color: var(--primary); cursor: pointer; border: 1px solid var(--border); }
.dim-link:hover { background: var(--primary); color: #fff; }
.dims-hint { font-size: 11px; color: var(--text-sub); margin-bottom: 8px; }
.dims-list { overflow-y: auto; flex: 1; }
.dim-item {
  display: flex; align-items: center; gap: 6px;
  padding: 6px 6px; border-radius: 4px; cursor: pointer;
  font-size: 12px; transition: background 0.1s;
}
.dim-item:hover { background: var(--bg-main); }
.dim-item.checked { background: var(--bg-main); }
.dim-item input { accent-color: var(--primary); width: 14px; height: 14px; cursor: pointer; flex-shrink: 0; }
.dim-icon { font-size: 13px; flex-shrink: 0; }
.dim-name { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.dim-bar-bg { width: 50px; height: 6px; background: var(--bg-main); border-radius: 3px; overflow: hidden; flex-shrink: 0; }
.dim-bar { height: 100%; border-radius: 3px; }
.dim-pct { width: 32px; text-align: right; font-weight: 600; font-size: 11px; color: var(--text-sub); flex-shrink: 0; }

/* 底部 */
.pd-bottom { display: flex; gap: 14px; }
.pd-weak { flex: 1; }
.pd-recent { flex: 1; }
.pd-weak h3, .pd-recent h3 { font-size: 14px; margin-bottom: 10px; color: var(--text-main); }
.weak-list { display: flex; flex-direction: column; gap: 8px; }
.weak-item { display: flex; align-items: center; gap: 8px; cursor: pointer; }
.weak-icon { font-size: 14px; width: 22px; }
.weak-name { font-size: 12px; width: 90px; flex-shrink: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.weak-bar-bg { flex: 1; height: 6px; background: var(--bg-main); border-radius: 3px; overflow: hidden; }
.weak-bar { height: 100%; background: var(--danger); border-radius: 3px; }
.weak-pct { font-size: 11px; font-weight: 600; width: 32px; text-align: right; color: var(--danger); }
.recent-list { display: flex; flex-direction: column; gap: 4px; }
.recent-item { display: flex; justify-content: space-between; align-items: center; padding: 5px 0; border-bottom: 1px solid var(--border); cursor: pointer; font-size: 12px; }
.recent-item:hover { color: var(--primary); }
.recent-title { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.recent-date { font-size: 10px; color: var(--text-sub); flex-shrink: 0; margin-left: 6px; }

@media (max-width: 1024px) {
  .pd-charts { flex-direction: column; }
  .pd-ring { flex: none; }
  .pd-dims { flex: none; max-height: 300px; }
}
@media (max-width: 768px) {
  .pd-cards { grid-template-columns: repeat(3, 1fr); }
  .pd-card-value { font-size: 20px; }
  .pd-bottom { flex-direction: column; }
}
</style>
