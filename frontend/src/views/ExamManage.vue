<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import axios from 'axios'

const auth = useAuthStore()
const activeTab = ref<'papers' | 'exams' | 'mine'>('exams')

// ===== Tab 1: 试卷管理（管理员）=====
interface QItem {
  id: number; question_type: string; question_content: string
  options: Record<string, string> | null; answer: string
  explanation: string | null; target_position: string | null
  difficulty_level: number; category_id: number | null; created_at: string | null
}
interface PaperItem {
  id: number; title: string; target_type: string; target_value: string | null
  time_mode: string; start_time: string | null; end_time: string | null
  duration_minutes: number; total_questions: number; status: string; created_at: string | null
}
interface PaperDetail extends PaperItem { questions: any[] }
interface PoolQuestion { id: number; question_type: string; question_content: string; options: any; answer: string; target_position: string | null; difficulty_level: number; category_id: number | null }

const loading = ref(false)
const items = ref<QItem[]>([])
const total = ref(0)
const page = ref(1)
const diffFilter = ref(0)
const typeFilter = ref('')
const keyword = ref('')
const showForm = ref(false)
const editing = ref<Partial<QItem>>({})
const isEdit = ref(false)
const stats = ref<{ total: number; by_position: { position: string; count: number }[]; avg_difficulty: number; recent_new: number }>({ total: 0, by_position: [], avg_difficulty: 0, recent_new: 0 })

const papers = ref<PaperItem[]>([])
const paperDetail = ref<PaperDetail | null>(null)
const showPaperDetail = ref(false)
const showAutoGenerate = ref(false)
const showManualCreate = ref(false)
const autoForm = ref({ title: '', target_type: 'all', target_value: '', category_ids: [] as number[], question_count: 20, time_mode: 'anytime', start_date: '', start_time: '', end_date: '', end_time: '', duration_minutes: 60 })
const autoLoading = ref(false)
const allCategories = ref<{ id: number; name: string; knowledge_base: string; icon: string | null }[]>([])
const poolKeyword = ref('')
const poolPosition = ref('')
const poolDifficulty = ref(0)
const poolCategory = ref(0)
const poolItems = ref<PoolQuestion[]>([])
const poolTotal = ref(0)
const poolPage = ref(1)
const poolLoading = ref(false)
const selectedQids = ref<Set<number>>(new Set())
const manualForm = ref({ title: '', target_type: 'all', target_value: '', time_mode: 'anytime', start_date: '', start_time: '', end_date: '', end_time: '', duration_minutes: 60 })
const manualLoading = ref(false)

const kbLabel: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }
const catFilter = ref(0)
const catExpanded = ref<Record<string, boolean>>({ public: false, sales: false, tech: false, service: false })
const catDropdown = ref(false)
const catSelectedLabel = computed(() => {
  if (catFilter.value === 0) return '全部分类'
  const found = allCategories.value.find(c => c.id === catFilter.value)
  return found ? `${found.icon || ''} ${found.name}` : '全部分类'
})
const posLabel: Record<string, string> = { sales: '销售', tech: '技术', service: '客服', clerk: '文员', public: '公共' }
const targetLabel: Record<string, string> = { all: '全员', dept: '部门', position: '岗位' }
const timeLabel: Record<string, string> = { anytime: '随时可考', scheduled: '定时考试' }
const typeLabelShort: Record<string, string> = { single_choice: '单选', multi_choice: '多选', true_false: '判断', fill_blank: '填空' }

// ===== Tab 2: 考试信息（所有人）=====
interface PublicPaper {
  id: number; title: string; target_type: string; target_value: string | null
  time_mode: string; start_time: string | null; end_time: string | null
  duration_minutes: number; total_questions: number
  can_enter: boolean; in_window: boolean; already_submitted: boolean
  created_at: string | null
}
const publicPapers = ref<PublicPaper[]>([])
const publicLoading = ref(false)
const examTimeFilter = ref<'all' | 'not_started' | 'in_progress' | 'ended'>('all')
let countdownTimer: any = null
const nowTs = ref(Date.now())

const filteredPublicPapers = computed(() => {
  if (examTimeFilter.value === 'all') return publicPapers.value
  return publicPapers.value.filter(p => timeStatus(p) === examTimeFilter.value)
})

// ===== Tab 3: 我的考试（所有人）=====
interface AvailableExam { id: number; title: string; target_type: string; time_mode: string; start_time: string | null; end_time: string | null; duration_minutes: number; total_questions: number; already_submitted: boolean; in_window?: boolean }
interface ExamQ { epq_id: number; id: number; question_type: string; question_content: string; options: Record<string, string> | null; difficulty_level: number; sort_order: number }
interface ExamInfo { attempt_id: number; paper_id: number; title: string; duration_minutes: number; total_questions: number; questions: ExamQ[]; started_at: string }
interface AttemptItem { id: number; paper_id: number; paper_title: string; score: number; correct_count: number; total_questions: number; status: string; started_at: string | null; submitted_at: string | null }

const availableExams = ref<AvailableExam[]>([])
const historyExams = ref<AttemptItem[]>([])
const mineLoading = ref(false)
const examInfo = ref<ExamInfo | null>(null)
const answers = ref<Record<string, string>>({})
const timeLeft = ref(0)
const submitted = ref(false)
const examResult = ref<{ score: number; correct_count: number; total_questions: number } | null>(null)
const submitting = ref(false)

const answeredCount = computed(() => Object.keys(answers.value).length)

