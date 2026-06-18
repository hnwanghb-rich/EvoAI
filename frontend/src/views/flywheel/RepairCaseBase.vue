<script setup lang="ts">
// FW-06 维修飞轮·故障案例库
// 案例检索 + 提交案例 + ⊙ 一次修复率占位
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface CaseItem {
  id: number
  title: string
  car_brand: string
  car_model: string
  tags: string
  safety_critical: boolean
  useful_count: number
  view_count: number
  preview: string
  created_at: string | null
}
interface Extracted {
  title?: string
  symptom?: string
  fault_code?: string
  diagnosis?: string
  root_cause?: string
  solution?: string
  parts?: string
  safety_flag?: boolean
}

const tab = ref<'search' | 'submit' | 'fixrate'>('search')

// 检索
const searchForm = ref({ q: '', car_brand: '', car_model: '', fault_code: '' })
const searchLoading = ref(false)
const searchItems = ref<CaseItem[]>([])
const searchError = ref('')

// 提交
const submitForm = ref({ content: '', car_brand: '', car_model: '' })
const submitting = ref(false)
const submitResult = ref<{ id: number; title: string; safety_critical: boolean; ai_extracted: boolean; extracted: Extracted | null } | null>(null)
const submitError = ref('')

// 修复率
const fixRateLoading = ref(false)
const fixRateData = ref<{ connected: boolean; message?: string; total_orders?: number } | null>(null)

async function doSearch() {
  searchLoading.value = true
  searchError.value = ''
  try {
    const res = await axios.get('/api/flywheel/repair/search', { params: searchForm.value })
    searchItems.value = res.data.data.items || []
  } catch {
    searchError.value = '检索失败'
  } finally {
    searchLoading.value = false
  }
}

async function submitCase() {
  if (!submitForm.value.content.trim()) { submitError.value = '请填写故障描述'; return }
  if (!submitForm.value.car_brand.trim() || !submitForm.value.car_model.trim()) {
    submitError.value = '车型品牌和车型为必填项'
    return
  }
  submitting.value = true
  submitError.value = ''
  submitResult.value = null
  try {
    const res = await axios.post('/api/flywheel/repair/case', null, { params: submitForm.value })
    submitResult.value = res.data.data
    submitForm.value = { content: '', car_brand: '', car_model: '' }
  } catch (e: any) {
    submitError.value = e?.response?.data?.detail || '提交失败'
  } finally {
    submitting.value = false
  }
}

async function loadFixRate() {
  fixRateLoading.value = true
  try {
    const res = await axios.get('/api/flywheel/repair/fix-rate')
    fixRateData.value = res.data.data
  } catch {
    fixRateData.value = { connected: false, message: '加载失败' }
  } finally {
    fixRateLoading.value = false
  }
}

function switchTab(t: 'search' | 'submit' | 'fixrate') {
  tab.value = t
  if (t === 'fixrate' && !fixRateData.value) loadFixRate()
}

onMounted(doSearch)
</script>

