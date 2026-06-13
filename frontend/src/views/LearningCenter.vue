<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface ExamHistoryItem { id: number; paper_id: number; paper_title: string; score: number; correct_count: number; total_questions: number; status: string; started_at: string | null; submitted_at: string | null }
interface ExamDetail { id: number; paper_id: number; score: number; correct_count: number; total_questions: number; submitted_at: string | null; questions: ExamDetailQ[] }
interface ExamDetailQ { id: number; question_type: string; question_content: string; options: Record<string, string> | null; answer: string; explanation: string | null; user_answer: string; is_correct: boolean }
interface DQStatItem { category_id: number; category_name: string; icon: string | null; total_questions: number; correct_count: number; accuracy: number }

const loading = ref(true)
const examHistory = ref<ExamHistoryItem[]>([])
const dqStats = ref<DQStatItem[]>([])
const dqTotal = ref(0)
const examDetail = ref<ExamDetail | null>(null)
const showExamDetail = ref(false)

const typeLabel: Record<string, string> = { single_choice: '单选题', multi_choice: '多选题', true_false: '判断题', fill_blank: '填空题' }

async function fetchData() {
  try {
    const [examRes, dqRes] = await Promise.all([
      axios.get('/api/exam/history'),
      axios.get('/api/questions/history-stats'),
    ])
    examHistory.value = examRes.data.data.items || []
    dqStats.value = dqRes.data.data.items || []
    dqTotal.value = dqRes.data.data.total || 0
  } finally {
    loading.value = false
  }
}

async function viewExamDetail(attemptId: number) {
  try {
    const { data } = await axios.get(`/api/exam/attempt/${attemptId}`)
    examDetail.value = data.data
    showExamDetail.value = true
  } catch (e: any) { alert(e.response?.data?.detail || '加载失败') }
}

function closeDetail() { showExamDetail.value = false; examDetail.value = null }

const totalExams = () => examHistory.value.filter(e => e.status === 'submitted').length
const avgScore = () => {
  const s = examHistory.value.filter(e => e.status === 'submitted' && e.total_questions > 0)
  if (!s.length) return 0
  return Math.round(s.reduce((a, e) => a + (e.correct_count / e.total_questions * 100), 0) / s.length)
}

onMounted(fetchData)
</script>

