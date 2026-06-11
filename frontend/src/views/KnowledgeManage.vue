<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import axios from 'axios'

const auth = useAuthStore()
const router = useRouter()

interface KnowledgeItem {
  id: number; title: string; content: string; tags: string | null
  car_brand: string | null; car_model: string | null
  knowledge_base: string; category_id: number
  view_count: number; useful_count: number; difficulty_level: number
  source_person: string | null; status: string
  created_at: string | null; updated_at: string | null; content_type: string
}
interface Category { id: number; name: string; knowledge_base: string; icon: string | null; knowledge_count?: number; question_count?: number }

const activeTab = ref<'browse' | 'manage'>('browse')

// 非管理员强制停留在浏览 Tab
function switchTab(tab: 'browse' | 'manage') {
  if (tab === 'manage' && !auth.isAdmin) return
  activeTab.value = tab
}

const items = ref<KnowledgeItem[]>([])
const total = ref(0)
const page = ref(1)
const loading = ref(false)
const keyword = ref('')
const statusFilter = ref('')
const categories = ref<Category[]>([])
const showForm = ref(false)
const editing = ref<Partial<KnowledgeItem> & { content?: string }>({})
const isEdit = ref(false)

// 批量导入
const showImport = ref(false)
const importFile = ref<File | null>(null)
const importLoading = ref(false)
const importSteps = ref<{step:string,status:string,detail:string}[]>([])
const importDone = ref(false)
const importText = ref('')
const showReview = ref(false)
const draftQuestions = ref<any[]>([])
const aiQuestionResult = ref('')
const questionTotal = ref(0)
const confirmDone = ref(false)  // 入库完成后显示最终结果

// 解析上传文件（停在第4步，不做AI拆题）
async function smartImport() {
  if (!importFile.value || !auth.token) return
  importLoading.value = true; importDone.value = false; showReview.value = false; confirmDone.value = false
  importSteps.value = []; aiQuestionResult.value = ''; draftQuestions.value = []; importText.value = ''
  try {
    const fd = new FormData(); fd.append('file', importFile.value)
    fd.append('category_id', String(editing.value.category_id || 0))
    fd.append('knowledge_base', editing.value.knowledge_base || 'public')
    fd.append('question_count', '0')  // 设为0，不让后端自动拆题
    const { data } = await axios.post('/api/upload/smart-import', fd)
    const d = data.data
    importSteps.value = d.steps || []
    importText.value = d.extracted_text || ''
    importDone.value = true
  } catch (e: any) {
    importSteps.value = [{ step: 'error', status: 'fail', detail: '❌ ' + (e.response?.data?.detail || e.message) }]
  } finally { importLoading.value = false }
}

// AI 拆分 —— 对已解析的文案执行拆题
async function aiSplitOnly() {
  if (!importText.value.trim()) return
  importLoading.value = true; aiQuestionResult.value = ''
  importSteps.value.push({ step: 'ai_split', status: 'progress', detail: '⏳ AI 正在分析文案，拆解知识点...' })
  try {
    const { data } = await axios.post('/api/questions/batch-ai-generate', {
      content_text: importText.value,
      target_position: editing.value.knowledge_base === 'sales' ? 'sales' : editing.value.knowledge_base === 'tech' ? 'tech' : editing.value.knowledge_base === 'service' ? 'service' : '',
      count: 10,
    })
    if (data.code === 0 && data.data.drafts?.length) {
      draftQuestions.value = data.data.drafts.map((q: any) => ({
        ...q, question_type: q.question_type || 'single_choice',
        options: q.options && typeof q.options === 'object' ? q.options : {A:'',B:'',C:'',D:''},
        answer: q.answer || 'A', difficulty_level: q.difficulty_level || 2, _selected: true,
      }))
      showReview.value = true
      importSteps.value = importSteps.value.filter(s => s.step !== 'ai_split')
      importSteps.value.push({ step: 'ai_split', status: 'ok', detail: `✅ AI拆分完成，生成 ${data.data.drafts.length} 道试题草稿` })
    } else {
      importSteps.value.push({ step: 'ai_split', status: 'fail', detail: '❌ AI出题失败，请确认LLM模型配置' })
    }
  } catch (e: any) {
    importSteps.value.push({ step: 'ai_split', status: 'fail', detail: '❌ ' + (e.response?.data?.detail || e.message) })
  } finally { importLoading.value = false }
}

