<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import axios from 'axios'

const auth = useAuthStore()

interface KnowledgeItem {
  id: number; title: string; content: string; tags: string | null
  car_brand: string | null; car_model: string | null
  knowledge_base: string; category_id: number
  view_count: number; useful_count: number; difficulty_level: number
  source_person: string | null; status: string
  created_at: string | null; updated_at: string | null
  content_type: string
}

interface Category {
  id: number; name: string; knowledge_base: string; icon: string | null
}

const items = ref<KnowledgeItem[]>([])
const total = ref(0)
const page = ref(1)
const loading = ref(false)
const keyword = ref('')
const statusFilter = ref('')
const categories = ref<Category[]>([])

// 编辑弹窗
const showForm = ref(false)
const editing = ref<Partial<KnowledgeItem> & { content?: string }>({})
const isEdit = ref(false)

// 批量导入
const showImport = ref(false)
const importFile = ref<File | null>(null)
const importText = ref('')
const importLoading = ref(false)

const kbLabel: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }
const statusLabel: Record<string, string> = { draft: '草稿', pending: '待审', approved: '已通过', rejected: '已驳回', archived: '已归档' }
const statusStyle: Record<string, string> = {
  approved: 'color: var(--success)', rejected: 'color: var(--danger)',
  pending: 'color: var(--accent)', archived: 'color: var(--text-sub)',
}

async function fetchCategories() {
  const { data } = await axios.get('/api/categories')
  categories.value = data.data
}

async function fetchList() {
  loading.value = true
  try {
    const params: any = { page: page.value, page_size: 20, sort_by: 'created_at' }
    if (keyword.value) params.keyword = keyword.value
    const { data } = await axios.get('/api/knowledge', { params })
    // 管理员需要用不同方式看全部状态的知识
    // 用原接口过滤 status
    let all = data.data.items || []
    if (statusFilter.value) {
      all = all.filter((i: any) => i.status === statusFilter.value)
    }
    items.value = all
    total.value = data.data.total
  } finally {
    loading.value = false
  }
}

function search() { page.value = 1; fetchList() }

// === 新增/编辑 ===
function openCreate() {
  isEdit.value = false
  editing.value = { title: '', content: '', category_id: 0, knowledge_base: 'public', tags: '', car_brand: '', car_model: '', difficulty_level: 1 }
  showForm.value = true
}
function openEdit(item: KnowledgeItem) {
  isEdit.value = true
  editing.value = { ...item }
  showForm.value = true
}
async function saveForm() {
  const body: any = {
    title: editing.value.title,
    content: editing.value.content,
    category_id: editing.value.category_id || categories.value[0]?.id || 1,
    knowledge_base: editing.value.knowledge_base,
    tags: editing.value.tags,
    car_brand: editing.value.car_brand,
    car_model: editing.value.car_model,
    difficulty_level: editing.value.difficulty_level || 1,
  }
  if (isEdit.value && editing.value.id) {
    await axios.put(`/api/knowledge/${editing.value.id}`, body)
  } else {
    await axios.post('/api/knowledge', body)
  }
  showForm.value = false
  fetchList()
}

// === 状态操作 ===
async function changeStatus(id: number, status: string) {
  await axios.put(`/api/knowledge/${id}/status?status=${status}`)
  fetchList()
}

// === 批量导入 ===
function onFileChange(e: Event) {
  const input = e.target as HTMLInputElement
  importFile.value = input.files?.[0] || null
  importText.value = ''
}
async function doImport() {
  if (!importFile.value || !auth.token) return
  importLoading.value = true
  try {
    const formData = new FormData()
    formData.append('file', importFile.value)
    const { data } = await axios.post('/api/upload/file', formData)
    importText.value = data.data.extracted_text || ''
  } catch (e: any) {
    alert('上传失败：' + (e.response?.data?.detail || e.message))
  } finally {
    importLoading.value = false
  }
}
async function createFromImport() {
  if (!importText.value.trim()) return
  const title = importFile.value?.name?.replace(/\.[^.]+$/, '') || '导入知识'
  await axios.post('/api/knowledge', {
    title, content: importText.value,
    category_id: editing.value.category_id || categories.value[0]?.id || 1,
    knowledge_base: 'public',
  })
  showImport.value = false
  fetchList()
}

onMounted(async () => {
  await fetchCategories()
  fetchList()
})
</script>

