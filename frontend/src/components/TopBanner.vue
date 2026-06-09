<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
const auth = useAuthStore()
</script>

<template>
  <header class="top-banner">
    <div class="banner-left">
      <div class="banner-title">
        <span class="banner-title-main">合群汽车集团</span>
        <span class="banner-title-divider">·</span>
        <span class="banner-title-sub">AI + 业务能力知识库</span>
      </div>
      <p class="banner-slogan">数字化经验沉淀 · 全员能力提升 · 知识驱动飞轮</p>
    </div>
    <div class="banner-right">
      <span class="banner-user" v-if="auth.isLoggedIn && auth.user">
        {{ auth.user.real_name }}
        <span class="banner-role">({{ auth.isBoss ? '老板' : auth.isAdmin ? '管理员' : '职员' }})</span>
      </span>
    </div>
  </header>
</template>

<style scoped>
.top-banner {
  position: fixed;
  top: 0; left: 0; right: 0;
  z-index: 1000;
  height: var(--banner-height, 120px);
  background: var(--banner-bg, linear-gradient(135deg, #C0403B, #D46864, #E8824A));
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.18);
}

/* ---- 文字标题区 ---- */
.banner-left {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.banner-title {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.banner-title-main {
  font-family: "STKaiti", "KaiTi", "楷体", "SimSun", "宋体", serif;
  font-size: 32px;
  font-weight: 700;
  color: #fff;
  letter-spacing: 6px;
  text-shadow: 0 2px 8px rgba(0,0,0,0.25);
}

.banner-title-divider {
  font-size: 26px;
  color: rgba(255,255,255,0.5);
  font-weight: 300;
}

.banner-title-sub {
  font-family: "STKaiti", "KaiTi", "楷体", "SimSun", "宋体", serif;
  font-size: 20px;
  font-weight: 400;
  color: rgba(255,255,255,0.85);
  letter-spacing: 4px;
  text-shadow: 0 1px 4px rgba(0,0,0,0.2);
}

.banner-slogan {
  margin: 0;
  font-size: 11px;
  color: rgba(255,255,255,0.55);
  letter-spacing: 3px;
  padding-left: 2px;
}

/* ---- 用户区 ---- */
.banner-right {
  display: flex; align-items: center; gap: 12px;
  flex-shrink: 0;
}

.banner-user {
  color: rgba(255,255,255,0.9);
  font-size: 14px;
  white-space: nowrap;
}

.banner-role {
  opacity: 0.7; font-size: 12px;
}

/* ---- 响应式 ---- */
@media (max-width: 768px) {
  :root { --banner-height: 64px; }
  .top-banner { padding: 0 12px; }
  .banner-title-main { font-size: 18px; letter-spacing: 2px; }
  .banner-title-divider { font-size: 14px; }
  .banner-title-sub { font-size: 12px; letter-spacing: 1px; }
  .banner-slogan { display: none; }
  .banner-user { font-size: 11px; }
}
</style>