const kbLabel: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }
const statusLabel: Record<string, string> = { draft: '草稿', pending: '待审', approved: '已通过', rejected: '已驳回', archived: '已归档' }
const statusStyle: Record<string, string> = {
  approved: 'color: var(--success)', rejected: 'color: var(--danger)',
  pending: 'color: var(--accent)', archived: 'color: var(--text-sub)',
}

// ===== 浏览 Tab =====
interface UnifiedItem {
  id: number; title: string; content: string
  knowledge_base: string; category_id: number
  view_count: number; difficulty_level: number
  tags: string | null; created_at: string | null
  item_type: 'knowledge' | 'question'
  question_type?: string
}
const browseItems = ref<UnifiedItem[]>([])
const browseTotal = ref(0)
const browseKeyword = ref('')
const browseSelectedKb = ref('')
const browseSelectedCat = ref(0)
const browseItemType = ref('all')
const browseLoading = ref(false)

const kbList = computed(() => {
  const pos = auth.user?.position
  if (auth.isAdmin) return ['public','sales','tech','service']
  if (pos === 'sales') return ['public','sales']
  if (pos === 'tech') return ['public','tech']
  if (pos === 'service') return ['public','service']
  return ['public']
})

async function fetchBrowseItems() {
  browseLoading.value = true
  try {
    const params: any = { page_size: 20, item_type: browseItemType.value }
    if (browseKeyword.value) params.keyword = browseKeyword.value
    if (browseSelectedKb.value) params.knowledge_base = browseSelectedKb.value
    if (browseSelectedCat.value > 0) params.category_id = browseSelectedCat.value
    const { data } = await axios.get('/api/knowledge/unified', { params })
    browseItems.value = data.data.items; browseTotal.value = data.data.total
  } finally { browseLoading.value = false }
}
function browseSearch() { fetchBrowseItems() }
function selectBrowseKb(kb: string) { browseSelectedKb.value = browseSelectedKb.value === kb ? '' : kb; browseSelectedCat.value = 0; fetchBrowseItems() }
function selectBrowseCat(id: number) { browseSelectedCat.value = browseSelectedCat.value === id ? 0 : id; fetchBrowseItems() }
function goBrowseDetail(item: UnifiedItem) {
  if (item.item_type === 'question') router.push('/question')
  else router.push(`/knowledge/${item.id}`)
}
function difficultyDots(n: number) { return '★'.repeat(n) + '☆'.repeat(5 - n) }
function typeLabel(t: string) { const m: Record<string,string> = { single_choice:'单选', multi_choice:'多选', true_false:'判断', fill_blank:'填空' }; return m[t] || t }

async function fetchCategories() { const { data } = await axios.get('/api/categories'); categories.value = data.data }
async function fetchList() {
  loading.value = true
  try {
    const params: any = { page: page.value, page_size: 20, sort_by: 'created_at' }
    if (keyword.value) params.keyword = keyword.value
    const { data } = await axios.get('/api/knowledge', { params })
    let all = data.data.items || []
    if (statusFilter.value) all = all.filter((i: any) => i.status === statusFilter.value)
    items.value = all; total.value = data.data.total
  } finally { loading.value = false }
}
function search() { page.value = 1; fetchList() }
function openCreate() {
  isEdit.value = false
  editing.value = { title: '', content: '', category_id: 0, knowledge_base: 'public', tags: '', car_brand: '', car_model: '', difficulty_level: 1 }
  showForm.value = true
}
function openEdit(item: KnowledgeItem) { isEdit.value = true; editing.value = { ...item }; showForm.value = true }
async function saveForm() {
  const body: any = {
    title: editing.value.title, content: editing.value.content,
    category_id: editing.value.category_id || categories.value[0]?.id || 1,
    knowledge_base: editing.value.knowledge_base, tags: editing.value.tags,
    car_brand: editing.value.car_brand, car_model: editing.value.car_model,
    difficulty_level: editing.value.difficulty_level || 1,
  }
  isEdit.value && editing.value.id ? await axios.put(`/api/knowledge/${editing.value.id}`, body) : await axios.post('/api/knowledge', body)
  showForm.value = false; fetchList()
}
async function changeStatus(id: number, status: string) { await axios.put(`/api/knowledge/${id}/status?status=${status}`); fetchList() }

