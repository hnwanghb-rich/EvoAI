<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import axios from 'axios'
import RadarChart from '@/components/RadarChart.vue'

interface MemberRank { user_id: number; real_name: string; position: string; points: number }
interface RadarItem { category_id: number; category_name: string; icon: string | null; description: string; mastery: number; expected: number }

const loading = ref(true)
const deptName = ref('')
const memberCount = ref(0)
const teamMastery = ref(0)
const monthNewLearned = ref(0)
const allRadarData = ref<RadarItem[]>([])
const weakAreas = ref<{ category_name: string; mastery: number }[]>([])
const memberRank = ref<MemberRank[]>([])
const teamPosition = ref('')

const posLabel: Record<string, string> = { sales: '销售', tech: '技术', service: '客服', clerk: '文员' }

const teamTitle = computed(() => {
  if (teamPosition.value && posLabel[teamPosition.value]) {
    return '团队看板 · ' + posLabel[teamPosition.value]
  }
  return '团队看板 · 全公司'
})

// 维度选择
const selectedCats = ref<Set<number>>(new Set())
const DIM_KEY = 'team_radar_dims'

function loadSavedDims() {
  try {
    const raw = localStorage.getItem(DIM_KEY)
    if (raw) return new Set(JSON.parse(raw) as number[])
  } catch { return null }
  return null
}
function saveDims() {
  localStorage.setItem(DIM_KEY, JSON.stringify([...selectedCats.value]))
}

const radarData = computed(() =>
  allRadarData.value.filter(d => selectedCats.value.has(d.category_id))
)

