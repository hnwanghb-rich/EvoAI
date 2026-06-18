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

const activeTab = ref<'browse' | 'manage' | 'category'>('browse')

// 非管理员强制停留在浏览 Tab
function switchTab(tab: 'browse' | 'manage' | 'category') {
  if ((tab === 'manage' || tab === 'category') && !auth.isAdmin) return
  activeTab.value = tab
  if (tab === 'category') fetchCategoryTree()
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

// ===== 知识类别 Tab =====
interface CatTreeNode {
  id: number; name: string; parent_id: number | null; knowledge_base: string
  sort_order: number; icon: string | null; description: string | null
  is_active: boolean; knowledge_count: number; question_count: number
}
const categoryTree = ref<CatTreeNode[]>([])
const selectedCat = ref<CatTreeNode | null>(null)
const catExpanded = ref<Record<string, boolean>>({ public: true, sales: false, tech: false, service: false })
const showCatForm = ref(false)
const catEditing = ref<{ id?: number; name: string; parent_id: number | null; knowledge_base: string; icon: string; sort_order: number }>({ name: '', parent_id: null, knowledge_base: 'public', icon: '', sort_order: 0 })
const catFormMode = ref<'create' | 'edit'>('create')
const catSaving = ref(false)

const positionLabel: Record<string, string> = { public: '全部岗位', sales: '销售岗', tech: '技术岗', service: '客服岗' }

const treeRoots = computed(() => {
  const roots = ['public', 'sales', 'tech', 'service']
  return roots.map(kb => ({
    key: kb,
    label: kbLabel[kb],
    children: categoryTree.value.filter(c => c.knowledge_base === kb)
  }))
})

async function fetchCategoryTree() {
  try {
    const { data } = await axios.get('/api/categories/tree')
    categoryTree.value = data.data.items || []
  } catch { /* ignore */ }
}

function selectCat(cat: CatTreeNode) {
  selectedCat.value = cat
}

function toggleCatRoot(kb: string) {
  catExpanded.value[kb] = !catExpanded.value[kb]
}

function openCatCreate(kb: string, parentId: number | null = null) {
  catFormMode.value = 'create'
  catEditing.value = { name: '', parent_id: parentId, knowledge_base: kb, icon: '', sort_order: 0 }
  showCatForm.value = true
}

function openCatEdit(cat: CatTreeNode) {
  catFormMode.value = 'edit'
  catEditing.value = { id: cat.id, name: cat.name, parent_id: cat.parent_id, knowledge_base: cat.knowledge_base, icon: cat.icon || '', sort_order: cat.sort_order }
  showCatForm.value = true
}

async function saveCatForm() {
  const d = catEditing.value
  if (!d.name.trim()) return
  catSaving.value = true
  try {
    if (catFormMode.value === 'create') {
      await axios.post('/api/categories', { name: d.name, parent_id: d.parent_id, knowledge_base: d.knowledge_base, icon: d.icon || null, sort_order: d.sort_order })
    } else {
      await axios.put(`/api/categories/${d.id}`, { name: d.name, icon: d.icon || null, sort_order: d.sort_order })
    }
    showCatForm.value = false; selectedCat.value = null
    await fetchCategoryTree(); await fetchCategories()  // 刷新分类缓存
  } catch (e: any) { alert(e.response?.data?.detail || '保存失败') }
  finally { catSaving.value = false }
}

async function deleteCat(cat: CatTreeNode) {
  const msg = cat.knowledge_count > 0 || cat.question_count > 0
    ? `该分类下有 ${cat.knowledge_count} 条知识、${cat.question_count} 道试题，将【停用】而非删除，确认？`
    : `确定删除分类「${cat.name}」？`
  if (!confirm(msg)) return
  try {
    const { data } = await axios.delete(`/api/categories/${cat.id}`)
    alert(data.msg || (data.data.deleted ? '已删除' : '已停用'))
    selectedCat.value = null
    await fetchCategoryTree(); await fetchCategories()
  } catch (e: any) { alert(e.response?.data?.detail || '操作失败') }
}

// 视频导入进度（SSE 流式）
const videoProgressPct = ref(0)
const videoProgressStep = ref('')
const videoProgressDetail = ref('')
const videoProgressElapsed = ref(0)
const videoProgressEstTotal = ref(0)

function formatDuration(sec: number): string {
  if (sec <= 0) return '--'
  const m = Math.floor(sec / 60)
  const s = Math.floor(sec % 60)
  return m > 0 ? `${m}分${s}秒` : `${s}秒`
}

// 解析上传文件（先检测是否结构化试题 → 是则直接解析，否则需用户手动点AI拆分）
async function smartImport() {
  if (!importFile.value || !auth.token) return
  const isVideo = /\.(mp4|webm|mp3|wav)$/i.test(importFile.value.name)
  if (isVideo) {
    return smartImportVideo()
  }
  importLoading.value = true; importDone.value = false; showReview.value = false; confirmDone.value = false
  importSteps.value = []; aiQuestionResult.value = ''; draftQuestions.value = []; importText.value = ''; videoProgressPct.value = 0
  try {
    const fd = new FormData(); fd.append('file', importFile.value)
    fd.append('category_id', String(editing.value.category_id || 0))
    fd.append('knowledge_base', editing.value.knowledge_base || 'public')
    fd.append('question_count', '0')  // 设为0，不触发AI自动拆分
    const { data } = await axios.post('/api/upload/smart-import', fd)
    const d = data.data
    importSteps.value = d.steps || []
    importText.value = d.extracted_text || ''

    // 检测到结构化试题 → 直接进复核面板，无需手动点AI拆分
    if (d.direct_parse && d.drafts?.length) {
      draftQuestions.value = d.drafts.map((q: any) => ({
        ...q, question_type: q.question_type || 'single_choice',
        options: q.options && typeof q.options === 'object' ? q.options : {A:'',B:'',C:'',D:''},
        answer: q.answer || 'A', difficulty_level: q.difficulty_level || 2, _selected: true,
      }))
      showReview.value = true
    }
    importDone.value = true
  } catch (e: any) {
    importSteps.value = [{ step: 'error', status: 'fail', detail: '❌ ' + (e.response?.data?.detail || e.message) }]
  } finally { importLoading.value = false }
}

// 视频 SSE 流式导入 —— 实时进度条 + 预估时间
async function smartImportVideo() {
  if (!importFile.value || !auth.token) return
  importLoading.value = true; importDone.value = false; showReview.value = false; confirmDone.value = false
  importSteps.value = []; aiQuestionResult.value = ''; draftQuestions.value = []; importText.value = ''
  videoProgressPct.value = 0; videoProgressStep.value = ''; videoProgressDetail.value = ''
  videoProgressElapsed.value = 0; videoProgressEstTotal.value = 0

  const fd = new FormData(); fd.append('file', importFile.value)
  fd.append('category_id', String(editing.value.category_id || 0))
  fd.append('knowledge_base', editing.value.knowledge_base || 'public')

  try {
    const resp = await fetch('/api/upload/video-import-stream', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${auth.token}` },
      body: fd,
    })
    if (!resp.ok) {
      const txt = await resp.text()
      importSteps.value = [{ step: 'error', status: 'fail', detail: '❌ ' + txt }]
      importLoading.value = false
      return
    }

    const reader = resp.body!.getReader()
    const decoder = new TextDecoder()
    let buf = ''
    let done = false

    while (!done) {
      const result = await reader.read()
      done = result.done
      buf += decoder.decode(result.value, { stream: !done })

      // 解析 SSE 事件
      const lines = buf.split('\n')
      buf = lines.pop() || ''
      let eventType = ''
      for (const line of lines) {
        if (line.startsWith('event: ')) {
          eventType = line.slice(7).trim()
        } else if (line.startsWith('data: ') && eventType) {
          try {
            const evt = JSON.parse(line.slice(6))
            handleSSEEvent(eventType, evt)
          } catch { /* skip malformed */ }
          eventType = ''
        }
      }
    }
  } catch (e: any) {
    importSteps.value = [{ step: 'error', status: 'fail', detail: '❌ 连接中断: ' + (e.message || '未知') }]
  } finally {
    importLoading.value = false
  }
}

function handleSSEEvent(type: string, evt: any) {
  if (type === 'progress') {
    videoProgressStep.value = evt.step || ''
    videoProgressDetail.value = evt.detail || ''
    videoProgressPct.value = evt.pct || videoProgressPct.value
    videoProgressElapsed.value = evt.elapsed_sec || videoProgressElapsed.value
    videoProgressEstTotal.value = evt.estimated_total_sec || videoProgressEstTotal.value
    // 根据 step 名称推断状态: audio_fail/transcribe_fallback → fail
    const stepStatus = /_fail$|_fallback$|_error$/i.test(evt.step || '') ? 'fail' : 'ok'
    importSteps.value.push({ step: evt.step || 'progress', status: stepStatus, detail: evt.detail || '' })
  } else if (type === 'done') {
    videoProgressPct.value = 100
    importSteps.value.push({ step: 'done', status: 'ok', detail: evt.message || '处理完成' })
    if (evt.drafts?.length) {
      draftQuestions.value = evt.drafts.map((q: any) => ({
        ...q, question_type: q.question_type || 'single_choice',
        options: q.options && typeof q.options === 'object' ? q.options : {A:'',B:'',C:'',D:''},
        answer: q.answer || 'A', difficulty_level: q.difficulty_level || 2, _selected: true,
      }))
      showReview.value = true
    }
    importDone.value = true
    // 视频导入完成后，如果有 entry_ids，把文本留空让用户选 AI 拆分
    if (evt.entry_ids?.length) {
      importText.value = ''  // 视频无文本，需要用户手动触发AI拆分或直接关闭
    }
  } else if (type === 'error') {
    importSteps.value.push({ step: 'error', status: 'fail', detail: '❌ ' + (evt.detail || '未知错误') })
  }
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
      count: 0,  // 0=AI自行判断出题数量
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
      <button :class="{ active: activeTab === 'browse' }" @click="switchTab('browse')">≡ 知识浏览</button>
      <button v-if="auth.isAdmin" :class="{ active: activeTab === 'manage' }" @click="switchTab('manage')">⌖ 知识导入</button>
      <button v-if="auth.isAdmin" :class="{ active: activeTab === 'category' }" @click="switchTab('category')">▤ 知识类别</button>
      <span style="margin-left:auto;font-size:12px;color:var(--text-sub)">知识 {{ total }} 条 · 题库 {{ questionTotal }} 题</span>
      <button v-if="auth.isAdmin" class="btn btn-sm btn-outline" @click="showImport = true" style="margin-left:8px">▼ 批量导入</button>
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
              <span v-if="item.item_type === 'knowledge'" class="kb-badge kb-badge-doc">≡ 知识</span>
              <span v-else class="kb-badge kb-badge-q">◇ 试题 · {{ typeLabel(item.question_type || '') }}</span>
              <span class="kb-badge kb-badge-kb">{{ item.knowledge_base === 'public' ? '公共' : item.knowledge_base === 'sales' ? '销售' : item.knowledge_base === 'tech' ? '技术' : '客服' }}</span>
            </div>
          </div>
          <p class="kb-card-desc">{{ item.content }}</p>
          <div class="kb-card-meta">
            <span v-if="item.tags" class="kb-card-tags">{{ item.tags }}</span>
            <span v-if="item.view_count > 0">◁ {{ item.view_count }}</span>
            <span>{{ difficultyDots(item.difficulty_level) }}</span>
          </div>
        </article>
        <div v-if="browseItems.length === 0" class="kb-empty">暂无内容</div>
      </div>
    </div>

    <!-- ==================== 知识类别 Tab ==================== -->
    <div v-if="activeTab === 'category'" class="km-category">
      <div class="km-cat-layout">
        <!-- 左侧：分类树 -->
        <div class="km-cat-left">
          <div class="km-cat-tree">
            <div v-for="root in treeRoots" :key="root.key" class="tree-root">
              <div class="tree-root-header" @click="toggleCatRoot(root.key)">
                <span class="tree-arrow">{{ catExpanded[root.key] ? '▼' : '▶' }}</span>
                <span class="tree-root-icon">▤</span>
                <span class="tree-root-label">{{ root.label }}</span>
                <span class="tree-root-count">{{ root.children.length }} 个分类</span>
                <button class="btn btn-xs" @click.stop="openCatCreate(root.key)" title="新增分类">+</button>
              </div>
              <div v-if="catExpanded[root.key]" class="tree-children">
                <div v-for="cat in root.children" :key="cat.id"
                  class="tree-node"
                  :class="{ active: selectedCat?.id === cat.id, inactive: !cat.is_active }"
                  @click="selectCat(cat)">
                  <span class="tree-node-icon">{{ cat.icon || '◈' }}</span>
                  <span class="tree-node-name">{{ cat.name }}</span>
                  <span v-if="!cat.is_active" class="tree-disabled-tag">已停用</span>
                  <span class="tree-node-stats">{{ cat.knowledge_count }}知/{{ cat.question_count }}题</span>
                  <span class="tree-node-actions">
                    <button class="btn btn-xs btn-outline" @click.stop="openCatEdit(cat)" title="编辑">✎</button>
                    <button class="btn btn-xs btn-outline" @click.stop="deleteCat(cat)" title="删除">⊘</button>
                  </span>
                </div>
                <div v-if="root.children.length === 0" class="tree-empty">暂无分类，点击 + 新建</div>
              </div>
            </div>
          </div>
        </div>

        <!-- 右侧：分类详情 -->
        <div class="km-cat-right">
          <div class="km-cat-right-inner">
          <div v-if="selectedCat" class="cat-detail card">
            <h3 class="cat-detail-name">{{ selectedCat.icon || '◈' }} {{ selectedCat.name }}</h3>
            <div class="cat-detail-status">
              <span :class="selectedCat.is_active ? 'badge-active' : 'badge-disabled'">
                {{ selectedCat.is_active ? '◉ 启用中' : '⊘ 已停用' }}
              </span>
            </div>
            <div class="cat-detail-grid">
              <div class="cat-detail-item"><label>所属知识库</label><span>{{ kbLabel[selectedCat.knowledge_base] || selectedCat.knowledge_base }}</span></div>
              <div class="cat-detail-item"><label>对应岗位</label><span>{{ positionLabel[selectedCat.knowledge_base] || '全部' }}</span></div>
              <div class="cat-detail-item"><label>知识数量</label><span class="cat-stat-num">{{ selectedCat.knowledge_count }} 条</span></div>
              <div class="cat-detail-item"><label>试题数量</label><span class="cat-stat-num">{{ selectedCat.question_count }} 题</span></div>
            </div>
            <div v-if="selectedCat.description" class="cat-detail-desc">
              <label>描述</label><p>{{ selectedCat.description }}</p>
            </div>
            <div class="cat-detail-actions">
              <button class="btn btn-sm" @click="openCatEdit(selectedCat)">✎ 编辑</button>
              <button class="btn btn-sm btn-outline" @click="deleteCat(selectedCat)">⊘ {{ (selectedCat.knowledge_count > 0 || selectedCat.question_count > 0) ? '停用' : '删除' }}</button>
            </div>
          </div>
          <div v-else class="cat-detail-empty">
            <p>← 点击左侧分类查看详情</p>
          </div>
          </div>
        </div>
      </div>

      <!-- 新增/编辑分类弹窗 -->
      <Teleport to="body">
        <div v-if="showCatForm" class="modal-overlay" @click.self="showCatForm = false">
          <div class="modal-panel" style="width:480px">
            <div class="modal-header">
              <h3>{{ catFormMode === 'create' ? '新增' : '编辑' }}分类</h3>
              <button @click="showCatForm = false" class="btn btn-sm">×</button>
            </div>
            <div class="modal-body">
              <div class="form-group"><label>分类名称</label><input v-model="catEditing.name" class="form-input" style="width:100%" placeholder="输入分类名称" /></div>
              <div class="form-group"><label>所属知识库</label>
                <select v-model="catEditing.knowledge_base" class="form-input" style="width:100%" :disabled="catFormMode === 'edit'">
                  <option value="public">公共</option><option value="sales">销售</option><option value="tech">技术</option><option value="service">客服</option>
                </select>
              </div>
              <div class="form-group"><label>图标</label><input v-model="catEditing.icon" class="form-input" style="width:100%" placeholder="如 ◈" /></div>
              <div class="form-group"><label>排序</label><input v-model.number="catEditing.sort_order" type="number" class="form-input" style="width:100px" /></div>
            </div>
            <div class="modal-footer">
              <button class="btn btn-outline" @click="showCatForm = false">取消</button>
              <button class="btn" @click="saveCatForm" :disabled="catSaving">{{ catSaving ? '保存中...' : '保存' }}</button>
            </div>
          </div>
        </div>
      </Teleport>
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
            <h3>▼ 批量智能导入</h3>
            <button @click="showImport = false" class="btn btn-sm">×</button>
          </div>
          <div class="modal-body">

            <!-- 选择文件 + 解析 -->
            <div style="display:flex;gap:10px;margin-bottom:10px;align-items:flex-end">
              <div class="form-group" style="flex:1"><label>选择文件（PDF/Word/Excel/视频/音频）</label><input type="file" accept=".pdf,.docx,.xlsx,.mp4,.webm,.mp3,.wav" @change="onFileChange" class="form-input" style="width:100%" /></div>
              <div class="form-group" style="width:110px"><label>目标岗位</label><select v-model="editing.knowledge_base" class="form-input" style="width:100%"><option value="public">公共</option><option value="sales">销售</option><option value="tech">技术</option><option value="service">客服</option></select></div>
              <div class="form-group" style="width:160px"><label>目标分类</label><select v-model="editing.category_id" class="form-input" style="width:100%"><option :value="0">自动匹配</option><option v-for="c in categories.filter(x => x.knowledge_base === editing.knowledge_base)" :key="c.id" :value="c.id">{{ c.icon }} {{ c.name }}</option></select></div>
              <div class="form-group"><button class="btn" @click="smartImport" :disabled="!importFile || importLoading" style="padding:10px 20px;font-size:14px;white-space:nowrap">
                {{ importLoading ? '⏳ 解析中...' : '▼ 解析上传文件' }}
              </button></div>
            </div>
            <!-- AI 拆题按钮（解析完成后才可点击） -->
            <div v-if="importSteps.length && importDone && !confirmDone" style="margin-bottom:14px">
              <button class="btn" @click="aiSplitOnly" :disabled="importLoading" style="padding:10px 20px;font-size:14px;background:var(--accent)">
                {{ importLoading ? '⏳ AI拆分中...' : '⌘ AI拆分【执行对上传文案的拆题】' }}
              </button>
              <span style="margin-left:10px;font-size:12px;color:var(--text-sub)">已将文本解析完成，点击AI拆分生成试题草稿</span>
            </div>
            <!-- 视频/音频处理时间提示 -->
            <div v-if="importFile && /\.(mp4|webm|mp3|wav)$/i.test(importFile.name)" style="margin-bottom:10px;font-size:12px;color:var(--accent)">
              ⏱ 视频/音频将自动转写为文字后拆解试题，处理可能需要1-2分钟，请耐心等待
            </div>

            <!-- 视频/音频实时进度条 -->
            <div v-if="importLoading && videoProgressPct > 0" class="video-progress-bar">
              <div class="vpb-header">
                <span class="vpb-step">{{ videoProgressDetail || '处理中...' }}</span>
                <span class="vpb-pct">{{ videoProgressPct }}%</span>
              </div>
              <div class="vpb-track">
                <div class="vpb-fill" :style="{ width: videoProgressPct + '%' }"></div>
              </div>
              <div class="vpb-time">
                <span>⏱ 已耗时 {{ formatDuration(videoProgressElapsed) }}</span>
                <span v-if="videoProgressEstTotal > 0">
                  | 预估剩余 {{ formatDuration(Math.max(0, videoProgressEstTotal - videoProgressElapsed)) }}
                </span>
              </div>
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
                <span><b>▤ AI 生成了 {{ draftQuestions.length }} 道试题草稿</b>，请逐题复核</span>
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

/* 视频进度条 */
.video-progress-bar {
  margin-bottom: 14px; padding: 12px 14px;
  background: var(--bg-main); border: 1px solid var(--border); border-radius: 10px;
}
.vpb-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.vpb-step { font-size: 13px; font-weight: 500; color: var(--text-main); }
.vpb-pct { font-size: 20px; font-weight: 700; color: var(--primary); }
.vpb-track { height: 10px; background: var(--border); border-radius: 5px; overflow: hidden; margin-bottom: 8px; }
.vpb-fill {
  height: 100%; background: linear-gradient(90deg, var(--primary), #4A90D9);
  border-radius: 5px; transition: width 0.4s ease;
}
.vpb-time { font-size: 12px; color: var(--text-sub); display: flex; gap: 8px; }

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

/* 知识类别 Tab */
.km-category { max-width: 100%; }
.km-cat-layout { display: flex; gap: 20px; align-items: flex-start; }
.km-cat-left { width: 340px; flex-shrink: 0; }
.km-cat-right { flex: 1; min-width: 0; }
.km-cat-right-inner { position: fixed; top: 50%; left: calc(50vw + 180px); transform: translate(-50%, -50%); max-width: 520px; width: 100%; }
.km-cat-tree { border: 1px solid var(--border); border-radius: 10px; background: var(--bg-card); overflow: hidden; }
.tree-root { border-bottom: 1px solid var(--border); }
.tree-root:last-child { border-bottom: none; }
.tree-root-header {
  display: flex; align-items: center; gap: 6px; padding: 10px 12px;
  cursor: pointer; background: var(--bg-main); font-weight: 600; font-size: 13px;
  user-select: none; transition: background 0.15s;
}
.tree-root-header:hover { background: var(--border); }
.tree-arrow { font-size: 10px; width: 14px; text-align: center; color: var(--text-sub); }
.tree-root-icon { font-size: 16px; }
.tree-root-label { flex: 1; color: var(--text-main); }
.tree-root-count { font-size: 11px; color: var(--text-sub); }
.tree-children { padding: 2px 0; }
.tree-node {
  display: flex; align-items: center; gap: 6px; padding: 7px 12px 7px 28px;
  cursor: pointer; font-size: 13px; transition: background 0.12s; border-left: 3px solid transparent;
}
.tree-node:hover { background: var(--bg-main); }
.tree-node.active { background: rgba(var(--primary-rgb, 74, 144, 226), 0.08); border-left-color: var(--primary); }
.tree-node.inactive { opacity: 0.6; }
.tree-node-icon { font-size: 14px; flex-shrink: 0; }
.tree-node-name { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: var(--text-main); }
.tree-node-stats { font-size: 11px; color: var(--text-sub); white-space: nowrap; }
.tree-node-actions { display: none; gap: 2px; }
.tree-node:hover .tree-node-actions { display: flex; }
.tree-disabled-tag { font-size: 10px; padding: 1px 5px; border-radius: 6px; background: var(--danger); color: #fff; }
.tree-empty { padding: 14px; text-align: center; font-size: 12px; color: var(--text-sub); }

.cat-detail { padding: 20px; min-height: 200px; }
.cat-detail-name { margin: 0 0 12px; font-size: 18px; }
.cat-detail-status { margin-bottom: 16px; }
.badge-active { padding: 3px 12px; border-radius: 12px; font-size: 12px; background: rgba(122,166,104,0.1); color: var(--success); border: 1px solid rgba(122,166,104,0.3); }
.badge-disabled { padding: 3px 12px; border-radius: 12px; font-size: 12px; background: rgba(192,64,59,0.08); color: var(--danger); border: 1px solid rgba(192,64,59,0.3); }
.cat-detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 16px; }
.cat-detail-item label { display: block; font-size: 11px; color: var(--text-sub); margin-bottom: 2px; }
.cat-detail-item span { font-size: 14px; color: var(--text-main); font-weight: 500; }
.cat-stat-num { color: var(--primary) !important; font-weight: 700 !important; }
.cat-detail-desc { margin-bottom: 16px; }
.cat-detail-desc label { font-size: 11px; color: var(--text-sub); }
.cat-detail-desc p { margin: 4px 0 0; font-size: 13px; color: var(--text-main); line-height: 1.5; }
.cat-detail-actions { display: flex; gap: 8px; }
.cat-detail-empty { display: flex; align-items: center; justify-content: center; min-height: 200px; color: var(--text-sub); font-size: 14px; }

.btn-xs { padding: 2px 6px; font-size: 11px; border-radius: 4px; border: 1px solid var(--border); background: var(--bg-card); cursor: pointer; color: var(--text-sub); }
.btn-xs:hover { background: var(--border); color: var(--text-main); }

@media (max-width: 768px) {
  .km-toolbar { flex-direction: column; }
  .km-search { width: 100%; }
  .km-search input { flex: 1; min-width: 0; }
  .km-ops { flex-direction: column; }
  .form-row { flex-direction: column; }
  .review-grid { grid-template-columns: 1fr; }
  .modal-panel-big { width: 100vw; max-width: 100vw; }
  .km-cat-layout { flex-direction: column; }
  .km-cat-left { width: 100%; }
  .km-cat-right { width: 100%; }
  .km-cat-right-inner { position: static; transform: none; max-width: 100%; }
}
</style>
