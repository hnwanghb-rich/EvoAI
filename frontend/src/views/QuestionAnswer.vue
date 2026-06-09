<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface Question { id: number; question_type: string; question_content: string; options: Record<string, string> | null; difficulty_level: number; push_date: string | null }
interface Result { correct: boolean; answer: string; explanation: string; score: number }

const loading = ref(true)
const question = ref<Question | null>(null)
const result = ref<Result | null>(null)
const userAnswer = ref('')
const selectedOption = ref('')
const submitting = ref(false)
const noQuestion = ref(false)

const typeLabel: Record<string, string> = {
  single_choice: '单选题', multi_choice: '多选题', true_false: '判断题', fill_blank: '填空题',
}
const difficultyLabel = (n: number) => '★'.repeat(n) + '☆'.repeat(5 - n)

async function fetchToday() {
  loading.value = true
  try {
    const { data } = await axios.get('/api/questions/today')
    if (data.data) {
      question.value = data.data
      noQuestion.value = false
    } else {
      noQuestion.value = true
    }
  } finally {
    loading.value = false
  }
}

async function submitAnswer() {
  if (!question.value) return
  let answer = ''
  if (question.value.question_type === 'single_choice' || question.value.question_type === 'multi_choice') {
    answer = selectedOption.value
  } else if (question.value.question_type === 'true_false') {
    answer = selectedOption.value
  } else {
    answer = userAnswer.value
  }
  if (!answer.trim()) return

  submitting.value = true
  try {
    const { data } = await axios.post(`/api/questions/${question.value.id}/answer?user_answer=${encodeURIComponent(answer)}`)
    result.value = data.data
  } finally {
    submitting.value = false
  }
}

onMounted(fetchToday)
</script>

<template>
  <div class="qa-page">
    <h2 class="page-title">每日一题</h2>

    <div v-if="loading" class="qa-loading">加载中...</div>
    <div v-else-if="noQuestion" class="qa-empty">🎉 暂无题目，请明天再来！</div>

    <template v-else-if="question">
      <div class="qa-card card">
        <div class="qa-header">
          <span class="qa-type">{{ typeLabel[question.question_type] || question.question_type }}</span>
          <span class="qa-diff">{{ difficultyLabel(question.difficulty_level) }}</span>
          <span class="qa-date" v-if="question.push_date">{{ question.push_date }}</span>
        </div>
        <div class="qa-content">
          <p>{{ question.question_content }}</p>
        </div>

        <!-- 选择题/判断题 -->
        <template v-if="question.question_type === 'single_choice' || question.question_type === 'true_false'">
          <div class="qa-options" v-if="!result">
            <label
              v-for="(label, key) in question.options || { 'true': '正确', 'false': '错误' }"
              :key="key"
              class="qa-option"
              :class="{ selected: selectedOption === key }"
            >
              <input type="radio" :value="key" v-model="selectedOption" />
              <span>{{ key }}. {{ label }}</span>
            </label>
          </div>
        </template>

        <!-- 多选题 -->
        <template v-else-if="question.question_type === 'multi_choice'">
          <div class="qa-options" v-if="!result" v-for="(label, key) in question.options" :key="key">
            <label class="qa-option checkbox">
              <input type="checkbox" :value="key" v-model="selectedOption" />
              <span>{{ key }}. {{ label }}</span>
            </label>
          </div>
        </template>

        <!-- 填空题 -->
        <template v-else-if="question.question_type === 'fill_blank'">
          <div class="qa-input" v-if="!result">
            <input v-model="userAnswer" placeholder="请输入答案" class="form-input" style="width:100%" @keydown.enter="submitAnswer" />
          </div>
        </template>

        <button v-if="!result" class="btn qa-submit" @click="submitAnswer" :disabled="submitting">
          {{ submitting ? '提交中...' : '提交答案' }}
        </button>

        <!-- 结果展示 -->
        <div v-if="result" class="qa-result" :class="{ correct: result.correct, wrong: !result.correct }">
          <div class="qa-result-icon">{{ result.correct ? '✅' : '❌' }}</div>
          <div class="qa-result-text">{{ result.correct ? '回答正确！+1积分' : '回答错误，已加入错题本' }}</div>
          <div class="qa-answer"><b>正确答案：</b>{{ result.answer }}</div>
          <div class="qa-explanation" v-if="result.explanation">{{ result.explanation }}</div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.qa-page { max-width: 640px; margin: 0 auto; }
.page-title { font-size: 20px; margin-bottom: 16px; color: var(--text-main); }
.qa-loading, .qa-empty { text-align: center; padding: 60px; color: var(--text-sub); }

.qa-card { padding: 24px; }
.qa-header { display: flex; gap: 12px; align-items: center; margin-bottom: 16px; }
.qa-type { padding: 3px 10px; background: var(--primary); color: #fff; border-radius: 10px; font-size: 12px; }
.qa-diff { font-size: 12px; color: var(--accent); }
.qa-date { font-size: 12px; color: var(--text-sub); margin-left: auto; }
.qa-content p { font-size: 16px; line-height: 1.7; color: var(--text-main); margin: 0; }

.qa-options { margin: 16px 0; }
.qa-option {
  display: flex; align-items: center; gap: 8px;
  padding: 10px 14px; margin-bottom: 8px;
  border: 1px solid var(--border); border-radius: 8px;
  cursor: pointer; font-size: 14px; transition: border-color 0.15s;
}
.qa-option:hover { border-color: var(--primary); }
.qa-option.selected { border-color: var(--primary); background: var(--bg-main); }
.qa-option input { accent-color: var(--primary); }
.qa-input { margin: 16px 0; }
.qa-submit { margin-top: 8px; }

.qa-result { margin-top: 16px; padding: 16px; border-radius: 8px; }
.qa-result.correct { background: rgba(122, 166, 104, 0.1); border: 1px solid var(--success); }
.qa-result.wrong { background: rgba(192, 64, 59, 0.08); border: 1px solid var(--danger); }
.qa-result-icon { font-size: 28px; margin-bottom: 6px; }
.qa-result-text { font-size: 16px; font-weight: 600; margin-bottom: 10px; }
.qa-answer { font-size: 14px; margin-bottom: 6px; }
.qa-explanation { font-size: 13px; color: var(--text-sub); line-height: 1.6; }

@media (max-width: 768px) {
  .qa-card { padding: 16px 12px; }
  .qa-header { flex-wrap: wrap; gap: 6px; }
  .qa-content p { font-size: 15px; }
  .qa-option { padding: 12px 10px; font-size: 14px; }
}
</style>