// ===== Tab 1 methods =====
async function fetchList() {
  loading.value = true
  try {
    const params: any = { page: page.value, page_size: 20 }
    if (diffFilter.value) params.difficulty = diffFilter.value
    if (typeFilter.value) params.question_type = typeFilter.value
    if (catFilter.value) params.category_id = catFilter.value
    if (keyword.value) params.keyword = keyword.value
    const { data } = await axios.get('/api/questions/list', { params })
    items.value = data.data.items; total.value = data.data.total
  } finally { loading.value = false }
}
async function fetchStats() { try { const { data } = await axios.get('/api/questions/stats'); stats.value = data.data } catch { /* */ } }
function search() { page.value = 1; fetchList() }
function openCreate() { isEdit.value = false; editing.value = { question_type: 'single_choice', question_content: '', answer: '', difficulty_level: 1 }; showForm.value = true }
function openEdit(q: QItem) { isEdit.value = true; editing.value = { ...q }; showForm.value = true }
async function saveForm() {
  const q = editing.value
  try {
    if (isEdit.value && q.id) {
      const params: any = {}
      if (q.question_content) params.question_content = q.question_content
      if (q.answer) params.answer = q.answer
      if (q.explanation) params.explanation = q.explanation
      if (q.target_position != null) params.target_position = q.target_position
      if (q.difficulty_level) params.difficulty_level = q.difficulty_level
      if (q.options) params.options_json = JSON.stringify(q.options)
      await axios.put(`/api/questions/${q.id}`, null, { params })
    } else {
      const params: any = { question_type: q.question_type, question_content: q.question_content, answer: q.answer || 'A' }
      if (q.explanation) params.explanation = q.explanation
      if (q.target_position) params.target_position = q.target_position
      if (q.difficulty_level) params.difficulty_level = q.difficulty_level
      if (q.options) params.options_json = JSON.stringify(q.options)
      await axios.post('/api/questions', null, { params })
    }
    showForm.value = false; fetchList(); fetchStats()
  } catch (e: any) { alert(e.response?.data?.detail || '保存失败') }
}
async function removeQ(id: number) { if (!confirm('确定移除此题目？')) return; await axios.put(`/api/questions/${id}/status`); fetchList(); fetchStats() }
async function fetchPapers() { try { const { data } = await axios.get('/api/exam/papers'); papers.value = data.data.items } catch { /* */ } }
async function fetchCategories() { try { const { data } = await axios.get('/api/categories'); allCategories.value = data.data } catch { /* */ } }
async function viewPaper(id: number) { try { const { data } = await axios.get(`/api/exam/papers/${id}`); paperDetail.value = data.data; showPaperDetail.value = true } catch { /* */ } }
async function doAutoGenerate() {
  if (!autoForm.value.title.trim()) { alert('请输入试卷名称'); return }
  autoLoading.value = true
  try {
    const body: any = { ...autoForm.value }
    if (body.start_date && body.start_time) body.start_time = new Date(body.start_date + 'T' + body.start_time).toISOString()
    else { delete body.start_time; delete body.start_date }
    if (body.end_date && body.end_time) body.end_time = new Date(body.end_date + 'T' + body.end_time).toISOString()
    else { delete body.end_time; delete body.end_date }
    delete body.start_date; delete body.end_date
    await axios.post('/api/exam/papers/auto-generate', body)
    showAutoGenerate.value = false; fetchPapers(); resetAutoForm()
  } catch (e: any) { alert(e.response?.data?.detail || '组卷失败') }
  finally { autoLoading.value = false }
}
function resetAutoForm() { autoForm.value = { title: '', target_type: 'all', target_value: '', category_ids: [], question_count: 20, time_mode: 'anytime', start_date: '', start_time: '', end_date: '', end_time: '', duration_minutes: 60 } }
async function fetchPool() {
  poolLoading.value = true
  try {
    const params: any = { page: poolPage.value, page_size: 50 }
    if (poolKeyword.value) params.keyword = poolKeyword.value
    if (poolPosition.value) params.target_position = poolPosition.value
    if (poolDifficulty.value) params.difficulty = poolDifficulty.value
    if (poolCategory.value) params.category_id = poolCategory.value
    const { data } = await axios.get('/api/exam/questions/pool', { params })
    poolItems.value = data.data.items; poolTotal.value = data.data.total
  } finally { poolLoading.value = false }
}
function poolSearch() { poolPage.value = 1; fetchPool() }
function toggleQ(qid: number) { if (selectedQids.value.has(qid)) selectedQids.value.delete(qid); else selectedQids.value.add(qid) }
function openManualCreate() { selectedQids.value = new Set(); manualForm.value = { title: '', target_type: 'all', target_value: '', time_mode: 'anytime', start_date: '', start_time: '', end_date: '', end_time: '', duration_minutes: 60 }; poolPage.value = 1; fetchPool(); showManualCreate.value = true }
async function doManualCreate() {
  if (!manualForm.value.title.trim()) { alert('请输入试卷名称'); return }
  if (selectedQids.value.size === 0) { alert('请至少选择1道题目'); return }
  manualLoading.value = true
  try {
    const body: any = { ...manualForm.value, question_ids: Array.from(selectedQids.value) }
    if (body.start_date && body.start_time) body.start_time = new Date(body.start_date + 'T' + body.start_time).toISOString()
    else { delete body.start_time; delete body.start_date }
    if (body.end_date && body.end_time) body.end_time = new Date(body.end_date + 'T' + body.end_time).toISOString()
    else { delete body.end_time; delete body.end_date }
    delete body.start_date; delete body.end_date
    await axios.post('/api/exam/papers', body)
    showManualCreate.value = false; fetchPapers()
  } catch (e: any) { alert(e.response?.data?.detail || '创建失败') }
  finally { manualLoading.value = false }
}
async function archivePaper(id: number) { if (!confirm('确定归档此试卷？')) return; await axios.put(`/api/exam/papers/${id}`, { status: 'archived' }); fetchPapers() }
async function deletePaper(id: number) { if (!confirm('确定删除？')) return; await axios.delete(`/api/exam/papers/${id}`); fetchPapers() }
function toggleCategory(cid: number) { const arr = autoForm.value.category_ids; const idx = arr.indexOf(cid); if (idx >= 0) arr.splice(idx, 1); else arr.push(cid) }
const poolSelectedCount = computed(() => selectedQids.value.size)

// ===== Tab 2 methods =====
async function fetchPublicPapers() {
  publicLoading.value = true
  try { const { data } = await axios.get('/api/exam/public-papers'); publicPapers.value = data.data.items } catch { /* */ }
  finally { publicLoading.value = false }
}

function countdownText(p: PublicPaper): string {
  if (p.time_mode === 'anytime') return '随时可考'
  if (!p.start_time || !p.end_time) return '—'
  const now = nowTs.value
  const start = new Date(p.start_time).getTime()
  const end = new Date(p.end_time).getTime()
  if (now < start) {
    const diff = Math.max(0, Math.floor((start - now) / 1000))
    const d = Math.floor(diff / 86400), h = Math.floor(diff / 3600 % 24), m = Math.floor(diff / 60 % 60), s = diff % 60
    if (d > 0) return `${d}天 ${h}时后开始`
    if (h > 0) return `${h}时${m}分后开始`
    return `${m}分${s}秒后开始`
  }
  if (now < end) {
    const diff = Math.max(0, Math.floor((end - now) / 1000))
    const d = Math.floor(diff / 86400), h = Math.floor(diff / 3600 % 24), m = Math.floor(diff / 60 % 60), s = diff % 60
    if (d > 0) return `剩余 ${d}天 ${h}时`
    if (h > 0) return `剩余 ${h}时${m}分`
    return `剩余 ${m}分${s}秒`
  }
  return '已结束'
}

function timeStatus(p: PublicPaper): 'not_started' | 'in_progress' | 'ended' | 'anytime' {
  if (p.time_mode === 'anytime') return 'anytime'
  if (!p.start_time || !p.end_time) return 'anytime'
  const now = nowTs.value
  const start = new Date(p.start_time).getTime()
  const end = new Date(p.end_time).getTime()
  if (now < start) return 'not_started'
  if (now < end) return 'in_progress'
  return 'ended'
}

function formatTimeRange(p: PublicPaper): string {
  if (p.time_mode !== 'scheduled' || !p.start_time || !p.end_time) return ''
  const s = new Date(p.start_time)
  const e = new Date(p.end_time)
  return `${s.getFullYear()}-${String(s.getMonth()+1).padStart(2,'0')}-${String(s.getDate()).padStart(2,'0')} ${String(s.getHours()).padStart(2,'0')}:${String(s.getMinutes()).padStart(2,'0')} → ${e.getFullYear()}-${String(e.getMonth()+1).padStart(2,'0')}-${String(e.getDate()).padStart(2,'0')} ${String(e.getHours()).padStart(2,'0')}:${String(e.getMinutes()).padStart(2,'0')}`
}

