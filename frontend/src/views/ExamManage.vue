<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface QItem {
  id: number; question_type: string; question_content: string
  options: Record<string, string> | null; answer: string
  explanation: string | null; target_position: string | null
  difficulty_level: number; related_knowledge_id: number | null; created_at: string | null
}
interface DraftItem {
  question_content: string; options: Record<string, string> | null
  answer: string; explanation: string; _draft?: boolean
}
interface Stats { total: number; by_position: { position: string; count: number }[]; avg_difficulty: number; recent_new: number }

const loading = ref(true)
const items = ref<QItem[]>([])
const total = ref(0)
const page = ref(1)
const posFilter = ref('')
const diffFilter = ref(0)
const typeFilter = ref('')
const keyword = ref('')

// 新增/编辑
const showForm = ref(false)
const editing = ref<Partial<QItem>>({})
const isEdit = ref(false)
const posLabel: Record<string, string> = { sales: '销售', tech: '技术', service: '客服', clerk: '文员', public: '公共' }

// AI出题
const showAI = ref(false)
const aiKnowledgeId = ref(0)
const aiCount = ref(3)
const aiDrafts = ref<DraftItem[]>([])
const aiLoading = ref(false)
const aiTitle = ref('')

// 统计
const stats = ref<Stats>({ total: 0, by_position: [], avg_difficulty: 0, recent_new: 0 })

async function fetchList() {
  loading.value = true
  const params: any = { page: page.value, page_size: 20 }
  if (posFilter.value) params.position = posFilter.value
  if (diffFilter.value) params.difficulty = diffFilter.value
  if (typeFilter.value) params.question_type = typeFilter.value
  if (keyword.value) params.keyword = keyword.value
  const { data } = await axios.get('/api/questions/list', { params })
  items.value = data.data.items
  total.value = data.data.total
  loading.value = false
}

async function fetchStats() {
  const { data } = await axios.get('/api/questions/stats')
  stats.value = data.data
}

function search() { page.value = 1; fetchList() }

function openCreate() { isEdit.value = false; editing.value = { question_type: 'single_choice', question_content: '', answer: '', difficulty_level: 1 }; showForm.value = true }
function openEdit(q: QItem) { isEdit.value = true; editing.value = { ...q }; showForm.value = true }

async function saveForm() {
  const q = editing.value
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
    const params: any = {
      question_type: q.question_type, question_content: q.question_content,
      answer: q.answer || 'A',
    }
    if (q.explanation) params.explanation = q.explanation
    if (q.target_position) params.target_position = q.target_position
    if (q.difficulty_level) params.difficulty_level = q.difficulty_level
    if (q.options) params.options_json = JSON.stringify(q.options)
    await axios.post('/api/questions', null, { params })
  }
  showForm.value = false
  fetchList(); fetchStats()
}

async function removeQ(id: number) {
  if (!confirm('确定移除此题目？')) return
  await axios.put(`/api/questions/${id}/status`)
  fetchList(); fetchStats()
}

async function aiGenerate() {
  aiLoading.value = true
  aiDrafts.value = []
  try {
    const { data } = await axios.post(`/api/questions/ai-generate?knowledge_id=${aiKnowledgeId.value}&count=${aiCount.value}`)
    aiDrafts.value = data.data.drafts || []
    aiTitle.value = data.data.knowledge_title
  } catch (e: any) {
    alert('AI出题失败: ' + (e.response?.data?.detail || e.message))
  } finally {
    aiLoading.value = false
  }
}

async function confirmDraft(d: DraftItem) {
  const params: any = {
    question_type: 'single_choice', question_content: d.question_content,
    options_json: JSON.stringify(d.options || {}), answer: d.answer,
  }
  if (d.explanation) params.explanation = d.explanation
  await axios.post('/api/questions', null, { params })
  fetchList(); fetchStats()
}

onMounted(() => { fetchList(); fetchStats() })
</script>