function onFileChange(e: Event) { const inp = e.target as HTMLInputElement; importFile.value = inp.files?.[0] || null }


async function confirmReviewDrafts() {
  const selected = draftQuestions.value.filter((d: any) => d._selected).map(({ _selected, ...r }: any) => r)
  if (!selected.length) { aiQuestionResult.value = '❌ 请至少勾选一道题目'; return }
  try {
    const { data } = await axios.post('/api/questions/batch-import', { questions: selected })
    questionTotal.value += data.data.inserted
    showReview.value = false; draftQuestions.value = []
    importSteps.value.push({ step: 'confirmed', status: 'ok', detail: `✅ 人工确认入库 ${data.data.inserted} 题` })
    aiQuestionResult.value = `✅ 已成功入库 ${data.data.inserted} 道题目`
    confirmDone.value = true  // 切换到完成界面
    try { const r = await axios.get('/api/questions/stats'); questionTotal.value = r.data.data.total } catch {/* */}
    fetchList()
  } catch (e: any) { aiQuestionResult.value = '❌ ' + (e.response?.data?.detail || e.message) }
}

onMounted(async () => {
  if (!auth.isAdmin) activeTab.value = 'browse'
  await fetchCategories(); fetchList(); fetchBrowseItems()
  try { const { data } = await axios.get('/api/questions/stats'); questionTotal.value = data.data.total } catch { /* ignore */ }
})
</script>