function enterExamPublic(p: PublicPaper) {
  if (!p.can_enter) return
  switchTab('mine'); startExam(p.id)
}

// ===== Tab 3: 我的考试 methods =====
async function fetchMyExams() {
  mineLoading.value = true
  try {
    const [availRes, histRes] = await Promise.all([
      axios.get('/api/exam/available'),
      axios.get('/api/exam/history'),
    ])
    availableExams.value = availRes.data.data.items
    historyExams.value = histRes.data.data.items
  } finally { mineLoading.value = false }
}

async function startExam(paperId: number) {
  try {
    const { data } = await axios.get(`/api/exam/start/${paperId}`)
    examInfo.value = data.data
    timeLeft.value = (data.data.duration_minutes || 60) * 60
    submitted.value = false; examResult.value = null; answers.value = {}
    startTimer()
    window.addEventListener('beforeunload', warnLeave)
  } catch (e: any) { alert(e.response?.data?.detail || '无法开始考试') }
}

function startTimer() {
  clearInterval(timer2)
  timer2 = setInterval(() => {
    if (timeLeft.value <= 0) { clearInterval(timer2); if (!submitted.value) submitExam(); return }
    timeLeft.value--
  }, 1000)
}
let timer2: any = null
function warnLeave(e: BeforeUnloadEvent) { if (!submitted.value && examInfo.value) { e.preventDefault(); e.returnValue = '' } }

async function submitExam() {
  if (submitted.value || !examInfo.value) return
  submitting.value = true
  try {
    const { data } = await axios.post(`/api/exam/submit/${examInfo.value.paper_id}`, { answers: answers.value })
    examResult.value = data.data; submitted.value = true
    clearInterval(timer2); window.removeEventListener('beforeunload', warnLeave)
  } catch (e: any) { alert(e.response?.data?.detail || '提交失败') }
  finally { submitting.value = false }
}

function backToMyExams() {
  if (!submitted.value && examInfo.value && !confirm('确定离开？未提交的答案将丢失。')) return
  examInfo.value = null; submitted.value = false; clearInterval(timer2)
  window.removeEventListener('beforeunload', warnLeave)
  fetchMyExams()
}

