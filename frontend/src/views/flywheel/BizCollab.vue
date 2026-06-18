<script setup lang="ts">
// 业务协同 —— 合并：赢单复盘 / 故障案例 / 投诉回流 / 跨线任务
import { ref } from 'vue'
import SalesWinReview from './SalesWinReview.vue'
import RepairCaseBase from './RepairCaseBase.vue'
import ServiceComplaintRoot from './ServiceComplaintRoot.vue'
import CrosslineTaskCenter from './CrosslineTaskCenter.vue'

const tab = ref<'sales' | 'repair' | 'service' | 'crossline'>('sales')
</script>

<template>
  <div class="biz-wrap">
    <div class="top-tabs">
      <button :class="['ttab', { active: tab === 'sales' }]" @click="tab = 'sales'">◆ 赢单复盘</button>
      <button :class="['ttab', { active: tab === 'repair' }]" @click="tab = 'repair'">⚙ 故障案例</button>
      <button :class="['ttab', { active: tab === 'service' }]" @click="tab = 'service'">☏ 投诉回流</button>
      <button :class="['ttab', { active: tab === 'crossline' }]" @click="tab = 'crossline'">⇄ 跨线任务</button>
    </div>
    <SalesWinReview v-if="tab === 'sales'" />
    <RepairCaseBase v-if="tab === 'repair'" />
    <ServiceComplaintRoot v-if="tab === 'service'" />
    <CrosslineTaskCenter v-if="tab === 'crossline'" />
  </div>
</template>

<style scoped>
.biz-wrap { display: flex; flex-direction: column; min-height: 100%; }
.top-tabs {
  display: flex;
  border-bottom: 2px solid var(--border, #e5e5e5);
  background: var(--bg-card, #fff);
  padding: 0 20px;
  position: sticky;
  top: 0;
  z-index: 10;
  flex-shrink: 0;
}
.ttab {
  padding: 10px 18px;
  border: none;
  background: none;
  cursor: pointer;
  font-size: 14px;
  color: var(--text-main);
  border-bottom: 2px solid transparent;
  margin-bottom: -2px;
  white-space: nowrap;
}
.ttab.active {
  color: var(--primary, #6B7B8B);
  border-bottom-color: var(--primary, #6B7B8B);
  font-weight: 600;
}
.ttab:hover { color: var(--primary, #6B7B8B); }
</style>
