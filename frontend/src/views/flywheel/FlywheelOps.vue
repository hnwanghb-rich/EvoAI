<script setup lang="ts">
// 飞轮运营 —— 合并：飞轮总览 / 知识缺口 / 查重预审 / 知识时效
import { ref } from 'vue'
import FlywheelOverview from './FlywheelOverview.vue'
import KnowledgeGapBoard from './KnowledgeGapBoard.vue'
import PreReviewDedup from './PreReviewDedup.vue'
import KnowledgeExpiry from './KnowledgeExpiry.vue'

const tab = ref<'overview' | 'gap' | 'prereview' | 'expiry'>('overview')
</script>

<template>
  <div class="ops-wrap">
    <div class="top-tabs">
      <button :class="['ttab', { active: tab === 'overview' }]" @click="tab = 'overview'">↺ 飞轮总览</button>
      <button :class="['ttab', { active: tab === 'gap' }]" @click="tab = 'gap'">◎ 知识缺口</button>
      <button :class="['ttab', { active: tab === 'prereview' }]" @click="tab = 'prereview'">⊕ 查重预审</button>
      <button :class="['ttab', { active: tab === 'expiry' }]" @click="tab = 'expiry'">⌚ 知识时效</button>
    </div>
    <FlywheelOverview v-if="tab === 'overview'" />
    <KnowledgeGapBoard v-if="tab === 'gap'" />
    <PreReviewDedup v-if="tab === 'prereview'" />
    <KnowledgeExpiry v-if="tab === 'expiry'" />
  </div>
</template>

<style scoped>
.ops-wrap { display: flex; flex-direction: column; min-height: 100%; }
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
