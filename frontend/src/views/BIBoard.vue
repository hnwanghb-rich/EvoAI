<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import axios from 'axios'
import * as echarts from 'echarts/core'
import { PieChart, BarChart, LineChart } from 'echarts/charts'
import { TooltipComponent, LegendComponent, GridComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'

echarts.use([PieChart, BarChart, LineChart, TooltipComponent, LegendComponent, GridComponent, CanvasRenderer])

interface TrendItem { month: string; count: number }
interface KbRatio { name: string; count: number }
interface Top10 { name: string; points: number }
interface DeadDept { dept_name: string }
interface NoHit { question: string; count: number }

const loading = ref(true)
const knowledgeTotal = ref(0)
const monthNew = ref(0)
const staffCount = ref(0)
const trend = ref<TrendItem[]>([])
const kbRatio = ref<KbRatio[]>([])
const top10 = ref<Top10[]>([])
const deposit = ref(0)
const iterationRate = ref(0)
const reuseRate = ref(0)
const deadDepts = ref<DeadDept[]>([])
const noHitTop5 = ref<NoHit[]>([])

const trendRef = ref<HTMLDivElement>()
const pieRef = ref<HTMLDivElement>()
const barRef = ref<HTMLDivElement>()

let trendChart: echarts.ECharts | null = null
let pieChart: echarts.ECharts | null = null
let barChart: echarts.ECharts | null = null

const kbLabel: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }

async function fetchData() {
  const { data } = await axios.get('/api/dashboard/global')
  const d = data.data
  knowledgeTotal.value = d.knowledge_total
  monthNew.value = d.month_new
  staffCount.value = d.staff_count
  trend.value = d.trend
  kbRatio.value = d.kb_ratio
  top10.value = d.top10_contributors || []
  deposit.value = d.flywheel_deposit || 0
  iterationRate.value = d.flywheel_iteration_rate || 0
  reuseRate.value = d.flywheel_reuse_rate || 0
  deadDepts.value = d.dead_departments || []
  noHitTop5.value = d.no_hit_top5 || []
  loading.value = false

  // 渲染图表
  setTimeout(() => { renderTrend(); renderPie(); renderBar(); }, 100)
}

function renderTrend() {
  if (!trendRef.value) return
  if (!trendChart) trendChart = echarts.init(trendRef.value)
  trendChart.setOption({
    tooltip: { trigger: 'axis' },
    grid: { left: 50, right: 20, top: 20, bottom: 30 },
    xAxis: { type: 'category', data: trend.value.map(t => t.month), axisLabel: { fontSize: 10 } },
    yAxis: { type: 'value', axisLabel: { fontSize: 10 } },
    series: [{
      type: 'line', data: trend.value.map(t => t.count),
      smooth: true, lineStyle: { color: 'var(--primary, #C0403B)', width: 2 },
      areaStyle: { color: 'rgba(192,64,59,0.1)' },
      itemStyle: { color: 'var(--primary)' },
    }],
  })
}

function renderPie() {
  if (!pieRef.value) return
  if (!pieChart) pieChart = echarts.init(pieRef.value)
  pieChart.setOption({
    tooltip: { trigger: 'item', formatter: '{b}: {c} 条 ({d}%)' },
    series: [{
      type: 'pie', radius: ['45%', '70%'],
      data: kbRatio.value.map(k => ({ name: kbLabel[k.name] || k.name, value: k.count })),
      label: { color: 'var(--text-sub)', fontSize: 11 },
      itemStyle: { borderRadius: 4 },
    }],
  })
}

function renderBar() {
  if (!barRef.value) return
  if (!barChart) barChart = echarts.init(barRef.value)
  barChart.setOption({
    tooltip: { trigger: 'axis' },
    grid: { left: 60, right: 20, top: 10, bottom: 30 },
    xAxis: { type: 'value', axisLabel: { fontSize: 10 } },
    yAxis: { type: 'category', data: top10.value.map(t => t.name).reverse(), axisLabel: { fontSize: 10 } },
    series: [{
      type: 'bar', data: top10.value.map(t => t.points).reverse(),
      itemStyle: { color: 'var(--primary)', borderRadius: [0, 4, 4, 0] },
    }],
  })
}

const isFullscreen = ref(false)

function toggleFullscreen() {
  if (document.fullscreenElement) {
    document.exitFullscreen?.()
    isFullscreen.value = false
  } else {
    document.documentElement.requestFullscreen?.()
    isFullscreen.value = true
  }
}

function onFsChange() {
  isFullscreen.value = !!document.fullscreenElement
}

onMounted(() => {
  fetchData()
  document.addEventListener('fullscreenchange', onFsChange)
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && isFullscreen.value) onFsChange() })
})
onUnmounted(() => {
  trendChart?.dispose(); pieChart?.dispose(); barChart?.dispose()
  document.removeEventListener('fullscreenchange', onFsChange)
})
</script>

