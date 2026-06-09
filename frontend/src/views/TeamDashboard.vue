<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'
import RadarChart from '@/components/RadarChart.vue'

interface MemberRank { user_id: number; real_name: string; position: string; points: number }
interface RadarItem { category_id: number; category_name: string; icon: string | null; mastery: number; expected: number }

const loading = ref(true)
const deptName = ref('')
const memberCount = ref(0)
const teamMastery = ref(0)
const monthNewLearned = ref(0)
const radarData = ref<RadarItem[]>([])
const weakAreas = ref<{ category_name: string; mastery: number }[]>([])
const memberRank = ref<MemberRank[]>([])

async function fetchData() {
  const { data } = await axios.get('/api/dashboard/team')
  const d = data.data
  deptName.value = d.dept_name
  memberCount.value = d.member_count
  teamMastery.value = d.team_mastery
  monthNewLearned.value = d.month_new_learned
  radarData.value = d.radar_data
  weakAreas.value = d.weak_areas
  memberRank.value = d.member_rank
  loading.value = false
}

onMounted(fetchData)
</script>

<template>
  <div class="td-page">
    <h2 class="page-title">团队看板 · {{ deptName }}</h2>

    <div v-if="loading" class="td-loading">加载中...</div>

    <template v-else>
      <!-- 顶部指标 -->
      <div class="td-cards">
        <div class="td-card card">
          <svg viewBox="0 0 100 100" width="86" height="86">
            <circle cx="50" cy="50" r="44" fill="none" stroke="var(--border)" stroke-width="6"/>
            <circle cx="50" cy="50" r="44" fill="none" stroke="var(--primary)" stroke-width="6"
              stroke-linecap="round"
              :stroke-dasharray="2 * Math.PI * 44"
              :stroke-dashoffset="2 * Math.PI * 44 * (1 - teamMastery / 100)"
              transform="rotate(-90 50 50)"
              style="transition: stroke-dashoffset 0.8s"/>
            <text x="50" y="48" text-anchor="middle" font-size="16" font-weight="bold" fill="var(--text-main)">{{ teamMastery }}%</text>
            <text x="50" y="62" text-anchor="middle" font-size="8" fill="var(--text-sub)">团队掌握度</text>
          </svg>
          <div class="td-card-text">团队掌握度</div>
        </div>
        <div class="td-card card">
          <div class="td-card-num">{{ memberCount }}</div>
          <div class="td-card-label">部门人数</div>
        </div>
        <div class="td-card card">
          <div class="td-card-num">{{ monthNewLearned }}</div>
          <div class="td-card-label">本月学习条目</div>
        </div>
      </div>

      <!-- 雷达图 -->
      <div class="td-charts">
        <div class="card" style="flex:1">
          <h3>团队分类掌握度</h3>
          <RadarChart :data="radarData" height="340px" />
        </div>
        <div class="card td-weak" v-if="weakAreas.length">
          <h3>📉 团队薄弱领域</h3>
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
              <td>
                <span class="rank-bar-bg">
                  <span class="rank-bar" :style="{ width: Math.min(m.points / (memberRank[0]?.points || 1) * 100, 100) + '%' }"></span>
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </div>
</template>

<style scoped>
.td-page { max-width: 1100px; margin: 0 auto; }
.page-title { font-size: 20px; margin-bottom: 16px; color: var(--text-main); }
.td-loading { text-align: center; padding: 60px; color: var(--text-sub); }

.td-cards { display: flex; gap: 12px; margin-bottom: 16px; }
.td-card { text-align: center; padding: 16px; flex: 1; }
.td-card-num { font-size: 32px; font-weight: 700; color: var(--primary); }
.td-card-text { font-size: 12px; color: var(--text-sub); margin-top: 4px; }
.td-card-label { font-size: 12px; color: var(--text-sub); margin-top: 4px; }

.td-charts { display: flex; gap: 16px; margin-bottom: 16px; }
.td-charts .card { padding: 16px; }
.td-charts .card h3 { font-size: 14px; margin-bottom: 10px; color: var(--text-sub); }
.td-weak { flex: 0 0 280px; }
.td-weak-item { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; font-size: 13px; }
.td-weak-name { width: 100px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.td-weak-bar-bg { flex: 1; height: 6px; background: var(--bg-main); border-radius: 3px; overflow: hidden; }
.td-weak-bar { height: 100%; border-radius: 3px; transition: width 0.5s; }
.td-weak-pct { font-size: 12px; font-weight: 600; width: 36px; text-align: right; color: var(--danger); }

.td-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.td-table th, .td-table td { padding: 10px 12px; text-align: left; border-bottom: 1px solid var(--border); }
.td-table th { font-size: 12px; color: var(--text-sub); background: var(--bg-main); }
.rank-bar-bg { display: inline-block; width: 100px; height: 6px; background: var(--bg-main); border-radius: 3px; overflow: hidden; }
.rank-bar { height: 100%; background: var(--primary); border-radius: 3px; display: block; }

.card h3 { font-size: 16px; margin-bottom: 12px; color: var(--text-main); }

@media (max-width: 768px) {
  .td-cards { flex-direction: column; }
  .td-charts { flex-direction: column; }
  .td-weak { flex: none; }
}
</style>
