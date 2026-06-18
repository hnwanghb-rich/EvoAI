<script setup lang="ts">
// FW-04 知识时效·保质期中心 —— 列表 + 设置保质期 + 续期 + 归档
// 降权逻辑（检索排序）单独确认后再改，本页不动 chat.py
import { ref, onMounted, computed } from 'vue'
import axios from 'axios'

interface ExpiryItem {
  id: number
  title: string
  knowledge_base: string
  status: string
  expire_at: string | null
  last_reviewed_at: string | null
  source_person: string
  version: number
  updated_at: string | null
  expiry_status: 'expired' | 'soon' | 'ok'
  days_left: number | null
}

const loading = ref(false)
const items = ref<ExpiryItem[]>([])
const scope = ref<'all' | 'expired' | 'soon' | 'ok'>('all')
const totalExpired = ref(0)
const totalSoon = ref(0)
const error = ref('')

// 设置保质期弹窗
const setVisible = ref(false)
const setTarget = ref<ExpiryItem | null>(null)
const setDays = ref(180)
const setMode = ref<'set' | 'renew'>('set')

const KB_LABEL: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/flywheel/expiry/list', { params: { scope: scope.value } })
    items.value = res.data.data.items || []
    totalExpired.value = res.data.data.total_expired
    totalSoon.value = res.data.data.total_soon
  } catch {
    error.value = '加载失败，请确认已用管理员账号登录'
  } finally {
    loading.value = false
  }
}

function openSet(item: ExpiryItem, mode: 'set' | 'renew') {
  setTarget.value = item
  setMode.value = mode
  setDays.value = 180
  setVisible.value = true
}

async function submitSet() {
  if (!setTarget.value) return
  const url = setMode.value === 'renew'
    ? `/api/flywheel/expiry/${setTarget.value.id}/renew`
    : `/api/flywheel/expiry/${setTarget.value.id}/set`
  try {
    await axios.post(url, null, { params: { days: setDays.value } })
    setVisible.value = false
    await load()
  } catch (e: any) {
    alert(e?.response?.data?.detail || '操作失败')
  }
}

async function archive(item: ExpiryItem) {
  if (!confirm(`确认归档"${item.title}"？归档后将从知识库检索中移除。`)) return
  try {
    await axios.post(`/api/flywheel/expiry/${item.id}/archive`)
    await load()
  } catch (e: any) {
    alert(e?.response?.data?.detail || '归档失败')
  }
}

function expiryClass(item: ExpiryItem) {
  if (item.expiry_status === 'expired') return 'expired'
  if (item.expiry_status === 'soon') return 'soon'
  return ''
}

function expiryLabel(item: ExpiryItem) {
  if (!item.expire_at) return '未设置'
  if (item.expiry_status === 'expired') return `已过期 ${Math.abs(item.days_left ?? 0)} 天`
  if (item.expiry_status === 'soon') return `${item.days_left} 天后到期`
  return `${item.days_left} 天后到期`
}

onMounted(load)
</script>

<template>
  <div class="expiry-page">
    <div class="page-head">
      <h2>知识时效中心</h2>
      <p class="sub">管理知识的"保质期"，防止过期话术和政策误导一线。降权检索功能待单独确认后启用。</p>
    </div>

    <!-- 统计栏 -->
    <div class="stat-row">
      <div class="stat-card" :class="{ active: scope === 'all' }" @click="scope = 'all'; load()">
        <div class="stat-val">{{ items.length }}</div>
        <div class="stat-label">已设保质期</div>
      </div>
      <div class="stat-card red" :class="{ active: scope === 'expired' }" @click="scope = 'expired'; load()">
        <div class="stat-val">{{ totalExpired }}</div>
        <div class="stat-label">已过期</div>
      </div>
      <div class="stat-card orange" :class="{ active: scope === 'soon' }" @click="scope = 'soon'; load()">
        <div class="stat-val">{{ totalSoon }}</div>
        <div class="stat-label">7天内到期</div>
      </div>
      <div class="stat-card green" :class="{ active: scope === 'ok' }" @click="scope = 'ok'; load()">
        <div class="stat-val">{{ items.filter(x => x.expiry_status === 'ok').length }}</div>
        <div class="stat-label">未到期</div>
      </div>
    </div>

    <div v-if="error" class="err">{{ error }}</div>

    <div class="block">
      <div class="block-head">
        <span>保质期列表</span>
        <button class="refresh-btn" @click="load" :disabled="loading">{{ loading ? '…' : '刷新' }}</button>
      </div>

      <div v-if="loading && items.length === 0" class="loading">加载中…</div>
      <div v-else-if="items.length === 0" class="empty">
        暂无设置保质期的知识。<br>
        <span class="hint">在列表中点击"设置保质期"为知识添加到期提醒。</span>
      </div>

      <table v-else>
        <thead>
          <tr>
            <th>知识标题</th>
            <th>知识库</th>
            <th>版本</th>
            <th>到期状态</th>
            <th>上次复审</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.id" :class="expiryClass(item)">
            <td class="title-cell">{{ item.title }}</td>
            <td>{{ KB_LABEL[item.knowledge_base] || item.knowledge_base }}</td>
            <td class="ver">v{{ item.version }}</td>
            <td>
              <span :class="['expiry-tag', item.expiry_status]">{{ expiryLabel(item) }}</span>
            </td>
            <td class="time">{{ item.last_reviewed_at ? item.last_reviewed_at.slice(0, 10) : '—' }}</td>
            <td class="actions">
              <button class="btn" @click="openSet(item, 'renew')">续期复审</button>
              <button class="btn danger" @click="archive(item)">归档</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- 设置保质期弹窗 -->
    <div v-if="setVisible" class="modal-overlay" @click.self="setVisible = false">
      <div class="modal">
        <h3>{{ setMode === 'renew' ? '续期复审' : '设置保质期' }}</h3>
        <p class="modal-title">{{ setTarget?.title }}</p>
        <label>保质期天数</label>
        <div class="days-presets">
          <button v-for="d in [30, 90, 180, 365]" :key="d"
            :class="['preset', { active: setDays === d }]"
            @click="setDays = d">{{ d }}天</button>
        </div>
        <input type="number" v-model.number="setDays" min="1" max="3650" class="days-input" />
        <p class="modal-note" v-if="setMode === 'renew'">续期将使知识版本 +1，旧版本保留可回溯。</p>
        <div class="modal-actions">
          <button class="btn" @click="setVisible = false">取消</button>
          <button class="btn primary" @click="submitSet">确认</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.expiry-page { padding: 20px; max-width: 70%; margin: 0; }
