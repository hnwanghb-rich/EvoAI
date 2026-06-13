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

// === 语音录入（录音 → 上传 → 后台转写 → 填入内容） ===
const recording = ref(false)
const recordingTime = ref(0)
const voiceTranscribing = ref(false)
let mediaRecorder: MediaRecorder | null = null
let audioChunks: Blob[] = []
let recordTimer: any = null

async function startRecording() {
  voiceTranscribing.value = false
  if (!navigator.mediaDevices?.getUserMedia) { error.value = '当前浏览器不支持录音（请使用 Chrome/Edge）'; return }
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    const rec = new MediaRecorder(stream, { mimeType: 'audio/webm;codecs=opus' })
    mediaRecorder = rec
    audioChunks = []
    rec.ondataavailable = (e) => { if (e.data.size > 0) audioChunks.push(e.data) }
    rec.onstop = async () => {
      const blob = new Blob(audioChunks, { type: 'audio/webm' })
      const fd = new FormData()
      fd.append('file', blob, 'experience-voice.webm')
      voiceTranscribing.value = true
      try {
        const { data } = await axios.post('/api/voice/upload', fd)
        let retries = 0
        const poll = setInterval(async () => {
          retries++
          try {
            const sr = await axios.get(`/api/voice/status/${data.data.id}`)
            if (sr.data.data.transcript_status === 'done') {
              const txt = sr.data.data.transcript || ''
              content.value = (content.value ? content.value + '\n' : '') + txt
              title.value = title.value || (txt.length > 20 ? txt.slice(0, 20) : txt)
              clearInterval(poll)
              voiceTranscribing.value = false
            } else if (sr.data.data.transcript_status === 'failed') {
              error.value = '语音识别失败，请手动输入'
              clearInterval(poll)
              voiceTranscribing.value = false
            }
            if (retries > 40) { clearInterval(poll); voiceTranscribing.value = false }
          } catch { clearInterval(poll); voiceTranscribing.value = false }
        }, 2000)
      } catch (e: any) { error.value = '语音上传失败'; voiceTranscribing.value = false }
    }
    rec.start(250)
    recording.value = true; recordingTime.value = 0; error.value = ''
    if (recordTimer) clearInterval(recordTimer)
    recordTimer = setInterval(() => recordingTime.value++, 1000)
  } catch (e: any) { error.value = '麦克风权限被拒绝' }
}

function stopRecording() {
  mediaRecorder?.stop()
  recording.value = false
  mediaRecorder?.stream.getTracks().forEach(t => t.stop())
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
          <button
            v-if="!recording && !voiceTranscribing"
            type="button" class="btn btn-sm btn-outline" @click="startRecording"
          >🎤 语音录入</button>
          <button
            v-if="recording"
            type="button"
            class="aneng-mic-recording"
            @click="stopRecording"
            title="停止录音"
          >🎤 {{ formatTime(recordingTime) }}</button>
          <span v-if="voiceTranscribing" class="voice-trans-hint">⏳ 转写中...</span>
          <span v-if="!recording && !voiceTranscribing" class="voice-hint">点击录音，自动转写为文字填入内容框</span>
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
.voice-trans-hint { font-size: 12px; color: var(--primary); font-weight: 600; animation: pulse 1s infinite; }
.aneng-mic-recording {
  width: auto; height: 32px; border-radius: 16px; border: none; padding: 0 14px;
  font-size: 14px; cursor: pointer; display: inline-flex; align-items: center; gap: 6px;
  background: var(--danger); color: #fff;
  animation: mic-pulse 1s infinite;
}
@keyframes mic-pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
@media (max-width: 768px) { .form-row { flex-direction: column; } }
</style>
