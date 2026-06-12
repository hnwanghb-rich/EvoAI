<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface PendingItem {
  id: number; title: string; content: string; knowledge_base: string
  source_type: string; source_person: string | null; source_dept: string | null
  tags: string | null; created_at: string | null
}
interface HistoryItem {
  id: number; title: string; status: string; audit_comment: string | null
  source_person: string | null; updated_at: string | null
}
interface QuestionDraft {
  question_type: string; question_content: string; options: Record<string, string>
  answer: string; explanation: string; difficulty_level: number
  target_position?: string
}

const pending = ref<PendingItem[]>([])
const pendingTotal = ref(0)
const selected = ref<PendingItem | null>(null)
const rejectComment = ref('')
const showReject = ref(false)

// AI拆分试题 & 试题入库
const drafts = ref<QuestionDraft[]>([])
const aiSplitting = ref(false)
const importingQuestions = ref(false)
const showDrafts = ref(false)
const aiSplitMsg = ref('')
const splittingEntryId = ref(0)

// toast 通知（不依赖 selected，确保提示始终可见）
const toastVisible = ref(false)
const toastMsg = ref('')
const toastType = ref<'success' | 'error'>('success')
let toastTimer: ReturnType<typeof setTimeout> | null = null
function showToast(msg: string, type: 'success' | 'error' = 'success') {
  toastMsg.value = msg
  toastType.value = type
  toastVisible.value = true
  if (toastTimer) clearTimeout(toastTimer)
  toastTimer = setTimeout(() => { toastVisible.value = false }, 4000)
}

const history = ref<HistoryItem[]>([])
const historyTotal = ref(0)
const tab = ref<'pending' | 'history'>('pending')

const kbLabel: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }
const statusLabel: Record<string, string> = { approved: '已通过', rejected: '已驳回' }

async function fetchPending() {
  const { data } = await axios.get('/api/review/pending')
  pending.value = data.data.items
  pendingTotal.value = data.data.total
  if (!selected.value && pending.value.length > 0) {
    selected.value = pending.value[0]
  }
}

async function fetchHistory() {
  const { data } = await axios.get('/api/review/history')
  history.value = data.data.items
  historyTotal.value = data.data.total
}

function selectItem(item: PendingItem) {
  selected.value = item
  rejectComment.value = ''
  showReject.value = false
  drafts.value = []
  showDrafts.value = false
  aiSplitMsg.value = ''
  splittingEntryId.value = 0
}

async function approve(id: number) {
  await axios.post(`/api/review/${id}/approve`)
  pending.value = pending.value.filter(i => i.id !== id)
  if (selected.value?.id === id) {
    selected.value = pending.value[0] || null
  }
}

async function reject(id: number) {
  if (!rejectComment.value.trim()) return
  await axios.post(`/api/review/${id}/reject`, {
    audit_comment: rejectComment.value,
  })
  pending.value = pending.value.filter(i => i.id !== id)
  if (selected.value?.id === id) {
    selected.value = pending.value[0] || null
  }
  showReject.value = false
  rejectComment.value = ''
}

async function aiSplitQuestions(id: number) {
  aiSplitting.value = true
  aiSplitMsg.value = ''
  drafts.value = []
  showDrafts.value = false
  splittingEntryId.value = id
  try {
    const { data } = await axios.post(`/api/review/${id}/ai-split-questions`)
    drafts.value = data.data?.drafts || []
    aiSplitMsg.value = data.msg || `AI已生成 ${drafts.value.length} 道题目草稿`
    showDrafts.value = true
  } catch (e: any) {
    aiSplitMsg.value = e?.response?.data?.msg || 'AI拆分失败，请重试'
  } finally {
    aiSplitting.value = false
  }
}

