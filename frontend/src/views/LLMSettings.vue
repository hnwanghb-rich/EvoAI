<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface Provider {
  id: number; name: string; provider_type: string
  base_url: string; api_key: string; api_key_set: boolean
  model_name: string; is_active: boolean; is_default: boolean
  max_tokens: number; temperature: number
}

const providers = ref<Provider[]>([])
const loading = ref(true)
const showForm = ref(false)
const editing = ref<Partial<Provider>>({})
const isEdit = ref(false)
const testResult = ref<{ id: number; success: boolean; msg: string; elapsed_ms: number } | null>(null)
const testingId = ref(0)
const showCustomForm = ref(false)
const customForm = ref({ name: '', provider_type: 'custom', base_url: '', api_key: '', model_name: '' })

const typeLabels: Record<string, string> = {
  tongyi: '通义千问', deepseek: 'DeepSeek', zhipu: '智谱GLM', kimi: '月之暗面Kimi',
  baichuan: '百川智能', xfyun: '讯飞星火', siliconflow: '硅基流动', dify: 'Dify', custom: '自定义',
}

async function fetchList() {
  const { data } = await axios.get('/api/llm/providers')
  providers.value = data.data
  loading.value = false
}

function openEdit(p: Provider) {
  isEdit.value = true
  editing.value = { ...p, api_key: '' }
  showForm.value = true
}

async function saveEdit() {
  const body: any = {}
  if (editing.value.name) body.name = editing.value.name
  if (editing.value.base_url) body.base_url = editing.value.base_url
  if (editing.value.api_key && editing.value.api_key.trim()) body.api_key = editing.value.api_key
  if (editing.value.model_name) body.model_name = editing.value.model_name
  if (editing.value.max_tokens != null) body.max_tokens = editing.value.max_tokens
  if (editing.value.temperature != null) body.temperature = editing.value.temperature
  if (editing.value.is_active != null) body.is_active = editing.value.is_active

  await axios.put(`/api/llm/providers/${editing.value.id}`, body)
  showForm.value = false
  fetchList()
}

async function toggleActive(p: Provider) {
  await axios.put(`/api/llm/providers/${p.id}`, { is_active: !p.is_active })
  fetchList()
}

async function setDefault(id: number) {
  await axios.put(`/api/llm/providers/${id}/set-default`)
  fetchList()
}

async function testConnection(id: number) {
  testingId.value = id
  testResult.value = null
  try {
    const { data } = await axios.post(`/api/llm/providers/${id}/test`)
    testResult.value = { id, success: true, msg: data.msg, elapsed_ms: data.data.elapsed_ms }
  } catch (e: any) {
    testResult.value = {
      id, success: false,
      msg: e.response?.data?.detail || '连接失败',
      elapsed_ms: 0,
    }
  } finally {
    testingId.value = 0
  }
}

async function createCustom() {
  if (!customForm.value.name || !customForm.value.base_url || !customForm.value.model_name) return
  await axios.post('/api/llm/providers', customForm.value)
  showCustomForm.value = false
  customForm.value = { name: '', provider_type: 'custom', base_url: '', api_key: '', model_name: '' }
  fetchList()
}

onMounted(fetchList)
</script>