.page-head h2 { margin: 0 0 4px; color: var(--text-main, #1a1a1a); }
.page-head .sub { margin: 0 0 16px; color: var(--text-sub, #888); font-size: 13px; }
.err { color: #c73a3a; font-size: 13px; margin-bottom: 10px; }
.loading { color: var(--text-sub, #999); padding: 12px 0; font-size: 13px; }
.empty { color: var(--text-sub, #999); font-size: 13px; padding: 16px 0; }
.hint { font-size: 12px; color: var(--text-sub, #bbb); }

/* 统计栏 */
.stat-row { display: flex; gap: 12px; margin-bottom: 16px; flex-wrap: wrap; }
.stat-card { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 14px 20px; cursor: pointer; transition: border-color 0.15s; min-width: 100px; }
.stat-card:hover, .stat-card.active { border-color: var(--primary, #6B7B8B); }
.stat-val { font-size: 30px; font-weight: 700; color: var(--primary, #6B7B8B); line-height: 1; }
.stat-card.red .stat-val { color: #c73a3a; }
.stat-card.orange .stat-val { color: #c77700; }
.stat-card.green .stat-val { color: #3a8f3a; }
.stat-label { font-size: 12px; color: var(--text-sub, #888); margin-top: 4px; }

/* 表格 */
.block { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 16px; }
.block-head { display: flex; align-items: center; gap: 10px; font-size: 14px; font-weight: 600; color: var(--text-main); margin-bottom: 12px; }
.refresh-btn { margin-left: auto; padding: 3px 12px; border: 1px solid var(--border, #ccc); border-radius: 4px; background: var(--bg-card, #fff); cursor: pointer; font-size: 12px; }

table { width: 100%; border-collapse: collapse; font-size: 13px; }
th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid var(--border, #eee); }
th { color: var(--text-sub, #888); font-weight: 600; }
td.title-cell { max-width: 360px; }
td.ver { color: var(--text-sub, #999); font-size: 12px; }
td.time { color: var(--text-sub, #999); font-size: 12px; white-space: nowrap; }
td.actions { white-space: nowrap; display: flex; gap: 6px; }

tr.expired td { background: #fff8f8; }
tr.soon td { background: #fffbf0; }

.expiry-tag { padding: 2px 8px; border-radius: 4px; font-size: 12px; white-space: nowrap; }
.expiry-tag.expired { background: #fef0f0; color: #c73a3a; }
.expiry-tag.soon { background: #fff4e5; color: #c77700; }
.expiry-tag.ok { background: #eef6ee; color: #3a8f3a; }

.btn { padding: 4px 10px; border: 1px solid var(--border, #ccc); background: var(--bg-card, #fff); border-radius: 4px; cursor: pointer; font-size: 12px; }
.btn:hover { border-color: var(--primary, #6B7B8B); color: var(--primary); }
.btn.primary { background: var(--primary, #6B7B8B); color: #fff; border-color: var(--primary); }
.btn.danger { color: #c73a3a; border-color: #e8b0b0; }
.btn.danger:hover { background: #fef0f0; }

/* 弹窗 */
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.35); z-index: 9999; display: flex; align-items: center; justify-content: center; }
.modal { background: var(--bg-card, #fff); border-radius: 8px; padding: 20px 24px; width: 380px; max-width: 92vw; }
.modal h3 { margin: 0 0 10px; }
.modal-title { font-size: 13px; color: var(--text-sub, #666); background: var(--bg-main, #f6f6f6); padding: 8px; border-radius: 4px; margin: 0 0 14px; }
.modal label { display: block; font-size: 12px; color: var(--text-sub, #888); margin-bottom: 6px; }
.days-presets { display: flex; gap: 6px; margin-bottom: 8px; }
.preset { padding: 4px 12px; border: 1px solid var(--border, #ccc); border-radius: 4px; background: var(--bg-card, #fff); cursor: pointer; font-size: 12px; }
.preset.active { border-color: var(--primary, #6B7B8B); color: var(--primary); background: var(--bg-main, #f0f4ff); }
.days-input { width: 100%; padding: 6px; border: 1px solid var(--border, #ccc); border-radius: 4px; font-size: 13px; box-sizing: border-box; }
.modal-note { font-size: 12px; color: var(--text-sub, #999); margin: 8px 0 0; }
.modal-actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 16px; }
</style>
