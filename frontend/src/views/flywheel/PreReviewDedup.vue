<script setup lang="ts">
// FW-03 AI 预审查重台 —— pending 知识查重预检
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface PendingItem {
  id: number
  title: string
  tags: string
  knowledge_base: string
  kb_label: string
  source_person: string
  created_at: string | null
}
interface Similar {
  candidate_id: number
  candidate_title: string
  title_sim: number
  content_sim: number
  combined_sim: number
  label: string
}
interface CheckResult {
  entry_id: number
  title: string
  knowledge_base: string
  verdict: string
  verdict_label: string
  similar_count: number
  similar: Similar[]
  note: string
}

const loading = ref(false)
const checkLoading = ref(false)
const items = ref<PendingItem[]>([])
const selected = ref<PendingItem | null>(null)
const checkResult = ref<CheckResult | null>(null)
const error = ref('')

async function loadList() {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/flywheel/prereview/list')
    items.value = res.data.data.items || []
  } catch {
    error.value = '加载失败，请确认已用管理员账号登录'
  } finally {
    loading.value = false
  }
}

async function checkEntry(item: PendingItem) {
  selected.value = item
  checkResult.value = null
  checkLoading.value = true
  try {
    const res = await axios.get(`/api/flywheel/prereview/check/${item.id}`)
    checkResult.value = res.data.data
  } catch (e: any) {
    error.value = e?.response?.data?.detail || '查重失败'
  } finally {
    checkLoading.value = false
  }
}

function verdictClass(verdict: string) {
  if (verdict === 'duplicate') return 'tag-red'
  if (verdict === 'related') return 'tag-orange'
  return 'tag-green'
}

function simColor(sim: number) {
  if (sim >= 0.6) return '#c73a3a'
  if (sim >= 0.35) return '#c77700'
  return '#3a8f3a'
}

onMounted(loadList)
</script>

