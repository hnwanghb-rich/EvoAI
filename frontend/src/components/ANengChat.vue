<script setup lang="ts">
import { ref, watch, nextTick, computed } from 'vue'
import { useChatStore } from '@/stores/chat'
import { useAuthStore } from '@/stores/auth'
import axios from 'axios'

const chat = useChatStore()
const auth = useAuthStore()
const input = ref('')
const msgList = ref<HTMLDivElement>()
const floatBtn = ref<HTMLButtonElement>()
const recording = ref(false)
const mediaRecorder = ref<MediaRecorder | null>(null)
const audioChunks = ref<Blob[]>([])

// === 悬浮按钮拖拽（支持鼠标 + 触摸） ===
const floatPos = ref({ x: 20, y: 60 })
const dragging = ref(false)
const dragStart = ref({ x: 0, y: 0, ox: 0, oy: 0 })
const hasMoved = ref(false)

function onDragStart(e: PointerEvent) {
  if (chat.open) return
  floatBtn.value?.setPointerCapture(e.pointerId)
  dragging.value = true
  hasMoved.value = false
  dragStart.value = {
    x: e.clientX,
    y: e.clientY,
    ox: floatPos.value.x,
    oy: floatPos.value.y,
  }
}

function onDragMove(e: PointerEvent) {
  if (!dragging.value) return
  const dx = dragStart.value.x - e.clientX
  const dy = dragStart.value.y - e.clientY
  if (Math.abs(dx) > 3 || Math.abs(dy) > 3) hasMoved.value = true
  floatPos.value = {
    x: Math.min(Math.max(dragStart.value.ox + dx, 8), window.innerWidth - 64),
    y: Math.min(Math.max(dragStart.value.oy + dy, 8), window.innerHeight - 64),
  }
}

function onDragEnd() {
  dragging.value = false
  savePosition()
  if (!hasMoved.value) {
    chat.toggle() // 没拖动 = 点击打开
  }
}

function loadPosition() {
  try {
    const saved = JSON.parse(localStorage.getItem('aneng_pos') || '{}')
    if (saved.x != null && saved.y != null) floatPos.value = saved
  } catch {/* use default */}
}
function savePosition() {
  localStorage.setItem('aneng_pos', JSON.stringify(floatPos.value))
}

loadPosition()

const modeLabel: Record<string, string> = {
  knowledge_qa: '知识问答',
  experience_input: '经验录入',
  mgmt_report: '管理汇报',
}

const welcomeMsg: Record<string, string> = {
  sales: '王销售您好！我是数字老师阿能，可以帮您查询车型卖点、销售话术、竞品对比。有什么想了解的？',
  tech: '赵技师您好！我是数字老师阿能，可以帮您查故障诊断、维修技术、零件信息。有什么需要帮助的？',
  service: '陈客服您好！我是数字老师阿能，可以帮您查投诉处理流程、保险理赔、客户回访规范。请问有什么问题？',
}

const greeting = computed(() => {
  const pos = auth.user?.position || 'sales'
  return welcomeMsg[pos] || '您好！我是数字老师阿能，有什么可以帮您的？'
})

function getGreeting() {
  if (chat.messages.length === 0) return greeting.value
  return ''
}

async function doSend() {
  const q = input.value.trim()
  if (!q || chat.loading || !auth.token) return
  input.value = ''
  await chat.sendMessage(q, auth.token)
  scrollBottom()
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault()
    doSend()
  }
}

function goKnowledge(id: number) {
  window.open(`/knowledge/${id}`, '_blank')
}

function scrollBottom() {
  nextTick(() => {
    if (msgList.value) {
      msgList.value.scrollTop = msgList.value.scrollHeight
    }
  })
}

watch(() => chat.open, (v) => {
  if (v) {
    // 首次打开显示欢迎语
    if (chat.messages.length === 0) {
      chat.addMessage('assistant', getGreeting())
    }
    scrollBottom()
  }
})

watch(() => chat.messages.length, scrollBottom)

// === 语音输入 ===
async function startVoice() {
  if (!navigator.mediaDevices?.getUserMedia) return
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    const recorder = new MediaRecorder(stream, { mimeType: 'audio/webm;codecs=opus' })
    mediaRecorder.value = recorder
    audioChunks.value = []

    recorder.ondataavailable = (e) => { if (e.data.size > 0) audioChunks.value.push(e.data) }
    recorder.onstop = async () => {
      const blob = new Blob(audioChunks.value, { type: 'audio/webm' })
      const form = new FormData()
      form.append('file', blob, 'chat-voice.webm')
      try {
        const { data } = await axios.post('/api/voice/upload', form)
        // poll for transcript
        let retries = 0
        const poll = setInterval(async () => {
          retries++
          try {
            const sr = await axios.get(`/api/voice/status/${data.data.id}`)
            if (sr.data.data.transcript) {
              input.value = sr.data.data.transcript
              clearInterval(poll)
              doSend()
            }
            if (retries > 30) clearInterval(poll)
          } catch { clearInterval(poll) }
        }, 1500)
      } catch { /* ignore */ }
    }
    recorder.start(250)
    recording.value = true
  } catch { /* mic denied */ }
}

