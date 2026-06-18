<script setup lang="ts">
// FW-01 知识缺口工作台 —— 飞轮"进化引擎"
// 候选缺口(未命中聚类) → 指派建单 → 关闭。独立页面，不改现有页面。
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface Candidate {
  question: string
  hit_count: number
  last_at: string | null
  first_at: string | null
  position: string
}
interface Gap {
  id: number
  question: string
  hit_count: number
  target_kb: string | null
  suggest_category_id: number | null
  category_name: string | null
  status: string
  assignee_id: number | null
  assignee_name: string | null
  related_knowledge_id: number | null
  created_at: string | null
  closed_at: string | null
}
interface UserOpt { id: number; real_name: string; position: string }
interface CatOpt { id: number; name: string; knowledge_base: string }

const loading = ref(false)
const candidates = ref<Candidate[]>([])
const gaps = ref<Gap[]>([])
const users = ref<UserOpt[]>([])
const categories = ref<CatOpt[]>([])

// 指派弹窗
const assignVisible = ref(false)
const assignForm = ref({ question: '', assignee_id: 0, target_kb: '', suggest_category_id: 0 })

const POS_LABEL: Record<string, string> = { sales: '销售', tech: '技术', service: '客服', clerk: '内勤' }
const KB_LABEL: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }

function posLabel(p: string) { return POS_LABEL[p] || p || '-' }

async function loadAll() {
  loading.value = true
  try {
    const [listRes, optRes] = await Promise.all([
      axios.get('/api/flywheel/gap/list'),
      axios.get('/api/flywheel/gap/options'),
    ])
    candidates.value = listRes.data.data.candidates || []
    gaps.value = listRes.data.data.gaps || []
    users.value = optRes.data.data.users || []
    categories.value = optRes.data.data.categories || []
  } catch (e) {
    alert('加载失败，请确认已用管理员账号登录')
  } finally {
    loading.value = false
  }
}

function openAssign(c: Candidate) {
  assignForm.value = {
    question: c.question,
    assignee_id: users.value[0]?.id || 0,
    target_kb: '',
    suggest_category_id: 0,
  }
  assignVisible.value = true
}

async function submitAssign() {
  if (!assignForm.value.assignee_id) { alert('请选择指派人'); return }
  try {
    await axios.post('/api/flywheel/gap/assign', null, {
      params: {
        question: assignForm.value.question,
        assignee_id: assignForm.value.assignee_id,
        target_kb: assignForm.value.target_kb,
        suggest_category_id: assignForm.value.suggest_category_id,
      },
    })
    assignVisible.value = false
    await loadAll()
  } catch (e: any) {
    alert(e?.response?.data?.detail || '指派失败')
  }
}

async function closeGap(g: Gap) {
  const input = prompt('关联补充的知识条目ID（可留空直接关闭）：', '')
  if (input === null) return
  const rid = input.trim() ? parseInt(input.trim()) : 0
  try {
    await axios.post(`/api/flywheel/gap/${g.id}/close`, null, {
      params: { related_knowledge_id: isNaN(rid) ? 0 : rid },
    })
    await loadAll()
  } catch (e: any) {
    alert(e?.response?.data?.detail || '关闭失败')
  }
}

onMounted(loadAll)
</script>

