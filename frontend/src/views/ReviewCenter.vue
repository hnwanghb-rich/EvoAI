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

const pending = ref<PendingItem[]>([])
const pendingTotal = ref(0)
const selected = ref<PendingItem | null>(null)
const rejectComment = ref('')
const showReject = ref(false)

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

onMounted(() => {
  fetchPending()
  fetchHistory()
})
</script>

<template>
  <div class="review-page">
    <h2 class="page-title">审核中心</h2>

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

.review-detail {
  flex: 1; min-width: 0;
  background: var(--bg-card); border: 1px solid var(--border);
  border-radius: 8px; padding: 20px;
}
.review-detail.empty {
  display: flex; align-items: center; justify-content: center;
  color: var(--text-sub);
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

@media (max-width: 768px) {
  .review-body { flex-direction: column; }
  .review-list { width: 100%; max-height: 240px; }
}
</style>
