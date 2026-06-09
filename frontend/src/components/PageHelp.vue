<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import { helpContent, getHelpKey, type HelpSection } from '@/helpContent'

const route = useRoute()
const open = ref(false)

const help = computed<HelpSection>(() => {
  const key = getHelpKey(route.path)
  return helpContent[key] || { title: '帮助', what: '暂无此页面的帮助内容。' }
})

watch(() => route.path, () => { open.value = false })
</script>

<template>
  <div class="page-help">
    <!-- ? 按钮 -->
    <button class="help-trigger" @click="open = true" title="页面帮助">?</button>

    <!-- 帮助抽屉 -->
    <Teleport to="body">
      <div v-if="open" class="help-overlay" @click.self="open = false">
        <div class="help-drawer">
          <div class="help-header">
            <h3>{{ help.title }} — 页面帮助</h3>
            <button class="help-close" @click="open = false">×</button>
          </div>
          <div class="help-body">
            <section v-if="help.what">
              <h4>功能说明</h4>
              <p>{{ help.what }}</p>
            </section>
            <section v-if="help.how && help.how.length">
              <h4>操作步骤</h4>
              <ol>
                <li v-for="(step, i) in help.how" :key="i">{{ step }}</li>
              </ol>
            </section>
            <section v-if="help.related && help.related.length">
              <h4>相关操作页面</h4>
              <ul>
                <li v-for="(r, i) in help.related" :key="i">
                  <router-link v-if="r.link" :to="r.link" @click="open = false">{{ r.name }}</router-link>
                  <span v-else>{{ r.name }}</span>
                  <span v-if="r.desc"> — {{ r.desc }}</span>
                </li>
              </ul>
            </section>
            <section v-if="help.logic">
              <h4>业务逻辑说明</h4>
              <div v-html="help.logic"></div>
            </section>
            <section v-if="help.note">
              <h4>注意事项</h4>
              <p>{{ help.note }}</p>
            </section>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.help-trigger {
  position: fixed;
  right: 20px;
  bottom: 100px;
  z-index: 900;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: none;
  background: var(--primary, #6B7B8B);
  color: #fff;
  font-size: 20px;
  font-weight: bold;
  cursor: pointer;
  opacity: 0.75;
  transition: opacity 0.2s;
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}
.help-trigger:hover { opacity: 1; }

.help-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background: rgba(0,0,0,0.3);
}
.help-drawer {
  position: fixed;
  top: 0;
  right: 0;
  width: 480px;
  max-width: 100vw;
  height: 100vh;
  background: var(--bg-card, #fff);
  box-shadow: -4px 0 20px rgba(0,0,0,0.12);
  display: flex;
  flex-direction: column;
  animation: slideIn 0.25s ease;
}
@keyframes slideIn {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}

.help-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid var(--border, #e5e5e5);
}
.help-header h3 {
  margin: 0;
  font-size: 16px;
  color: var(--text-main, #1a1a1a);
}
.help-close {
  width: 32px; height: 32px;
  border: none; background: none;
  font-size: 22px; cursor: pointer;
  color: var(--text-sub, #888);
}

.help-body {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  color: var(--text-main, #1a1a1a);
  line-height: 1.75;
}
.help-body h4 {
  margin: 20px 0 8px;
  font-size: 14px;
  color: var(--primary, #6B7B8B);
}
.help-body h4:first-child { margin-top: 0; }
.help-body ol, .help-body ul { padding-left: 20px; margin: 4px 0; }
.help-body li { margin-bottom: 4px; }
.help-body a { color: var(--primary); }
.help-body p { margin: 4px 0; }
</style>