async function batchImportQuestions() {
  if (drafts.value.length === 0) return
  importingQuestions.value = true
  try {
    // 1. 批量入库试题
    const { data } = await axios.post('/api/questions/batch-import', {
      questions: drafts.value,
    })
    const imported = data.data?.inserted || drafts.value.length

    // 2. 同时审核通过该条知识（试题入库 + 知识入库）
    if (splittingEntryId.value > 0) {
      await axios.post(`/api/review/${splittingEntryId.value}/approve`)
      pending.value = pending.value.filter(i => i.id !== splittingEntryId.value)
      if (selected.value?.id === splittingEntryId.value) {
        selected.value = pending.value[0] || null
      }
    }

    aiSplitMsg.value = `已入库 ${imported} 道试题，知识条目已审核通过`
    showToast(`已入库 ${imported} 道试题，知识条目已审核通过`, 'success')
    drafts.value = []
    showDrafts.value = false
    splittingEntryId.value = 0
  } catch (e: any) {
    aiSplitMsg.value = e?.response?.data?.msg || '入库失败，请重试'
    showToast(e?.response?.data?.msg || '入库失败，请重试', 'error')
  } finally {
    importingQuestions.value = false
  }
}

onMounted(() => {
  fetchPending()
  fetchHistory()
})
</script>

<template>
  <div class="review-page">
    <h2 class="page-title">审核中心</h2>

    <!-- Toast 通知 -->
    <transition name="toast-fade">
      <div v-if="toastVisible" :class="['toast-bar', toastType]">
        <span>{{ toastMsg }}</span>
        <button class="toast-close" @click="toastVisible = false">✕</button>
      </div>
    </transition>

    <!-- Tab 切换 -->
    <div class="review-tabs">
      <button :class="{ active: tab === 'pending' }" @click="tab = 'pending'">
        待审核 ({{ pendingTotal }})
      </button>
      <button :class="{ active: tab === 'history' }" @click="tab = 'history'">
        审核历史 ({{ historyTotal }})
      </button>
    </div>

    <!-- 待审核 -->
    <div class="review-body" v-if="tab === 'pending'">
      <!-- 左侧列表 -->
      <div class="review-list">
        <div
          v-for="item in pending" :key="item.id"
          class="review-list-item"
          :class="{ active: selected?.id === item.id }"
          @click="selectItem(item)"
        >
          <div class="rli-title">{{ item.title }}</div>
          <div class="rli-meta">
            <span>{{ item.source_person || '未知' }}</span>
            <span>{{ kbLabel[item.knowledge_base] || item.knowledge_base }}</span>
          </div>
        </div>
        <div v-if="pending.length === 0" class="empty">暂无待审核内容</div>
      </div>

      <!-- 右侧详情 + 操作 -->
      <div class="review-detail" v-if="selected">
        <div class="rd-header">
          <h3>{{ selected.title }}</h3>
          <span class="rd-badge">{{ kbLabel[selected.knowledge_base] || selected.knowledge_base }}</span>
        </div>
        <div class="rd-meta">
          <span>提交人：{{ selected.source_person || '未知' }}</span>
          <span v-if="selected.source_dept">部门：{{ selected.source_dept }}</span>
          <span v-if="selected.tags">标签：{{ selected.tags }}</span>
          <span v-if="selected.created_at">{{ selected.created_at?.slice(0, 10) }}</span>
        </div>
        <div class="rd-content">
          <pre>{{ selected.content }}</pre>
        </div>
        <div class="rd-actions">
          <button class="btn btn-sm" style="background:var(--success)" @click="approve(selected.id)">
            ✓ 审核通过
          </button>
          <button class="btn btn-sm btn-danger" @click="showReject = true">
            ✗ 驳回
          </button>
          <button
            class="btn btn-sm btn-ai"
            :disabled="aiSplitting"
            @click="aiSplitQuestions(selected.id)"
          >
            {{ aiSplitting ? '⏳ AI拆分中...' : '🤖 AI拆分试题' }}
          </button>
          <button
            class="btn btn-sm btn-import"
            :disabled="drafts.length === 0 || importingQuestions"
            @click="batchImportQuestions"
          >
            {{ importingQuestions ? '⏳ 入库中...' : '📥 试题入库' }}
          </button>
        </div>
        <div v-if="showReject" class="rd-reject">
          <textarea
            v-model="rejectComment"
            placeholder="请输入驳回原因（必填）"
            class="form-input"
            style="width:100%;min-height:80px"
          ></textarea>
          <div style="margin-top:8px;display:flex;gap:8px">
            <button class="btn btn-sm btn-danger" :disabled="!rejectComment.trim()" @click="reject(selected.id)">
              确认驳回
            </button>
            <button class="btn btn-sm btn-outline" @click="showReject = false">取消</button>
          </div>
        </div>

        <!-- AI拆分试题草稿 -->
        <div v-if="aiSplitMsg" class="rd-ai-msg">{{ aiSplitMsg }}</div>
        <div v-if="showDrafts && drafts.length > 0" class="rd-drafts">
          <h4 style="margin:0 0 8px 0;color:var(--text-main)">📋 AI生成的题目草稿（{{ drafts.length }}道）</h4>
          <div
            v-for="(d, di) in drafts" :key="di"
            class="rd-draft-item"
          >
            <div class="draft-header">
              <strong>第{{ di + 1 }}题</strong>
              <span class="draft-badge">{{ d.question_type }}</span>
              <span class="draft-badge">难度: {{ d.difficulty_level }}</span>
              <span v-if="d.target_position" class="draft-badge">岗位: {{ d.target_position }}</span>
            </div>
            <div class="draft-q">{{ d.question_content }}</div>
            <div class="draft-opts" v-if="d.options">
              <span v-for="(val, key) in d.options" :key="key" class="draft-opt">
                <strong>{{ key }}</strong>: {{ val }}
              </span>
            </div>
            <div class="draft-a">
              ✅ 答案：<strong>{{ d.answer }}</strong>
              <span v-if="d.explanation"> | 💡 {{ d.explanation }}</span>
            </div>
          </div>
        </div>
      </div>
      <div class="review-detail empty" v-else>请选择左侧待审核条目</div>
    </div>

    <!-- 历史 -->
    <div class="review-history" v-if="tab === 'history'">
      <table class="rh-table">
        <thead>
          <tr>
            <th>ID</th><th>标题</th><th>提交人</th><th>审核结果</th><th>原因/备注</th><th>时间</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="h in history" :key="h.id">
            <td>{{ h.id }}</td>
            <td>{{ h.title }}</td>
            <td>{{ h.source_person || '-' }}</td>
            <td>
              <span :style="h.status === 'approved' ? 'color:var(--success)' : 'color:var(--danger)'">
                {{ statusLabel[h.status] || h.status }}
              </span>
            </td>
            <td>{{ h.audit_comment || '-' }}</td>
            <td>{{ h.updated_at?.slice(0, 10) || '-' }}</td>
          </tr>
          <tr v-if="history.length === 0">
            <td colspan="6" style="text-align:center;padding:40px;color:var(--text-sub)">暂无审核历史</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<style scoped>
