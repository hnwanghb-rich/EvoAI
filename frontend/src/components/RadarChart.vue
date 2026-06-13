<script setup lang="ts">
import { ref, onMounted, watch, onUnmounted } from 'vue'
import * as echarts from 'echarts/core'
import { RadarChart } from 'echarts/charts'
import { TooltipComponent, LegendComponent } from 'echarts/components'
import { computed } from 'vue'
import { CanvasRenderer } from 'echarts/renderers'

echarts.use([RadarChart, TooltipComponent, LegendComponent, CanvasRenderer])

interface RadarItem {
  category_name: string; mastery: number; expected: number; description?: string
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

  // 全部维度展示
  const displayData = props.data

  const count = displayData.length
  const radarRadius = count <= 6 ? '40%' : count <= 10 ? '38%' : '34%'
  const radarCenter = ['50%', '55%']

  const indicators = displayData.map(d => ({
    name: d.category_name,
    max: 100,
  }))

  chart.setOption({
    tooltip: {
      trigger: 'item',
      formatter: (p: any) => {
        const dimIdx = p.dimensionIndex ?? 0
        const dim = displayData[dimIdx]
        const dimName = dim?.category_name || p.name || ''
        const desc = dim?.description || ''
        const vals = Array.isArray(p.value) ? p.value : [p.value]
        let html = `<b>${dimName}</b>`
        if (desc) html += `<br/><span style="color:#999;font-size:12px">${desc}</span>`
        html += `<br/>${p.seriesName}: ${vals[0] ?? p.value}%`
        return html
      },
    },
    legend: {
      data: ['我的掌握度', '岗位期望'],
      bottom: 0,
      textStyle: { color: '#888888', fontSize: 12 },
    },
    radar: {
      center: radarCenter,
      radius: radarRadius,
      indicator: indicators,
      axisName: { color: '#222222', fontSize: 12, fontWeight: 600 },
      nameGap: 16,
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
        symbolSize: 6,
        label: {
          show: true,
          formatter: (p: any) => { const v = Array.isArray(p.value) ? p.value : [p.value]; return `${v[0]}%` },
          fontSize: 11, color: '#4A90D9', fontWeight: 'bold',
        },
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
        label: {
          show: true,
          formatter: (p: any) => { const v = Array.isArray(p.value) ? p.value : [p.value]; return `${v[0]}%` },
          fontSize: 10, color: '#E8824A',
        },
      },
    ],
  })
}

onMounted(() => { renderChart() })
watch(() => props.data, () => { chart?.dispose(); chart = null; renderChart() }, { deep: true })
onUnmounted(() => { chart?.dispose() })

const h = computed(() => props.height || '520px')
</script>

<template>
  <div ref="chartRef" :style="{ width: '100%', height: h, minHeight: '280px' }"></div>
</template>