<template>
  <div class="bi-page" :class="{ fullscreen: isFullscreen }">
    <div class="bi-head">
      <h2>◈ 合群汽车集团 · BI 数据大屏</h2>
      <button class="btn btn-sm" @click="toggleFullscreen">{{ isFullscreen ? '退出全屏' : '⛶ 全屏' }}</button>
    </div>

    <div v-if="loading" class="bi-loading">加载中...</div>

    <template v-else>
      <!-- 顶部四大数字卡 -->
      <div class="bi-kpis">
        <div class="bi-kpi card"><span class="bi-kpi-num">{{ knowledgeTotal }}</span><span class="bi-kpi-label">知识总量</span></div>
        <div class="bi-kpi card"><span class="bi-kpi-num">+{{ monthNew }}</span><span class="bi-kpi-label">月新增</span></div>
        <div class="bi-kpi card"><span class="bi-kpi-num">{{ staffCount }}</span><span class="bi-kpi-label">员工总数</span></div>
        <div class="bi-kpi card"><span class="bi-kpi-num">{{ reuseRate }}%</span><span class="bi-kpi-label">知识复用率</span></div>
      </div>

      <!-- 2x3 图表网格 -->
      <div class="bi-grid">
        <!-- 趋势 -->
        <div class="bi-cell card">
          <h4>知识增长趋势</h4>
          <div ref="trendRef" style="width:100%;height:220px"></div>
        </div>
        <!-- 占比 -->
        <div class="bi-cell card">
          <h4>四大知识库占比</h4>
          <div ref="pieRef" style="width:100%;height:220px"></div>
        </div>
        <!-- 贡献榜 -->
        <div class="bi-cell card">
          <h4>经验贡献 TOP10</h4>
          <div ref="barRef" style="width:100%;height:220px" v-if="top10.length"></div>
          <div v-else class="empty-chart">暂无数据</div>
        </div>
        <!-- 飞轮指标 -->
        <div class="bi-cell card">
          <h4>知识飞轮运转</h4>
          <div class="flywheel-metrics">
            <div class="fw-item"><span class="fw-val">{{ deposit }}</span><span class="fw-lbl">本月沉淀</span></div>
            <div class="fw-item"><span class="fw-val">{{ iterationRate }}%</span><span class="fw-lbl">迭代率</span></div>
            <div class="fw-item"><span class="fw-val">{{ reuseRate }}%</span><span class="fw-lbl">复用率</span></div>
          </div>
          <div class="fw-desc">
            <p>本月经验提交数 <b>{{ deposit }}</b> 次</p>
            <p>知识迭代率 <b>{{ iterationRate }}%</b>（归档/总量）</p>
            <p>AI 对话命中率 <b>{{ reuseRate }}%</b></p>
          </div>
        </div>
        <!-- 预警：死部门 -->
        <div class="bi-cell card">
          <h4>⚡ 长期无沉淀部门</h4>
          <div v-if="deadDepts.length" class="alert-list">
            <p v-for="d in deadDepts" :key="d.dept_name">⚠ {{ d.dept_name }}</p>
          </div>
          <div v-else class="empty-chart">◆ 各部门近期均有贡献</div>
        </div>
        <!-- 预警：未命中 -->
        <div class="bi-cell card">
          <h4>▲ 高频未命中问题</h4>
          <div v-if="noHitTop5.length" class="alert-list">
            <p v-for="n in noHitTop5" :key="n.question">{{ n.question.slice(0, 40) }}... ({{ n.count }}次)</p>
          </div>
          <div v-else class="empty-chart">暂无数据</div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.bi-page { max-width: 1400px; margin: 0 auto; }
.bi-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.bi-head h2 { font-size: 20px; color: var(--text-main); margin: 0; }
.bi-loading { text-align: center; padding: 80px; color: var(--text-sub); }

.bi-kpis { display: flex; gap: 12px; margin-bottom: 16px; }
.bi-kpi { flex: 1; text-align: center; padding: 16px; }
.bi-kpi-num { display: block; font-size: 32px; font-weight: 700; color: var(--primary); }
.bi-kpi-label { display: block; font-size: 12px; color: var(--text-sub); margin-top: 4px; }

.bi-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
.bi-cell { padding: 16px; }
.bi-cell h4 { font-size: 13px; margin: 0 0 10px; color: var(--text-sub); }
.empty-chart { text-align: center; padding: 40px; color: var(--text-sub); font-size: 13px; }

.flywheel-metrics { display: flex; justify-content: space-around; margin-bottom: 12px; }
.fw-item { text-align: center; }
.fw-val { display: block; font-size: 28px; font-weight: 700; color: var(--accent); }
.fw-lbl { font-size: 11px; color: var(--text-sub); }
.fw-desc { font-size: 11px; color: var(--text-sub); line-height: 1.8; }

.alert-list { font-size: 13px; }
.alert-list p { padding: 4px 0; color: var(--text-main); border-bottom: 1px solid var(--border); }

@media (max-width: 1024px) {
  .bi-grid { grid-template-columns: repeat(2, 1fr); }
  .bi-kpis { flex-wrap: wrap; }
  .bi-kpi { flex: 1 1 40%; }
}
/* 全屏模式 */
.bi-page.fullscreen {
  position: fixed; inset: 0; z-index: 9999;
  background: var(--bg-main);
  overflow-y: auto;
  padding: 30px;
  max-width: none;
}
.bi-page.fullscreen .bi-grid {
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

@media (max-width: 768px) {
  .bi-grid { grid-template-columns: 1fr; }
  .bi-kpis { flex-direction: column; }
  .bi-page.fullscreen .bi-grid { grid-template-columns: repeat(2, 1fr); }
}
</style>
