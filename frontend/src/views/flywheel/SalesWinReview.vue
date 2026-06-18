<script setup lang="ts">
// FW-05 销售飞轮·赢单复盘台
// 话术沉淀 + 话术墙 + ⊙ 成交转化占位
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface WallItem {
  id: number
  title: string
  content_preview: string
  car_brand: string
  car_model: string
  tags: string
  source_person: string
  useful_count: number
  view_count: number
  created_at: string | null
}
interface Extracted {
  title?: string
  objection?: string
  tactic?: string
  car_model?: string
  competitor?: string
  summary?: string
}

const tab = ref<'submit' | 'wall' | 'conversion'>('wall')

// 提交表单
const submitForm = ref({ content: '', car_brand: '', car_model: '' })
const submitting = ref(false)
const submitResult = ref<{ id: number; title: string; ai_extracted: boolean; extracted: Extracted | null } | null>(null)
const submitError = ref('')

// 话术墙
const wallLoading = ref(false)
const wallItems = ref<WallItem[]>([])
const wallFilter = ref({ car_brand: '', car_model: '' })
const wallError = ref('')

// 成交转化
const convLoading = ref(false)
const convData = ref<{ connected: boolean; message?: string; items?: any[]; total_deals?: number } | null>(null)

async function submitReview() {
  if (!submitForm.value.content.trim()) { submitError.value = '请填写复盘内容'; return }
  submitting.value = true
  submitError.value = ''
  submitResult.value = null
  try {
    const res = await axios.post('/api/flywheel/sales/win-review', null, {
      params: {
        content: submitForm.value.content,
        car_brand: submitForm.value.car_brand,
        car_model: submitForm.value.car_model,
      },
    })
    submitResult.value = res.data.data
    submitForm.value = { content: '', car_brand: '', car_model: '' }
  } catch (e: any) {
    submitError.value = e?.response?.data?.detail || '提交失败'
  } finally {
    submitting.value = false
  }
}

async function loadWall() {
  wallLoading.value = true
  wallError.value = ''
  try {
    const res = await axios.get('/api/flywheel/sales/wall', {
      params: { car_brand: wallFilter.value.car_brand, car_model: wallFilter.value.car_model },
    })
    wallItems.value = res.data.data.items || []
  } catch {
    wallError.value = '加载失败'
  } finally {
    wallLoading.value = false
  }
}

async function loadConversion() {
  convLoading.value = true
  try {
    const res = await axios.get('/api/flywheel/sales/conversion')
    convData.value = res.data.data
  } catch {
    convData.value = { connected: false, message: '加载失败' }
  } finally {
    convLoading.value = false
  }
}

function switchTab(t: 'submit' | 'wall' | 'conversion') {
  tab.value = t
  if (t === 'wall' && wallItems.value.length === 0) loadWall()
  if (t === 'conversion' && !convData.value) loadConversion()
}

onMounted(loadWall)
</script>

