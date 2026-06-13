<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const auth = useAuthStore()

interface MenuItem { path: string; label: string; icon: string; roles: string[] }

const allMenus: MenuItem[] = [
  { path: '/', label: '首页', icon: '🏠', roles: ['boss', 'admin', 'staff'] },
  { path: '/knowledge-manage', label: '知识管理', icon: '📚', roles: ['boss', 'admin', 'staff'] },
  { path: '/submit-experience', label: '提交经验', icon: '✏️', roles: ['staff'] },
  { path: '/personal-dashboard', label: '个人看板', icon: '📊', roles: ['staff'] },
  { path: '/learning', label: '学习中心', icon: '🎓', roles: ['staff'] },
  { path: '/question', label: '每次一题', icon: '❓', roles: ['staff'] },
  { path: '/exam-manage', label: '考试管理', icon: '📝', roles: ['boss', 'admin', 'staff'] },
  { path: '/profile', label: '个人中心', icon: '👤', roles: ['boss', 'admin', 'staff'] },
  { path: '/review', label: '审核中心', icon: '✅', roles: ['admin'] },
  { path: '/team-dashboard', label: '团队看板', icon: '👥', roles: ['admin', 'boss'] },
  { path: '/user-manage', label: '用户管理', icon: '👨‍👩‍👧', roles: ['admin'] },
  { path: '/llm-settings', label: 'LLM配置', icon: '🤖', roles: ['admin'] },
  { path: '/system-settings', label: '系统管理', icon: '🔧', roles: ['admin'] },
  { path: '/bi-board', label: 'BI大屏', icon: '📈', roles: ['boss'] },
]

const menus = computed(() =>
  allMenus.filter(m => m.roles.includes(auth.user?.role || ''))
)

function isActive(path: string) {
  if (path === '/') return route.path === '/'
  return route.path.startsWith(path)
}
</script>

<template>
  <nav class="side-menu">
    <ul>
      <li v-for="m in menus" :key="m.path">
        <router-link :to="m.path" :class="{ active: isActive(m.path) }">
          <span class="menu-icon">{{ m.icon }}</span>
          <span class="menu-label">{{ m.label }}</span>
        </router-link>
      </li>
    </ul>
  </nav>
</template>

<style scoped>
.side-menu {
  position: fixed;
  top: var(--banner-height);
  left: 0;
  bottom: 0;
  width: var(--side-menu-width);
  background: var(--bg-card);
  border-right: 1px solid var(--border);
  overflow-y: auto;
  z-index: 900;
  padding: 8px 0;
}

.side-menu ul {
  list-style: none;
  padding: 0; margin: 0;
}

.side-menu li a {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 18px;
  font-size: 14px;
  color: var(--text-main);
  transition: background 0.15s, color 0.15s;
  border-left: 3px solid transparent;
  text-decoration: none;
}
.side-menu li a:hover {
  background: var(--bg-main);
  color: var(--primary);
}
.side-menu li a.active {
  background: var(--bg-main);
  color: var(--primary);
  border-left-color: var(--primary);
  font-weight: 600;
}
.menu-icon { font-size: 16px; width: 22px; text-align: center; }
.menu-label { white-space: nowrap; }
</style>
