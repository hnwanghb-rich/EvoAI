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

  const indicators = props.data.map(d => ({
    name: d.category_name.replace(/^(.{4}).*/, '$1…').slice(0, 5),
    max: 100,
  }))
  const fullNames = props.data.map(d => d.category_name)

  chart.setOption({
    tooltip: {
      formatter: (p: any) => {
        const i = p.dataIndex
        const name = fullNames[p.seriesIndex] || ''
        const idx = p.dimensionIndex
        const cat = fullNames[idx] || ''
        return `<b>${cat}</b><br/>${name}: ${p.value}%`
      },
    },
    legend: {
      data: ['我的掌握度', '岗位期望'],
      bottom: 0,
      textStyle: { color: 'var(--text-sub, #888)', fontSize: 12 },
    },
    radar: {
      center: ['50%', '48%'],
      radius: '65%',
      indicator: indicators,
      axisName: { color: 'var(--text-sub, #888)', fontSize: 11 },
    },
    series: [
      {
        name: '我的掌握度',
        type: 'radar',
        data: [{ value: props.data.map(d => d.mastery), name: '掌握度' }],
        lineStyle: { color: '#4A90D9', width: 2 },
        areaStyle: { color: 'rgba(74,144,217,0.15)' },
        itemStyle: { color: '#4A90D9' },
        symbol: 'circle',
        symbolSize: 4,
      },
      {
        name: '岗位期望',
        type: 'radar',
        data: [{ value: props.data.map(d => d.expected), name: '期望' }],
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

const h = computed(() => props.height || '340px')
</script>

<template>
  <div ref="chartRef" :style="{ width: '100%', height: h, minHeight: '280px' }"></div>
</template>

