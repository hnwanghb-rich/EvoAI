<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import axios from 'axios'

const router = useRouter()
const auth = useAuthStore()

interface Category {
  id: number; name: string; knowledge_base: string; icon: string | null
}

const title = ref('')
const content = ref('')
const categoryId = ref(0)
const knowledgeBase = ref('public')
const tags = ref('')
const carBrand = ref('')
const carModel = ref('')
const submitting = ref(false)
const success = ref(false)
const error = ref('')
const categories = ref<Category[]>([])

const kbLabel: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }

const filteredCats = computed(() =>
  categories.value.filter(c => auth.isAdmin || c.knowledge_base === knowledgeBase.value)
)

// 自动匹配知识库到职员岗位
onMounted(async () => {
  const { data } = await axios.get('/api/categories')
  categories.value = data.data
  if (auth.user?.position) knowledgeBase.value = auth.user.position
})

async function submit() {
  error.value = ''
  if (!title.value.trim()) { error.value = '请输入经验标题'; return }
  if (!content.value.trim()) { error.value = '请输入经验内容'; return }
  if (!categoryId.value) { error.value = '请选择分类'; return }
  submitting.value = true
  try {
    await axios.post('/api/knowledge/submit-experience', {
      title: title.value, content: content.value,
      category_id: categoryId.value, knowledge_base: knowledgeBase.value,
      tags: tags.value, car_brand: carBrand.value, car_model: carModel.value,
    })
    success.value = true
  } catch (e: any) { error.value = e.response?.data?.detail || '提交失败' }
  finally { submitting.value = false }
}

function reset() {
  title.value = ''; content.value = ''; tags.value = ''
  carBrand.value = ''; carModel.value = ''
  success.value = false; error.value = ''
}

// === 语音录入（浏览器 Web Speech API，无需后端 ASR） ===
const recording = ref(false)
const recordingTime = ref(0)
let recordTimer: any = null

const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition
const recognition = SpeechRecognition ? new SpeechRecognition() : null
if (recognition) {
  recognition.continuous = true
  recognition.interimResults = true
  recognition.lang = 'zh-CN'
  recognition.onresult = (e: any) => {
    let transcript = ''
    for (let i = e.resultIndex; i < e.results.length; i++) transcript += e.results[i][0].transcript
    content.value = transcript
    title.value = title.value || (transcript.length > 20 ? transcript.slice(0, 20) : transcript)
  }
  recognition.onerror = (e: any) => {
    error.value = '语音识别出错：' + (e.error || '')
    stopRecording()
  }
  recognition.onend = () => { recording.value = false }
}

function startRecording() {
  if (!recognition) { error.value = '当前浏览器不支持语音识别（请使用 Chrome/Edge）'; return }
  try {
    recognition.start()
    recording.value = true; recordingTime.value = 0; error.value = ''
    if (recordTimer) clearInterval(recordTimer)
    recordTimer = setInterval(() => recordingTime.value++, 1000)
  } catch (e: any) { error.value = '语音识别启动失败：' + (e.message || '') }
}

function stopRecording() {
  recognition?.stop()
  recording.value = false
  if (recordTimer) { clearInterval(recordTimer); recordTimer = null }
}

function formatTime(s: number) { return `${Math.floor(s/60)}:${String(s%60).padStart(2,'0')}` }
</script>