<template>
  <div class="em-page">
    <div class="em-head">
      <h2 class="page-title">考试管理</h2>
      <div class="em-actions">
        <button class="btn btn-sm" @click="openCreate">+ 新增题目</button>
        <button class="btn btn-sm btn-outline" @click="showAI = true; aiKnowledgeId = 0; aiDrafts = []">🤖 AI出题</button>
      </div>
    </div>

    <!-- 健康度 -->
    <div class="em-stats" v-if="stats.total">
      <div class="em-stat"><span class="ems-num">{{ stats.total }}</span><span class="ems-label">题目总数</span></div>
      <div class="em-stat"><span class="ems-num">{{ stats.avg_difficulty }}</span><span class="ems-label">平均难度</span></div>
      <div class="em-stat"><span class="ems-num">+{{ stats.recent_new }}</span><span class="ems-label">近7天新增</span></div>
      <div class="em-stat pos-breakdown"><span v-for="b in stats.by_position" :key="b.position">{{ posLabel[b.position] || b.position || '未知' }}：{{ b.count }} 题</span></div>
    </div>

    <!-- 筛选栏 -->
    <div class="em-tools">
      <input v-model="keyword" placeholder="搜索题目..." class="form-input" style="width:200px" @keydown.enter="search" />
      <select v-model="posFilter" @change="search" class="form-input" style="width:auto"><option value="">全部岗位</option><option value="sales">销售</option><option value="tech">技术</option><option value="service">客服</option><option value="clerk">文员</option><option value="">公共</option></select>
      <select v-model="diffFilter" @change="search" class="form-input" style="width:auto"><option value="0">全部难度</option><option v-for="n in 5" :key="n" :value="n">{{ '★'.repeat(n) }}</option></select>
      <select v-model="typeFilter" @change="search" class="form-input" style="width:auto"><option value="">全部题型</option><option value="single_choice">单选</option><option value="multi_choice">多选</option><option value="true_false">判断</option><option value="fill_blank">填空</option></select>
      <button class="btn btn-sm" @click="search">搜索</button>
    </div>

    <!-- 题目列表 -->
    <div class="table-responsive" v-if="!loading">
      <table class="em-table">
        <thead><tr><th>ID</th><th>内容</th><th>类型</th><th>答案</th><th>岗位</th><th>难度</th><th>操作</th></tr></thead>
        <tbody>
          <tr v-for="q in items" :key="q.id">
            <td>{{ q.id }}</td><td class="em-q-text">{{ q.question_content.slice(0, 60) }}...</td>
            <td>{{ q.question_type === 'single_choice' ? '单选' : q.question_type === 'multi_choice' ? '多选' : q.question_type === 'true_false' ? '判断' : '填空' }}</td>
            <td>{{ q.answer }}</td><td>{{ posLabel[q.target_position || ''] || '公共' }}</td>
            <td>{{ '★'.repeat(q.difficulty_level) }}</td>
            <td>
              <button class="btn btn-sm btn-outline" @click="openEdit(q)">编辑</button>
              <button class="btn btn-sm btn-danger" @click="removeQ(q.id)">移除</button>
            </td>
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

    <!-- 新增/编辑弹窗 -->
    <Teleport to="body">
      <div v-if="showForm" class="modal-overlay" @click.self="showForm=false">
        <div class="modal-panel">
          <div class="modal-header"><h3>{{ isEdit ? '编辑' : '新增' }}题目</h3><button @click="showForm=false" class="btn btn-sm">×</button></div>
          <div class="modal-body">
            <div class="form-group"><label>题型</label><select v-model="editing.question_type" class="form-input" style="width:100%"><option value="single_choice">单选题</option><option value="multi_choice">多选题</option><option value="true_false">判断题</option><option value="fill_blank">填空题</option></select></div>
            <div class="form-group"><label>题目内容</label><textarea v-model="editing.question_content" class="form-input" style="width:100%;min-height:80px"></textarea></div>
            <div class="form-group"><label>答案</label><input v-model="editing.answer" class="form-input" style="width:100%" placeholder="A/B/C/D 或 true/false 或填空答案" /></div>
            <div class="form-group"><label>解析</label><textarea v-model="editing.explanation" class="form-input" style="width:100%;min-height:60px"></textarea></div>
            <div class="form-row">
              <div class="form-group"><label>目标岗位</label><select v-model="editing.target_position" class="form-input" style="width:100%"><option value="">公共(全员)</option><option value="sales">销售</option><option value="tech">技术</option><option value="service">客服</option><option value="clerk">文员</option></select></div>
              <div class="form-group"><label>难度(1-5)</label><input v-model.number="editing.difficulty_level" type="number" min="1" max="5" class="form-input" style="width:80px" /></div>
            </div>
          </div>
          <div class="modal-footer"><button class="btn btn-outline" @click="showForm=false">取消</button><button class="btn" @click="saveForm">保存</button></div>
        </div>
      </div>
    </Teleport>

    <!-- AI出题弹窗 -->
    <Teleport to="body">
      <div v-if="showAI" class="modal-overlay" @click.self="showAI=false">
        <div class="modal-panel">
          <div class="modal-header"><h3>🤖 AI 自动出题</h3><button @click="showAI=false" class="btn btn-sm">×</button></div>
          <div class="modal-body">
            <div class="form-group"><label>选择知识条目ID</label><input v-model.number="aiKnowledgeId" type="number" class="form-input" style="width:100%" placeholder="输入已有知识的ID" /></div>
            <div class="form-group"><label>生成题目数</label><input v-model.number="aiCount" type="number" min="1" max="5" class="form-input" style="width:80px" /></div>
            <button class="btn" @click="aiGenerate" :disabled="aiLoading || !aiKnowledgeId">{{ aiLoading ? 'AI生成中...' : '生成草稿' }}</button>
            <div v-if="aiTitle" style="margin-top:12px;font-size:13px;color:var(--text-sub)">基于知识：{{ aiTitle }}</div>
            <div v-if="aiDrafts.length" style="margin-top:16px">
              <h4 style="font-size:13px;color:var(--text-main);margin-bottom:8px">AI 生成的草稿（点击确认入库）</h4>
              <div v-for="(d, i) in aiDrafts" :key="i" class="draft-item">
                <p class="draft-q">{{ i + 1 }}. {{ d.question_content }}</p>
                <p class="draft-a">答案：{{ d.answer }} | {{ d.explanation?.slice(0, 40) }}</p>
                <button class="btn btn-sm" @click="confirmDraft(d)">确认入库</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.em-page { max-width: 1100px; margin: 0 auto; }