function stopVoice() {
  mediaRecorder.value?.stop()
  recording.value = false
  mediaRecorder.value?.stream.getTracks().forEach(t => t.stop())
}
</script>

<template>
  <!-- 悬浮按钮（可拖拽） -->
  <button
    v-if="!chat.open"
    ref="floatBtn"
    class="aneng-float"
    :style="{ right: floatPos.x + 'px', bottom: floatPos.y + 'px' }"
    @pointerdown.prevent="onDragStart"
    @pointermove="onDragMove"
    @pointerup="onDragEnd"
    @pointercancel="onDragEnd"
    :class="{ dragging: dragging }"
    title="拖动移动 · 点击召唤阿能"
  >
    <span class="aneng-icon">🤖</span>
    <span class="aneng-label">阿能</span>
  </button>

  <!-- 对话面板 -->
  <Teleport to="body">
    <div v-if="chat.open" class="aneng-overlay" @click.self="chat.toggle()">
      <div class="aneng-panel">
        <!-- 头部 -->
        <div class="aneng-header">
          <div class="aneng-title">
            <span class="aneng-avatar">🤖</span>
            <span>数字老师 · 阿能</span>
          </div>
          <div class="aneng-head-actions">
            <button class="aneng-btn-icon" @click="chat.clearChat()" title="清空对话">🗑</button>
            <button class="aneng-btn-icon" @click="chat.toggle()">×</button>
          </div>
        </div>

        <!-- 消息列表 -->
        <div class="aneng-messages" ref="msgList">
          <div
            v-for="msg in chat.messages" :key="msg.id"
            class="msg-row"
            :class="msg.role"
          >
            <div class="msg-bubble">
              <div class="msg-content" v-html="msg.content.replace(/\*\*(.+?)\*\*/g, '<b>$1</b>').replace(/\n/g, '<br>')"></div>
              <!-- 来源标识 -->
              <div v-if="msg.role === 'assistant' && msg.source && !msg.streaming" class="msg-source">
                <span v-if="msg.source === 'knowledge_base'" class="source-badge kb" title="来自企业知识库">
                  📚 知识库 · 匹配度 {{ ((msg.confidence || 0) * 100).toFixed(0) }}%
                </span>
                <span v-else-if="msg.source === 'llm'" class="source-badge llm" title="AI大模型生成">
                  🤖 AI生成 · 基于检索
                </span>
                <span v-else-if="msg.source === 'llm_no_match'" class="source-badge llm-no" title="AI通用知识兜底">
                  🌐 通用知识 · 知识库无匹配
                </span>
              </div>
              <!-- 引用卡片 -->
              <div v-if="msg.references && msg.references.length && msg.role === 'assistant' && !msg.streaming" class="msg-refs">
                <div class="refs-title">📚 参考来源：</div>
                <div
                  v-for="ref in msg.references" :key="ref.id"
                  class="ref-item"
                  @click="goKnowledge(ref.id)"
                >
                  {{ ref.title }}
                </div>
              </div>
              <!-- loading -->
              <span v-if="msg.streaming && !msg.content" class="msg-loading">思考中...</span>
            </div>
          </div>
        </div>

        <!-- 输入区 -->
        <div class="aneng-input">
          <textarea
            v-model="input"
            @keydown="onKeydown"
            placeholder="输入您的问题..."
            rows="2"
            :disabled="chat.loading"
          ></textarea>
          <button
            v-if="!recording"
            class="btn btn-sm"
            @click="doSend"
            :disabled="chat.loading || !input.trim()"
          >
            {{ chat.loading ? '...' : '发送' }}
          </button>
          <button
            :class="recording ? 'aneng-mic-recording' : 'aneng-mic'"
            @click="recording ? stopVoice() : startVoice()"
            :title="recording ? '停止录音' : '语音输入'"
          >
            🎤
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
/* 悬浮按钮 */
.aneng-float {
  position: fixed;
  z-index: 950;
  width: 56px; height: 56px;
  border-radius: 50%;
  border: none;
  background: var(--primary);
  color: #fff;
  cursor: grab;
  box-shadow: 0 4px 16px var(--shadow);
  display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  transition: transform 0.2s, box-shadow 0.2s;
  touch-action: none;
  user-select: none;
}
.aneng-float:hover {
  transform: scale(1.08);
  box-shadow: 0 6px 24px rgba(0,0,0,0.2);
}
.aneng-float.dragging {
  cursor: grabbing;
  transform: scale(1.12);
  box-shadow: 0 8px 28px rgba(0,0,0,0.3);
  transition: none;
}
/* 面板 */
.aneng-overlay {
  position: fixed; inset: 0;
  z-index: 9999;
  background: rgba(0,0,0,0.35);
  display: flex; align-items: flex-end; justify-content: flex-end;
}
.aneng-panel {
  width: 420px; max-width: 100vw; height: 560px; max-height: 80vh;
  margin: 0 16px 16px 0;
  background: var(--bg-card);
  border-radius: 12px;
  box-shadow: 0 8px 40px rgba(0,0,0,0.2);
  display: flex; flex-direction: column;
  overflow: hidden;
}