<template>
  <div class="llm-page">
    <div class="llm-head">
      <h2 class="page-title">LLM 模型配置</h2>
      <button class="btn btn-sm" @click="showCustomForm = true">+ 自定义模型</button>
    </div>

    <div v-if="loading" class="llm-loading">加载中...</div>

    <!-- 模型卡片列表 -->
    <div class="llm-grid" v-else>
      <div v-for="p in providers" :key="p.id" class="llm-card card"
        :style="p.is_default ? { borderColor: 'var(--primary)', borderWidth: '2px' } : {}">

        <div class="llm-card-head">
          <div class="llm-card-title">
            <h3>{{ p.name }}</h3>
            <span class="llm-type">{{ typeLabels[p.provider_type] || p.provider_type }}</span>
            <span v-if="p.is_default" class="llm-default-badge">默认</span>
          </div>
          <div class="llm-switches">
            <label class="llm-toggle" :title="p.is_active ? '已启用' : '已停用'">
              <input type="checkbox" :checked="p.is_active" @change="toggleActive(p)" />
              <span class="toggle-slider"></span>
            </label>
          </div>
        </div>

        <div class="llm-card-body">
          <div class="llm-field">
            <span class="llm-label">API 地址</span>
            <span class="llm-value llm-url">{{ p.base_url }}</span>
          </div>
          <div class="llm-field">
            <span class="llm-label">模型名</span>
            <span class="llm-value">{{ p.model_name }}</span>
          </div>
          <div class="llm-field">
            <span class="llm-label">API Key</span>
            <span class="llm-value" :style="{ color: p.api_key_set ? 'var(--success)' : 'var(--danger)' }">
              {{ p.api_key_set ? p.api_key : '未配置' }}
            </span>
          </div>
          <div class="llm-field">
            <span class="llm-label">Temperature</span>
            <span class="llm-value">{{ p.temperature }}</span>
          </div>
          <div class="llm-field">
            <span class="llm-label">Max Tokens</span>
            <span class="llm-value">{{ p.max_tokens }}</span>
          </div>
        </div>

        <div class="llm-card-actions">
          <button class="btn btn-sm btn-outline" @click="openEdit(p)">编辑</button>
          <button class="btn btn-sm btn-outline" :disabled="!p.api_key_set" @click="testConnection(p.id)">
            {{ testingId === p.id ? '测试中...' : '测试连接' }}
          </button>
          <button v-if="!p.is_default" class="btn btn-sm btn-outline" @click="setDefault(p.id)">设为默认</button>
        </div>

        <!-- 测试结果 -->
        <div v-if="testResult?.id === p.id" class="llm-test-result"
          :style="{
            borderColor: testResult.success ? 'var(--success)' : 'var(--danger)',
            background: testResult.success ? 'rgba(122,166,104,0.08)' : 'rgba(192,64,59,0.08)',
          }">
          {{ testResult.success ? '✅' : '❌' }} {{ testResult.msg }}
          <span v-if="testResult.success">, 回复: "{{ p.model_name }}"</span>
        </div>
      </div>
    </div>

    <!-- 编辑弹窗 -->
    <Teleport to="body">
      <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
        <div class="modal-panel">
          <div class="modal-header">
            <h3>编辑模型 - {{ editing.name }}</h3>
            <button @click="showForm = false" class="btn btn-sm">×</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label>名称</label>
              <input v-model="editing.name" class="form-input" style="width:100%" />
            </div>
            <div class="form-group">
              <label>Base URL</label>
              <input v-model="editing.base_url" class="form-input" style="width:100%" placeholder="https://api.example.com/v1" />
            </div>
            <div class="form-group">
              <label>API Key（留空则不修改）</label>
              <input v-model="editing.api_key" class="form-input" style="width:100%" placeholder="输入新的 API Key" />
            </div>
            <div class="form-group">
              <label>Model Name</label>
              <input v-model="editing.model_name" class="form-input" style="width:100%" />
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Temperature</label>
                <input v-model.number="editing.temperature" type="number" min="0" max="2" step="0.1" class="form-input" style="width:100%" />
              </div>
              <div class="form-group">
                <label>Max Tokens</label>
                <input v-model.number="editing.max_tokens" type="number" min="1" max="32768" class="form-input" style="width:100%" />
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-outline" @click="showForm = false">取消</button>
            <button class="btn" @click="saveEdit">保存</button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- 自定义模型弹窗 -->
    <Teleport to="body">
      <div v-if="showCustomForm" class="modal-overlay" @click.self="showCustomForm = false">
        <div class="modal-panel">
          <div class="modal-header">
            <h3>新增自定义模型</h3>
            <button @click="showCustomForm = false" class="btn btn-sm">×</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label>名称 <span style="color:var(--danger)">*</span></label>
              <input v-model="customForm.name" class="form-input" style="width:100%" placeholder="如：本地Ollama" />
            </div>
            <div class="form-group">
              <label>Base URL <span style="color:var(--danger)">*</span></label>
              <input v-model="customForm.base_url" class="form-input" style="width:100%" placeholder="https://your-api.com/v1" />
            </div>
            <div class="form-group">
              <label>API Key（可选）</label>
              <input v-model="customForm.api_key" class="form-input" style="width:100%" />
            </div>
            <div class="form-group">
              <label>Model Name <span style="color:var(--danger)">*</span></label>
              <input v-model="customForm.model_name" class="form-input" style="width:100%" placeholder="gpt-4-turbo" />
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-outline" @click="showCustomForm = false">取消</button>
            <button class="btn" @click="createCustom" :disabled="!customForm.name || !customForm.base_url || !customForm.model_name">添加</button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.llm-page { max-width: 1100px; margin: 0 auto; }