<template>
  <div class="lc-page">
    <h2 class="page-title">学习中心</h2>
    <div v-if="loading" class="lc-loading">加载中...</div>

    <template v-else>
      <div class="lc-stats">
        <div class="lc-stat card"><div class="stat-num">{{ totalExams() }}</div><div class="stat-label">参加考试</div></div>
        <div class="lc-stat card"><div class="stat-num">{{ dqTotal }}</div><div class="stat-label">每次一题</div></div>
        <div class="lc-stat card"><div class="stat-num">{{ avgScore() }}%</div><div class="stat-label">考试均分</div></div>
      </div>

      <div class="card" style="margin-bottom:16px">
        <h3 style="font-size:14px;margin:0 0 10px">📝 考试记录（{{ examHistory.length }} 次）</h3>
        <div v-if="examHistory.length === 0" class="empty-hint">暂无考试记录</div>
        <div v-else class="scroll-wrap">
          <table class="lc-table"><thead><tr><th>试卷</th><th>得分</th><th>正确</th><th>状态</th><th>时间</th><th>操作</th></tr></thead>
            <tbody>
              <tr v-for="e in examHistory" :key="e.id">
                <td>{{ e.paper_title }}</td>
                <td><b :style="{ color: e.score >= 60 ? 'var(--success)' : 'var(--danger)' }">{{ e.score }} 分</b></td>
                <td>{{ e.correct_count }}/{{ e.total_questions }}</td>
                <td>{{ e.status === 'submitted' ? '✅ 已交卷' : '⏳ 进行中' }}</td>
                <td style="font-size:11px;color:var(--text-sub)">{{ (e.submitted_at || e.started_at || '').slice(0, 16) }}</td>
                <td><button v-if="e.status === 'submitted'" class="btn btn-sm btn-outline" @click="viewExamDetail(e.id)">👁 详情</button></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div class="card">
        <h3 style="font-size:14px;margin:0 0 10px">❓ 每次一题汇总（{{ dqTotal }} 题）</h3>
        <div v-if="!dqStats.length" class="empty-hint">暂无答题记录</div>
        <div v-else class="dq-summary-grid">
          <div v-for="s in dqStats" :key="s.category_id" class="dq-summary-card">
            <div class="dqs-icon">{{ s.icon || '📄' }}</div>
            <div class="dqs-info">
              <div class="dqs-name">{{ s.category_name }}</div>
              <div class="dqs-bar-wrap">
                <div class="dqs-bar-bg">
                  <div class="dqs-bar" :style="{ width: s.accuracy + '%', background: s.accuracy < 40 ? 'var(--danger)' : s.accuracy < 70 ? 'var(--accent)' : 'var(--success)' }"></div>
                </div>
                <span class="dqs-pct">{{ s.accuracy }}%</span>
              </div>
              <div class="dqs-detail">做对 {{ s.correct_count }} / 共 {{ s.total_questions }} 题</div>
            </div>
          </div>
        </div>
      </div>
    </template>

    <Teleport to="body">
      <div v-if="showExamDetail && examDetail" class="modal-overlay" @click.self="closeDetail">
        <div class="modal-panel-big">
          <div class="modal-header"><h3>📝 考试详情</h3><button @click="closeDetail" class="btn btn-sm">×</button></div>
          <div class="modal-body">
            <div class="det-sum"><span class="ds-num">{{ examDetail.score }}</span><span class="ds-unit">分</span><span style="margin-left:16px;font-size:13px;color:var(--text-sub)">答对 {{ examDetail.correct_count }}/{{ examDetail.total_questions }} 题（{{ Math.round(examDetail.correct_count / examDetail.total_questions * 100) }}%）</span></div>
            <div class="det-qs">
              <div v-for="(q, i) in examDetail.questions" :key="q.id" class="dq" :class="q.is_correct ? 'ok' : 'err'">
                <div class="dq-hd"><b>{{ i + 1 }}.</b> <span class="dq-type">{{ typeLabel[q.question_type] || q.question_type }}</span> <span :style="{ color: q.is_correct ? 'var(--success)' : 'var(--danger)' }">{{ q.is_correct ? '✅ 正确' : '❌ 错误' }}</span></div>
                <p class="dq-txt">{{ q.question_content }}</p>
                <div v-if="q.options" class="dq-opts">
                  <span v-for="(v, k) in q.options" :key="k" class="dq-o" :class="{ 'dq-o-ok': k === q.answer, 'dq-o-bad': k === q.user_answer && k !== q.answer }">{{ k }}. {{ v }}</span>
                </div>
                <div class="dq-ans">你的答案：<b :style="{ color: q.is_correct ? 'var(--success)' : 'var(--danger)' }">{{ q.user_answer || '(未作答)' }}</b> <template v-if="!q.is_correct">| 正确答案：<b style="color:var(--success)">{{ q.answer }}</b></template></div>
                <div v-if="q.explanation" class="dq-exp">💡 {{ q.explanation }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.lc-page { max-width: 960px; margin: 0 auto; }
.page-title { font-size: 20px; margin-bottom: 16px; color: var(--text-main); }
.lc-loading, .empty-hint { text-align: center; padding: 40px; color: var(--text-sub); }
.lc-stats { display: flex; gap: 12px; margin-bottom: 16px; }
.lc-stat { flex: 1; text-align: center; padding: 16px; }
.stat-num { font-size: 28px; font-weight: 700; color: var(--primary); }
.stat-label { font-size: 12px; color: var(--text-sub); margin-top: 4px; }
.scroll-wrap { overflow-x: auto; }
.lc-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.lc-table th, .lc-table td { padding: 8px 10px; text-align: left; border-bottom: 1px solid var(--border); }
.lc-table th { font-size: 12px; color: var(--text-sub); background: var(--bg-main); }

/* 每次一题汇总卡片 */
.dq-summary-grid { display: flex; flex-direction: column; gap: 8px; }
.dq-summary-card { display: flex; align-items: center; gap: 12px; padding: 12px 14px; border: 1px solid var(--border); border-radius: 10px; transition: background 0.1s; }
.dq-summary-card:hover { background: var(--bg-main); }
.dqs-icon { font-size: 22px; width: 36px; text-align: center; flex-shrink: 0; }
.dqs-info { flex: 1; min-width: 0; }
.dqs-name { font-size: 13px; font-weight: 600; color: var(--text-main); margin-bottom: 4px; }
.dqs-bar-wrap { display: flex; align-items: center; gap: 8px; }
.dqs-bar-bg { flex: 1; height: 6px; background: var(--bg-main); border-radius: 3px; overflow: hidden; }
.dqs-bar { height: 100%; border-radius: 3px; transition: width 0.3s; }
.dqs-pct { font-size: 13px; font-weight: 700; color: var(--primary); min-width: 40px; text-align: right; }
.dqs-detail { font-size: 11px; color: var(--text-sub); margin-top: 2px; }

.modal-overlay { position: fixed; inset: 0; z-index: 8500; background: rgba(0,0,0,0.4); display: flex; align-items: center; justify-content: center; }
.modal-panel-big { width: 900px; max-width: 97vw; max-height: 92vh; background: var(--bg-card); border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.25); display: flex; flex-direction: column; }
.modal-header { display: flex; justify-content: space-between; align-items: center; padding: 14px 18px; border-bottom: 1px solid var(--border); }
.modal-header h3 { margin: 0; font-size: 16px; }
.modal-body { padding: 16px 18px; overflow-y: auto; flex: 1; }
.det-sum { margin-bottom: 16px; padding: 16px; background: var(--bg-main); border-radius: 10px; display: flex; align-items: center; }
.ds-num { font-size: 42px; font-weight: 700; color: var(--primary); }
.ds-unit { font-size: 16px; color: var(--text-sub); margin-left: 4px; }
.det-qs { display: flex; flex-direction: column; gap: 12px; }
.dq { padding: 14px 16px; border-radius: 10px; border: 1px solid var(--border); border-left: 4px solid var(--border); }
.dq.ok { border-left-color: var(--success); background: rgba(122,166,104,0.04); }
.dq.err { border-left-color: var(--danger); background: rgba(192,64,59,0.04); }
.dq-hd { display: flex; align-items: center; gap: 8px; margin-bottom: 6px; font-size: 14px; }
.dq-type { padding: 1px 8px; border-radius: 6px; font-size: 10px; background: var(--bg-main); color: var(--primary); }
.dq-txt { margin: 0 0 8px; font-size: 14px; line-height: 1.6; }
.dq-opts { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 8px; }
.dq-o { padding: 4px 10px; border: 1px solid var(--border); border-radius: 6px; font-size: 12px; color: var(--text-sub); }
.dq-o-ok { background: rgba(122,166,104,0.1); border-color: var(--success); color: var(--success); font-weight: 600; }
.dq-o-bad { background: rgba(192,64,59,0.08); border-color: var(--danger); color: var(--danger); }
.dq-ans { font-size: 13px; margin-bottom: 4px; }
.dq-exp { font-size: 12px; color: var(--text-sub); margin-top: 4px; padding: 6px 8px; background: var(--bg-main); border-radius: 6px; }
@media (max-width: 768px) { .lc-stats { flex-direction: column; } }
</style>