<template>
  <div class="gap-board">
    <div class="page-head">
      <h2>知识缺口工作台</h2>
      <p class="sub">把员工"问了没问到答案"的问题，沉淀为可指派、可关闭的知识缺口工单（飞轮的进化引擎）。</p>
    </div>

    <div v-if="loading" class="loading">加载中…</div>

    <!-- 候选缺口 -->
    <section class="block">
      <h3>候选缺口 <span class="count">{{ candidates.length }}</span>
        <span class="hint">（阿能问答未命中，按被问次数排序，已建单的不再出现）</span>
      </h3>
      <table v-if="candidates.length">
        <thead>
          <tr><th>问题</th><th>被问次数</th><th>提问岗位</th><th>最近提问</th><th>操作</th></tr>
        </thead>
        <tbody>
          <tr v-for="(c, i) in candidates" :key="i">
            <td class="q">{{ c.question }}</td>
            <td class="num">{{ c.hit_count }}</td>
            <td>{{ posLabel(c.position) }}</td>
            <td class="time">{{ c.last_at ? c.last_at.slice(0, 16).replace('T', ' ') : '-' }}</td>
            <td><button class="btn" @click="openAssign(c)">指派</button></td>
          </tr>
        </tbody>
      </table>
      <p v-else-if="!loading" class="empty">暂无候选缺口（所有未命中问题都已建单，或还没有未命中记录）。</p>
    </section>

    <!-- 已建单缺口 -->
    <section class="block">
      <h3>缺口工单 <span class="count">{{ gaps.length }}</span></h3>
      <table v-if="gaps.length">
        <thead>
          <tr><th>问题</th><th>被问</th><th>目标库</th><th>建议分类</th><th>指派给</th><th>状态</th><th>操作</th></tr>
        </thead>
        <tbody>
          <tr v-for="g in gaps" :key="g.id" :class="{ closed: g.status === 'closed' }">
            <td class="q">{{ g.question }}</td>
            <td class="num">{{ g.hit_count }}</td>
            <td>{{ g.target_kb ? (KB_LABEL[g.target_kb] || g.target_kb) : '-' }}</td>
            <td>{{ g.category_name || '-' }}</td>
            <td>{{ g.assignee_name || '-' }}</td>
            <td>
              <span :class="['tag', g.status]">{{ g.status === 'assigned' ? '处理中' : '已关闭' }}</span>
            </td>
            <td>
              <button v-if="g.status === 'assigned'" class="btn close" @click="closeGap(g)">关闭</button>
              <span v-else class="rel">{{ g.related_knowledge_id ? '知识#' + g.related_knowledge_id : '—' }}</span>
            </td>
          </tr>
        </tbody>
      </table>
      <p v-else-if="!loading" class="empty">暂无缺口工单。</p>
    </section>

    <!-- 指派弹窗 -->
    <div v-if="assignVisible" class="modal-overlay" @click.self="assignVisible = false">
      <div class="modal">
        <h3>指派知识缺口</h3>
        <label>问题</label>
        <p class="q-text">{{ assignForm.question }}</p>
        <label>指派给</label>
        <select v-model.number="assignForm.assignee_id">
          <option v-for="u in users" :key="u.id" :value="u.id">
            {{ u.real_name }}（{{ posLabel(u.position) }}）
          </option>
        </select>
        <label>目标知识库</label>
        <select v-model="assignForm.target_kb">
          <option value="">（不指定）</option>
          <option value="public">公共</option>
          <option value="sales">销售</option>
          <option value="tech">技术</option>
          <option value="service">客服</option>
        </select>
        <label>建议分类</label>
        <select v-model.number="assignForm.suggest_category_id">
          <option :value="0">（不指定）</option>
          <option v-for="c in categories" :key="c.id" :value="c.id">
            {{ c.name }}（{{ KB_LABEL[c.knowledge_base] || c.knowledge_base }}）
          </option>
        </select>
        <div class="modal-actions">
          <button class="btn" @click="assignVisible = false">取消</button>
          <button class="btn primary" @click="submitAssign">确认指派</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.gap-board { padding: 20px; max-width: 70%; margin: 0; }
.page-head h2 { margin: 0 0 4px; color: var(--text-main, #1a1a1a); }
.page-head .sub { margin: 0 0 16px; color: var(--text-sub, #888); font-size: 13px; }
.loading { color: var(--text-sub, #888); padding: 12px 0; }
.block { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 16px; margin-bottom: 20px; }
.block h3 { margin: 0 0 12px; font-size: 15px; color: var(--text-main, #1a1a1a); }
.count { display: inline-block; background: var(--primary, #6B7B8B); color: #fff; border-radius: 10px; padding: 0 8px; font-size: 12px; margin-left: 4px; }
.hint, .block h3 .hint { font-weight: normal; font-size: 12px; color: var(--text-sub, #999); margin-left: 6px; }
table { width: 100%; border-collapse: collapse; font-size: 13px; }
th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid var(--border, #eee); }
th { color: var(--text-sub, #888); font-weight: 600; }
td.q { max-width: 380px; }
td.num { font-weight: 600; color: var(--primary, #6B7B8B); }
td.time { color: var(--text-sub, #999); white-space: nowrap; }
tr.closed { opacity: 0.55; }
.tag { padding: 2px 8px; border-radius: 4px; font-size: 12px; }
.tag.assigned { background: #fff4e5; color: #c77700; }
.tag.closed { background: #eef6ee; color: #3a8f3a; }
.btn { padding: 4px 12px; border: 1px solid var(--border, #ccc); background: var(--bg-card, #fff); border-radius: 4px; cursor: pointer; font-size: 12px; }
.btn:hover { border-color: var(--primary, #6B7B8B); color: var(--primary, #6B7B8B); }
.btn.primary { background: var(--primary, #6B7B8B); color: #fff; border-color: var(--primary, #6B7B8B); }
.btn.close { color: #c77700; }
.rel { color: var(--text-sub, #999); font-size: 12px; }
.empty { color: var(--text-sub, #999); font-size: 13px; padding: 8px 0; }
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.35); z-index: 9999; display: flex; align-items: center; justify-content: center; }
.modal { background: var(--bg-card, #fff); border-radius: 8px; padding: 20px 24px; width: 420px; max-width: 92vw; }
.modal h3 { margin: 0 0 14px; }
.modal label { display: block; font-size: 12px; color: var(--text-sub, #888); margin: 10px 0 4px; }
.modal .q-text { margin: 0; font-size: 13px; color: var(--text-main, #1a1a1a); background: var(--bg-main, #f6f6f6); padding: 8px; border-radius: 4px; }
.modal select { width: 100%; padding: 6px; border: 1px solid var(--border, #ccc); border-radius: 4px; font-size: 13px; }
.modal-actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 18px; }
</style>