.review-page { max-width: 1200px; margin: 0 auto; }
.page-title { font-size: 20px; margin-bottom: 16px; color: var(--text-main); }

/* Toast 通知条 */
.toast-bar {
  display: flex; align-items: center; justify-content: space-between;
  padding: 12px 16px; border-radius: 8px; margin-bottom: 16px;
  font-size: 14px; font-weight: 500;
}
.toast-bar.success { background: #d1fae5; color: #065f46; border: 1px solid #6ee7b7; }
.toast-bar.error   { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; }
.toast-close { background: none; border: none; cursor: pointer; font-size: 16px; margin-left: 16px; opacity: 0.5; }
.toast-close:hover { opacity: 1; }
.toast-fade-enter-active, .toast-fade-leave-active { transition: all 0.3s ease; }
.toast-fade-enter-from, .toast-fade-leave-to { opacity: 0; transform: translateY(-8px); }

.review-tabs { display: flex; gap: 0; margin-bottom: 16px; }
.review-tabs button {
  padding: 8px 20px; border: 1px solid var(--border); background: var(--bg-card);
  font-size: 14px; cursor: pointer; color: var(--text-sub);
}
.review-tabs button:first-child { border-radius: 6px 0 0 6px; }
.review-tabs button:last-child { border-radius: 0 6px 6px 0; }
.review-tabs button.active { background: var(--primary); color: #fff; border-color: var(--primary); }

/* 左右分栏 */
.review-body { display: flex; gap: 16px; }
.review-list {
  width: 320px; flex-shrink: 0;
  background: var(--bg-card); border: 1px solid var(--border);
  border-radius: 8px; max-height: calc(100vh - 260px); overflow-y: auto;
}
.review-list-item {
  padding: 12px 16px; border-bottom: 1px solid var(--border); cursor: pointer;
  transition: background 0.15s;
}
.review-list-item:hover { background: var(--bg-main); }
.review-list-item.active { background: var(--bg-main); border-left: 3px solid var(--primary); }
.rli-title { font-size: 14px; font-weight: 600; color: var(--text-main); margin-bottom: 4px; }
.rli-meta { font-size: 12px; color: var(--text-sub); display: flex; gap: 12px; }

.empty { font-size: 14px; color: var(--text-sub); text-align: center; padding: 40px 0; }

.review-detail {
  flex: 1; min-width: 0;
  background: var(--bg-card); border: 1px solid var(--border);
  border-radius: 8px; padding: 20px;
}
.review-detail.empty {
  display: flex; align-items: center; justify-content: center;
  color: var(--text-sub); font-size: 14px;
}
.rd-header { display: flex; gap: 12px; align-items: center; margin-bottom: 12px; }
.rd-header h3 { font-size: 18px; margin: 0; color: var(--text-main); }
.rd-badge {
  padding: 2px 10px; border-radius: 10px; font-size: 12px;
  background: var(--primary); color: #fff;
}
.rd-meta { display: flex; flex-wrap: wrap; gap: 16px; font-size: 13px; color: var(--text-sub); margin-bottom: 16px; }
.rd-content pre {
  white-space: pre-wrap; word-break: break-word;
  font-family: inherit; font-size: 14px; line-height: 1.7;
  color: var(--text-main); background: var(--bg-main);
  padding: 16px; border-radius: 6px; margin: 0;
}
.rd-actions { display: flex; gap: 10px; margin-top: 16px; }
.rd-reject { margin-top: 12px; padding: 12px; background: var(--bg-main); border-radius: 8px; }

/* 历史表格 */
.rh-table {
  width: 100%; border-collapse: collapse; font-size: 13px;
  background: var(--bg-card); border-radius: 8px; overflow: hidden;
}
.rh-table th, .rh-table td {
  padding: 10px 12px; text-align: left; border-bottom: 1px solid var(--border);
}
.rh-table th { background: var(--bg-main); font-weight: 600; color: var(--text-sub); font-size: 12px; }

/* AI拆分 & 入库按钮 */
.btn-ai { background: #7c3aed; color: #fff; border: none; }
.btn-ai:hover:not(:disabled) { background: #6d28d9; }
.btn-ai:disabled { opacity: 0.6; cursor: not-allowed; }
.btn-import { background: #059669; color: #fff; border: none; }
.btn-import:hover:not(:disabled) { background: #047857; }
.btn-import:disabled { opacity: 0.5; cursor: not-allowed; }

/* AI拆分消息 */
.rd-ai-msg {
  margin-top: 12px; padding: 8px 12px; border-radius: 6px;
  background: var(--bg-main); color: var(--primary); font-size: 13px;
}

/* 题目草稿列表 */
.rd-drafts {
  margin-top: 12px; padding: 12px;
  background: var(--bg-main); border-radius: 8px;
  max-height: 400px; overflow-y: auto;
}
.rd-draft-item {
  padding: 10px; margin-bottom: 8px;
  background: var(--bg-card); border: 1px solid var(--border);
  border-radius: 6px;
}
.rd-draft-item:last-child { margin-bottom: 0; }
.draft-header {
  display: flex; align-items: center; gap: 8px;
  margin-bottom: 6px; font-size: 13px;
}
.draft-badge {
  padding: 1px 6px; border-radius: 4px; font-size: 11px;
  background: var(--primary); color: #fff;
}
.draft-q { font-size: 14px; color: var(--text-main); margin-bottom: 6px; }
.draft-opts { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 6px; }
.draft-opt { font-size: 12px; color: var(--text-sub); background: var(--bg-main); padding: 2px 8px; border-radius: 4px; }
.draft-a { font-size: 12px; color: var(--success); }

@media (max-width: 768px) {
  .review-body { flex-direction: column; }
  .review-list { width: 100%; max-height: 240px; }
}
</style>
