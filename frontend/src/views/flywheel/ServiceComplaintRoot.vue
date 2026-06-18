<script setup lang="ts">
// FW-07 客服飞轮·投诉根因回流台
// 投诉记录列表 + 提交投诉 + 派发跨线任务 + ⊙ 满意度占位
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface ComplaintItem {
  id: number
  title: string
  tags: string
  source_person: string
  useful_count: number
  created_at: string | null
  preview: string
}
interface Extracted {
  title?: string
  complaint_type?: string
  demand?: string
  appease_tactic?: string
  process?: string
  result?: string
  root_cause?: string
}

const tab = ref<'list' | 'submit' | 'satisfaction'>('list')

// 列表
const listLoading = ref(false)
const listItems = ref<ComplaintItem[]>([])
const listError = ref('')

// 提交
const submitContent = ref('')
const submitting = ref(false)
const submitResult = ref<{
  id: number; title: string; root_cause: string; root_cause_label: string;
  need_dispatch: boolean; ai_extracted: boolean; extracted: Extracted | null
} | null>(null)
const submitError = ref('')

// 派发
const dispatchVisible = ref(false)
const dispatchTarget = ref<{ id: number; title: string } | null>(null)
const dispatchLine = ref('sales')
const dispatchNote = ref('')
const dispatching = ref(false)

// 满意度
const satisData = ref<{ connected: boolean; message?: string } | null>(null)

const ROOT_LABELS: Record<string, string> = {
  service: '客服自身', sales: '销售过度承诺', tech: '维修质量', pdi: 'PDI/交车', factory: '厂家/产品',
}

async function loadList() {
  listLoading.value = true
  listError.value = ''
  try {
    const res = await axios.get('/api/flywheel/service/list')
    listItems.value = res.data.data.items || []
  } catch {
    listError.value = '加载失败'
  } finally {
    listLoading.value = false
  }
}

async function submitComplaint() {
  if (!submitContent.value.trim()) { submitError.value = '请填写投诉内容'; return }
  submitting.value = true
  submitError.value = ''
  submitResult.value = null
  try {
    const res = await axios.post('/api/flywheel/service/complaint', null, {
      params: { content: submitContent.value },
    })
    submitResult.value = res.data.data
    submitContent.value = ''
  } catch (e: any) {
    submitError.value = e?.response?.data?.detail || '提交失败'
  } finally {
    submitting.value = false
  }
}

function openDispatch(item: { id: number; title: string }) {
  dispatchTarget.value = item
  dispatchLine.value = 'sales'
  dispatchNote.value = ''
  dispatchVisible.value = true
}

async function submitDispatch() {
  if (!dispatchTarget.value) return
  dispatching.value = true
  try {
    const res = await axios.post(`/api/flywheel/service/${dispatchTarget.value.id}/dispatch`, null, {
      params: { target_line: dispatchLine.value, note: dispatchNote.value },
    })
    alert(res.data.msg)
    dispatchVisible.value = false
  } catch (e: any) {
    alert(e?.response?.data?.detail || '派发失败')
  } finally {
    dispatching.value = false
  }
}

async function loadSatisfaction() {
  try {
    const res = await axios.get('/api/flywheel/service/satisfaction')
    satisData.value = res.data.data
  } catch {
    satisData.value = { connected: false, message: '加载失败' }
  }
}

function switchTab(t: 'list' | 'submit' | 'satisfaction') {
  tab.value = t
  if (t === 'satisfaction' && !satisData.value) loadSatisfaction()
}

onMounted(loadList)
</script>