<template>
  <div class="prereview">
    <div class="page-head">
      <h2>AI 预审查重台</h2>
      <p class="sub">对待审核知识做查重预检，标出疑似重复和高度相关条目，辅助审核人决策（AI 建议，人工裁决）。</p>
    </div>

    <div v-if="error" class="err">{{ error }}</div>

    <div class="layout">
      <!-- 左：待审列表 -->
      <div class="left-panel">
        <div class="panel-head">
          待审核知识
          <span class="count">{{ items.length }}</span>
          <button class="refresh-btn" @click="loadList" :disabled="loading">{{ loading ? '…' : '刷新' }}</button>
        </div>
        <div v-if="loading && items.length === 0" class="loading">加载中…</div>
        <div v-else-if="items.length === 0" class="empty">暂无待审核知识</div>
        <div v-else class="item-list">
          <div
            v-for="item in items" :key="item.id"
            class="item-row"
            :class="{ active: selected?.id === item.id }"
            @click="checkEntry(item)"
          >
            <div class="item-title">{{ item.title }}</div>
            <div class="item-meta">
              <span class="kb-tag">{{ item.kb_label }}</span>
              <span class="person">{{ item.source_person || '—' }}</span>
              <span class="time">{{ item.created_at ? item.created_at.slice(0, 10) : '' }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 右：查重结果 -->
      <div class="right-panel">
        <div v-if="!selected" class="placeholder">← 点击左侧条目，查看 AI 查重结果</div>
        <div v-else>
          <div class="check-head">
            <span class="check-title">{{ selected.title }}</span>
            <span :class="['verdict-tag', checkResult ? verdictClass(checkResult.verdict) : 'tag-grey']">
              {{ checkResult ? checkResult.verdict_label : (checkLoading ? '查重中…' : '—') }}
            </span>
          </div>

          <div v-if="checkLoading" class="loading">AI 查重中…</div>

          <template v-if="checkResult">
            <p class="note">{{ checkResult.note }}</p>

            <div v-if="checkResult.similar.length === 0" class="empty">未发现相似知识（相似度均低于 0.2）</div>
            <table v-else>
              <thead>
                <tr><th>相似知识标题</th><th>标题相似</th><th>内容相似</th><th>综合</th><th>判定</th></tr>
              </thead>
              <tbody>
                <tr v-for="s in checkResult.similar" :key="s.candidate_id">
                  <td class="sim-title">{{ s.candidate_title }}</td>
                  <td :style="{ color: simColor(s.title_sim) }">{{ (s.title_sim * 100).toFixed(0) }}%</td>
                  <td :style="{ color: simColor(s.content_sim) }">{{ (s.content_sim * 100).toFixed(0) }}%</td>
                  <td :style="{ color: simColor(s.combined_sim) }"><b>{{ (s.combined_sim * 100).toFixed(0) }}%</b></td>
                  <td>
                    <span :class="['label-tag', verdictClass(s.label === '疑似重复' ? 'duplicate' : s.label === '高度相关' ? 'related' : 'clean')]">
                      {{ s.label }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>

            <div class="action-hint">
              确认查重结果后，请前往
              <router-link to="/review" class="link">审核中心</router-link>
              完成最终审核。
            </div>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.prereview { padding: 20px; max-width: 70%; margin: 0; }
.page-head h2 { margin: 0 0 4px; color: var(--text-main, #1a1a1a); }
.page-head .sub { margin: 0 0 16px; color: var(--text-sub, #888); font-size: 13px; }
.err { color: #c73a3a; font-size: 13px; margin-bottom: 10px; }
.loading { color: var(--text-sub, #999); font-size: 13px; padding: 12px 0; }
.empty { color: var(--text-sub, #999); font-size: 13px; padding: 8px 0; }

.layout { display: flex; gap: 16px; align-items: flex-start; }
.left-panel { width: 320px; flex-shrink: 0; background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; overflow: hidden; }
.panel-head { padding: 10px 14px; font-size: 14px; font-weight: 600; color: var(--text-main, #1a1a1a); border-bottom: 1px solid var(--border, #eee); display: flex; align-items: center; gap: 6px; }
.count { background: var(--primary, #6B7B8B); color: #fff; border-radius: 10px; padding: 0 7px; font-size: 12px; }
.refresh-btn { margin-left: auto; padding: 2px 10px; border: 1px solid var(--border, #ccc); border-radius: 4px; background: var(--bg-card, #fff); cursor: pointer; font-size: 12px; }

.item-list { max-height: calc(100vh - 200px); overflow-y: auto; }
.item-row { padding: 10px 14px; cursor: pointer; border-bottom: 1px solid var(--border, #f0f0f0); transition: background 0.1s; }
.item-row:hover { background: var(--bg-main, #f6f6f6); }
.item-row.active { background: var(--bg-main, #f0f4ff); border-left: 3px solid var(--primary, #6B7B8B); }
.item-title { font-size: 13px; color: var(--text-main, #1a1a1a); margin-bottom: 4px; line-height: 1.4; }
.item-meta { display: flex; gap: 6px; align-items: center; }
.kb-tag { background: var(--bg-main, #eee); border-radius: 3px; padding: 1px 6px; font-size: 11px; color: var(--text-sub, #666); }
.person { font-size: 11px; color: var(--text-sub, #999); }
.time { font-size: 11px; color: var(--text-sub, #bbb); margin-left: auto; }

.right-panel { flex: 1; background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 16px 18px; min-height: 300px; }
.placeholder { color: var(--text-sub, #bbb); font-size: 13px; padding: 40px 0; text-align: center; }
.check-head { display: flex; align-items: center; gap: 12px; margin-bottom: 10px; flex-wrap: wrap; }
.check-title { font-size: 15px; font-weight: 600; color: var(--text-main, #1a1a1a); flex: 1; }
.note { font-size: 11px; color: var(--text-sub, #bbb); margin: 0 0 12px; font-style: italic; }

.verdict-tag, .label-tag { padding: 2px 10px; border-radius: 4px; font-size: 12px; white-space: nowrap; }
.tag-red { background: #fef0f0; color: #c73a3a; }
.tag-orange { background: #fff4e5; color: #c77700; }
.tag-green { background: #eef6ee; color: #3a8f3a; }
.tag-grey { background: var(--bg-main, #f0f0f0); color: var(--text-sub, #999); }

table { width: 100%; border-collapse: collapse; font-size: 13px; }
th, td { text-align: left; padding: 7px 10px; border-bottom: 1px solid var(--border, #eee); }
th { color: var(--text-sub, #888); font-weight: 600; }
td.sim-title { max-width: 300px; }

.action-hint { margin-top: 14px; font-size: 13px; color: var(--text-sub, #888); }
.link { color: var(--primary, #6B7B8B); text-decoration: none; }
</style>