<template>
  <div class="km-page">
    <!-- Tab 切换 -->
    <div class="km-tabs">
      <button :class="{ active: activeTab === 'browse' }" @click="switchTab('browse')">📖 知识浏览</button>
      <button v-if="auth.isAdmin" :class="{ active: activeTab === 'manage' }" @click="switchTab('manage')">⚙️ 知识管理</button>
      <span style="margin-left:auto;font-size:12px;color:var(--text-sub)">知识 {{ total }} 条 · 题库 {{ questionTotal }} 题</span>
      <button v-if="auth.isAdmin" class="btn btn-sm btn-outline" @click="showImport = true" style="margin-left:8px">📥 批量导入</button>
    </div>

    <!-- ==================== 浏览 Tab ==================== -->
    <div v-if="activeTab === 'browse'" class="km-browse">
      <div class="kb-toolbar">
        <form @submit.prevent="browseSearch" class="kb-search">
          <input v-model="browseKeyword" placeholder="搜索知识或试题…" class="form-input" style="flex:1" />
          <select v-model="browseItemType" @change="browseSearch" class="form-input" style="width:auto;font-size:12px">
            <option value="all">全部</option><option value="knowledge">仅知识</option><option value="question">仅试题</option>
          </select>
          <button type="submit" class="btn btn-sm">搜索</button>
        </form>
        <div class="kb-tags">
          <button :class="{ active: !browseSelectedKb }" @click="selectBrowseKb('')">全部</button>
          <button v-for="kb in kbList" :key="kb" :class="{ active: browseSelectedKb === kb }" @click="selectBrowseKb(kb)">{{ kb === 'public' ? '公共' : kb === 'sales' ? '销售' : kb === 'tech' ? '技术' : '客服' }}</button>
        </div>
      </div>
      <div class="kb-cat-row">
        <button v-for="c in categories.filter(x => kbList.includes(x.knowledge_base))" :key="c.id"
          class="kb-cat-chip" :class="{ active: browseSelectedCat === c.id }"
          @click="selectBrowseCat(c.id)">
          {{ c.icon }} {{ c.name }}
        </button>
      </div>
      <div class="kb-list-head" style="font-size:12px;color:var(--text-sub);margin-bottom:8px">共 {{ browseTotal }} 条</div>
      <div v-if="browseLoading" class="kb-loading">加载中...</div>
      <div v-else class="kb-result-list">
        <article v-for="item in browseItems" :key="item.item_type + '-' + item.id" class="kb-card card" @click="goBrowseDetail(item)">
          <div class="kb-card-header">
            <h3>{{ item.title }}</h3>
            <div class="kb-badges">
              <span v-if="item.item_type === 'knowledge'" class="kb-badge kb-badge-doc">📄 知识</span>
              <span v-else class="kb-badge kb-badge-q">❓ 试题 · {{ typeLabel(item.question_type || '') }}</span>
              <span class="kb-badge kb-badge-kb">{{ item.knowledge_base === 'public' ? '公共' : item.knowledge_base === 'sales' ? '销售' : item.knowledge_base === 'tech' ? '技术' : '客服' }}</span>
            </div>
          </div>
          <p class="kb-card-desc">{{ item.content }}</p>
          <div class="kb-card-meta">
            <span v-if="item.tags" class="kb-card-tags">{{ item.tags }}</span>
            <span v-if="item.view_count > 0">👁 {{ item.view_count }}</span>
            <span>{{ difficultyDots(item.difficulty_level) }}</span>
          </div>
        </article>
        <div v-if="browseItems.length === 0" class="kb-empty">暂无内容</div>
      </div>
    </div>

    <!-- ==================== 管理 Tab ==================== -->
    <div v-if="activeTab === 'manage'">
      <div class="km-toolbar">
        <form @submit.prevent="search" class="km-search">
          <input v-model="keyword" placeholder="搜索知识..." class="form-input" style="width:240px" />
          <select v-model="statusFilter" @change="search" class="form-input" style="width:auto">
            <option value="">全部状态</option><option value="approved">已通过</option>
            <option value="pending">待审核</option><option value="rejected">已驳回</option><option value="archived">已归档</option>
          </select>
          <button type="submit" class="btn btn-sm">搜索</button>
        </form>
        <div class="km-actions">
          <button v-if="auth.isAdmin" class="btn btn-sm" @click="openCreate">+ 新增知识</button>
        </div>
      </div>

      <div class="table-responsive">
      <table class="km-table"><thead><tr><th>ID</th><th>标题</th><th>知识库</th><th>车型</th><th>来源</th><th>浏览</th><th>状态</th><th>操作</th></tr></thead>
        <tbody>
          <tr v-for="row in items" :key="row.id">
            <td>{{ row.id }}</td><td class="km-title-cell">{{ row.title }}</td>
            <td><span class="km-tag">{{ kbLabel[row.knowledge_base] || row.knowledge_base }}</span></td>
            <td>{{ row.car_brand || '-' }}{{ row.car_model ? ' ' + row.car_model : '' }}</td>
            <td>{{ row.source_person || '-' }}</td><td>{{ row.view_count }}</td>
            <td><span :style="statusStyle[row.status] || ''">{{ statusLabel[row.status] || row.status }}</span></td>
            <td class="km-ops">
              <button class="btn btn-sm btn-outline" @click="openEdit(row)">编辑</button>
              <select @change="(e: any) => changeStatus(row.id, e.target.value)" class="form-input" style="width:auto;font-size:11px;padding:2px 4px">
                <option value="">变更状态</option><option value="approved">通过</option><option value="rejected">驳回</option><option value="archived">归档</option>
              </select>
            </td>
          </tr>
          <tr v-if="!loading && items.length === 0"><td colspan="8" style="text-align:center;padding:40px;color:var(--text-sub)">暂无数据</td></tr>
        </tbody>
      </table>
    </div>
    <div class="km-pager" v-if="total > 20">
      <button :disabled="page<=1" @click="page--;fetchList()" class="btn btn-sm btn-outline">上一页</button>
      <span>{{ page }} / {{ Math.ceil(total/20) }}</span>
      <button :disabled="page>=Math.ceil(total/20)" @click="page++;fetchList()" class="btn btn-sm btn-outline">下一页</button>
    </div>
    </div><!-- /manage tab -->

    <!-- 编辑弹窗 -->
    <Teleport to="body">
      <div v-if="showForm" class="modal-overlay" @click.self="showForm=false"><div class="modal-panel">
        <div class="modal-header"><h3>{{ isEdit ? '编辑' : '新增' }}知识</h3><button @click="showForm=false" class="btn btn-sm">×</button></div>
        <div class="modal-body">
          <div class="form-group"><label>标题</label><input v-model="editing.title" class="form-input" style="width:100%" /></div>
          <div class="form-group"><label>知识库</label><select v-model="editing.knowledge_base" class="form-input" style="width:100%"><option value="public">公共</option><option value="sales">销售</option><option value="tech">技术</option><option value="service">客服</option></select></div>
          <div class="form-group"><label>分类</label><select v-model="editing.category_id" class="form-input" style="width:100%"><option v-for="c in categories.filter(x => x.knowledge_base === editing.knowledge_base)" :key="c.id" :value="c.id">{{ c.icon }} {{ c.name }}</option></select></div>
          <div class="form-group"><label>内容</label><textarea v-model="editing.content" class="form-input" style="width:100%;min-height:200px"></textarea></div>
          <div class="form-row"><div class="form-group"><label>标签</label><input v-model="editing.tags" class="form-input" style="width:100%" /></div><div class="form-group"><label>难度</label><input v-model.number="editing.difficulty_level" type="number" min="1" max="5" class="form-input" style="width:80px" /></div></div>
          <div class="form-row"><div class="form-group"><label>品牌</label><input v-model="editing.car_brand" class="form-input" style="width:100%" /></div><div class="form-group"><label>车型</label><input v-model="editing.car_model" class="form-input" style="width:100%" /></div></div>
        </div>
        <div class="modal-footer"><button class="btn btn-outline" @click="showForm=false">取消</button><button class="btn" @click="saveForm">{{ isEdit ? '保存' : '创建' }}</button></div>
      </div></div>
    </Teleport>

    <!-- 批量导入弹窗 -->
    <Teleport to="body">
      <div v-if="showImport" class="modal-overlay" @click.self="showImport = false">
        <div class="modal-panel-big">
          <div class="modal-header">
            <h3>📥 批量智能导入</h3>
            <button @click="showImport = false" class="btn btn-sm">×</button>
          </div>
          <div class="modal-body">

            <!-- 选择文件 + 解析 -->
            <div style="display:flex;gap:10px;margin-bottom:10px;align-items:flex-end">
              <div class="form-group" style="flex:1"><label>选择文件（PDF/Word/Excel）</label><input type="file" accept=".pdf,.docx,.xlsx" @change="onFileChange" class="form-input" style="width:100%" /></div>
              <div class="form-group" style="width:110px"><label>目标岗位</label><select v-model="editing.knowledge_base" class="form-input" style="width:100%"><option value="public">公共</option><option value="sales">销售</option><option value="tech">技术</option><option value="service">客服</option></select></div>
              <div class="form-group" style="width:160px"><label>目标分类</label><select v-model="editing.category_id" class="form-input" style="width:100%"><option :value="0">自动匹配</option><option v-for="c in categories" :key="c.id" :value="c.id">{{ c.icon }} {{ c.name }}</option></select></div>
              <div class="form-group"><button class="btn" @click="smartImport" :disabled="!importFile || importLoading" style="padding:10px 20px;font-size:14px;white-space:nowrap">
                {{ importLoading ? '⏳ 解析中...' : '📄 解析上传文件' }}
              </button></div>
            </div>
            <!-- AI 拆题按钮（解析完成后才可点击） -->
            <div v-if="importSteps.length && importDone && !confirmDone" style="margin-bottom:14px">
              <button class="btn" @click="aiSplitOnly" :disabled="importLoading" style="padding:10px 20px;font-size:14px;background:var(--accent)">
                {{ importLoading ? '⏳ AI拆分中...' : '🤖 AI拆分【执行对上传文案的拆题】' }}
              </button>
              <span style="margin-left:10px;font-size:12px;color:var(--text-sub)">已将文本解析完成，点击AI拆分生成试题草稿</span>
            </div>

            <!-- 处理步骤 -->
            <div v-if="importSteps.length && !confirmDone" class="smart-steps">
              <div v-for="(s,i) in importSteps" :key="i" class="smart-step" :class="'step-' + s.status">
                <span class="step-icon">{{ s.status === 'ok' ? '✅' : s.status === 'skip' ? '⏭' : s.status === 'fail' ? '❌' : '⏳' }}</span>
                <span class="step-detail">{{ s.detail }}</span>
              </div>
            </div>

            <!-- AI 复核面板 -->
            <div v-if="showReview && draftQuestions.length" class="review-section">
              <div class="review-head">
                <span><b>📋 AI 生成了 {{ draftQuestions.length }} 道试题草稿</b>，请逐题复核</span>
                <div class="review-head-actions">
                  <button class="btn btn-sm btn-outline" @click="draftQuestions.forEach(d => d._selected = true)">全选</button>
                  <button class="btn btn-sm btn-outline" @click="draftQuestions.forEach(d => d._selected = false)">取消</button>
                </div>
              </div>
              <div class="review-grid">
                <div v-for="(d, idx) in draftQuestions" :key="idx" class="review-card" :class="{ selected: d._selected }">
                  <div class="rc-top">
                    <label class="rc-check"><input type="checkbox" v-model="d._selected" /><b>{{ idx + 1 }}</b></label>
                    <select v-model="d.question_type" class="form-input" style="width:80px;font-size:11px;padding:2px 4px"><option value="single_choice">单选</option><option value="multi_choice">多选</option><option value="true_false">判断</option><option value="fill_blank">填空</option></select>
                    <input v-model.number="d.difficulty_level" type="number" min="1" max="5" class="form-input" style="width:50px;font-size:11px;padding:2px 4px" title="难度" />
                  </div>
                  <textarea v-model="d.question_content" class="form-input" style="width:100%;min-height:50px;font-size:12px;margin-bottom:6px" rows="2"></textarea>
                  <div v-if="d.question_type === 'single_choice' || d.question_type === 'multi_choice'" class="rc-opts">
                    <div v-for="k in ['A','B','C','D']" :key="k" class="rc-opt-row"><span class="rc-opt-key">{{ k }}</span><input v-model="d.options[k]" class="form-input" style="flex:1;font-size:12px" /></div>
                  </div>
                  <div class="rc-ans">
                    <div class="form-group" style="flex:1"><label>答案</label><input v-model="d.answer" class="form-input" style="width:100%;font-size:12px" /></div>
                    <div class="form-group" style="flex:2"><label>解析</label><input v-model="d.explanation" class="form-input" style="width:100%;font-size:12px" /></div>
                  </div>
                </div>
              </div>
              <div v-if="aiQuestionResult" class="ai-import-msg" :class="aiQuestionResult.startsWith('✅') ? 'ok' : 'err'">{{ aiQuestionResult }}</div>
            </div>

            <!-- 入库完成 -->
            <div v-if="confirmDone && importSteps.length" class="confirm-done" style="padding: 30px 20px; text-align: center;">
              <div style="font-size: 48px; margin-bottom: 12px;">✅</div>
              <h3 style="font-size: 18px; margin-bottom: 8px; color: var(--text-main)">试题入库完成</h3>
              <p style="font-size: 14px; color: var(--text-sub); margin-bottom: 6px;">{{ aiQuestionResult }}</p>
              <div style="margin: 16px 0;"><b>处理摘要：</b></div>
              <div class="smart-steps" style="text-align: left; max-width: 500px; margin: 0 auto;">
                <div v-for="(s,i) in importSteps" :key="i" class="smart-step" :class="'step-' + s.status">
                  <span class="step-icon">{{ s.status === 'ok' ? '✅' : s.status === 'skip' ? '⏭' : '❌' }}</span>
                  <span class="step-detail">{{ s.detail }}</span>
                </div>
              </div>
              <button class="btn" @click="showImport = false" style="margin-top: 20px; padding: 10px 40px; font-size: 15px;">关闭</button>
            </div>

          </div>
          <div class="modal-footer" v-if="!confirmDone">
            <button class="btn btn-outline" @click="showImport = false">关闭</button>
            <button v-if="showReview && draftQuestions.length" class="btn" @click="confirmReviewDrafts" style="background:var(--accent);font-size:14px;padding:8px 20px">
              ✅ 确认入库（{{ draftQuestions.filter((d:any)=>d._selected).length }} 题）
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.km-page { max-width: 1200px; margin: 0 auto; }
/* Tabs */
.km-tabs { display: flex; gap: 0; margin-bottom: 16px; align-items: center; }
.km-tabs button {
  padding: 8px 24px; border: 1px solid var(--border); background: var(--bg-card);
  font-size: 14px; cursor: pointer; color: var(--text-sub);
}
.km-tabs button:first-child { border-radius: 6px 0 0 6px; }
.km-tabs button:last-child { border-radius: 0 6px 6px 0; }
.km-tabs button.active { background: var(--primary); color: #fff; border-color: var(--primary); }

.km-toolbar { display: flex; justify-content: space-between; align-items: center; gap: 12px; margin-bottom: 16px; flex-wrap: wrap; }
.km-search { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.km-actions { display: flex; gap: 8px; align-items: center; }
.km-stat { padding: 4px 12px; border-radius: 14px; font-size: 12px; font-weight: 600; background: var(--bg-main); color: var(--primary); border: 1px solid var(--border); white-space: nowrap; }
.km-table { width: 100%; border-collapse: collapse; font-size: 13px; background: var(--bg-card); border-radius: 8px; overflow: hidden; }
.km-table th, .km-table td { padding: 10px 12px; text-align: left; border-bottom: 1px solid var(--border); }
.km-table th { background: var(--bg-main); font-weight: 600; color: var(--text-sub); font-size: 12px; }
.km-title-cell { max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.km-tag { padding: 2px 8px; border-radius: 10px; font-size: 11px; background: var(--primary); color: #fff; }
.km-ops { display: flex; gap: 4px; align-items: center; white-space: nowrap; }
.km-pager { display: flex; justify-content: center; align-items: center; gap: 12px; margin-top: 16px; }
.modal-overlay { position: fixed; inset: 0; z-index: 8500; background: rgba(0,0,0,0.4); display: flex; align-items: center; justify-content: center; }
.modal-panel { width: 640px; max-width: 95vw; max-height: 90vh; background: var(--bg-card); border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.2); display: flex; flex-direction: column; }
.modal-panel-big { width: 1100px; max-width: 97vw; max-height: 92vh; background: var(--bg-card); border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.25); display: flex; flex-direction: column; }
.modal-header { display: flex; justify-content: space-between; align-items: center; padding: 14px 18px; border-bottom: 1px solid var(--border); }
.modal-header h3 { margin: 0; font-size: 16px; }
.modal-body { padding: 16px 18px; overflow-y: auto; flex: 1; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 12px 18px; border-top: 1px solid var(--border); }
.form-group { margin-bottom: 10px; }
.form-group label { display: block; font-size: 12px; color: var(--text-sub); margin-bottom: 3px; }
.form-row { display: flex; gap: 12px; }
.form-row .form-group { flex: 1; }

.smart-steps { display: flex; flex-direction: column; gap: 6px; margin-bottom: 12px; }
.smart-step { display: flex; align-items: center; gap: 8px; padding: 8px 10px; border-radius: 6px; font-size: 13px; }
.smart-step.step-ok { background: rgba(122,166,104,0.08); }
.smart-step.step-skip { background: rgba(232,130,74,0.08); }
.smart-step.step-fail { background: rgba(192,64,59,0.08); color: var(--danger); }
.step-icon { font-size: 14px; flex-shrink: 0; }

.review-section { border-top: 2px solid var(--primary); padding-top: 14px; }
.review-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; flex-wrap: wrap; gap: 8px; font-size: 14px; }
.review-head-actions { display: flex; gap: 6px; }
.review-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(420px, 1fr)); gap: 10px; max-height: 55vh; overflow-y: auto; }
.review-card { padding: 12px; border: 1px solid var(--border); border-radius: 8px; background: var(--bg-card); }
.review-card.selected { border-color: var(--primary); background: var(--bg-main); }
.rc-top { display: flex; align-items: center; gap: 6px; margin-bottom: 8px; }
.rc-check { display: flex; align-items: center; gap: 4px; cursor: pointer; font-size: 14px; }
.rc-opts { margin-bottom: 6px; }
.rc-opt-row { display: flex; align-items: center; gap: 4px; margin-bottom: 3px; }
.rc-opt-key { width: 18px; font-weight: 700; font-size: 12px; color: var(--primary); text-align: center; }
.rc-ans { display: flex; gap: 8px; }
.rc-ans .form-group { margin-bottom: 0; flex: 1; }
.ai-import-msg { padding: 10px 12px; border-radius: 6px; font-size: 13px; margin-top: 10px; }
.ai-import-msg.ok { background: rgba(122,166,104,0.1); color: var(--success); border: 1px solid rgba(122,166,104,0.3); }
.ai-import-msg.err { background: rgba(192,64,59,0.08); color: var(--danger); border: 1px solid rgba(192,64,59,0.3); }

