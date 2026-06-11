import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

export interface ChatMessage {
  id: string
  role: 'user' | 'assistant'
  content: string
  references?: { title: string; id: number; confidence?: number }[]
  timestamp: number
  source?: string
  confidence?: number
}

export const useChatStore = defineStore('chat', () => {
  const messages = ref<ChatMessage[]>([])
  const open = ref(false)
  const loading = ref(false)
  const mode = ref('knowledge_qa')

  const lastAssistantMsg = computed(() => {
    for (let i = messages.value.length - 1; i >= 0; i--) {
      if (messages.value[i].role === 'assistant') return messages.value[i]
    }
    return null
  })

  function addMessage(role: 'user' | 'assistant', content: string, refs?: { title: string; id: number; confidence?: number }[], source?: string, confidence?: number) {
    const msg: ChatMessage = {
      id: Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
      role,
      content,
      references: refs,
      timestamp: Date.now(),
      source,
      confidence,
    }
    messages.value.push(msg)
    return msg
  }

  async function sendMessage(question: string, _token: string) {
    if (!question.trim() || loading.value) return

    addMessage('user', question)
    loading.value = true

    try {
      const { data } = await axios.get('/api/chat/ask', {
        params: { question, mode: mode.value },
      })
      const d = data.data
      addMessage('assistant', d.answer || data.msg || '(无响应)', d.references, d.source, d.confidence)
    } catch (e: any) {
      const msg = e.response?.data?.detail || e.response?.data?.msg || e.message || '请求失败'
      addMessage('assistant', '抱歉，请求出错了：' + msg)
    } finally {
      loading.value = false
    }
  }

  async function clearChat() {
    messages.value = []
    try { await axios.post('/api/chat/clear') } catch { /* ignore */ }
  }

  function toggle() { open.value = !open.value }

  return { messages, open, loading, mode, lastAssistantMsg, addMessage, sendMessage, clearChat, clear: clearChat, toggle }
})
