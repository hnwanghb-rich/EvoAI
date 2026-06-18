<script setup lang="ts">
// FW-08 跨线协同任务中心
// 汇总所有业务线发起的跨线整改任务，支持接收/处理/关闭流转
import { ref, onMounted, computed } from 'vue'
import axios from 'axios'
import { useAuthStore } from '@/stores/auth'

interface Task {
  id: number
  source_line: string
  source_line_label: string
  target_line: string
  target_line_label: string
  title: string
  description: string
  status: string
  status_label: string
  priority: number
  note: string
  resolve_note: string | null
  created_at: string | null
  resolved_at: string | null
  source_entry_id: number | null
  creator_name: string | null
}

const auth = useAuthStore()
const isAdmin = computed(() => auth.user?.role === 'admin')

const tasks = ref<Task[]>([])
const loading = ref(false)
const error = ref('')

// 筛选
const filterTarget = ref('')
const filterStatus = ref('')

// 处理弹窗
const resolveVisible = ref(false)
const resolveTarget = ref<Task | null>(null)
const resolveNote = ref('')
const resolving = ref(false)

const STATUS_COLOR: Record<string, string> = {
  pending: 'status-pending',
  accepted: 'status-accepted',
  resolved: 'status-resolved',
  closed: 'status-closed',
}

const PRIORITY_LABEL: Record<number, string> = { 1: '低', 2: '中', 3: '高' }
const PRIORITY_COLOR: Record<number, string> = { 1: 'pri-low', 2: 'pri-mid', 3: 'pri-high' }

async function loadTasks() {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/flywheel/crossline/tasks', {
      params: {
        target_line: filterTarget.value || undefined,
        status: filterStatus.value || undefined,
      },
    })
    tasks.value = res.data.data.items || []
  } catch {
    error.value = '加载失败'
  } finally {
    loading.value = false
  }
}

async function acceptTask(task: Task) {
  try {
    await axios.post(`/api/flywheel/crossline/${task.id}/accept`)
    await loadTasks()
  } catch (e: any) {
    alert(e?.response?.data?.detail || '操作失败')
  }
}

function openResolve(task: Task) {
  resolveTarget.value = task
  resolveNote.value = ''
  resolveVisible.value = true
}

async function submitResolve() {
  if (!resolveNote.value.trim()) { alert('请填写处理说明'); return }
  if (!resolveTarget.value) return
  resolving.value = true
  try {
    await axios.post(`/api/flywheel/crossline/${resolveTarget.value.id}/resolve`, null, {
      params: { resolve_note: resolveNote.value },
    })
    resolveVisible.value = false
    await loadTasks()
  } catch (e: any) {
    alert(e?.response?.data?.detail || '操作失败')
  } finally {
    resolving.value = false
  }
}

async function closeTask(task: Task) {
  if (!confirm(`确认关闭任务「${task.title}」？`)) return
  try {
    await axios.post(`/api/flywheel/crossline/${task.id}/close`)
    await loadTasks()
  } catch (e: any) {
    alert(e?.response?.data?.detail || '操作失败')
  }
}

// 统计
const stats = computed(() => {
  const s = { pending: 0, accepted: 0, resolved: 0, closed: 0 }
  tasks.value.forEach(t => { if (t.status in s) (s as any)[t.status]++ })
  return s
})

onMounted(loadTasks)
</script>