async function fetchData() {
  const params: any = {}
  if (teamPosition.value) params.position = teamPosition.value
  const { data } = await axios.get('/api/dashboard/team', { params })
  const d = data.data
  deptName.value = d.dept_name
  memberCount.value = d.member_count
  teamMastery.value = d.team_mastery
  monthNewLearned.value = d.month_new_learned
  allRadarData.value = d.radar_data
  weakAreas.value = d.weak_areas
  memberRank.value = d.member_rank

  const saved = loadSavedDims()
  if (saved && saved.size > 0 && allRadarData.value.some(d => saved.has(d.category_id))) {
    selectedCats.value = saved
  } else {
    const sorted = [...allRadarData.value].sort((a, b) => a.mastery - b.mastery)
    selectedCats.value = new Set(sorted.slice(0, 5).map(d => d.category_id))
  }
  loading.value = false
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

onMounted(fetchData)
</script>

<template>
  <div class="td-page">
    <div class="td-top-bar">
      <h2 class="page-title">{{ teamTitle }}</h2>
      <div class="td-pos-filter">
        <button :class="{ active: teamPosition === '' }" @click="teamPosition = ''; fetchData()">全部</button>
        <button :class="{ active: teamPosition === 'sales' }" @click="teamPosition = 'sales'; fetchData()">💼 销售</button>
        <button :class="{ active: teamPosition === 'tech' }" @click="teamPosition = 'tech'; fetchData()">🔧 技术</button>
        <button :class="{ active: teamPosition === 'service' }" @click="teamPosition = 'service'; fetchData()">📞 客服</button>
        <button :class="{ active: teamPosition === 'clerk' }" @click="teamPosition = 'clerk'; fetchData()">📋 文员</button>
      </div>
    </div>

    <div v-if="loading" class="td-loading">加载中...</div>

    <template v-else>
      <div class="td-cards">
        <div class="td-card card">
          <svg viewBox="0 0 100 100" width="76" height="76">
            <circle cx="50" cy="50" r="44" fill="none" stroke="var(--border)" stroke-width="6"/>
            <circle cx="50" cy="50" r="44" fill="none" stroke="var(--primary)" stroke-width="6"
              stroke-linecap="round"
              :stroke-dasharray="2 * Math.PI * 44"
              :stroke-dashoffset="2 * Math.PI * 44 * (1 - teamMastery / 100)"
              transform="rotate(-90 50 50)" style="transition: stroke-dashoffset 0.8s"/>
            <text x="50" y="48" text-anchor="middle" font-size="14" font-weight="bold" fill="var(--text-main)">{{ teamMastery }}%</text>
            <text x="50" y="62" text-anchor="middle" font-size="7" fill="var(--text-sub)">团队掌握度</text>
          </svg>
          <div class="td-card-text">团队掌握度</div>
        </div>
        <div class="td-card card"><div class="td-card-num">{{ memberCount }}</div><div class="td-card-label">部门人数</div></div>
        <div class="td-card card"><div class="td-card-num">{{ monthNewLearned }}</div><div class="td-card-label">本月学习</div></div>
        <div class="td-card card" style="flex:2"><div class="td-card-num" style="font-size:20px">{{ radarData.length }} / {{ allRadarData.length }}</div><div class="td-card-label">雷达维度</div></div>
      </div>

      <!-- 雷达图 + 维度选择 -->
      <div class="td-charts">
        <div class="card" style="flex:1">
          <h3>团队分类掌握度</h3>
          <RadarChart v-if="radarData.length" :data="radarData" height="380px" />
          <div v-else class="td-no-dim">请从右侧选择至少一个维度</div>
        </div>

        <!-- 维度选择面板 -->
        <div class="td-dims card">
          <div class="dims-head">
            <h3>🖊 可选维度</h3>
            <div class="dims-quick">
              <span class="dim-link" @click="selectTopN(3)">前3</span>
              <span class="dim-link" @click="selectTopN(5)">前5</span>
              <span class="dim-link" @click="selectTopN(8)">前8</span>
              <span class="dim-link" @click="selectTopN(allRadarData.length)">全部</span>
            </div>
          </div>
          <p class="dims-hint">勾选展示维度，雷达图实时更新。系统记住选择。</p>
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

        <!-- 薄弱领域 -->
        <div class="card td-weak" v-if="weakAreas.length">
          <h3>📉 薄弱领域</h3>
          <div v-for="w in weakAreas" :key="w.category_name" class="td-weak-item">
            <span class="td-weak-name">{{ w.category_name }}</span>
            <span class="td-weak-bar-bg">
              <span class="td-weak-bar" :style="{ width: w.mastery + '%', background: 'var(--danger)' }"></span>
            </span>
            <span class="td-weak-pct">{{ w.mastery }}%</span>
          </div>
        </div>
      </div>

      <!-- 成员排行 -->
      <div class="card" v-if="memberRank.length">
        <h3>🏆 团队成员积分排行</h3>
        <table class="td-table">
          <thead><tr><th>排名</th><th>姓名</th><th>岗位</th><th>积分</th><th>进度</th></tr></thead>
          <tbody>
            <tr v-for="(m, i) in memberRank" :key="m.user_id">
              <td>{{ i + 1 }}</td>
              <td>{{ m.real_name }}</td>
              <td>{{ m.position || '-' }}</td>
              <td>{{ m.points }}</td>
              <td><span class="rank-bar-bg"><span class="rank-bar" :style="{ width: Math.min(m.points / (memberRank[0]?.points || 1) * 100, 100) + '%' }"></span></span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </div>
</template>

<style scoped>
.td-page { max-width: 1300px; margin: 0 auto; }
.td-top-bar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; flex-wrap: wrap; gap: 10px; }
.page-title { font-size: 20px; margin: 0; color: var(--text-main); }
.td-loading { text-align: center; padding: 60px; color: var(--text-sub); }
.td-pos-filter { display: flex; gap: 4px; }
.td-pos-filter button { padding: 5px 14px; border: 1px solid var(--border); border-radius: 14px; font-size: 12px; background: none; color: var(--text-sub); cursor: pointer; transition: all 0.15s; }
.td-pos-filter button:hover { border-color: var(--primary); color: var(--primary); }
.td-pos-filter button.active { background: var(--primary); color: #fff; border-color: var(--primary); }

.td-cards { display: flex; gap: 10px; margin-bottom: 16px; }
.td-card { text-align: center; padding: 14px 10px; flex: 1; }
.td-card-num { font-size: 26px; font-weight: 700; color: var(--primary); }
.td-card-text { font-size: 12px; color: var(--text-sub); margin-top: 4px; }
.td-card-label { font-size: 11px; color: var(--text-sub); margin-top: 4px; }

.td-charts { display: flex; gap: 12px; margin-bottom: 16px; }
.td-charts .card { padding: 12px; }
.td-charts .card h3 { font-size: 13px; margin-bottom: 8px; color: var(--text-sub); }
.td-no-dim { text-align: center; padding: 60px 20px; color: var(--text-sub); font-size: 14px; }

/* 维度面板 */
.td-dims { flex: 0 0 260px; padding: 12px 14px; max-height: 460px; display: flex; flex-direction: column; }
.td-dims .dims-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
.td-dims .dims-head h3 { font-size: 13px; margin: 0 !important; color: var(--text-main); }
.dims-quick { display: flex; gap: 4px; }
.dim-link { padding: 2px 8px; border-radius: 10px; font-size: 11px; background: var(--bg-main); color: var(--primary); cursor: pointer; border: 1px solid var(--border); }
.dim-link:hover { background: var(--primary); color: #fff; }
.dims-hint { font-size: 11px; color: var(--text-sub); margin-bottom: 8px; }
.dims-list { overflow-y: auto; flex: 1; }
.dim-item { display: flex; align-items: center; gap: 5px; padding: 5px 4px; border-radius: 4px; cursor: pointer; font-size: 12px; }
.dim-item:hover { background: var(--bg-main); }
.dim-item.checked { background: var(--bg-main); }
.dim-item input { accent-color: var(--primary); width: 13px; height: 13px; cursor: pointer; flex-shrink: 0; }
.dim-icon { font-size: 12px; flex-shrink: 0; }
.dim-name { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.dim-bar-bg { width: 45px; height: 5px; background: var(--bg-main); border-radius: 3px; overflow: hidden; flex-shrink: 0; }
.dim-bar { height: 100%; border-radius: 3px; }
.dim-pct { width: 28px; text-align: right; font-weight: 600; font-size: 10px; color: var(--text-sub); flex-shrink: 0; }

.td-weak { flex: 0 0 240px; }
.td-weak h3 { font-size: 13px; margin-bottom: 10px; color: var(--text-main); }
.td-weak-item { display: flex; align-items: center; gap: 6px; margin-bottom: 8px; font-size: 12px; }
.td-weak-name { width: 90px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.td-weak-bar-bg { flex: 1; height: 5px; background: var(--bg-main); border-radius: 3px; overflow: hidden; }
.td-weak-bar { height: 100%; border-radius: 3px; }
.td-weak-pct { font-size: 11px; font-weight: 600; width: 30px; text-align: right; color: var(--danger); }

.td-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.td-table th, .td-table td { padding: 10px 12px; text-align: left; border-bottom: 1px solid var(--border); }
.td-table th { font-size: 12px; color: var(--text-sub); background: var(--bg-main); }
.rank-bar-bg { display: inline-block; width: 100px; height: 6px; background: var(--bg-main); border-radius: 3px; overflow: hidden; }
.rank-bar { height: 100%; background: var(--primary); border-radius: 3px; display: block; }

@media (max-width: 1024px) {
  .td-charts { flex-wrap: wrap; }
  .td-dims { flex: 1 1 100%; max-height: 280px; }
}
@media (max-width: 768px) {
  .td-cards { flex-wrap: wrap; }
  .td-card { flex: 1 1 40%; }
  .td-weak { flex: 1 1 100%; }
}
</style>