<template>
  <div class="km-page">
    <div class="km-toolbar">
      <form @submit.prevent="search" class="km-search">
        <input v-model="keyword" placeholder="搜索知识..." class="form-input" style="width:240px" />
        <select v-model="statusFilter" @change="search" class="form-input" style="width:auto">
          <option value="">全部状态</option>
          <option value="approved">已通过</option>
          <option value="pending">待审核</option>
          <option value="rejected">已驳回</option>
          <option value="archived">已归档</option>
        </select>
        <button type="submit" class="btn btn-sm">搜索</button>
      </form>
      <div class="km-actions">
        <button class="btn btn-sm" @click="openCreate">+ 新增知识</button>
        <button class="btn btn-sm btn-outline" @click="showImport = true">📥 批量导入</button>
      </div>
    </div>

    <!-- 表格 -->
    <div class="table-responsive">
      <table class="km-table">
        <thead>
          <tr>
            <th>ID</th><th>标题</th><th>知识库</th><th>车型</th><th>来源</th>
            <th>浏览</th><th>状态</th><th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="row in items" :key="row.id">
            <td>{{ row.id }}</td>
            <td class="km-title-cell">{{ row.title }}</td>
            <td><span class="km-tag">{{ kbLabel[row.knowledge_base] || row.knowledge_base }}</span></td>
            <td>{{ row.car_brand || '-' }}{{ row.car_model ? ' ' + row.car_model : '' }}</td>
            <td>{{ row.source_person || '-' }}</td>
            <td>{{ row.view_count }}</td>
            <td><span :style="statusStyle[row.status] || ''">{{ statusLabel[row.status] || row.status }}</span></td>
            <td class="km-ops">
              <button class="btn btn-sm btn-outline" @click="openEdit(row)">编辑</button>
              <select @change="(e: any) => changeStatus(row.id, e.target.value)" class="form-input" style="width:auto;font-size:11px;padding:2px 4px">
                <option value="">变更状态</option>
                <option value="approved">通过</option>
                <option value="rejected">驳回</option>
                <option value="archived">归档</option>
              </select>
            </td>
          </tr>
          <tr v-if="!loading && items.length === 0">
            <td colspan="8" style="text-align:center;padding:40px;color:var(--text-sub)">暂无数据</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="km-pager" v-if="total > 20">
      <button :disabled="page<=1" @click="page--;fetchList()" class="btn btn-sm btn-outline">上一页</button>
      <span>{{ page }} / {{ Math.ceil(total/20) }}</span>
      <button :disabled="page>=Math.ceil(total/20)" @click="page++;fetchList()" class="btn btn-sm btn-outline">下一页</button>
    </div>

    <!-- 编辑弹窗 -->
    <Teleport to="body">
      <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
        <div class="modal-panel">
          <div class="modal-header">
            <h3>{{ isEdit ? '编辑知识' : '新增知识' }}</h3>
            <button @click="showForm = false" class="btn btn-sm">×</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label>标题</label>
              <input v-model="editing.title" class="form-input" style="width:100%" />
            </div>
            <div class="form-group">
              <label>知识库</label>
              <select v-model="editing.knowledge_base" class="form-input" style="width:100%">
                <option value="public">公共通用</option>
                <option value="sales">销售专属</option>
                <option value="tech">技术服务</option>
                <option value="service">售后客服</option>
              </select>
            </div>
            <div class="form-group">
              <label>分类</label>
              <select v-model="editing.category_id" class="form-input" style="width:100%">
                <option v-for="c in categories.filter(x => x.knowledge_base === editing.knowledge_base)" :key="c.id" :value="c.id">{{ c.icon }} {{ c.name }}</option>
              </select>
            </div>
            <div class="form-group">
              <label>内容（支持 Markdown）</label>
              <textarea v-model="editing.content" class="form-input" style="width:100%;min-height:200px" placeholder="知识正文..."></textarea>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>标签（用 / 分隔）</label>
                <input v-model="editing.tags" class="form-input" style="width:100%" placeholder="如: 星瑞/新能源/续航" />
              </div>
              <div class="form-group">
                <label>难度(1-5)</label>
                <input v-model.number="editing.difficulty_level" type="number" min="1" max="5" class="form-input" style="width:80px" />
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>品牌</label>
                <input v-model="editing.car_brand" class="form-input" style="width:100%" />
              </div>
              <div class="form-group">
                <label>车型</label>
                <input v-model="editing.car_model" class="form-input" style="width:100%" />
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-outline" @click="showForm = false">取消</button>
            <button class="btn" @click="saveForm">{{ isEdit ? '保存修改' : '创建知识' }}</button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- 批量导入弹窗 -->
    <Teleport to="body">
      <div v-if="showImport" class="modal-overlay" @click.self="showImport = false">
        <div class="modal-panel">
          <div class="modal-header">
            <h3>批量导入知识</h3>
            <button @click="showImport = false" class="btn btn-sm">×</button>
          </div>
          <div class="modal-body">
            <p class="import-hint">支持 PDF / Word / Excel 文件，系统自动提取文本。上传后请确认内容再入库。</p>
            <div class="form-group">
              <label>选择文件</label>
              <input type="file" accept=".pdf,.docx,.xlsx" @change="onFileChange" class="form-input" style="width:100%" />
            </div>
            <button class="btn btn-sm" @click="doImport" :disabled="!importFile || importLoading" style="margin-top:8px">
              {{ importLoading ? '解析中...' : '上传并解析' }}
            </button>
            <div class="form-group" style="margin-top:12px" v-if="importText">
              <label>解析结果（可编辑后入库）</label>
              <textarea v-model="importText" class="form-input" style="width:100%;min-height:200px;font-size:12px"></textarea>
            </div>
            <div class="form-group" style="margin-top:8px" v-if="importText">
              <label>目标分类</label>
              <select v-model="editing.category_id" class="form-input" style="width:100%">
                <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.icon }} {{ c.name }} ({{ kbLabel[c.knowledge_base] }})</option>
              </select>
            </div>
          </div>
          <div class="modal-footer" v-if="importText">
            <button class="btn btn-outline" @click="showImport = false">取消</button>
            <button class="btn" @click="createFromImport">确认入库</button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.km-page { max-width: 1200px; margin: 0 auto; }

