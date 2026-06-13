<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import axios from 'axios'

const auth = useAuthStore()
const router = useRouter()
const route = useRoute()

interface ExamQ {
  epq_id: number; id: number; question_type: string; question_content: string
  options: Record<string, string> | null; difficulty_level: number; sort_order: number
}
interface ExamInfo { attempt_id: number; paper_id: number; title: string; duration_minutes: number; total_questions: number; questions: ExamQ[]; started_at: string }

const examInfo = ref<ExamInfo | null>(null)
const answers = ref<Record<string, string>>({})
const timeLeft = ref(0)       // 剩余秒数
const submitted = ref(false)
const result = ref<{ score: number; correct_count: number; total_questions: number } | null>(null)
const submitting = ref(false)

// 可用考试列表
interface AvailableExam { id: number; title: string; target_type: string; time_mode: string; duration_minutes: number; total_questions: number; already_submitted: boolean }
const availableExams = ref<AvailableExam[]>([])
const loading = ref(true)

const typeLabel: Record<string, string> = { single_choice: '单选题', multi_choice: '多选题', true_false: '判断题', fill_blank: '填空题' }

function formatTime(sec: number): string {
  const m = Math.floor(sec / 60), s = sec % 60
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
}

let timer: any = null

async function fetchAvailable() {
  loading.value = true
  try {
    const { data } = await axios.get('/api/exam/available')
    availableExams.value = data.data.items
  } finally { loading.value = false }
}

async function startExam(paperId: number) {
  try {
    const { data } = await axios.get(`/api/exam/start/${paperId}`)
    examInfo.value = data.data
    timeLeft.value = (data.data.duration_minutes || 60) * 60
    submitted.value = false; result.value = null; answers.value = {}
    startTimer()
    // 阻止意外离开
    window.addEventListener('beforeunload', warnLeave)
  } catch (e: any) {
    alert(e.response?.data?.detail || '无法开始考试')
  }
}

function startTimer() {
  clearInterval(timer)
  timer = setInterval(() => {
    if (timeLeft.value <= 0) {
      clearInterval(timer)
      if (!submitted.value) submitExam()
      return
    }
    timeLeft.value--
  }, 1000)
}

function warnLeave(e: BeforeUnloadEvent) {
  if (!submitted.value && examInfo.value) {
    e.preventDefault(); e.returnValue = ''
  }
}

async function submitExam() {
  if (submitted.value || !examInfo.value) return
  submitting.value = true
  try {
    const { data } = await axios.post(`/api/exam/submit/${examInfo.value.paper_id}`, { answers: answers.value })
    result.value = data.data
    submitted.value = true
    clearInterval(timer)
    window.removeEventListener('beforeunload', warnLeave)
  } catch (e: any) { alert(e.response?.data?.detail || '提交失败') }
  finally { submitting.value = false }
}

function goBack() {
  if (!submitted.value && examInfo.value && !confirm('确定离开？未提交的答案将丢失。')) return
  examInfo.value = null; submitted.value = false; clearInterval(timer)
  window.removeEventListener('beforeunload', warnLeave)
}

const answeredCount = computed(() => Object.keys(answers.value).length)

onMounted(fetchAvailable)
onUnmounted(() => { clearInterval(timer); window.removeEventListener('beforeunload', warnLeave) })
</script>