function formatTime(sec: number): string { const m = Math.floor(sec / 60), s = sec % 60; return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}` }

const typeLabel: Record<string, string> = { single_choice: '单选题', multi_choice: '多选题', true_false: '判断题', fill_blank: '填空题' }

// ===== Tab 切换 =====
function switchTab(tab: 'papers' | 'exams' | 'mine') {
  if (tab === 'papers' && !auth.isAdmin) return
  activeTab.value = tab
  if (tab === 'exams') { fetchPublicPapers(); startCountdown() }
  if (tab === 'mine') { fetchMyExams(); stopCountdown() }
  if (tab === 'papers') { stopCountdown(); fetchPapers(); fetchCategories(); if (items.value.length === 0) { fetchList(); fetchStats() } }
}

function startCountdown() {
  stopCountdown()
  countdownTimer = setInterval(() => { nowTs.value = Date.now() }, 1000)
}
function stopCountdown() { clearInterval(countdownTimer) }

onMounted(() => {
  if (auth.isAdmin) { fetchList(); fetchStats(); fetchPapers(); fetchCategories() }
  fetchPublicPapers(); startCountdown()
})
onUnmounted(() => { stopCountdown(); clearInterval(timer2); window.removeEventListener('beforeunload', warnLeave) })
</script>

<template>
  <div class="em-page">
    <!-- Tab 切换 -->
    <div class="em-tabs">
      <button v-if="auth.isAdmin" :class="{ active: activeTab === 'papers' }" @click="switchTab('papers')">▤ 试卷管理</button>
      <button :class="{ active: activeTab === 'exams' }" @click="switchTab('exams')">◉ 考试信息</button>
      <button :class="{ active: activeTab === 'mine' }" @click="switchTab('mine')">☐ 我的考试</button>
    </div>

    <!-- ==================== Tab 1: 试卷管理（管理员） ==================== -->
    <div v-if="activeTab === 'papers' && auth.isAdmin">
      <div class="em-head">
        <h2 class="page-title">试卷管理</h2>
        <div class="em-actions">
          <button class="btn btn-sm" @click="showAutoGenerate = true">⌘ 自动组卷</button>
          <button class="btn btn-sm btn-outline" @click="openManualCreate">▤ 手动组卷</button>
          <button class="btn btn-sm" @click="openCreate">+ 新增题目</button>
        </div>
      </div>

      <!-- 题库统计 -->
      <div class="em-stats" v-if="stats.total">
        <div class="em-stat"><span class="ems-num">{{ stats.total }}</span><span class="ems-label">题目总数</span></div>
        <div class="em-stat"><span class="ems-num">{{ stats.avg_difficulty }}</span><span class="ems-label">平均难度</span></div>
        <div class="em-stat"><span class="ems-num">+{{ stats.recent_new }}</span><span class="ems-label">近7天新增</span></div>
        <div class="em-stat pos-breakdown"><span v-for="b in stats.by_position" :key="b.position">{{ posLabel[b.position] || b.position || '公共' }}：{{ b.count }} 题</span></div>
      </div>

      <!-- 题库筛选+列表 -->
      <div class="em-tools">
        <input v-model="keyword" placeholder="搜索题目..." class="form-input" style="width:200px" @keydown.enter="search" />
        <select v-model="diffFilter" @change="search" class="form-input" style="width:auto"><option value="0">全部难度</option><option v-for="n in 5" :key="n" :value="n">{{ '★'.repeat(n) }}</option></select>
        <select v-model="typeFilter" @change="search" class="form-input" style="width:auto"><option value="">全部题型</option><option value="single_choice">单选</option><option value="multi_choice">多选</option><option value="true_false">判断</option><option value="fill_blank">填空</option></select>
        <div class="cat-dropdown">
          <button class="cat-dropdown-btn" @click="catDropdown = !catDropdown">
            ▤ {{ catSelectedLabel }} ▾
          </button>
          <div v-if="catDropdown" class="cat-dropdown-backdrop" @click="catDropdown = false"></div>
          <div v-if="catDropdown" class="cat-dropdown-panel">
            <span :class="{ active: catFilter === 0 }" @click="catFilter = 0; catDropdown = false; search()">全部类型</span>
            <div v-for="kb in ['public','sales','tech','service']" :key="kb" class="cat-dd-group">
              <span class="cat-dd-root" @click.stop="catExpanded[kb] = !catExpanded[kb]">
                {{ catExpanded[kb] ? '▼' : '▶' }} {{ kbLabel[kb] }}
              </span>
              <div v-if="catExpanded[kb]" class="cat-dd-subs">
                <span v-for="c in allCategories.filter(x => x.knowledge_base === kb)" :key="c.id"
                  :class="{ active: catFilter === c.id }"
                  @click="catFilter = c.id; catDropdown = false; search()">{{ c.icon || '' }} {{ c.name }}</span>
              </div>
            </div>
          </div>
        </div>
        <button class="btn btn-sm" @click="search">搜索</button>
      </div>
      <div class="table-responsive" v-if="!loading">
        <table class="em-table"><thead><tr><th>ID</th><th>内容</th><th>类型</th><th>答案</th><th>岗位</th><th>难度</th><th>操作</th></tr></thead>
          <tbody>
            <tr v-for="q in items" :key="q.id">
              <td>{{ q.id }}</td><td class="em-q-text">{{ q.question_content.slice(0, 60) }}...</td>
              <td>{{ typeLabelShort[q.question_type] || q.question_type }}</td><td>{{ q.answer }}</td>
              <td>{{ posLabel[q.target_position || ''] || '公共' }}</td><td>{{ '★'.repeat(q.difficulty_level) }}</td>
              <td><button class="btn btn-sm btn-outline" @click="openEdit(q)">编辑</button><button class="btn btn-sm btn-danger" @click="removeQ(q.id)">移除</button></td>
            </tr>
            <tr v-if="items.length === 0"><td colspan="7" style="text-align:center;padding:40px;color:var(--text-sub)">暂无题目</td></tr>
          </tbody>
        </table>
      </div>
      <div class="em-pager" v-if="total > 20">
        <button :disabled="page<=1" @click="page--;fetchList()" class="btn btn-sm btn-outline">上一页</button>
        <span>{{ page }}/{{ Math.ceil(total/20) }}</span>
        <button :disabled="page>=Math.ceil(total/20)" @click="page++;fetchList()" class="btn btn-sm btn-outline">下一页</button>
      </div>
    </div>

    <!-- ==================== Tab 2: 考试信息（所有人） ==================== -->
    <div v-if="activeTab === 'exams'">
      <div class="em-head">
        <h2 class="page-title">◉ 公司考试</h2>
      </div>
      <!-- 时间筛选 -->
      <div class="exam-filter-bar">
        <button :class="{ active: examTimeFilter === 'all' }" @click="examTimeFilter = 'all'">全部 ({{ publicPapers.length }})</button>
        <button :class="{ active: examTimeFilter === 'not_started' }" @click="examTimeFilter = 'not_started'">◷ 未开始</button>
        <button :class="{ active: examTimeFilter === 'in_progress' }" @click="examTimeFilter = 'in_progress'">◉ 进行中</button>
        <button :class="{ active: examTimeFilter === 'ended' }" @click="examTimeFilter = 'ended'">⊘ 已结束</button>
      </div>

      <div v-if="publicLoading" style="text-align:center;padding:40px;color:var(--text-sub)">加载中...</div>
      <div v-else-if="publicPapers.length === 0" style="text-align:center;padding:60px;color:var(--text-sub)"><div style="font-size:48px;margin-bottom:12px">◇</div><p>暂无考试</p></div>
      <div v-else class="exam-list">
        <div v-for="p in filteredPublicPapers" :key="p.id" class="exam-card card">
          <div class="exam-card-left">
            <!-- 时间状态标签（每个考试都有） -->
            <div class="exam-status-col" :class="'status-' + timeStatus(p)">
              <span class="exam-status-icon">{{ timeStatus(p) === 'not_started' ? '◷' : timeStatus(p) === 'in_progress' ? '◉' : timeStatus(p) === 'ended' ? '⊘' : '◉' }}</span>
              <span class="exam-status-label">{{ timeStatus(p) === 'not_started' ? '未开始' : timeStatus(p) === 'in_progress' ? '进行中' : timeStatus(p) === 'ended' ? '已结束' : '已开始' }}</span>
            </div>
            <div class="exam-card-body">
              <h3>{{ p.title }}</h3>
              <div class="exam-card-meta">
                <span>◎ {{ targetLabel[p.target_type] || '全员' }}{{ p.target_value ? ' · ' + (posLabel[p.target_value] || p.target_value) : '' }}</span>
                <span>☐ {{ p.total_questions }} 题</span>
                <span>◷ {{ p.duration_minutes }} 分钟</span>
              </div>
              <div v-if="p.time_mode === 'scheduled'" class="exam-time-info">
                <span class="exam-time-range">◷ {{ formatTimeRange(p) }}</span>
                <span class="countdown-badge">{{ countdownText(p) }}</span>
              </div>
            </div>
          </div>
          <div class="exam-card-action">
            <button v-if="p.already_submitted" class="btn btn-sm" disabled>✓ 已交卷</button>
            <button v-else-if="!p.can_enter" class="btn btn-sm" disabled>
              {{ timeStatus(p) === 'not_started' ? '◷ 未到时间' : timeStatus(p) === 'ended' ? '⊘ 已截止' : '⊗ 无权限' }}
            </button>
            <button v-else class="btn" @click="enterExamPublic(p)">进入考试</button>
          </div>
        </div>
      </div>
    </div>

    <!-- ==================== Tab 3: 我的考试（所有人） ==================== -->
    <div v-if="activeTab === 'mine'">
      <!-- 考试答题界面 -->
      <div v-if="examInfo">
        <!-- 结果页 -->
        <div v-if="submitted && examResult" class="exam-result">
          <div class="result-card">
            <div class="result-icon">◆</div><h2>考试完成！</h2>
            <div class="result-score">{{ examResult.score }} <span>分</span></div>
            <div class="result-detail"><span>答对 {{ examResult.correct_count }} / {{ examResult.total_questions }} 题</span><span>正确率 {{ Math.round(examResult.correct_count / examResult.total_questions * 100) }}%</span></div>
            <button class="btn" @click="backToMyExams" style="margin-top:20px;padding:10px 40px">返回</button>
          </div>
        </div>
        <!-- 答题页 -->
        <div v-else>
          <div class="exam-top-bar">
            <button class="btn btn-sm btn-outline" @click="backToMyExams">← 返回</button>
            <span class="exam-title">{{ examInfo.title }}</span>
            <span class="exam-progress">{{ answeredCount }}/{{ examInfo.total_questions }} 已答</span>
            <span class="exam-timer" :class="{ urgent: timeLeft < 300 }">⏱ {{ formatTime(timeLeft) }}</span>
            <button class="btn btn-sm" @click="submitExam" :disabled="submitting" style="background:var(--success)">{{ submitting ? '提交中...' : '提交答卷' }}</button>
          </div>
          <div class="exam-qs">
            <div v-for="q in examInfo.questions" :key="q.id" class="eq-item card">
              <div class="eq-header"><span>{{ q.sort_order }}.</span><span class="eq-type-badge">{{ typeLabel[q.question_type] || q.question_type }}</span><span class="eq-diff">{{ '★'.repeat(q.difficulty_level) }}</span></div>
              <p class="eq-content">{{ q.question_content }}</p>
              <!-- 单选 -->
              <div v-if="q.question_type === 'single_choice' && q.options" class="eq-options">
                <label v-for="(v, k) in q.options" :key="k" class="eq-opt" :class="{ picked: answers[String(q.id)] === k }">
                  <input type="radio" :name="'q' + q.id" :value="k" v-model="answers[String(q.id)]" /><span>{{ k }}. {{ v }}</span>
                </label>
              </div>
              <!-- 多选 -->
              <div v-if="q.question_type === 'multi_choice' && q.options" class="eq-options">
                <label v-for="(v, k) in q.options" :key="k" class="eq-opt" :class="{ picked: (answers[String(q.id)] || '').includes(k) }">
                  <input type="checkbox" :value="k" @change="(e: any) => { const cur = answers[String(q.id)] || ''; const arr = cur ? cur.split(',') : []; if (e.target.checked) arr.push(k); else { const idx = arr.indexOf(k); if (idx >= 0) arr.splice(idx, 1) } answers[String(q.id)] = arr.join(',') }" /><span>{{ k }}. {{ v }}</span>
                </label>
              </div>
              <!-- 判断 -->
              <div v-if="q.question_type === 'true_false'" class="eq-options">
                <label class="eq-opt" :class="{ picked: answers[String(q.id)] === 'true' }"><input type="radio" :name="'q' + q.id" value="true" v-model="answers[String(q.id)]" />✅ 正确</label>
                <label class="eq-opt" :class="{ picked: answers[String(q.id)] === 'false' }"><input type="radio" :name="'q' + q.id" value="false" v-model="answers[String(q.id)]" />❌ 错误</label>
              </div>
              <!-- 填空 -->
              <div v-if="q.question_type === 'fill_blank'" class="eq-fill"><input v-model="answers[String(q.id)]" class="form-input" style="width:100%" placeholder="请输入答案" /></div>
            </div>
          </div>
        </div>
      </div>

      <!-- 考试列表 -->
      <div v-else>
        <div class="em-head"><h2 class="page-title">☐ 我的考试</h2></div>
        <div v-if="mineLoading" style="text-align:center;padding:40px;color:var(--text-sub)">加载中...</div>
        <div v-else>
          <!-- 可参加的考试 -->
          <div v-if="availableExams.length" class="em-section">
            <h3 class="em-section-title">◉ 可参加的考试（{{ availableExams.length }}）</h3>
            <div class="exam-list">
              <div v-for="ex in availableExams" :key="'av-'+ex.id" class="exam-card card">
                <div class="exam-card-info">
                  <h3>{{ ex.title }}</h3>
                  <div class="exam-card-meta">
                    <span>☐ {{ ex.total_questions }} 题</span><span>◷ {{ ex.duration_minutes }} 分钟</span>
                    <span>{{ ex.time_mode === 'scheduled' ? '定时考试' : '随时可考' }}</span>
                  </div>
                </div>
                <button v-if="ex.already_submitted" class="btn btn-sm" disabled>✓ 已完成</button>
                <button v-else class="btn" @click="startExam(ex.id)">开始考试</button>
              </div>
            </div>
          </div>

          <!-- 历史记录 -->
          <div v-if="historyExams.length" class="em-section">
            <h3 class="em-section-title">☐ 考试记录（{{ historyExams.length }} 次）</h3>
            <div class="table-responsive">
              <table class="em-table">
                <thead><tr><th>试卷</th><th>得分</th><th>正确</th><th>状态</th><th>提交时间</th></tr></thead>
                <tbody>
                  <tr v-for="h in historyExams" :key="h.id">
                    <td>{{ h.paper_title }}</td>
                    <td><b :style="{ color: h.score >= 60 ? 'var(--success)' : 'var(--danger)' }">{{ h.score }} 分</b></td>
                    <td>{{ h.correct_count }}/{{ h.total_questions }}</td>
                    <td>{{ h.status === 'submitted' ? '✅ 已交卷' : '进行中' }}</td>
                    <td>{{ h.submitted_at?.slice(0, 16) || '—' }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div v-if="!availableExams.length && !historyExams.length" style="text-align:center;padding:60px;color:var(--text-sub)">
            <div style="font-size:48px;margin-bottom:12px">◇</div><p>暂无考试记录</p>
          </div>
        </div>
      </div>
    </div>

    <!-- ========== 弹窗：试卷详情 ========== -->
    <Teleport to="body">
      <div v-if="showPaperDetail && paperDetail" class="modal-overlay" @click.self="showPaperDetail = false">
        <div class="modal-panel-big"><div class="modal-header"><h3>☐ {{ paperDetail.title }}</h3><button @click="showPaperDetail = false" class="btn btn-sm">×</button></div>
          <div class="modal-body">
            <div class="paper-detail-meta"><span>◎ {{ targetLabel[paperDetail.target_type] || '全员' }}{{ paperDetail.target_value ? ' · ' + paperDetail.target_value : '' }}</span><span>{{ timeLabel[paperDetail.time_mode] || paperDetail.time_mode }}</span><span>◷ {{ paperDetail.duration_minutes }} 分钟</span><span v-if="paperDetail.time_mode === 'scheduled'">{{ paperDetail.start_time?.slice(0,16) }} ~ {{ paperDetail.end_time?.slice(0,16) }}</span></div>
            <h4 style="font-size:13px;margin:12px 0 6px">题目列表（{{ paperDetail.total_questions }} 题）</h4>
            <div class="paper-detail-qs"><div v-for="(q,i) in paperDetail.questions" :key="i" class="paper-q-item"><div class="pq-header">{{ i+1 }}. [{{ typeLabelShort[q.question_type] || q.question_type }}] {{ q.question_content.slice(0,80) }}</div><div class="pq-meta">答案：{{ q.answer }} | 难度：{{ '★'.repeat(q.difficulty_level) }}</div></div></div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- ========== 弹窗：自动组卷 ========== -->
    <Teleport to="body">
      <div v-if="showAutoGenerate" class="modal-overlay" @click.self="showAutoGenerate = false">
        <div class="modal-panel" style="width:700px"><div class="modal-header"><h3>⌘ 自动组卷</h3><button @click="showAutoGenerate = false" class="btn btn-sm">×</button></div>
          <div class="modal-body">
            <div class="form-group"><label>试卷名称</label><input v-model="autoForm.title" class="form-input" style="width:100%" placeholder="如：2026Q2 销售岗位技能考核" /></div>
            <div class="form-row">
              <div class="form-group"><label>目标范围</label><select v-model="autoForm.target_type" class="form-input" style="width:100%"><option value="all">全员</option><option value="dept">部门</option><option value="position">岗位</option></select></div>
              <div class="form-group" v-if="autoForm.target_type === 'position'"><label>目标岗位</label><select v-model="autoForm.target_value" class="form-input" style="width:100%"><option value="sales">销售</option><option value="tech">技术</option><option value="service">客服</option><option value="clerk">文员</option></select></div>
              <div class="form-group"><label>题目数量</label><input v-model.number="autoForm.question_count" type="number" min="1" max="100" class="form-input" style="width:100px" /></div>
            </div>
            <div class="form-group"><label>知识类别（可选，不选则从全部题目随机）</label>
              <div class="cat-check-grid"><label v-for="c in allCategories" :key="c.id" class="cat-check" :class="{ on: autoForm.category_ids.includes(c.id) }" @click="toggleCategory(c.id)">{{ c.icon || '◈' }} {{ c.name }}</label></div>
            </div>
            <div class="form-row">
              <div class="form-group"><label>考试时间模式</label><select v-model="autoForm.time_mode" class="form-input" style="width:100%"><option value="anytime">随时可考</option><option value="scheduled">定时考试</option></select></div>
              <div class="form-group"><label>答题限时（分钟）</label><input v-model.number="autoForm.duration_minutes" type="number" min="1" class="form-input" style="width:100px" /></div>
            </div>
            <div v-if="autoForm.time_mode === 'scheduled'" class="scheduled-time-box">
              <div class="form-group"><label>开始日期</label><input v-model="autoForm.start_date" type="date" class="form-input" style="width:100%" /></div>
              <div class="form-group"><label>开始时间</label><input v-model="autoForm.start_time" type="time" class="form-input" style="width:100%" /></div>
              <div class="form-group"><label>截止日期</label><input v-model="autoForm.end_date" type="date" class="form-input" style="width:100%" /></div>
              <div class="form-group"><label>截止时间</label><input v-model="autoForm.end_time" type="time" class="form-input" style="width:100%" /></div>
            </div>
            <div v-if="autoForm.time_mode === 'scheduled' && autoForm.start_date && autoForm.end_date" class="scheduled-summary">
              ◷ {{ autoForm.start_date }} {{ autoForm.start_time || '00:00' }} → {{ autoForm.end_date }} {{ autoForm.end_time || '23:59' }}
            </div>
          </div>
          <div class="modal-footer"><button class="btn btn-outline" @click="showAutoGenerate = false">取消</button><button class="btn" @click="doAutoGenerate" :disabled="autoLoading">{{ autoLoading ? '生成中...' : '◈ 随机组卷' }}</button></div>
        </div>
      </div>
    </Teleport>

    <!-- ========== 弹窗：手动组卷 ========== -->
    <Teleport to="body">
      <div v-if="showManualCreate" class="modal-overlay" @click.self="showManualCreate = false">
        <div class="modal-panel" style="width:1100px;max-width:97vw"><div class="modal-header"><h3>▤ 手动组卷</h3><button @click="showManualCreate = false" class="btn btn-sm">×</button></div>
          <div class="modal-body" style="display:flex;gap:16px;flex-wrap:wrap">
            <div style="flex:1;min-width:400px">
              <div class="form-group"><label>试卷名称</label><input v-model="manualForm.title" class="form-input" style="width:100%" placeholder="输入试卷名称" /></div>
              <div class="form-row">
                <div class="form-group"><label>目标范围</label><select v-model="manualForm.target_type" class="form-input" style="width:100%"><option value="all">全员</option><option value="position">岗位</option></select></div>
                <div class="form-group" v-if="manualForm.target_type === 'position'"><label>岗位</label><select v-model="manualForm.target_value" class="form-input" style="width:100%"><option value="sales">销售</option><option value="tech">技术</option><option value="service">客服</option><option value="clerk">文员</option></select></div>
                <div class="form-group"><label>时限(分钟)</label><input v-model.number="manualForm.duration_minutes" type="number" min="1" class="form-input" style="width:80px" /></div>
                <div class="form-group"><label>时间模式</label><select v-model="manualForm.time_mode" class="form-input" style="width:auto"><option value="anytime">随时</option><option value="scheduled">定时</option></select></div>
              </div>
              <div v-if="manualForm.time_mode === 'scheduled'" style="display:flex;gap:8px;flex-wrap:wrap">
                <div class="form-group"><label>开始日期</label><input v-model="manualForm.start_date" type="date" class="form-input" style="width:100%" /></div>
                <div class="form-group"><label>开始时间</label><input v-model="manualForm.start_time" type="time" class="form-input" style="width:100px" /></div>
                <div class="form-group"><label>截止日期</label><input v-model="manualForm.end_date" type="date" class="form-input" style="width:100%" /></div>
                <div class="form-group"><label>截止时间</label><input v-model="manualForm.end_time" type="time" class="form-input" style="width:100px" /></div>
              </div>
              <div class="pool-tools"><input v-model="poolKeyword" placeholder="搜索题目" class="form-input" style="width:150px" @keydown.enter="poolSearch" /><select v-model="poolPosition" @change="poolSearch" class="form-input" style="width:auto"><option value="">全部岗位</option><option value="sales">销售</option><option value="tech">技术</option><option value="service">客服</option><option value="clerk">文员</option></select><select v-model="poolDifficulty" @change="poolSearch" class="form-input" style="width:auto"><option value="0">全部难度</option><option v-for="n in 5" :key="n" :value="n">{{ '★'.repeat(n) }}</option></select><button class="btn btn-sm" @click="poolSearch">搜索</button></div>
              <div class="pool-list" style="max-height:50vh;overflow-y:auto;border:1px solid var(--border);border-radius:8px">
                <div v-if="poolLoading" style="padding:20px;text-align:center;color:var(--text-sub)">加载中...</div>
                <div v-for="q in poolItems" :key="q.id" class="pool-row" :class="{ selected: selectedQids.has(q.id) }" @click="toggleQ(q.id)">
                  <input type="checkbox" :checked="selectedQids.has(q.id)" style="pointer-events:none" /><span class="pool-type">{{ typeLabelShort[q.question_type] || q.question_type }}</span><span class="pool-text">{{ q.question_content.slice(0, 60) }}</span><span class="pool-ans">答案:{{ q.answer }}</span><span class="pool-diff">{{ '★'.repeat(q.difficulty_level) }}</span>
                </div>
                <div v-if="!poolLoading && poolItems.length === 0" style="padding:20px;text-align:center;color:var(--text-sub)">无题目</div>
              </div>
              <div style="margin-top:4px;display:flex;justify-content:space-between;align-items:center"><span style="font-size:12px;color:var(--text-sub)">共 {{ poolTotal }} 题</span><div style="display:flex;gap:4px"><button :disabled="poolPage<=1" @click="poolPage--;fetchPool()" class="btn btn-sm btn-outline">上一页</button><button :disabled="poolPage>=Math.ceil(poolTotal/50)" @click="poolPage++;fetchPool()" class="btn btn-sm btn-outline">下一页</button></div></div>
            </div>
            <div style="width:280px;flex-shrink:0"><div class="selected-box"><h4 style="margin:0 0 8px;font-size:14px">✓ 已选题目（{{ poolSelectedCount }} 题）</h4><div style="margin-bottom:12px;font-size:12px;color:var(--text-sub);max-height:40vh;overflow-y:auto"><div v-for="qid in Array.from(selectedQids).slice(0, 20)" :key="qid" style="padding:2px 0">#{{ qid }} {{ poolItems.find(q => q.id === qid)?.question_content?.slice(0, 30) || '' }}...</div><div v-if="poolSelectedCount > 20" style="color:var(--text-sub)">... 还有 {{ poolSelectedCount - 20 }} 题</div></div><button class="btn" style="width:100%" @click="doManualCreate" :disabled="manualLoading || poolSelectedCount === 0">{{ manualLoading ? '创建中...' : `▤ 创建试卷（${poolSelectedCount} 题）` }}</button></div></div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- ========== 弹窗：题目编辑 ========== -->
    <Teleport to="body">
      <div v-if="showForm" class="modal-overlay" @click.self="showForm=false">
        <div class="modal-panel"><div class="modal-header"><h3>{{ isEdit ? '编辑' : '新增' }}题目</h3><button @click="showForm=false" class="btn btn-sm">×</button></div>
          <div class="modal-body">
            <div class="form-group"><label>题型</label><select v-model="editing.question_type" class="form-input" style="width:100%"><option value="single_choice">单选题</option><option value="multi_choice">多选题</option><option value="true_false">判断题</option><option value="fill_blank">填空题</option></select></div>
            <div class="form-group"><label>题目内容</label><textarea v-model="editing.question_content" class="form-input" style="width:100%;min-height:80px"></textarea></div>
            <div class="form-group"><label>答案</label><input v-model="editing.answer" class="form-input" style="width:100%" /></div>
            <div class="form-group"><label>解析</label><textarea v-model="editing.explanation" class="form-input" style="width:100%;min-height:60px"></textarea></div>
            <div class="form-row"><div class="form-group"><label>目标岗位</label><select v-model="editing.target_position" class="form-input" style="width:100%"><option value="">公共</option><option value="sales">销售</option><option value="tech">技术</option><option value="service">客服</option><option value="clerk">文员</option></select></div><div class="form-group"><label>难度</label><input v-model.number="editing.difficulty_level" type="number" min="1" max="5" class="form-input" style="width:80px" /></div></div>
          </div>
          <div class="modal-footer"><button class="btn btn-outline" @click="showForm=false">取消</button><button class="btn" @click="saveForm">保存</button></div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.em-page { max-width: 1200px; margin: 0 auto; }
.page-title { font-size: 20px; margin: 0; color: var(--text-main); }

/* Tabs */
.em-tabs { display: flex; gap: 0; margin-bottom: 16px; }
.em-tabs button { padding: 8px 24px; border: 1px solid var(--border); background: var(--bg-card); font-size: 14px; cursor: pointer; color: var(--text-sub); }
.em-tabs button:first-child { border-radius: 6px 0 0 6px; }
.em-tabs button:last-child { border-radius: 0 6px 6px 0; }
.em-tabs button.active { background: var(--primary); color: #fff; border-color: var(--primary); }

.em-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.em-actions { display: flex; gap: 8px; }
.em-section { margin-bottom: 20px; }
.em-section-title { font-size: 15px; margin: 0 0 10px; color: var(--text-main); }

/* 试卷卡片 */
.paper-list { display: flex; flex-direction: column; gap: 8px; }
.paper-card { padding: 14px 18px; cursor: pointer; display: flex; align-items: center; gap: 16px; transition: box-shadow 0.15s; }
.paper-card:hover { box-shadow: 0 4px 16px var(--shadow); }
.paper-card-top { display: flex; align-items: center; gap: 10px; min-width: 180px; }
.paper-card-top h4 { margin: 0; font-size: 14px; color: var(--text-main); }
.paper-active { padding: 2px 8px; border-radius: 8px; font-size: 11px; background: rgba(122,166,104,0.1); color: var(--success); }
.paper-archived { padding: 2px 8px; border-radius: 8px; font-size: 11px; background: rgba(192,64,59,0.08); color: var(--danger); }
.paper-card-meta { display: flex; gap: 12px; flex: 1; font-size: 12px; color: var(--text-sub); }
.paper-card-actions { display: flex; gap: 4px; }

/* 统计分析 */
.em-stats { display: flex; gap: 16px; margin-bottom: 16px; flex-wrap: wrap; }
.em-stat { text-align: center; padding: 12px 20px; background: var(--bg-card); border: 1px solid var(--border); border-radius: 8px; min-width: 100px; }
.em-stat.pos-breakdown { min-width: 140px; text-align: left; }
.em-stat.pos-breakdown span { display: block; font-size: 13px; line-height: 1.8; }
.ems-num { display: block; font-size: 24px; font-weight: 700; color: var(--primary); }
.ems-label { font-size: 11px; color: var(--text-sub); }

/* 题库筛选/列表 */
.em-tools { display: flex; gap: 8px; margin-bottom: 8px; align-items: center; flex-wrap: wrap; }
/* 知识类别下拉树 */
.cat-dropdown { position: relative; display: inline-block; }
.cat-dropdown-btn { padding: 6px 14px; border: 1px solid var(--border); border-radius: 8px; font-size: 13px; background: var(--bg-card); color: var(--text-main); cursor: pointer; white-space: nowrap; }
.cat-dropdown-btn:hover { border-color: var(--primary); }
.cat-dropdown-backdrop { position: fixed; inset: 0; z-index: 10; }
.cat-dropdown-panel { position: absolute; top: 100%; left: 0; z-index: 100; margin-top: 4px; width: 280px; max-height: 420px; overflow-y: auto; background: var(--bg-card); border: 1px solid var(--border); border-radius: 10px; box-shadow: 0 6px 24px var(--shadow); padding: 8px; }
.cat-dropdown-panel > span { display: block; padding: 6px 10px; border-radius: 6px; font-size: 12px; cursor: pointer; color: var(--text-sub); }
.cat-dropdown-panel > span:hover { background: var(--bg-main); }
.cat-dropdown-panel > span.active { background: var(--primary); color: #fff; }
.cat-dd-group { margin-top: 4px; }
.cat-dd-root { display: block; padding: 5px 10px; font-size: 12px; font-weight: 600; cursor: pointer; color: var(--text-main); border-radius: 6px; user-select: none; }
.cat-dd-root:hover { background: var(--bg-main); }
.cat-dd-subs { padding: 2px 0 4px 16px; display: flex; flex-wrap: wrap; gap: 2px; }
.cat-dd-subs span { padding: 3px 10px; border-radius: 8px; font-size: 11px; cursor: pointer; border: 1px solid transparent; color: var(--text-sub); white-space: nowrap; }
.cat-dd-subs span:hover { border-color: var(--primary); color: var(--primary); }
.cat-dd-subs span.active { background: var(--primary); color: #fff; border-color: var(--primary); }
.em-table { width: 100%; border-collapse: collapse; font-size: 13px; background: var(--bg-card); border-radius: 8px; overflow: hidden; }
.em-table th, .em-table td { padding: 8px 10px; text-align: left; border-bottom: 1px solid var(--border); }
.em-table th { background: var(--bg-main); font-size: 12px; color: var(--text-sub); }
.em-q-text { max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.em-pager { display: flex; justify-content: center; align-items: center; gap: 12px; margin-top: 16px; }

/* 考试信息 / 我的考试 通用列表 */
.exam-filter-bar { display: flex; gap: 4px; margin-bottom: 14px; flex-wrap: wrap; }
.exam-filter-bar button { padding: 5px 16px; border: 1px solid var(--border); border-radius: 14px; font-size: 12px; background: none; color: var(--text-sub); cursor: pointer; transition: all 0.15s; }
.exam-filter-bar button:hover { border-color: var(--primary); color: var(--primary); }
.exam-filter-bar button.active { background: var(--primary); color: #fff; border-color: var(--primary); }

.exam-list { display: flex; flex-direction: column; gap: 10px; }
.exam-card { padding: 16px 20px; display: flex; justify-content: space-between; align-items: center; gap: 16px; }
.exam-card.exam-disabled { opacity: 0.55; }
.exam-card-left { display: flex; gap: 14px; align-items: flex-start; flex: 1; min-width: 0; }
.exam-card-body { flex: 1; min-width: 0; }
.exam-card-body h3 { margin: 0 0 6px; font-size: 15px; color: var(--text-main); }
.exam-card-meta { display: flex; gap: 12px; font-size: 12px; color: var(--text-sub); align-items: center; flex-wrap: wrap; margin-bottom: 4px; }
.exam-card-action { flex-shrink: 0; }

/* 左侧状态标签列 */
.exam-status-col { display: flex; flex-direction: column; align-items: center; gap: 2px; min-width: 56px; padding: 6px 8px; border-radius: 8px; }
.exam-status-col.status-anytime,
.exam-status-col.status-in_progress { background: rgba(122,166,104,0.08); }
.exam-status-col.status-not_started { background: rgba(232,130,74,0.08); }
.exam-status-col.status-ended { background: rgba(192,64,59,0.06); }
.exam-status-icon { font-size: 18px; }
.exam-status-label { font-size: 11px; font-weight: 600; color: var(--text-main); white-space: nowrap; }

.exam-time-info { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; font-size: 12px; }
.exam-time-range { color: var(--text-sub); }
.countdown-badge { padding: 2px 8px; border-radius: 10px; font-size: 11px; background: var(--bg-main); color: var(--primary); font-weight: 600; }

/* 答题界面 */
.exam-top-bar { display: flex; align-items: center; gap: 16px; padding: 10px 16px; background: var(--bg-card); border: 1px solid var(--border); border-radius: 10px; position: sticky; top: 0; z-index: 100; margin-bottom: 16px; }
.exam-title { font-weight: 600; font-size: 14px; color: var(--text-main); flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.exam-progress { font-size: 12px; color: var(--text-sub); white-space: nowrap; }
.exam-timer { font-size: 18px; font-weight: 700; color: var(--primary); white-space: nowrap; font-variant-numeric: tabular-nums; }
.exam-timer.urgent { color: var(--danger); animation: pulse 1s infinite; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.5} }
.exam-qs { display: flex; flex-direction: column; gap: 16px; }
.eq-item { padding: 16px 20px; }
.eq-header { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; font-weight: 600; font-size: 14px; }
.eq-type-badge { padding: 2px 8px; border-radius: 6px; font-size: 11px; background: var(--bg-main); color: var(--primary); }
.eq-diff { font-size: 12px; color: var(--accent); }
.eq-content { margin: 0 0 12px; font-size: 14px; line-height: 1.6; color: var(--text-main); }
.eq-options { display: flex; flex-direction: column; gap: 6px; }
.eq-opt { display: flex; align-items: center; gap: 8px; padding: 8px 12px; border: 1px solid var(--border); border-radius: 8px; cursor: pointer; font-size: 14px; transition: all 0.12s; }
.eq-opt:hover { border-color: var(--primary); }
.eq-opt.picked { border-color: var(--primary); background: rgba(var(--primary-rgb, 74,144,226), 0.06); }
.eq-opt input { accent-color: var(--primary); }
.eq-fill { margin-top: 8px; }

/* 结果页 */
.exam-result { display: flex; justify-content: center; padding-top: 60px; }
.result-card { text-align: center; padding: 40px 60px; background: var(--bg-card); border-radius: 16px; border: 2px solid var(--primary); }
.result-icon { font-size: 64px; margin-bottom: 10px; }
.result-card h2 { margin: 0 0 16px; color: var(--text-main); }
.result-score { font-size: 56px; font-weight: 700; color: var(--primary); }
.result-score span { font-size: 20px; color: var(--text-sub); }
.result-detail { display: flex; gap: 20px; justify-content: center; margin-top: 12px; font-size: 14px; color: var(--text-sub); }

/* 试卷详情 */
.paper-detail-meta { display: flex; gap: 16px; font-size: 13px; color: var(--text-sub); flex-wrap: wrap; }
.paper-detail-qs { display: flex; flex-direction: column; gap: 6px; max-height: 50vh; overflow-y: auto; }
.paper-q-item { padding: 8px 10px; border: 1px solid var(--border); border-radius: 6px; }
.pq-header { font-size: 13px; color: var(--text-main); }
.pq-meta { font-size: 11px; color: var(--text-sub); margin-top: 2px; }

/* 组卷工具 */
.cat-check-grid { display: flex; flex-wrap: wrap; gap: 4px; max-height: 120px; overflow-y: auto; }
.cat-check { padding: 3px 8px; border: 1px solid var(--border); border-radius: 10px; font-size: 12px; cursor: pointer; user-select: none; color: var(--text-sub); }
.cat-check.on { background: var(--primary); color: #fff; border-color: var(--primary); }
.cat-check:hover { border-color: var(--primary); }
.pool-tools { display: flex; gap: 6px; margin-bottom: 8px; flex-wrap: wrap; }
.pool-row { display: flex; align-items: center; gap: 8px; padding: 7px 10px; cursor: pointer; border-bottom: 1px solid var(--border); font-size: 12px; }
.pool-row:hover { background: var(--bg-main); }
.pool-row.selected { background: rgba(var(--primary-rgb, 74,144,226), 0.06); }
.pool-type { padding: 1px 5px; border-radius: 4px; background: var(--bg-main); font-size: 10px; color: var(--primary); white-space: nowrap; }
.pool-text { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: var(--text-main); }
.pool-ans { font-size: 11px; color: var(--success); white-space: nowrap; }
.pool-diff { font-size: 11px; color: var(--accent); white-space: nowrap; }
.selected-box { border: 2px solid var(--primary); border-radius: 10px; padding: 12px; background: var(--bg-main); position: sticky; top: 12px; }

/* 弹窗 */
.modal-overlay { position: fixed; inset: 0; z-index: 8500; background: rgba(0,0,0,0.4); display: flex; align-items: center; justify-content: center; }
.modal-panel { width: 640px; max-width: 95vw; max-height: 90vh; background: var(--bg-card); border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.2); display: flex; flex-direction: column; }
.modal-panel-big { width: 900px; max-width: 97vw; max-height: 92vh; background: var(--bg-card); border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.25); display: flex; flex-direction: column; }
.modal-header { display: flex; justify-content: space-between; align-items: center; padding: 14px 18px; border-bottom: 1px solid var(--border); }
.modal-header h3 { margin: 0; font-size: 16px; }
.modal-body { padding: 16px 18px; overflow-y: auto; flex: 1; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 12px 18px; border-top: 1px solid var(--border); }
.form-group { margin-bottom: 10px; }
.form-group label { display: block; font-size: 12px; color: var(--text-sub); margin-bottom: 3px; }
.form-row { display: flex; gap: 12px; }
.form-row .form-group { flex: 1; }

/* 定时考试输入控件 */
.scheduled-time-box { display: flex; gap: 8px; flex-wrap: wrap; padding: 10px 14px; background: var(--bg-main); border: 1px dashed var(--primary); border-radius: 8px; margin-bottom: 6px; }
.scheduled-time-box .form-group { margin-bottom: 0; min-width: 120px; }
.scheduled-summary { font-size: 13px; color: var(--primary); font-weight: 600; margin-bottom: 10px; padding: 4px 10px; background: rgba(var(--primary-rgb, 74,144,226), 0.06); border-radius: 6px; display: inline-block; }

@media (max-width: 768px) {
  .em-tools { flex-direction: column; }
  .em-stats { flex-wrap: wrap; }
  .em-stat { flex: 1 1 40%; }
  .paper-card { flex-direction: column; align-items: flex-start; }
  .paper-card-meta { flex-wrap: wrap; }
  .exam-top-bar { flex-wrap: wrap; gap: 8px; }
  .exam-title { width: 100%; }
}
</style>
