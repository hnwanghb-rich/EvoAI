<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'

const router = useRouter()

interface Course { id: number; title: string; car_brand: string | null; category_id: number; knowledge_base: string; learned: boolean }
interface LearnRecord { id: number; knowledge_id: number; learn_type: string; knowledge_title: string; created_at: string | null }
interface WrongItem { id: number; knowledge_id: number; score: number; created_at: string | null }

const loading = ref(true)
const courses = ref<Course[]>([])
const allRecords = ref<LearnRecord[]>([])
const wrongItems = ref<WrongItem[]>([])
const totalHours = ref(0)
const dailyCounts = ref<Record<string, number>>({})

const kbLabel: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }

const learnedIds = computed(() => new Set(allRecords.value.map(r => r.knowledge_id)))
const coursesWithStatus = computed(() =>
  courses.value.map(c => ({ ...c, learned: learnedIds.value.has(c.id) }))
)
const requiredCourses = computed(() => coursesWithStatus.value)
const learnedCount = computed(() => requiredCourses.value.filter(c => c.learned).length)

const calendarData = computed(() => {
  const today = new Date()
  const days: { date: number; count: number; month: number }[] = []
  for (let i = 29; i >= 0; i--) {
    const d = new Date(today.getFullYear(), today.getMonth(), today.getDate() - i)
    const key = d.toISOString().slice(0, 10)
    days.push({ date: d.getDate(), month: d.getMonth(), count: dailyCounts.value[key] || 0 })
  }
  const maxCount = Math.max(...days.map(d => d.count), 1)
  return days.map(d => ({ ...d, intensity: Math.round(d.count / maxCount * 100) }))
})

async function fetchData() {
  try {
    const [kbRes, lrRes, lhRes, axRes] = await Promise.all([
      axios.get('/api/knowledge', { params: { page_size: 200 } }),
      axios.get('/api/learning/history', { params: { page_size: 200 } }),
      axios.get('/api/dashboard/personal'),
      axios.get('/api/questions/history'),
    ])
    courses.value = (kbRes.data.data.items || []).map((i: any) => ({
      id: i.id, title: i.title, car_brand: i.car_brand,
      category_id: i.category_id, knowledge_base: i.knowledge_base,
    }))
    allRecords.value = lrRes.data.data.items || []
    totalHours.value = Math.round((lhRes.data.data.week_duration_sec || 0) / 3600)
    wrongItems.value = (axRes.data.data || []).filter((r: any) => r.score === 0)

    // 统计每天学习数
    const counts: Record<string, number> = {}
    allRecords.value.forEach(r => {
      if (r.created_at) {
        const day = r.created_at.slice(0, 10)
        counts[day] = (counts[day] || 0) + 1
      }
    })
    dailyCounts.value = counts
  } finally {
    loading.value = false
  }
}

function goKnowledge(id: number) { router.push(`/knowledge/${id}`) }

onMounted(fetchData)
</script>

<template>
  <div class="lc-page">
    <h2 class="page-title">学习中心</h2>
    <div v-if="loading" class="lc-loading">加载中...</div>

    <template v-else>
      <!-- 学习统计 -->
      <div class="lc-stats">
        <div class="lc-stat card">
          <div class="stat-num">{{ learnedCount }}/{{ courses.length }}</div>
          <div class="stat-label">已学课程</div>
        </div>
        <div class="lc-stat card">
          <div class="stat-num">{{ totalHours }}h</div>
          <div class="stat-label">学习时长(周)</div>
        </div>
        <div class="lc-stat card">
          <div class="stat-num">{{ wrongItems.length }}</div>
          <div class="stat-label">错题本</div>
        </div>
      </div>

      <!-- 学习日历 -->
      <div class="lc-calendar card">
        <h3>📅 学习日历（近30天）</h3>
        <div class="cal-grid">
          <div v-for="d in calendarData" :key="d.date" class="cal-day"
            :style="{
              background: d.count > 0
                ? `rgba(var(--primary-rgb, 192,64,59), ${Math.min(d.intensity / 100, 1)})`
                : 'var(--bg-main)',
              color: d.intensity > 50 ? '#fff' : 'var(--text-main)',
            }"
            :title="`${d.count} 条学习记录`"
          >
            {{ d.date }}
          </div>
        </div>
      </div>

      <!-- 必修课列表 -->
      <div class="lc-courses card">
        <h3>📚 必修课程</h3>
        <div class="course-list">
          <div v-for="c in requiredCourses" :key="c.id" class="course-item"
            :style="{ borderLeftColor: c.learned ? 'var(--success)' : 'var(--border)' }"
            @click="goKnowledge(c.id)">
            <span class="course-status">{{ c.learned ? '✅' : '📖' }}</span>
            <span class="course-title">{{ c.title }}</span>
            <span class="course-kb">{{ kbLabel[c.knowledge_base] || c.knowledge_base }}</span>
          </div>
        </div>
      </div>

      <!-- 错题本 -->
      <div class="lc-wrong card" v-if="wrongItems.length">
        <h3>📝 错题本</h3>
        <div class="wrong-list">
          <div v-for="w in wrongItems.slice(0, 10)" :key="w.id" class="wrong-item" @click="goKnowledge(w.knowledge_id)">
            <span>❌ 知识ID {{ w.knowledge_id }}</span>
            <span class="wrong-date">{{ w.created_at?.slice(0, 10) || '-' }}</span>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.lc-page { max-width: 900px; margin: 0 auto; }
.page-title { font-size: 20px; margin-bottom: 16px; color: var(--text-main); }
.lc-loading { text-align: center; padding: 60px; color: var(--text-sub); }

.lc-stats { display: flex; gap: 12px; margin-bottom: 16px; }
.lc-stat { flex: 1; text-align: center; padding: 16px; }
.stat-num { font-size: 28px; font-weight: 700; color: var(--primary); }
.stat-label { font-size: 12px; color: var(--text-sub); margin-top: 4px; }

/* 日历 */
.lc-calendar { margin-bottom: 16px; }
.lc-calendar h3 { font-size: 14px; margin-bottom: 10px; color: var(--text-main); }
.cal-grid { display: grid; grid-template-columns: repeat(15, 1fr); gap: 3px; }
.cal-day {
  width: 100%; aspect-ratio: 1;
  display: flex; align-items: center; justify-content: center;
  font-size: 10px; border-radius: 4px; cursor: default;
}

/* 课程列表 */
.lc-courses { margin-bottom: 16px; }
.lc-courses h3 { font-size: 14px; margin-bottom: 10px; color: var(--text-main); }
.course-list { display: flex; flex-direction: column; gap: 6px; }
.course-item {
  display: flex; align-items: center; gap: 10px;
  padding: 10px 12px; border-left: 3px solid var(--border);
  cursor: pointer; border-radius: 4px; font-size: 13px;
  transition: background 0.15s;
}
.course-item:hover { background: var(--bg-main); }
.course-title { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.course-kb { font-size: 11px; color: var(--text-sub); flex-shrink: 0; }

/* 错题本 */
.lc-wrong { margin-bottom: 16px; }
.lc-wrong h3 { font-size: 14px; margin-bottom: 10px; color: var(--text-main); }
.wrong-list { display: flex; flex-direction: column; gap: 4px; }
.wrong-item {
  display: flex; justify-content: space-between;
  padding: 6px 8px; font-size: 13px; cursor: pointer;
  border-bottom: 1px solid var(--border);
}
.wrong-date { font-size: 11px; color: var(--text-sub); }

@media (max-width: 768px) {
  .lc-stats { flex-direction: column; }
  .cal-grid { grid-template-columns: repeat(7, 1fr); }
}
</style>