.page-title { font-size: 20px; margin: 0; color: var(--text-main); }
.em-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.em-actions { display: flex; gap: 8px; }

.em-stats { display: flex; gap: 16px; margin-bottom: 16px; flex-wrap: wrap; }
.em-stat { text-align: center; padding: 12px 20px; background: var(--bg-card); border: 1px solid var(--border); border-radius: 8px; min-width: 100px; }
.em-stat.pos-breakdown { min-width: 140px; text-align: left; }
.em-stat.pos-breakdown span { display: block; font-size: 13px; line-height: 1.8; }
.ems-num { display: block; font-size: 24px; font-weight: 700; color: var(--primary); }
.ems-label { font-size: 11px; color: var(--text-sub); }

.em-tools { display: flex; gap: 8px; margin-bottom: 12px; align-items: center; flex-wrap: wrap; }

.em-table { width: 100%; border-collapse: collapse; font-size: 13px; background: var(--bg-card); border-radius: 8px; overflow: hidden; }
.em-table th, .em-table td { padding: 8px 10px; text-align: left; border-bottom: 1px solid var(--border); }
.em-table th { background: var(--bg-main); font-size: 12px; color: var(--text-sub); }
.em-q-text { max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.em-pager { display: flex; justify-content: center; align-items: center; gap: 12px; margin-top: 16px; }

.modal-overlay { position: fixed; inset: 0; z-index: 8500; background: rgba(0,0,0,0.4); display: flex; align-items: center; justify-content: center; }
.modal-panel { width: 640px; max-width: 95vw; max-height: 90vh; background: var(--bg-card); border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.2); display: flex; flex-direction: column; }
.modal-header { display: flex; justify-content: space-between; align-items: center; padding: 14px 18px; border-bottom: 1px solid var(--border); }
.modal-header h3 { margin: 0; font-size: 16px; }
.modal-body { padding: 16px 18px; overflow-y: auto; flex: 1; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 12px 18px; border-top: 1px solid var(--border); }
.form-group { margin-bottom: 10px; }
.form-group label { display: block; font-size: 12px; color: var(--text-sub); margin-bottom: 3px; }
.form-row { display: flex; gap: 12px; }
.form-row .form-group { flex: 1; }

.draft-item { padding: 12px; border: 1px solid var(--border); border-radius: 8px; margin-bottom: 10px; }
.draft-q { font-size: 14px; color: var(--text-main); margin: 0 0 4px; }
.draft-a { font-size: 12px; color: var(--text-sub); margin: 0 0 8px; }

@media (max-width: 768px) {
  .em-tools { flex-direction: column; }
  .em-stats { flex-wrap: wrap; }
  .em-stat { flex: 1 1 40%; }
}
</style>
