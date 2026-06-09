<script setup lang="ts">
import { ref } from 'vue'
import { useSkinStore, SKINS } from '@/stores/skin'
import { useAuthStore } from '@/stores/auth'

const skin = useSkinStore()
const auth = useAuthStore()
const open = ref(false)

function select(id: number) {
  skin.applySkin(id)
  skin.saveToServer(auth.token)
  open.value = false
}
</script>

<template>
  <div class="skin-switcher">
    <button class="skin-trigger" @click="open = !open" title="切换皮肤">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10" />
        <path d="M12 2a10 10 0 0 0 0 20" />
        <path d="M2 12h20" />
      </svg>
    </button>
    <div v-if="open" class="skin-panel">
      <div
        v-for="s in SKINS" :key="s.id"
        class="skin-swatch"
        :class="{ active: skin.skinId === s.id }"
        :style="{ background: s.color }"
        @click="select(s.id)"
        :title="s.name"
      ></div>
    </div>
  </div>
</template>

<style scoped>
.skin-switcher {
  position: fixed;
  top: 8px;
  right: 8px;
  z-index: 1100;
}

.skin-trigger {
  width: 32px; height: 32px;
  border-radius: 50%;
  border: none;
  background: rgba(255,255,255,0.25);
  color: rgba(255,255,255,0.85);
  cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  transition: background 0.2s;
}
.skin-trigger:hover { background: rgba(255,255,255,0.4); }

.skin-panel {
  position: absolute;
  top: 38px; right: 0;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 8px;
  display: grid;
  grid-template-columns: repeat(4, 32px);
  gap: 6px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
}

.skin-swatch {
  width: 32px; height: 32px;
  border-radius: 6px;
  cursor: pointer;
  border: 2px solid transparent;
  transition: border-color 0.2s, transform 0.15s;
}
.skin-swatch:hover { transform: scale(1.1); }
.skin-swatch.active { border-color: var(--text-main); }
</style>
