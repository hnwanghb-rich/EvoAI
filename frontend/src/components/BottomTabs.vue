<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const auth = useAuthStore()

interface TabItem { path: string; label: string; icon: string; roles: string[] }

const allTabs: TabItem[] = [
  { path: '/', label: '首页', icon: '🏠', roles: ['boss', 'admin', 'staff'] },
  { path: '/knowledge', label: '知识库', icon: '📚', roles: ['boss', 'admin', 'staff'] },
  { path: '/submit-experience', label: '经验', icon: '✏️', roles: ['staff'] },
  { path: '/learning', label: '学习', icon: '🎓', roles: ['staff'] },
  { path: '/review', label: '审核', icon: '✅', roles: ['admin'] },
  { path: '/knowledge-manage', label: '管理', icon: '⚙️', roles: ['admin'] },
  { path: '/profile', label: '我的', icon: '👤', roles: ['boss', 'admin', 'staff'] },
]

const tabs = computed(() =>
  allTabs.filter(t => t.roles.includes(auth.user?.role || ''))
)

function isActive(path: string) {
  if (path === '/') return route.path === '/'
  return route.path.startsWith(path)
}
</script>

<template>
  <nav class="bottom-tabs">
    <router-link
      v-for="t in tabs" :key="t.path"
      :to="t.path"
      class="tab-item"
      :class="{ active: isActive(t.path) }"
    >
      <span class="tab-icon">{{ t.icon }}</span>
      <span class="tab-label">{{ t.label }}</span>
    </router-link>
  </nav>
</template>

<style scoped>
.bottom-tabs {
  position: fixed;
  bottom: 0; left: 0; right: 0;
  z-index: 900;
  height: var(--bottom-tabs-height);
  display: flex;
  background: var(--bg-card);
  border-top: 1px solid var(--border);
  box-shadow: 0 -2px 8px rgba(0,0,0,0.06);
}

.tab-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
  color: var(--text-sub);
  font-size: 12px;
  transition: color 0.15s;
  text-decoration: none;
}
.tab-item.active {
  color: var(--primary);
  font-weight: 600;
}
.tab-icon { font-size: 18px; }
.tab-label { font-size: 10px; }
</style>