/* 浏览Tab */
.km-browse { max-width: 100%; }
.kb-toolbar { display: flex; gap: 10px; margin-bottom: 10px; align-items: center; flex-wrap: wrap; }
.kb-search { display: flex; gap: 8px; flex: 1; align-items: center; }
.kb-search input { flex: 1; min-width: 0; }
.kb-tags { display: flex; flex-wrap: wrap; gap: 4px; }
.kb-tags button { padding: 3px 10px; border: 1px solid var(--border); border-radius: 12px; font-size: 12px; background: none; color: var(--text-sub); cursor: pointer; }
.kb-tags button.active { background: var(--primary); color: #fff; border-color: var(--primary); }
.kb-cat-row { display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 12px; }
.kb-cat-chip { padding: 3px 10px; border: 1px solid var(--border); border-radius: 12px; font-size: 12px; background: none; color: var(--text-sub); cursor: pointer; white-space: nowrap; }
.kb-cat-chip.active { background: var(--accent); color: #fff; border-color: var(--accent); }
.kb-cat-chip:hover { border-color: var(--primary); }
.kb-list-head { margin-bottom: 8px; }
.kb-loading, .kb-empty { text-align: center; padding: 40px; color: var(--text-sub); }
.kb-result-list { display: flex; flex-direction: column; gap: 10px; }
.kb-card { padding: 14px 16px; cursor: pointer; transition: box-shadow 0.15s; }
.kb-card:hover { box-shadow: 0 4px 16px var(--shadow); }
.kb-card-header { display: flex; justify-content: space-between; align-items: flex-start; gap: 10px; }
.kb-card-header h3 { font-size: 15px; margin: 0; color: var(--text-main); line-height: 1.3; }
.kb-badges { display: flex; gap: 4px; flex-shrink: 0; flex-wrap: wrap; }
.kb-badge { padding: 2px 8px; border-radius: 8px; font-size: 11px; white-space: nowrap; }
.kb-badge-doc { background: var(--bg-main); color: var(--primary); border: 1px solid var(--border); }
.kb-badge-q { background: rgba(232,130,74,0.08); color: var(--accent); border: 1px solid rgba(232,130,74,0.3); }
.kb-badge-kb { background: var(--primary); color: #fff; }
.kb-card-desc { margin: 8px 0; font-size: 13px; color: var(--text-sub); line-height: 1.5; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.kb-card-meta { display: flex; flex-wrap: wrap; gap: 12px; font-size: 12px; color: var(--text-sub); }
.kb-card-tags { color: var(--accent); }

@media (max-width: 768px) {
  .km-toolbar { flex-direction: column; }
  .km-search { width: 100%; }
  .km-search input { flex: 1; min-width: 0; }
  .km-ops { flex-direction: column; }
  .form-row { flex-direction: column; }
  .review-grid { grid-template-columns: 1fr; }
  .modal-panel-big { width: 100vw; max-width: 100vw; }
}
</style>