<template>
  <div class="service-page">
    <div class="page-head">
      <h2>客服飞轮 · 投诉根因回流台</h2>
      <p class="sub">把每一次投诉变成全店的改进信号。AI 自动判断根因归属，把整改任务派回对应业务线，客服是三条线的枢纽。</p>
    </div>

    <div class="tabs">
      <button :class="['tab', { active: tab === 'list' }]" @click="switchTab('list')">投诉记录</button>
      <button :class="['tab', { active: tab === 'submit' }]" @click="tab = 'submit'">新增投诉</button>
      <button :class="['tab', { active: tab === 'satisfaction' }]" @click="switchTab('satisfaction')">⊙ 满意度</button>
    </div>

    <!-- 投诉记录列表 -->
    <div v-if="tab === 'list'">
      <div v-if="listError" class="err">{{ listError }}</div>
      <div v-if="listLoading" class="loading">加载中…</div>
      <div v-else-if="listItems.length === 0" class="empty">暂无已通过的投诉处理记录。提交后审核通过将在此显示。</div>
      <div v-else class="complaint-list">
        <div v-for="item in listItems" :key="item.id" class="complaint-card">
          <div class="card-title">{{ item.title }}</div>
          <div class="card-tags" v-if="item.tags">
            <span v-for="t in item.tags.split(',')" :key="t" class="tag">{{ t }}</span>
          </div>
          <div class="card-preview">{{ item.preview }}</div>
          <div class="card-foot">
            <span class="person">{{ item.source_person || '—' }}</span>
            <span class="time">{{ item.created_at ? item.created_at.slice(0, 10) : '' }}</span>
            <button class="btn-dispatch" @click="openDispatch(item)">派发整改</button>
          </div>
        </div>
      </div>
    </div>

    <!-- 新增投诉 -->
    <div v-if="tab === 'submit'" class="submit-panel">
      <div class="form-block">
        <label>投诉处理描述 <span class="req">*</span></label>
        <p class="form-hint">描述客户投诉内容、你的处理过程和结果。AI 自动提取结构化信息并判断根因归属。</p>
        <textarea v-model="submitContent" rows="7"
          placeholder="例：客户投诉提车后一个月发现车门异响，多次返厂维修未能彻底解决。客户要求换车或全额退款。经协调，安排技术总监亲自处理，更换门板密封条后异响消除，客户接受并撤诉……"
          class="textarea"></textarea>
        <div v-if="submitError" class="err">{{ submitError }}</div>
        <button class="btn primary" @click="submitComplaint" :disabled="submitting">
          {{ submitting ? 'AI 分析中…' : '提交投诉记录' }}
        </button>
      </div>

      <div v-if="submitResult" class="result-block">
        <div class="result-head">
          ✅ 已提交审核
          <span class="ai-badge" v-if="submitResult.ai_extracted">AI 已拆解</span>
          <span class="ai-badge plain" v-else>AI 未响应，已按原文保存</span>
        </div>
        <div class="result-title">{{ submitResult.title }}</div>
        <div class="root-cause-row">
          <span class="root-label">根因归属：</span>
          <span :class="['root-tag', submitResult.root_cause !== 'service' ? 'cross' : 'self']">
            {{ submitResult.root_cause_label }}
          </span>
          <span v-if="submitResult.need_dispatch" class="dispatch-hint">
            → 根因非客服自身，建议派发整改任务
          </span>
        </div>
        <template v-if="submitResult.extracted">
          <div class="extracted-row" v-if="submitResult.extracted.complaint_type"><b>投诉类型：</b>{{ submitResult.extracted.complaint_type }}</div>
          <div class="extracted-row" v-if="submitResult.extracted.demand"><b>客户诉求：</b>{{ submitResult.extracted.demand }}</div>
          <div class="extracted-row" v-if="submitResult.extracted.appease_tactic"><b>安抚话术：</b>{{ submitResult.extracted.appease_tactic }}</div>
          <div class="extracted-row" v-if="submitResult.extracted.result"><b>处理结果：</b>{{ submitResult.extracted.result }}</div>
        </template>
        <div class="dispatch-btn-row" v-if="submitResult.need_dispatch">
          <button class="btn primary" @click="openDispatch({ id: submitResult.id, title: submitResult.title })">
            派发整改任务 →
          </button>
        </div>
      </div>
    </div>

    <!-- ⊙ 满意度 -->
    <div v-if="tab === 'satisfaction'">
      <div v-if="!satisData" class="loading">加载中…</div>
      <div v-else-if="!satisData.connected" class="plugin-tip">
        <div class="plugin-icon">⊙</div>
        <div class="plugin-msg">{{ satisData.message }}</div>
      </div>
    </div>

    <!-- 派发弹窗 -->
    <div v-if="dispatchVisible" class="modal-overlay" @click.self="dispatchVisible = false">
      <div class="modal">
        <h3>派发跨线整改任务</h3>
        <p class="modal-title">{{ dispatchTarget?.title }}</p>
        <label>整改目标业务线</label>
        <select v-model="dispatchLine" class="select">
          <option value="sales">销售线（过度承诺）</option>
          <option value="tech">维修线（维修质量）</option>
          <option value="pdi">PDI/交车</option>
          <option value="factory">厂家/产品问题</option>
        </select>
        <label>备注（可选）</label>
        <textarea v-model="dispatchNote" rows="3" placeholder="具体整改要求或背景…" class="textarea sm"></textarea>
        <p class="modal-note">FW-08 跨线协同任务中心上线后，该任务将出现在对应业务线的任务列表中。</p>
        <div class="modal-actions">
          <button class="btn" @click="dispatchVisible = false">取消</button>
          <button class="btn primary" @click="submitDispatch" :disabled="dispatching">
            {{ dispatching ? '派发中…' : '确认派发' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.service-page { padding: 20px; max-width: 70%; margin: 0; }
.page-head h2 { margin: 0 0 4px; color: var(--text-main, #1a1a1a); }
.page-head .sub { margin: 0 0 16px; color: var(--text-sub, #888); font-size: 13px; }
.err { color: #c73a3a; font-size: 13px; margin: 8px 0; }
.loading { color: var(--text-sub, #999); padding: 12px 0; font-size: 13px; }
.empty { color: var(--text-sub, #999); font-size: 13px; padding: 16px 0; }

.tabs { display: flex; margin-bottom: 16px; border-bottom: 2px solid var(--border, #e5e5e5); }
.tab { padding: 8px 20px; border: none; background: none; cursor: pointer; font-size: 14px; color: var(--text-sub, #888); border-bottom: 2px solid transparent; margin-bottom: -2px; }
.tab.active { color: var(--primary, #6B7B8B); border-bottom-color: var(--primary); font-weight: 600; }

/* 列表 */
.complaint-list { display: flex; flex-direction: column; gap: 10px; }
.complaint-card { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 14px; }
.card-title { font-size: 14px; font-weight: 600; color: var(--text-main, #1a1a1a); margin-bottom: 6px; }
.card-tags { display: flex; gap: 4px; flex-wrap: wrap; margin-bottom: 8px; }
.tag { background: var(--bg-main, #f0f0f0); border-radius: 3px; padding: 1px 7px; font-size: 11px; color: var(--text-sub, #666); }
.card-preview { font-size: 12px; color: var(--text-sub, #888); line-height: 1.6; margin-bottom: 8px; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
.card-foot { display: flex; align-items: center; gap: 10px; font-size: 12px; color: var(--text-sub, #999); }
.time { margin-left: auto; }
.btn-dispatch { padding: 3px 10px; border: 1px solid var(--primary, #6B7B8B); color: var(--primary); background: none; border-radius: 4px; cursor: pointer; font-size: 12px; }

/* 提交 */
.submit-panel { max-width: 640px; }
.form-block { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 18px; margin-bottom: 14px; }
label { display: block; font-size: 12px; color: var(--text-sub, #888); margin-bottom: 4px; }
.req { color: #c73a3a; }
.form-hint { font-size: 12px; color: var(--text-sub, #bbb); margin: 0 0 8px; }
.textarea { width: 100%; padding: 8px; border: 1px solid var(--border, #ccc); border-radius: 4px; font-size: 13px; resize: vertical; box-sizing: border-box; font-family: inherit; }

.result-block { background: #f0f7f0; border: 1px solid #b8dbb8; border-radius: 8px; padding: 14px; }
.result-head { font-size: 13px; font-weight: 600; color: #3a8f3a; margin-bottom: 10px; display: flex; gap: 8px; align-items: center; }
.ai-badge { background: #3a8f3a; color: #fff; border-radius: 3px; padding: 1px 8px; font-size: 11px; font-weight: normal; }
.ai-badge.plain { background: var(--text-sub, #999); }
.result-title { font-size: 14px; font-weight: 600; color: var(--text-main, #1a1a1a); margin-bottom: 10px; }
.root-cause-row { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; flex-wrap: wrap; }
.root-label { font-size: 13px; color: var(--text-sub, #666); }
.root-tag { padding: 2px 10px; border-radius: 4px; font-size: 12px; }
.root-tag.self { background: #eef6ee; color: #3a8f3a; }
.root-tag.cross { background: #fff4e5; color: #c77700; }
.dispatch-hint { font-size: 12px; color: #c77700; }
.extracted-row { font-size: 13px; color: var(--text-main, #333); margin-bottom: 5px; }
.dispatch-btn-row { margin-top: 12px; }

/* ⊙ */
.plugin-tip { background: var(--bg-card, #fff); border: 2px dashed var(--border, #ccc); border-radius: 8px; padding: 32px; text-align: center; }
.plugin-icon { font-size: 32px; margin-bottom: 12px; }
.plugin-msg { font-size: 13px; color: var(--text-sub, #888); line-height: 1.7; }

/* 弹窗 */
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.35); z-index: 9999; display: flex; align-items: center; justify-content: center; }
.modal { background: var(--bg-card, #fff); border-radius: 8px; padding: 20px 24px; width: 420px; max-width: 92vw; }
.modal h3 { margin: 0 0 10px; }
.modal-title { font-size: 13px; color: var(--text-sub, #666); background: var(--bg-main, #f6f6f6); padding: 8px; border-radius: 4px; margin: 0 0 14px; }
.select { width: 100%; padding: 6px; border: 1px solid var(--border, #ccc); border-radius: 4px; font-size: 13px; margin-bottom: 10px; }
.textarea.sm { height: 70px; }
.modal-note { font-size: 11px; color: var(--text-sub, #bbb); margin: 8px 0 0; font-style: italic; }
.modal-actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 14px; }

.btn { padding: 6px 16px; border: 1px solid var(--border, #ccc); background: var(--bg-card, #fff); border-radius: 4px; cursor: pointer; font-size: 13px; margin-top: 10px; }
.btn:hover { border-color: var(--primary, #6B7B8B); color: var(--primary); }
.btn.primary { background: var(--primary, #6B7B8B); color: #fff; border-color: var(--primary); }
.btn:disabled { opacity: 0.6; cursor: not-allowed; }
</style>