<template>
  <div class="crossline-page">
    <div class="page-head">
      <h2>跨线协同任务中心</h2>
      <p class="sub">客服、销售、维修三条线之间的整改任务在这里流转。每一条任务都对应一个真实的客户投诉或知识缺口，处理完后闭环回流。</p>
    </div>

    <!-- 统计栏 -->
    <div class="stat-row">
      <div :class="['stat-card', filterStatus === 'pending' ? 'active' : '']" @click="filterStatus = filterStatus === 'pending' ? '' : 'pending'; loadTasks()">
        <div class="stat-num warn">{{ stats.pending }}</div>
        <div class="stat-label">待处理</div>
      </div>
      <div :class="['stat-card', filterStatus === 'accepted' ? 'active' : '']" @click="filterStatus = filterStatus === 'accepted' ? '' : 'accepted'; loadTasks()">
        <div class="stat-num info">{{ stats.accepted }}</div>
        <div class="stat-label">处理中</div>
      </div>
      <div :class="['stat-card', filterStatus === 'resolved' ? 'active' : '']" @click="filterStatus = filterStatus === 'resolved' ? '' : 'resolved'; loadTasks()">
        <div class="stat-num ok">{{ stats.resolved }}</div>
        <div class="stat-label">待确认关闭</div>
      </div>
      <div :class="['stat-card', filterStatus === 'closed' ? 'active' : '']" @click="filterStatus = filterStatus === 'closed' ? '' : 'closed'; loadTasks()">
        <div class="stat-num muted">{{ stats.closed }}</div>
        <div class="stat-label">已关闭</div>
      </div>
    </div>

    <!-- 筛选栏（admin 才显示业务线筛选） -->
    <div class="filter-row" v-if="isAdmin">
      <select v-model="filterTarget" class="select" @change="loadTasks">
        <option value="">全部接收方</option>
        <option value="sales">销售线</option>
        <option value="tech">维修线</option>
        <option value="pdi">PDI/交车</option>
        <option value="factory">厂家/产品</option>
        <option value="service">客服线</option>
      </select>
      <button class="btn" @click="loadTasks">刷新</button>
    </div>

    <div v-if="error" class="err">{{ error }}</div>
    <div v-if="loading" class="loading">加载中…</div>
    <div v-else-if="tasks.length === 0" class="empty">
      暂无跨线任务。当客服投诉根因判定为非客服自身时，派发后会出现在这里。
    </div>
    <div v-else class="task-list">
      <div v-for="task in tasks" :key="task.id" :class="['task-card', task.status === 'closed' ? 'dimmed' : '']">
        <div class="task-head">
          <span :class="['priority-tag', PRIORITY_COLOR[task.priority]]">{{ PRIORITY_LABEL[task.priority] }}优先级</span>
          <span class="task-title">{{ task.title }}</span>
          <span :class="['status-tag', STATUS_COLOR[task.status]]">{{ task.status_label }}</span>
        </div>

        <div class="task-meta">
          <span class="line-badge src">{{ task.source_line_label }} 发起</span>
          <span class="arrow">→</span>
          <span class="line-badge dst">{{ task.target_line_label }} 处理</span>
          <span class="sep" v-if="task.creator_name">·</span>
          <span class="creator" v-if="task.creator_name">{{ task.creator_name }}</span>
          <span class="sep">·</span>
          <span class="time">{{ task.created_at ? task.created_at.slice(0, 10) : '' }}</span>
        </div>

        <div class="task-desc" v-if="task.description">{{ task.description }}</div>
        <div class="task-note" v-if="task.note">▤ 派发备注：{{ task.note }}</div>
        <div class="task-resolve" v-if="task.resolve_note">✓ 处理说明：{{ task.resolve_note }}</div>

        <div class="task-actions" v-if="task.status !== 'closed'">
          <button v-if="task.status === 'pending'" class="btn-action accept" @click="acceptTask(task)">
            接收任务
          </button>
          <button v-if="task.status === 'pending' || task.status === 'accepted'" class="btn-action resolve" @click="openResolve(task)">
            标记处理完成
          </button>
          <button v-if="task.status === 'resolved' && isAdmin" class="btn-action close" @click="closeTask(task)">
            确认关闭
          </button>
        </div>
      </div>
    </div>

    <!-- 处理完成弹窗 -->
    <div v-if="resolveVisible" class="modal-overlay" @click.self="resolveVisible = false">
      <div class="modal">
        <h3>标记处理完成</h3>
        <p class="modal-task">{{ resolveTarget?.title }}</p>
        <label>处理说明 <span class="req">*</span></label>
        <textarea v-model="resolveNote" rows="4"
          placeholder="描述具体整改措施和结果，如：已约谈相关销售顾问，重新培训承诺规范…"
          class="textarea"></textarea>
        <div class="modal-actions">
          <button class="btn" @click="resolveVisible = false">取消</button>
          <button class="btn primary" @click="submitResolve" :disabled="resolving">
            {{ resolving ? '提交中…' : '确认完成' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.crossline-page { padding: 20px; max-width: 70%; margin: 0; }
.page-head h2 { margin: 0 0 4px; color: var(--text-main, #1a1a1a); }
.page-head .sub { margin: 0 0 16px; color: var(--text-sub, #888); font-size: 13px; }
.err { color: #c73a3a; font-size: 13px; margin: 8px 0; }
.loading { color: var(--text-sub, #999); padding: 12px 0; font-size: 13px; }
.empty { color: var(--text-sub, #999); font-size: 13px; padding: 16px 0; line-height: 1.7; }

/* 统计 */
.stat-row { display: flex; gap: 12px; margin-bottom: 16px; flex-wrap: wrap; }
.stat-card { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 12px 20px; cursor: pointer; min-width: 90px; text-align: center; transition: border-color 0.15s; }
.stat-card.active, .stat-card:hover { border-color: var(--primary, #6B7B8B); }
.stat-num { font-size: 24px; font-weight: 700; }
.stat-num.warn { color: #c77700; }
.stat-num.info { color: #3a6f8f; }
.stat-num.ok { color: #3a8f3a; }
.stat-num.muted { color: var(--text-sub, #bbb); }
.stat-label { font-size: 12px; color: var(--text-sub, #888); margin-top: 2px; }

/* 筛选 */
.filter-row { display: flex; gap: 8px; margin-bottom: 14px; align-items: center; }
.select { padding: 6px 10px; border: 1px solid var(--border, #ccc); border-radius: 4px; font-size: 13px; }

/* 任务列表 */
.task-list { display: flex; flex-direction: column; gap: 10px; }
.task-card { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 14px; }
.task-card.dimmed { opacity: 0.6; }
.task-head { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; flex-wrap: wrap; }
.task-title { font-size: 14px; font-weight: 600; color: var(--text-main, #1a1a1a); flex: 1; }
.priority-tag { border-radius: 3px; padding: 1px 7px; font-size: 11px; }
.pri-high { background: #fef0f0; color: #c73a3a; }
.pri-mid { background: #fff4e5; color: #c77700; }
.pri-low { background: var(--bg-main, #f0f0f0); color: var(--text-sub, #888); }
.status-tag { border-radius: 3px; padding: 2px 8px; font-size: 12px; white-space: nowrap; }
.status-pending { background: #fff4e5; color: #c77700; }
.status-accepted { background: #e5f0ff; color: #3a6f8f; }
.status-resolved { background: #eef6ee; color: #3a8f3a; }
.status-closed { background: var(--bg-main, #f0f0f0); color: var(--text-sub, #999); }

.task-meta { display: flex; align-items: center; gap: 6px; font-size: 12px; color: var(--text-sub, #888); margin-bottom: 8px; flex-wrap: wrap; }
.line-badge { border-radius: 3px; padding: 1px 8px; font-size: 11px; }
.line-badge.src { background: #e5f0ff; color: #3a6f8f; }
.line-badge.dst { background: #fff4e5; color: #c77700; }
.arrow { color: var(--text-sub, #bbb); }
.sep { color: var(--text-sub, #ccc); }

.task-desc { font-size: 13px; color: var(--text-sub, #666); line-height: 1.6; margin-bottom: 6px; }
.task-note { font-size: 12px; color: var(--text-sub, #888); margin-bottom: 4px; }
.task-resolve { font-size: 12px; color: #3a8f3a; margin-bottom: 4px; }

.task-actions { display: flex; gap: 8px; margin-top: 10px; flex-wrap: wrap; }
.btn-action { padding: 4px 14px; border-radius: 4px; border: 1px solid; font-size: 12px; cursor: pointer; }
.btn-action.accept { border-color: #3a6f8f; color: #3a6f8f; background: none; }
.btn-action.accept:hover { background: #e5f0ff; }
.btn-action.resolve { border-color: #3a8f3a; color: #3a8f3a; background: none; }
.btn-action.resolve:hover { background: #eef6ee; }
.btn-action.close { border-color: var(--text-sub, #999); color: var(--text-sub); background: none; }
.btn-action.close:hover { background: var(--bg-main, #f0f0f0); }

/* 弹窗 */
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.35); z-index: 9999; display: flex; align-items: center; justify-content: center; }
.modal { background: var(--bg-card, #fff); border-radius: 8px; padding: 20px 24px; width: 440px; max-width: 92vw; }
.modal h3 { margin: 0 0 10px; }
.modal-task { font-size: 13px; color: var(--text-sub, #666); background: var(--bg-main, #f6f6f6); padding: 8px; border-radius: 4px; margin: 0 0 14px; }
label { display: block; font-size: 12px; color: var(--text-sub, #888); margin-bottom: 4px; }
.req { color: #c73a3a; }
.textarea { width: 100%; padding: 8px; border: 1px solid var(--border, #ccc); border-radius: 4px; font-size: 13px; resize: vertical; box-sizing: border-box; font-family: inherit; }
.modal-actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 14px; }

.btn { padding: 6px 16px; border: 1px solid var(--border, #ccc); background: var(--bg-card, #fff); border-radius: 4px; cursor: pointer; font-size: 13px; }
.btn:hover { border-color: var(--primary, #6B7B8B); color: var(--primary); }
.btn.primary { background: var(--primary, #6B7B8B); color: #fff; border-color: var(--primary); }
.btn:disabled { opacity: 0.6; cursor: not-allowed; }
</style>
