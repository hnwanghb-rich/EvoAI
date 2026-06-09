<script setup lang="ts">
import { onMounted } from 'vue'
import { useAuthStore } from './stores/auth'
import { useSkinStore } from './stores/skin'
import TopBanner from './components/TopBanner.vue'
import SkinSwitcher from './components/SkinSwitcher.vue'
import PageHelp from './components/PageHelp.vue'
import SideMenu from './components/SideMenu.vue'
import BottomTabs from './components/BottomTabs.vue'
import ANengChat from './components/ANengChat.vue'

const auth = useAuthStore()
const skin = useSkinStore()

onMounted(() => {
  auth.init()
  // 同步皮肤到 body
  document.body.setAttribute('data-skin', String(skin.skinId))
})
</script>

<template>
  <div class="app-shell">
    <!-- 登录页：无布局 -->
    <template v-if="!auth.isLoggedIn">
      <router-view />
    </template>

    <!-- 已登录：完整布局 -->
    <template v-else>
      <TopBanner />
      <SkinSwitcher />

      <div class="side-menu-wrapper">
        <SideMenu />
      </div>

      <main class="app-main">
        <router-view />
      </main>

      <div class="bottom-tabs-wrapper">
        <BottomTabs />
      </div>

      <ANengChat />
      <PageHelp />
    </template>
  </div>
</template>

<style>
/* 全局基础样式 */
*, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }
html, body, #app { height: 100%; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Microsoft YaHei", sans-serif;
  background: var(--bg-main, #FEF9F6);
  color: var(--text-main, #3D2B28);
  -webkit-font-smoothing: antialiased;
}
a { color: inherit; text-decoration: none; }
.app-main {
  padding: 16px;
  transition: margin-left 0.2s;
}
/* 手机端减小 padding */
@media (max-width: 768px) {
  .app-main { padding: 10px; }
}
</style>