<template>
  <div class="repair-page">
    <div class="page-head">
      <h2>维修飞轮 · 故障案例</h2>
      <p class="sub">把老师傅的诊断直觉变成全店可查的故障案例。疑难故障修复后沉淀"现象→排查→方案"，新人遇到同类问题直接检索。</p>
    </div>

    <div class="tabs">
      <button :class="['tab', { active: tab === 'search' }]" @click="switchTab('search')">案例检索</button>
      <button :class="['tab', { active: tab === 'submit' }]" @click="tab = 'submit'">新增案例</button>
      <button :class="['tab', { active: tab === 'fixrate' }]" @click="switchTab('fixrate')">⊙ 一次修复率</button>
    </div>

    <!-- 案例检索 -->
    <div v-if="tab === 'search'">
      <div class="filter-row">
        <input v-model="searchForm.car_brand" placeholder="品牌" class="filter-input short" />
        <input v-model="searchForm.car_model" placeholder="车型" class="filter-input short" />
        <input v-model="searchForm.fault_code" placeholder="故障码" class="filter-input short" />
        <input v-model="searchForm.q" placeholder="现象关键词" class="filter-input" @keyup.enter="doSearch" />
        <button class="btn" @click="doSearch" :disabled="searchLoading">搜索</button>
      </div>
      <div v-if="searchError" class="err">{{ searchError }}</div>
      <div v-if="searchLoading" class="loading">检索中…</div>
      <div v-else-if="searchItems.length === 0" class="empty">未找到匹配案例。提交新案例审核通过后将在此显示。</div>
      <div v-else class="case-list">
        <div v-for="item in searchItems" :key="item.id" class="case-card">
          <div class="case-head">
            <span class="case-title">{{ item.title }}</span>
            <span v-if="item.safety_critical" class="safety-badge">△ 安全关键</span>
          </div>
          <div class="case-meta">
            <span class="tag">{{ item.car_brand }} {{ item.car_model }}</span>
            <span v-if="item.tags" class="tags-text">{{ item.tags }}</span>
          </div>
          <div class="case-preview">{{ item.preview }}</div>
          <div class="case-foot">
            <span class="useful">△ {{ item.useful_count }}</span>
            <span class="views">◁ {{ item.view_count }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 新增案例 -->
    <div v-if="tab === 'submit'" class="submit-panel">
      <div class="form-block">
        <div class="safety-tip">
          △ <b>安全红线</b>：涉及新能源高压、动力电池、制动/ABS/ESP、安全气囊的案例，系统自动标记需技术总监二次签核。
        </div>
        <div class="form-row">
          <div class="form-col">
            <label>品牌 <span class="req">*</span></label>
            <input v-model="submitForm.car_brand" placeholder="如：吉利" class="input" />
          </div>
          <div class="form-col">
            <label>车型 <span class="req">*</span></label>
            <input v-model="submitForm.car_model" placeholder="如：星瑞L" class="input" />
          </div>
        </div>
        <label>故障描述 <span class="req">*</span></label>
        <p class="form-hint">描述故障现象、排查过程、最终解决方案。AI 自动拆成结构化案例卡。</p>
        <textarea v-model="submitForm.content" rows="7"
          placeholder="例：客户反映发动机抖动，故障码P0301，检查后发现1缸火花塞积碳严重，更换全套火花塞后故障消除……"
          class="textarea"></textarea>
        <div v-if="submitError" class="err">{{ submitError }}</div>
        <button class="btn primary" @click="submitCase" :disabled="submitting">
          {{ submitting ? 'AI 拆解中…' : '提交案例' }}
        </button>
      </div>

      <div v-if="submitResult" :class="['result-block', { safety: submitResult.safety_critical }]">
        <div class="result-head">
          ✓ 已提交审核
          <span v-if="submitResult.safety_critical" class="safety-badge">△ 安全关键·需技术总监二次签核</span>
          <span class="ai-badge" v-if="submitResult.ai_extracted">AI 已拆解</span>
          <span class="ai-badge plain" v-else>AI 未响应，已按原文保存</span>
        </div>
        <div class="result-title">{{ submitResult.title }}</div>
        <template v-if="submitResult.extracted">
          <div class="extracted-row" v-if="submitResult.extracted.symptom"><b>故障现象：</b>{{ submitResult.extracted.symptom }}</div>
          <div class="extracted-row" v-if="submitResult.extracted.fault_code"><b>故障码：</b>{{ submitResult.extracted.fault_code }}</div>
          <div class="extracted-row" v-if="submitResult.extracted.root_cause"><b>根本原因：</b>{{ submitResult.extracted.root_cause }}</div>
          <div class="extracted-row" v-if="submitResult.extracted.solution"><b>维修方案：</b>{{ submitResult.extracted.solution }}</div>
          <div class="extracted-row" v-if="submitResult.extracted.parts"><b>更换配件：</b>{{ submitResult.extracted.parts }}</div>
        </template>
      </div>
    </div>

    <!-- ⊙ 一次修复率 -->
    <div v-if="tab === 'fixrate'">
      <div v-if="fixRateLoading" class="loading">加载中…</div>
      <div v-else-if="fixRateData && !fixRateData.connected" class="plugin-tip">
        <div class="plugin-icon">⊙</div>
        <div class="plugin-msg">{{ fixRateData.message }}</div>
      </div>
      <div v-else-if="fixRateData" class="sub">
        已导入 {{ fixRateData.total_orders }} 条 DMS 工单，一次修复率分析功能开发中。
      </div>
    </div>
  </div>
</template>

<style scoped>
.repair-page { padding: 20px; max-width: 70%; margin: 0; }
.page-head h2 { margin: 0 0 4px; color: var(--text-main, #1a1a1a); }
.page-head .sub { margin: 0 0 16px; color: var(--text-sub, #888); font-size: 13px; }
.err { color: #c73a3a; font-size: 13px; margin: 8px 0; }
.loading { color: var(--text-sub, #999); padding: 12px 0; font-size: 13px; }
.empty { color: var(--text-sub, #999); font-size: 13px; padding: 16px 0; }
.sub { font-size: 13px; color: var(--text-sub, #888); padding: 16px 0; }

.tabs { display: flex; gap: 0; margin-bottom: 16px; border-bottom: 2px solid var(--border, #e5e5e5); }
.tab { padding: 8px 20px; border: none; background: none; cursor: pointer; font-size: 14px; color: var(--text-sub, #888); border-bottom: 2px solid transparent; margin-bottom: -2px; }
.tab.active { color: var(--primary, #6B7B8B); border-bottom-color: var(--primary); font-weight: 600; }

/* 检索 */
.filter-row { display: flex; gap: 8px; margin-bottom: 14px; flex-wrap: wrap; }
.filter-input { padding: 6px 10px; border: 1px solid var(--border, #ccc); border-radius: 4px; font-size: 13px; flex: 1; min-width: 100px; }
.filter-input.short { flex: 0 0 100px; }

.case-list { display: flex; flex-direction: column; gap: 10px; }
.case-card { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 14px; }
.case-head { display: flex; align-items: center; gap: 8px; margin-bottom: 6px; flex-wrap: wrap; }
.case-title { font-size: 14px; font-weight: 600; color: var(--text-main, #1a1a1a); flex: 1; }
.safety-badge { background: #fef0f0; color: #c73a3a; border-radius: 4px; padding: 2px 8px; font-size: 12px; white-space: nowrap; }
.case-meta { display: flex; gap: 6px; margin-bottom: 8px; flex-wrap: wrap; align-items: center; }
.tag { background: var(--bg-main, #f0f0f0); border-radius: 3px; padding: 1px 7px; font-size: 11px; color: var(--text-sub, #666); }
.tags-text { font-size: 11px; color: var(--text-sub, #bbb); }
.case-preview { font-size: 12px; color: var(--text-sub, #888); line-height: 1.6; margin-bottom: 8px; display: -webkit-box; -webkit-line-clamp: 4; -webkit-box-orient: vertical; overflow: hidden; }
.case-foot { display: flex; gap: 12px; font-size: 12px; color: var(--text-sub, #999); }
.useful { color: var(--primary, #6B7B8B); }

/* 提交 */
.submit-panel { max-width: 640px; }
.form-block { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 18px; margin-bottom: 14px; }
.safety-tip { background: #fff4e5; border: 1px solid #f5c97a; border-radius: 6px; padding: 10px 14px; font-size: 12px; color: #7a4f00; margin-bottom: 14px; }
.form-row { display: flex; gap: 12px; margin-bottom: 12px; }
.form-col { flex: 1; }
.form-col label { display: block; font-size: 12px; color: var(--text-sub, #888); margin-bottom: 4px; }
.req { color: #c73a3a; }
.form-hint { font-size: 12px; color: var(--text-sub, #bbb); margin: 0 0 6px; }
label { display: block; font-size: 12px; color: var(--text-sub, #888); margin-bottom: 4px; }
.input { width: 100%; padding: 6px; border: 1px solid var(--border, #ccc); border-radius: 4px; font-size: 13px; box-sizing: border-box; }
.textarea { width: 100%; padding: 8px; border: 1px solid var(--border, #ccc); border-radius: 4px; font-size: 13px; resize: vertical; box-sizing: border-box; font-family: inherit; }

.result-block { background: #f0f7f0; border: 1px solid #b8dbb8; border-radius: 8px; padding: 14px; }
.result-block.safety { background: #fff8f0; border-color: #f5c97a; }
.result-head { font-size: 13px; font-weight: 600; color: #3a8f3a; margin-bottom: 8px; display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.result-block.safety .result-head { color: #7a4f00; }
.ai-badge { background: #3a8f3a; color: #fff; border-radius: 3px; padding: 1px 8px; font-size: 11px; font-weight: normal; }
.ai-badge.plain { background: var(--text-sub, #999); }
.result-title { font-size: 14px; font-weight: 600; color: var(--text-main, #1a1a1a); margin-bottom: 10px; }
.extracted-row { font-size: 13px; color: var(--text-main, #333); margin-bottom: 5px; }

/* ⊙ 占位 */
.plugin-tip { background: var(--bg-card, #fff); border: 2px dashed var(--border, #ccc); border-radius: 8px; padding: 32px; text-align: center; }
.plugin-icon { font-size: 32px; margin-bottom: 12px; }
.plugin-msg { font-size: 13px; color: var(--text-sub, #888); line-height: 1.7; }

.btn { padding: 6px 16px; border: 1px solid var(--border, #ccc); background: var(--bg-card, #fff); border-radius: 4px; cursor: pointer; font-size: 13px; margin-top: 10px; }
.btn:hover { border-color: var(--primary, #6B7B8B); color: var(--primary); }
.btn.primary { background: var(--primary, #6B7B8B); color: #fff; border-color: var(--primary); }
.btn:disabled { opacity: 0.6; cursor: not-allowed; }
</style>