<template>
  <div class="et-page">
    <!-- 考试列表 -->
    <div v-if="!examInfo">
      <div class="et-head">
        <h2 class="page-title">📝 我的考试</h2>
      </div>

      <div v-if="loading" style="text-align:center;padding:40px;color:var(--text-sub)">加载中...</div>
      <div v-else-if="availableExams.length === 0" style="text-align:center;padding:60px;color:var(--text-sub)">
        <div style="font-size:48px;margin-bottom:12px">📭</div>
        <p>暂无可用考试</p>
      </div>
      <div v-else class="exam-list">
        <div v-for="ex in availableExams" :key="ex.id" class="exam-card card">
          <div class="exam-card-info">
            <h3>{{ ex.title }}</h3>
            <div class="exam-card-meta">
              <span>📝 {{ ex.total_questions }} 题</span>
              <span>⏱ {{ ex.duration_minutes }} 分钟</span>
              <span>{{ ex.time_mode === 'scheduled' ? '定时考试' : '随时可考' }}</span>
            </div>
          </div>
          <button v-if="ex.already_submitted" class="btn btn-sm" disabled>✅ 已完成</button>
          <button v-else class="btn" @click="startExam(ex.id)">开始考试</button>
        </div>
      </div>
    </div>

    <!-- 考试答题 -->
    <div v-else>
      <!-- 结果页 -->
      <div v-if="submitted && result" class="exam-result">
        <div class="result-card">
          <div class="result-icon">🎉</div>
          <h2>考试完成！</h2>
          <div class="result-score">{{ result.score }} <span>分</span></div>
          <div class="result-detail">
            <span>答对 {{ result.correct_count }} / {{ result.total_questions }} 题</span>
            <span>正确率 {{ Math.round(result.correct_count / result.total_questions * 100) }}%</span>
          </div>
          <button class="btn" @click="goBack" style="margin-top:20px;padding:10px 40px">返回考试列表</button>
        </div>
      </div>

      <!-- 答题页 -->
      <div v-else>
        <div class="exam-top-bar">
          <button class="btn btn-sm btn-outline" @click="goBack">← 返回</button>
          <span class="exam-title">{{ examInfo.title }}</span>
          <span class="exam-progress">{{ answeredCount }} / {{ examInfo.total_questions }} 已答</span>
          <span class="exam-timer" :class="{ urgent: timeLeft < 300 }">⏱ {{ formatTime(timeLeft) }}</span>
          <button class="btn btn-sm" @click="submitExam" :disabled="submitting" style="background:var(--success)">{{ submitting ? '提交中...' : '提交答卷' }}</button>
        </div>

        <div class="exam-qs">
          <div v-for="q in examInfo.questions" :key="q.id" class="eq-item card">
            <div class="eq-header">
              <span>{{ q.sort_order }}.</span>
              <span class="eq-type-badge">{{ typeLabel[q.question_type] || q.question_type }}</span>
              <span class="eq-diff">{{ '★'.repeat(q.difficulty_level) }}</span>
            </div>
            <p class="eq-content">{{ q.question_content }}</p>

            <!-- 单选 -->
            <div v-if="q.question_type === 'single_choice' && q.options" class="eq-options">
              <label v-for="(v, k) in q.options" :key="k" class="eq-opt" :class="{ picked: answers[String(q.id)] === k }">
                <input type="radio" :name="'q' + q.id" :value="k" v-model="answers[String(q.id)]" />
                <span>{{ k }}. {{ v }}</span>
              </label>
            </div>

            <!-- 多选 -->
            <div v-if="q.question_type === 'multi_choice' && q.options" class="eq-options">
              <label v-for="(v, k) in q.options" :key="k" class="eq-opt" :class="{ picked: (answers[String(q.id)] || '').includes(k) }">
                <input type="checkbox" :value="k" @change="(e: any) => {
                  const cur = answers[String(q.id)] || ''
                  const arr = cur ? cur.split(',') : []
                  if (e.target.checked) arr.push(k)
                  else { const idx = arr.indexOf(k); if (idx >= 0) arr.splice(idx, 1) }
                  answers[String(q.id)] = arr.join(',')
                }" />
                <span>{{ k }}. {{ v }}</span>
              </label>
            </div>

            <!-- 判断 -->
            <div v-if="q.question_type === 'true_false'" class="eq-options">
              <label class="eq-opt" :class="{ picked: answers[String(q.id)] === 'true' }">
                <input type="radio" :name="'q' + q.id" value="true" v-model="answers[String(q.id)]" />✅ 正确
              </label>
              <label class="eq-opt" :class="{ picked: answers[String(q.id)] === 'false' }">
                <input type="radio" :name="'q' + q.id" value="false" v-model="answers[String(q.id)]" />❌ 错误
              </label>
            </div>

            <!-- 填空 -->
            <div v-if="q.question_type === 'fill_blank'" class="eq-fill">
              <input v-model="answers[String(q.id)]" class="form-input" style="width:100%" placeholder="请输入答案" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.et-page { max-width: 800px; margin: 0 auto; }
.page-title { font-size: 20px; margin: 0; color: var(--text-main); }
.et-head { margin-bottom: 16px; }

.exam-list { display: flex; flex-direction: column; gap: 10px; }
.exam-card { padding: 16px 20px; display: flex; justify-content: space-between; align-items: center; }
.exam-card-info h3 { margin: 0 0 6px; font-size: 15px; color: var(--text-main); }
.exam-card-meta { display: flex; gap: 12px; font-size: 12px; color: var(--text-sub); }

/* 答题顶部栏 */
.exam-top-bar { display: flex; align-items: center; gap: 16px; padding: 10px 16px; background: var(--bg-card); border: 1px solid var(--border); border-radius: 10px; position: sticky; top: 0; z-index: 100; margin-bottom: 16px; }
.exam-title { font-weight: 600; font-size: 14px; color: var(--text-main); flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.exam-progress { font-size: 12px; color: var(--text-sub); white-space: nowrap; }
.exam-timer { font-size: 18px; font-weight: 700; color: var(--primary); white-space: nowrap; font-variant-numeric: tabular-nums; }
.exam-timer.urgent { color: var(--danger); animation: pulse 1s infinite; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.5} }

/* 题目 */
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

@media (max-width: 768px) {
  .exam-top-bar { flex-wrap: wrap; gap: 8px; }
  .exam-title { width: 100%; }
}
</style>