.page-title { font-size: 20px; margin: 0; color: var(--text-main); }
.llm-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.llm-loading { text-align: center; padding: 60px; color: var(--text-sub); }

.llm-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 16px; }

.llm-card { padding: 16px; display: flex; flex-direction: column; }
.llm-card-head { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 12px; }
.llm-card-title { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
.llm-card-title h3 { font-size: 15px; margin: 0; color: var(--text-main); }
.llm-type {
  padding: 2px 8px; border-radius: 10px; font-size: 11px;
  background: var(--bg-main); color: var(--text-sub); border: 1px solid var(--border);
}
.llm-default-badge {
  padding: 2px 8px; border-radius: 10px; font-size: 11px;
  background: var(--primary); color: #fff;
}

/* 开关 */
.llm-toggle { position: relative; display: inline-block; width: 40px; height: 22px; cursor: pointer; }
.llm-toggle input { opacity: 0; width: 0; height: 0; }
.toggle-slider {
  position: absolute; inset: 0;
  background: var(--border); border-radius: 11px; transition: 0.2s;
}
.toggle-slider::before {
  content: ''; position: absolute; height: 16px; width: 16px;
  left: 3px; bottom: 3px; background: #fff; border-radius: 50%; transition: 0.2s;
}
.llm-toggle input:checked + .toggle-slider { background: var(--success); }
.llm-toggle input:checked + .toggle-slider::before { transform: translateX(18px); }

.llm-card-body { flex: 1; }
.llm-field { display: flex; justify-content: space-between; padding: 4px 0; font-size: 13px; }
.llm-label { color: var(--text-sub); flex-shrink: 0; }
.llm-value { color: var(--text-main); text-align: right; max-width: 60%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.llm-card-actions { display: flex; gap: 6px; margin-top: 12px; padding-top: 10px; border-top: 1px solid var(--border); flex-wrap: wrap; }

.llm-test-result {
  margin-top: 10px; padding: 8px 12px; border-radius: 6px;
  font-size: 12px; border: 1px solid;
}

/* 弹窗 */
.modal-overlay { position: fixed; inset: 0; z-index: 8500; background: rgba(0,0,0,0.4); display: flex; align-items: center; justify-content: center; }
.modal-panel { width: 520px; max-width: 95vw; max-height: 90vh; background: var(--bg-card); border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.2); display: flex; flex-direction: column; }
.modal-header { display: flex; justify-content: space-between; align-items: center; padding: 14px 18px; border-bottom: 1px solid var(--border); }
.modal-header h3 { margin: 0; font-size: 16px; }
.modal-body { padding: 16px 18px; overflow-y: auto; flex: 1; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 12px 18px; border-top: 1px solid var(--border); }
.form-group { margin-bottom: 10px; }
.form-group label { display: block; font-size: 12px; color: var(--text-sub); margin-bottom: 3px; }
.form-row { display: flex; gap: 12px; }
.form-row .form-group { flex: 1; }

@media (max-width: 768px) {
  .llm-grid { grid-template-columns: 1fr; }
  .form-row { flex-direction: column; }
}
</style>