.km-toolbar {
  display: flex; justify-content: space-between; align-items: center;
  gap: 12px; margin-bottom: 16px; flex-wrap: wrap;
}
.km-search { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.km-actions { display: flex; gap: 8px; }

.km-table {
  width: 100%; border-collapse: collapse; font-size: 13px;
  background: var(--bg-card); border-radius: 8px; overflow: hidden;
}
.km-table th, .km-table td {
  padding: 10px 12px; text-align: left;
  border-bottom: 1px solid var(--border);
}
.km-table th {
  background: var(--bg-main); font-weight: 600;
  color: var(--text-sub); font-size: 12px;
}
.km-title-cell { max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.km-tag {
  padding: 2px 8px; border-radius: 10px; font-size: 11px;
  background: var(--primary); color: #fff;
}
.km-ops { display: flex; gap: 4px; align-items: center; white-space: nowrap; }

.km-pager { display: flex; justify-content: center; align-items: center; gap: 12px; margin-top: 16px; }

/* 弹窗 */
.modal-overlay {
  position: fixed; inset: 0; z-index: 8500;
  background: rgba(0,0,0,0.4); display: flex; align-items: center; justify-content: center;
}
.modal-panel {
  width: 640px; max-width: 95vw; max-height: 90vh;
  background: var(--bg-card); border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.2);
  display: flex; flex-direction: column;
}
.modal-header {
  display: flex; justify-content: space-between; align-items: center;
  padding: 16px 20px; border-bottom: 1px solid var(--border);
}
.modal-header h3 { margin: 0; font-size: 16px; }
.modal-body { padding: 20px; overflow-y: auto; flex: 1; }
.modal-footer {
  display: flex; justify-content: flex-end; gap: 8px;
  padding: 12px 20px; border-top: 1px solid var(--border);
}
.form-group { margin-bottom: 12px; }
.form-group label { display: block; font-size: 13px; color: var(--text-sub); margin-bottom: 4px; }
.form-row { display: flex; gap: 12px; }
.form-row .form-group { flex: 1; }
.import-hint { font-size: 13px; color: var(--text-sub); margin-bottom: 12px; }

@media (max-width: 768px) {
  .km-toolbar { flex-direction: column; }
  .km-search { width: 100%; }
  .km-search input { flex: 1; min-width: 0; }
  .km-ops { flex-direction: column; }
  .form-row { flex-direction: column; }
}
</style>