<template>
  <div class="sales-page">
    <div class="page-head">
      <h2>销售飞轮 · 赢单复盘台</h2>
      <p class="sub">把刚赢下的单沉淀成全店共享的话术弹药。30秒语音/文字复盘，AI 拆成结构化话术卡，审核后进入话术墙。</p>
    </div>

    <div class="tabs">
      <button :class="['tab', { active: tab === 'wall' }]" @click="switchTab('wall')">话术墙</button>
      <button :class="['tab', { active: tab === 'submit' }]" @click="tab = 'submit'">新增复盘</button>
      <button :class="['tab', { active: tab === 'conversion' }]" @click="switchTab('conversion')">
        ⊙ 成交转化
      </button>
    </div>

    <!-- 话术墙 -->
    <div v-if="tab === 'wall'">
      <div class="filter-row">
        <input v-model="wallFilter.car_brand" placeholder="品牌筛选" class="filter-input" />
        <input v-model="wallFilter.car_model" placeholder="车型筛选" class="filter-input" />
        <button class="btn" @click="loadWall" :disabled="wallLoading">搜索</button>
      </div>
      <div v-if="wallError" class="err">{{ wallError }}</div>
      <div v-if="wallLoading" class="loading">加载中…</div>
      <div v-else-if="wallItems.length === 0" class="empty">暂无已通过的销售话术经验。提交复盘审核通过后将在此显示。</div>
      <div v-else class="wall-grid">
        <div v-for="item in wallItems" :key="item.id" class="wall-card">
          <div class="card-title">{{ item.title }}</div>
          <div class="card-meta">
            <span v-if="item.car_brand" class="tag">{{ item.car_brand }}</span>
            <span v-if="item.car_model" class="tag">{{ item.car_model }}</span>
          </div>
          <div class="card-preview">{{ item.content_preview }}</div>
          <div class="card-foot">
            <span>{{ item.source_person || '—' }}</span>
            <span class="useful">△ {{ item.useful_count }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 新增复盘 -->
    <div v-if="tab === 'submit'" class="submit-panel">
      <div class="form-block">
        <label>复盘内容 <span class="req">*</span></label>
        <p class="form-hint">描述这单怎么赢的：客户卡在哪、你怎么应对、结果如何。AI 会自动拆解成话术卡草稿。</p>
        <textarea v-model="submitForm.content" rows="6" placeholder="例：客户纠结星瑞L和途观，我先承认途观底盘调校更成熟，然后引导他试驾对比，最终星瑞L的智能座舱打动了他……" class="textarea"></textarea>
        <div class="form-row">
          <div class="form-col">
            <label>品牌（可选）</label>
            <input v-model="submitForm.car_brand" placeholder="如：吉利" class="input" />
          </div>
          <div class="form-col">
            <label>车型（可选）</label>
            <input v-model="submitForm.car_model" placeholder="如：星瑞L" class="input" />
          </div>
        </div>
        <div v-if="submitError" class="err">{{ submitError }}</div>
        <button class="btn primary" @click="submitReview" :disabled="submitting">
          {{ submitting ? 'AI 拆解中…' : '提交复盘' }}
        </button>
      </div>

      <!-- 提交结果预览 -->
      <div v-if="submitResult" class="result-block">
        <div class="result-head">
          ✅ 已提交审核
          <span class="ai-badge" v-if="submitResult.ai_extracted">AI 已拆解</span>
          <span class="ai-badge plain" v-else>AI 未响应，已按原文保存</span>
        </div>
        <div class="result-title">{{ submitResult.title }}</div>
        <template v-if="submitResult.extracted">
          <div class="extracted-row"><b>客户异议：</b>{{ submitResult.extracted.objection }}</div>
          <div class="extracted-row"><b>应对话术：</b>{{ submitResult.extracted.tactic }}</div>
          <div class="extracted-row" v-if="submitResult.extracted.car_model"><b>适用车型：</b>{{ submitResult.extracted.car_model }}</div>
          <div class="extracted-row" v-if="submitResult.extracted.competitor"><b>涉及竞品：</b>{{ submitResult.extracted.competitor }}</div>
        </template>
        <p class="result-note">审核通过后将出现在话术墙，供全员复用。</p>
      </div>
    </div>

    <!-- ⊙ 成交转化 -->
    <div v-if="tab === 'conversion'">
      <div v-if="convLoading" class="loading">加载中…</div>
      <template v-else-if="convData">
        <div v-if="!convData.connected" class="plugin-tip">
          <div class="plugin-icon">⊙</div>
          <div class="plugin-msg">{{ convData.message }}</div>
        </div>
        <template v-else>
          <p class="sub">共导入 {{ convData.total_deals }} 条成交单，按关联话术统计转化效果。</p>
          <table>
            <thead><tr><th>话术标题</th><th>关联成交数</th><th>平均毛利</th></tr></thead>
            <tbody>
              <tr v-for="item in convData.items" :key="item.knowledge_id">
                <td>{{ item.title }}</td>
                <td class="num">{{ item.deal_count }}</td>
                <td class="num">{{ item.avg_margin !== null ? '¥' + item.avg_margin.toLocaleString() : '—' }}</td>
              </tr>
            </tbody>
          </table>
        </template>
      </template>
    </div>
  </div>
</template>

<style scoped>
.sales-page { padding: 20px; max-width: 70%; margin: 0; }
.page-head h2 { margin: 0 0 4px; color: var(--text-main, #1a1a1a); }
.page-head .sub { margin: 0 0 16px; color: var(--text-sub, #888); font-size: 13px; }
.err { color: #c73a3a; font-size: 13px; margin: 8px 0; }
.loading { color: var(--text-sub, #999); padding: 12px 0; font-size: 13px; }
.empty { color: var(--text-sub, #999); font-size: 13px; padding: 16px 0; }

.tabs { display: flex; gap: 0; margin-bottom: 16px; border-bottom: 2px solid var(--border, #e5e5e5); }
.tab { padding: 8px 20px; border: none; background: none; cursor: pointer; font-size: 14px; color: var(--text-main); border-bottom: 2px solid transparent; margin-bottom: -2px; }
.tab.active { color: var(--primary, #6B7B8B); border-bottom-color: var(--primary, #6B7B8B); font-weight: 600; }

/* 话术墙 */
.filter-row { display: flex; gap: 8px; margin-bottom: 14px; }
.filter-input { padding: 6px 10px; border: 1px solid var(--border, #ccc); border-radius: 4px; font-size: 13px; width: 140px; background: var(--bg-card); color: var(--text-main); }
.wall-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 12px; }
.wall-card { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 14px; }
.card-title { font-size: 14px; font-weight: 600; color: var(--text-main, #1a1a1a); margin-bottom: 6px; }
.card-meta { display: flex; gap: 4px; margin-bottom: 8px; flex-wrap: wrap; }
.tag { background: var(--bg-main, #f0f0f0); border-radius: 3px; padding: 1px 7px; font-size: 11px; color: var(--text-sub, #666); }
.card-preview { font-size: 12px; color: var(--text-sub, #888); line-height: 1.5; margin-bottom: 8px; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
.card-foot { display: flex; justify-content: space-between; font-size: 12px; color: var(--text-sub, #999); }
.useful { color: var(--primary, #6B7B8B); }

/* 提交表单 */
.submit-panel { max-width: 640px; }
.form-block { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 18px; margin-bottom: 14px; }
.form-block label { display: block; font-size: 12px; color: var(--text-sub, #888); margin-bottom: 4px; }
.form-hint { font-size: 12px; color: var(--text-sub, #bbb); margin: 0 0 8px; }
.req { color: #c73a3a; }
.textarea { width: 100%; padding: 8px; border: 1px solid var(--border, #ccc); border-radius: 4px; font-size: 13px; resize: vertical; box-sizing: border-box; font-family: inherit; }
.form-row { display: flex; gap: 12px; margin: 10px 0; }
.form-col { flex: 1; }
.input { width: 100%; padding: 6px; border: 1px solid var(--border, #ccc); border-radius: 4px; font-size: 13px; box-sizing: border-box; }

.result-block { background: #f0f7f0; border: 1px solid #b8dbb8; border-radius: 8px; padding: 14px; }
.result-head { font-size: 13px; font-weight: 600; color: #3a8f3a; margin-bottom: 8px; display: flex; gap: 8px; align-items: center; }
.ai-badge { background: #3a8f3a; color: #fff; border-radius: 3px; padding: 1px 8px; font-size: 11px; font-weight: normal; }
.ai-badge.plain { background: var(--text-sub, #999); }
.result-title { font-size: 14px; font-weight: 600; color: var(--text-main, #1a1a1a); margin-bottom: 10px; }
.extracted-row { font-size: 13px; color: var(--text-main, #333); margin-bottom: 5px; }
.result-note { font-size: 12px; color: var(--text-sub, #888); margin-top: 10px; }

/* 成交转化 */
.plugin-tip { background: var(--bg-card, #fff); border: 2px dashed var(--border, #ccc); border-radius: 8px; padding: 32px; text-align: center; }
.plugin-icon { font-size: 32px; margin-bottom: 12px; }
.plugin-msg { font-size: 13px; color: var(--text-sub, #888); line-height: 1.7; }
.sub { font-size: 13px; color: var(--text-sub, #888); margin-bottom: 12px; }
table { width: 100%; border-collapse: collapse; font-size: 13px; }
th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid var(--border, #eee); }
th { color: var(--text-sub, #888); font-weight: 600; }
td.num { font-weight: 600; color: var(--primary, #6B7B8B); }

.btn { padding: 6px 16px; border: 1px solid var(--border, #ccc); background: var(--bg-card, #fff); border-radius: 4px; cursor: pointer; font-size: 13px; margin-top: 10px; }
.btn:hover { border-color: var(--primary, #6B7B8B); color: var(--primary); }
.btn.primary { background: var(--primary, #6B7B8B); color: #fff; border-color: var(--primary); }
.btn:disabled { opacity: 0.6; cursor: not-allowed; }
</style>