.aneng-header {
  display: flex; justify-content: space-between; align-items: center;
  padding: 12px 16px;
  background: var(--banner-bg, linear-gradient(135deg, #C0403B, #D46864, #E8824A));
  color: #fff;
}
.aneng-title { display: flex; align-items: center; gap: 8px; font-size: 15px; font-weight: 600; }
.aneng-avatar { font-size: 22px; }
.aneng-btn-icon {
  width: 28px; height: 28px; border: none; background: rgba(255,255,255,0.2);
  color: #fff; border-radius: 4px; cursor: pointer; font-size: 13px;
}
.aneng-head-actions { display: flex; gap: 4px; }

/* 消息区 */
.aneng-messages {
  flex: 1; overflow-y: auto; padding: 12px 16px;
  display: flex; flex-direction: column; gap: 10px;
}
.msg-row { display: flex; }
.msg-row.user { justify-content: flex-end; }
.msg-row.assistant { justify-content: flex-start; }
.msg-bubble {
  max-width: 85%;
  padding: 10px 14px; border-radius: 12px;
  font-size: 13px; line-height: 1.6;
  word-break: break-word;
}
.msg-row.user .msg-bubble {
  background: var(--primary); color: #fff;
  border-bottom-right-radius: 4px;
}
.msg-row.assistant .msg-bubble {
  background: var(--bg-main); color: var(--text-main);
  border: 1px solid var(--border);
  border-bottom-left-radius: 4px;
}
.msg-loading { color: var(--text-sub); font-style: italic; font-size: 12px; }

/* 引用 */
.msg-refs { margin-top: 8px; padding-top: 8px; border-top: 1px solid var(--border); }
.refs-title { font-size: 11px; color: var(--text-sub); margin-bottom: 4px; }
.ref-item {
  font-size: 12px; color: var(--primary); cursor: pointer;
  padding: 3px 0; text-decoration: underline;
}
.ref-item:hover { opacity: 0.8; }

/* 输入区 */
.aneng-input {
  display: flex; gap: 8px; padding: 10px 12px;
  border-top: 1px solid var(--border);
  background: var(--bg-card);
}
.aneng-input textarea {
  flex: 1; resize: none;
  padding: 8px 10px; border: 1px solid var(--border);
  border-radius: 8px; font-size: 13px; font-family: inherit;
  background: var(--bg-main); color: var(--text-main);
  outline: none;
}
.aneng-input textarea:focus { border-color: var(--primary); }

/* 来源标识 */
.msg-source { margin-top: 6px; }
.source-badge {
  display: inline-block; padding: 2px 8px; border-radius: 8px; font-size: 11px;
}
.source-badge.kb { background: rgba(122,166,104,0.12); color: var(--success); border: 1px solid rgba(122,166,104,0.3); }
.source-badge.llm { background: rgba(74,144,217,0.1); color: #4A90D9; border: 1px solid rgba(74,144,217,0.3); }
.source-badge.llm-no { background: rgba(232,130,74,0.1); color: var(--accent); border: 1px solid rgba(232,130,74,0.3); }

/* 语音按钮 */
.aneng-mic, .aneng-mic-recording {
  width: 32px; height: 32px; border-radius: 50%; border: none;
  font-size: 16px; cursor: pointer; display: flex; align-items: center; justify-content: center;
  transition: background 0.2s;
}
.aneng-mic { background: var(--bg-main); }
.aneng-mic:hover { background: var(--border); }
.aneng-mic-recording { background: var(--danger); animation: mic-pulse 1s infinite; }
@keyframes mic-pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }

/* 手机全屏 */
@media (max-width: 768px) {
  .aneng-panel {
    width: 100vw; height: 100vh; max-height: 100vh;
    margin: 0; border-radius: 0;
  }
}
</style>
