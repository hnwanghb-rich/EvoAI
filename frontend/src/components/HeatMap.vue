<script setup lang="ts">
import { ref, onMounted, watch, onUnmounted } from 'vue'
import * as echarts from 'echarts/core'
import { HeatmapChart } from 'echarts/charts'
import { TooltipComponent, GridComponent, VisualMapComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'

echarts.use([HeatmapChart, TooltipComponent, GridComponent, VisualMapComponent, CanvasRenderer])

interface Props {
  xLabels: string[]       // 门店名（列）
  yLabels: string[]       // 分类名（行）
  data: number[][]        // [y][x] 掌握度矩阵
  height?: string
}

const props = withDefaults(defineProps<Props>(), { height: '380px' })
const chartRef = ref<HTMLDivElement>()
let chart: echarts.ECharts | null = null

function render() {
  if (!chartRef.value || !props.data.length) return
  if (!chart) chart = echarts.init(chartRef.value)

  // 构建 heatmap 数据: [x, y, value]
  const hmData: [number, number, number][] = []
  for (let y = 0; y < props.data.length; y++) {
    for (let x = 0; x < (props.data[y]?.length || 0); x++) {
      hmData.push([x, y, props.data[y][x]])
    }
  }

  const maxVal = Math.max(...hmData.map(d => d[2]), 1)

  chart.setOption({
    tooltip: {
      formatter: (p: any) =>
        `${props.yLabels[p.data[1]]} / ${props.xLabels[p.data[0]]}<br/>掌握度: <b>${p.data[2]}%</b>`,
    },
    grid: { left: 120, right: 40, top: 20, bottom: 60 },
    xAxis: {
      type: 'category',
      data: props.xLabels,
      axisLabel: { rotate: 30, fontSize: 11, color: 'var(--text-sub, #888)' },
    },
    yAxis: {
      type: 'category',
      data: props.yLabels,
      axisLabel: { fontSize: 11, color: 'var(--text-sub, #888)', width: 100, overflow: 'truncate' },
    },
    visualMap: {
      min: 0, max: maxVal || 100,
      calculable: true,
      orient: 'horizontal',
      left: 'center', bottom: 0,
      inRange: { color: ['#f0f4f8', '#c6e0b4', '#7bc96f', '#2ea043', '#1a7f37'] },
      textStyle: { color: 'var(--text-sub, #888)', fontSize: 10 },
    },
    series: [{
      type: 'heatmap',
      data: hmData,
      label: { show: true, fontSize: 10, color: 'var(--text-main)' },
      emphasis: { itemStyle: { shadowBlur: 10, shadowColor: 'rgba(0,0,0,0.3)' } },
    }],
  })
}

onMounted(render)
watch(() => [props.data, props.xLabels, props.yLabels], () => { chart?.dispose(); chart = null; render() }, { deep: true })
onUnmounted(() => chart?.dispose())
</script>

<template>
  <div ref="chartRef" :style="{ width: '100%', height: props.height }"></div>
</template>
