<script setup lang="ts">
import { ref, onMounted, watch, onUnmounted } from 'vue'
import * as echarts from 'echarts/core'
import { RadarChart } from 'echarts/charts'
import { TooltipComponent, LegendComponent } from 'echarts/components'
import { computed } from 'vue'
import { CanvasRenderer } from 'echarts/renderers'

echarts.use([RadarChart, TooltipComponent, LegendComponent, CanvasRenderer])

interface RadarItem {
  category_name: string; mastery: number; expected: number
}

const props = defineProps<{
  data: RadarItem[]
  height?: string
}>()

const chartRef = ref<HTMLDivElement>()
let chart: echarts.ECharts | null = null

function renderChart() {
  if (!chartRef.value || !props.data.length) return
  if (!chart) {
    chart = echarts.init(chartRef.value)
  }

  // 最多显示 10 个维度，优先显示掌握度低的（薄弱领域）
  const displayData = props.data.length > 10
    ? [...props.data].sort((a, b) => a.mastery - b.mastery).slice(0, 10)
    : props.data

  const indicators = displayData.map(d => ({
    name: d.category_name,
    max: 100,
  }))

  chart.setOption({
    tooltip: {
      trigger: 'item',
      formatter: (p: any) => {
        const dimName = p.name || p.dimensionNames?.[p.dimensionIndex] || ''
        const vals = Array.isArray(p.value) ? p.value : [p.value]
        return `<b>${dimName}</b><br/>${p.seriesName}: ${vals[0] ?? p.value}%`
      },
    },
    legend: {
      data: ['我的掌握度', '岗位期望'],
      bottom: 0,
      textStyle: { color: 'var(--text-sub, #888)', fontSize: 12 },
    },
    radar: {
      center: ['50%', '52%'],
      radius: '58%',
      indicator: indicators,
      axisName: { color: 'var(--text-main)', fontSize: 12, fontWeight: 500 },
      name: {
        textStyle: { color: 'var(--text-main)', fontSize: 12 },
      },
    },
    series: [
      {
        name: '我的掌握度',
        type: 'radar',
        data: [{ value: displayData.map(d => d.mastery), name: '掌握度' }],
        lineStyle: { color: '#4A90D9', width: 2 },
        areaStyle: { color: 'rgba(74,144,217,0.15)' },
        itemStyle: { color: '#4A90D9' },
        symbol: 'circle',
        symbolSize: 4,
      },
      {
        name: '岗位期望',
        type: 'radar',
        data: [{ value: displayData.map(d => d.expected), name: '期望' }],
        lineStyle: { color: '#E8824A', width: 2, type: 'dashed' },
        areaStyle: { color: 'rgba(232,130,74,0.05)' },
        itemStyle: { color: '#E8824A' },
        symbol: 'circle',
        symbolSize: 3,
      },
    ],
  })
}

onMounted(() => { renderChart() })
watch(() => props.data, () => { chart?.dispose(); chart = null; renderChart() }, { deep: true })
onUnmounted(() => { chart?.dispose() })

const h = computed(() => props.height || '420px')
</script>

<template>
  <div ref="chartRef" :style="{ width: '100%', height: h, minHeight: '280px' }"></div>
</template>