<template>
  <div class="exp-page">
    <h2 class="page-title">提交工作经验</h2>

    <div class="exp-card card" v-if="!success">
      <div class="form-group">
        <label>经验标题 <span style="color:var(--danger)">*</span></label>
        <input v-model="title" placeholder="简洁概括，如：星瑞客户谈价三步法" class="form-input" style="width:100%" />
      </div>

      <div class="form-group">
        <label>经验内容 <span style="color:var(--danger)">*</span> <span class="hint">(支持 Markdown)</span></label>
        <textarea v-model="content" placeholder="详细描述您的经验或技巧，也可点击下方按钮语音录入..." class="form-input" style="width:100%;min-height:240px"></textarea>
        <!-- 语音录入 -->
        <div class="voice-bar">
          <template v-if="!recording">
            <button type="button" class="btn btn-sm btn-outline" @click="startRecording">🎤 语音录入</button>
            <span class="voice-hint">点击后说话，Chrome/Edge 浏览器自动转写为文字</span>
          </template>
          <div v-else class="voice-recording">
            <span class="voice-dot"></span>
            <span>正在识别 {{ formatTime(recordingTime) }}...</span>
            <button type="button" class="btn btn-sm btn-danger" @click="stopRecording">停止</button>
          </div>
        </div>
      </div>

      <div class="form-row">
        <div class="form-group"><label>知识库</label>
          <select v-model="knowledgeBase" class="form-input" style="width:100%" :disabled="auth.isStaff && !!auth.user?.position">
            <option value="public">公共通用</option><option value="sales">销售专属</option>
            <option value="tech">技术服务</option><option value="service">售后客服</option>
          </select>
        </div>
        <div class="form-group"><label>分类 <span style="color:var(--danger)">*</span></label>
          <select v-model.number="categoryId" class="form-input" style="width:100%">
            <option :value="0">请选择分类</option>
            <option v-for="c in filteredCats" :key="c.id" :value="c.id">{{ c.icon }} {{ c.name }}</option>
          </select>
        </div>
      </div>

      <div class="form-row">
        <div class="form-group"><label>品牌（可选）</label><input v-model="carBrand" placeholder="如：比亚迪" class="form-input" style="width:100%" /></div>
        <div class="form-group"><label>车型（可选）</label><input v-model="carModel" placeholder="如：汉EV" class="form-input" style="width:100%" /></div>
      </div>

      <div class="form-group"><label>标签（用 / 分隔）</label><input v-model="tags" placeholder="如：星瑞/谈判/价格" class="form-input" style="width:100%" /></div>

      <div class="exp-info"><h4>💡 提交须知</h4>
        <ul>
          <li>提交后获得 <b>+1 积分</b>，审核通过再得 <b>+10 积分</b></li>
          <li>被同事点击"有用"可获得 <b>+2 积分/次</b></li>
          <li>经验提交后不可直接修改，请仔细检查后再提交</li>
          <li>如被驳回，可在个人中心查看原因并修改后重新提交</li>
        </ul>
      </div>
      <p v-if="error" class="exp-error">{{ error }}</p>
      <div class="exp-submit"><button class="btn" @click="submit" :disabled="submitting">{{ submitting ? '提交中...' : '提交审核' }}</button></div>
    </div>

    <div v-else class="exp-success card">
      <p class="success-icon">✅</p>
      <h3>经验提交成功！</h3>
      <p>已获得 <b>+1 积分</b>，请等待管理员审核。审核通过后将再获得 <b>+10 积分</b>。</p>
      <div class="success-actions"><button class="btn" @click="reset">继续提交</button><button class="btn btn-outline" @click="router.push('/')">返回首页</button></div>
    </div>
  </div>
</template>

<style scoped>
.exp-page { max-width: 700px; margin: 0 auto; }
.page-title { font-size: 20px; margin-bottom: 16px; color: var(--text-main); }
.exp-card { padding: 24px; }
.form-group { margin-bottom: 14px; }
.form-group label { display: block; font-size: 13px; color: var(--text-sub); margin-bottom: 4px; }
.hint { font-size: 11px; color: var(--text-sub); opacity: 0.7; }
.form-row { display: flex; gap: 12px; }
.form-row .form-group { flex: 1; }
.exp-info { margin-top: 16px; padding: 14px; background: var(--bg-main); border-radius: 8px; font-size: 13px; color: var(--text-sub); }
.exp-info h4 { font-size: 14px; margin: 0 0 8px; color: var(--text-main); }
.exp-info ul { padding-left: 18px; margin: 0; }
.exp-info li { margin-bottom: 4px; }
.exp-error { color: var(--danger); font-size: 13px; margin: 10px 0; }
.exp-submit { margin-top: 16px; }
.exp-success { padding: 40px 32px; text-align: center; }
.success-icon { font-size: 48px; margin: 0 0 16px; }
.exp-success h3 { font-size: 20px; margin-bottom: 10px; color: var(--text-main); }
.exp-success p { color: var(--text-sub); line-height: 1.8; }
.success-actions { display: flex; gap: 10px; justify-content: center; margin-top: 20px; }
.voice-bar { margin-top: 8px; display: flex; align-items: center; gap: 10px; }
.voice-hint { font-size: 12px; color: var(--text-sub); }
.voice-recording { display: flex; align-items: center; gap: 10px; padding: 8px 14px; background: rgba(192,64,59,0.08); border: 1px solid var(--danger); border-radius: 8px; }
.voice-dot { width: 10px; height: 10px; border-radius: 50%; background: var(--danger); animation: pulse 1s infinite; }
@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
.voice-recording span { font-size: 14px; font-weight: 600; color: var(--danger); }
@media (max-width: 768px) { .form-row { flex-direction: column; } }
</style>
