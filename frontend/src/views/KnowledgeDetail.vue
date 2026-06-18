<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import axios from 'axios'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

interface DetailData {
  id: number; title: string; content: string; content_type: string
  category_id: number; category_name: string | null; knowledge_base: string
  source_type: string; source_person: string | null; source_dept: string | null
  media_url: string | null; media_start_sec: number; media_end_sec: number
  tags: string | null; car_brand: string | null; car_model: string | null
  difficulty_level: number; view_count: number; useful_count: number
  status: string; version: number
  created_at: string | null; updated_at: string | null
  related: { id: number; title: string }[]
}
interface ClipItem { id: number; title: string; start: number; end: number }

const entry = ref<DetailData | null>(null)
const loading = ref(true)
const usefulClicked = ref(false)
const favorited = ref(false)
let startTime = Date.now()
const clips = ref<ClipItem[]>([])
const videoRef = ref<HTMLVideoElement>()
const learningRecorded = ref(false)

const kbLabel: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }
const hasMedia = computed(() =>
  (entry.value?.content_type === 'video' || entry.value?.content_type === 'audio') && entry.value?.media_url
)

function difficultyDots(n: number) { return '★'.repeat(n) + '☆'.repeat(5 - n) }

async function fetchDetail() {
  const id = route.params.id
  try {
    const { data } = await axios.get(`/api/knowledge/${id}`)
    entry.value = data.data
    const favs = JSON.parse(localStorage.getItem('favorites') || '[]')
    favorited.value = favs.includes(entry.value!.id)

    // 视频类：获取同源片段
    if (entry.value.content_type === 'video' || entry.value.content_type === 'audio') {
      try {
        const cr = await axios.get(`/api/knowledge/${id}/clips`)
        clips.value = cr.data.data.clips || []
      } catch { /* skip */ }
    }
  } catch {
    entry.value = null
  } finally {
    loading.value = false
  }
}

async function markUseful() {
  if (usefulClicked.value || !entry.value) return
  try {
    await axios.post(`/api/knowledge/${entry.value.id}/useful`)
    usefulClicked.value = true
    entry.value.useful_count++
  } catch { /* ignore */ }
}

function toggleFavorite() {
  favorited.value = !favorited.value
  const favs = JSON.parse(localStorage.getItem('favorites') || '[]')
  if (favorited.value) {
    if (!favs.includes(entry.value!.id)) favs.push(entry.value!.id)
  } else {
    const idx = favs.indexOf(entry.value!.id)
    if (idx >= 0) favs.splice(idx, 1)
  }
  localStorage.setItem('favorites', JSON.stringify(favs))
}

function formatTs(sec: number): string {
  if (!sec && sec !== 0) return '--:--'
  const m = Math.floor(sec / 60)
  const s = Math.floor(sec % 60)
  return `${m}:${String(s).padStart(2, '0')}`
}

// 跳转到视频时间戳
function seekTo(sec: number) {
  if (videoRef.value) {
    videoRef.value.currentTime = sec
    videoRef.value.play()
  }
}

// 30秒后自动记录学习
function recordLearning() {
  if (learningRecorded.value || !entry.value) return
  learningRecorded.value = true
  axios.post(`/api/learning/record?knowledge_id=${entry.value.id}&learn_type=view&duration_sec=${Math.round((Date.now() - startTime) / 1000)}`).catch(() => {})
}

// 路由变化时重新加载
watch(() => route.params.id, () => {
  learningRecorded.value = false
  usefulClicked.value = false
  startTime = Date.now()
  fetchDetail()
})

onMounted(() => {
  fetchDetail()
  setTimeout(() => recordLearning(), 30000)
})
onUnmounted(() => recordLearning())
</script>

<template>
  <div class="kd-page">
    <div v-if="loading" class="kd-loading">加载中...</div>

    <template v-else-if="entry">
      <!-- 标题区 -->
      <div class="kd-header card">
        <div class="kd-title-row">
          <h1>{{ entry.title }}</h1>
          <div class="kd-badges">
            <span class="kd-badge">{{ kbLabel[entry.knowledge_base] || entry.knowledge_base }}</span>
            <span class="kd-badge kd-source">{{ entry.source_type === 'experience' ? '经验' : entry.source_type === 'policy' ? '制度' : entry.source_type === 'video' ? '视频' : '知识' }}</span>
          </div>
        </div>
        <div class="kd-meta">
          <span v-if="entry.source_person">♢ {{ entry.source_person }}</span>
          <span v-if="entry.source_dept">{{ entry.source_dept }}</span>
          <span v-if="entry.car_brand">◈ {{ entry.car_brand }}{{ entry.car_model ? ' ' + entry.car_model : '' }}</span>
          <span>难度 {{ difficultyDots(entry.difficulty_level) }}</span>
          <span>版本 V{{ entry.version }}</span>
        </div>
        <div class="kd-stats">
          <span>◁ {{ entry.view_count }} 次浏览</span>
          <span>△ {{ entry.useful_count }} 人觉得有用</span>
          <span v-if="entry.created_at">◷ {{ entry.created_at?.slice(0, 10) }}</span>
        </div>
        <div class="kd-actions">
          <button class="btn" :class="{ 'btn-outline': usefulClicked }" @click="markUseful" :disabled="usefulClicked">
            {{ usefulClicked ? '已标记有用' : '△ 有用' }}
          </button>
          <button class="btn btn-outline" @click="toggleFavorite">
            {{ favorited ? '★ 已收藏' : '☆ 收藏' }}
          </button>
        </div>
      </div>

      <!-- 视频/音频播放器 -->
      <div v-if="hasMedia" class="kd-media card">
        <video
          v-if="entry.content_type === 'video'"
          ref="videoRef"
          :src="entry.media_url!"
          controls
          class="kd-video"
          preload="metadata"
        ></video>
        <audio
          v-else
          ref="videoRef"
          :src="entry.media_url!"
          controls
          class="kd-audio"
          preload="metadata"
        ></audio>
        <!-- 当前片段时间范围 -->
        <div class="kd-segment-info" v-if="entry.media_start_sec || entry.media_end_sec">
          当前片段：
          <span class="kd-ts">{{ formatTs(entry.media_start_sec) }}</span>
          -
          <span class="kd-ts">{{ formatTs(entry.media_end_sec) }}</span>
        </div>
      </div>

      <!-- 视频片段导航 -->
      <div v-if="clips.length" class="kd-clips card">
        <h4>▶ 同视频其他片段</h4>
        <div class="clips-list">
          <div
            v-for="c in clips" :key="c.id"
            class="clip-item"
            :class="{ current: c.id === entry.id }"
            @click="router.push(`/knowledge/${c.id}`)"
          >
            <span>{{ c.title }}</span>
            <span class="clip-ts">{{ formatTs(c.start) }} - {{ formatTs(c.end) }}</span>
          </div>
        </div>
      </div>

      <!-- 正文 -->
      <div class="kd-content card">
        <pre class="kd-text">{{ entry.content }}</pre>
      </div>

      <!-- 标签 -->
      <div class="kd-tags card" v-if="entry.tags">
        <span class="tag" v-for="t in entry.tags.split('/')" :key="t">{{ t.trim() }}</span>
      </div>

      <!-- 相关推荐 -->
      <div class="kd-related" v-if="entry.related && entry.related.length">
        <h3>相关推荐</h3>
        <div class="related-list">
          <router-link v-for="r in entry.related" :key="r.id" :to="`/knowledge/${r.id}`" class="related-item card">
            {{ r.title }}
          </router-link>
        </div>
      </div>
    </template>

    <div v-else class="kd-empty">知识不存在或无权查看</div>
  </div>
</template>

<style scoped>
.kd-page { max-width: 900px; margin: 0 auto; }
.kd-loading, .kd-empty { text-align: center; padding: 60px 20px; color: var(--text-sub); }

.kd-header { margin-bottom: 16px; }
.kd-title-row { display: flex; justify-content: space-between; align-items: flex-start; gap: 16px; }
.kd-title-row h1 { font-size: 22px; margin: 0; color: var(--text-main); line-height: 1.4; }
.kd-badges { display: flex; gap: 6px; flex-shrink: 0; }
.kd-badge { padding: 3px 10px; border-radius: 10px; font-size: 12px; background: var(--primary); color: #fff; white-space: nowrap; }
.kd-source { background: var(--accent); }
.kd-meta { margin-top: 10px; display: flex; flex-wrap: wrap; gap: 16px; font-size: 13px; color: var(--text-sub); }
.kd-stats { margin-top: 8px; display: flex; gap: 16px; font-size: 13px; color: var(--text-sub); }
.kd-actions { margin-top: 12px; display: flex; gap: 10px; }

/* 视频播放器 */
.kd-media { margin-bottom: 16px; padding: 16px; }
.kd-video { width: 100%; max-height: 480px; border-radius: 8px; background: #000; }
.kd-audio { width: 100%; }
.kd-segment-info { margin-top: 8px; font-size: 13px; color: var(--text-sub); }
.kd-ts { font-weight: 600; color: var(--primary); font-family: monospace; }

/* 片段导航 */
.kd-clips { margin-bottom: 16px; padding: 16px; }
.kd-clips h4 { font-size: 14px; margin: 0 0 10px; color: var(--text-main); }
.clips-list { display: flex; flex-direction: column; gap: 6px; }
.clip-item {
  display: flex; justify-content: space-between; align-items: center;
  padding: 8px 12px; border: 1px solid var(--border); border-radius: 6px;
  cursor: pointer; font-size: 13px; transition: border-color 0.15s;
}
.clip-item:hover { border-color: var(--primary); }
.clip-item.current { border-color: var(--primary); background: var(--bg-main); }
.clip-ts { font-size: 11px; color: var(--text-sub); font-family: monospace; }

.kd-content { padding: 24px; }
.kd-text { white-space: pre-wrap; word-break: break-word; font-family: inherit; font-size: 15px; line-height: 1.8; color: var(--text-main); background: none; margin: 0; }

.kd-tags { margin-top: 12px; display: flex; flex-wrap: wrap; gap: 6px; }
.tag { padding: 2px 10px; border-radius: 10px; font-size: 12px; background: var(--bg-main); color: var(--accent); border: 1px solid var(--border); }

.kd-related { margin-top: 24px; }
.kd-related h3 { font-size: 16px; margin-bottom: 12px; color: var(--text-main); }
.related-list { display: flex; flex-direction: column; gap: 8px; }
.related-item { display: block; padding: 12px; font-size: 14px; color: var(--text-main); transition: border-color 0.15s; cursor: pointer; }
.related-item:hover { border-color: var(--primary); }

/* 响应式 */
@media (max-width: 768px) {
  .kd-title-row { flex-direction: column; gap: 8px; }
  .kd-title-row h1 { font-size: 18px; }
  .kd-badges { flex-wrap: wrap; }
  .kd-meta { gap: 10px; font-size: 12px; }
  .kd-stats { gap: 10px; font-size: 12px; flex-wrap: wrap; }
  .kd-actions { flex-wrap: wrap; }
  .kd-video { max-height: 240px; }
  .kd-content { padding: 14px; }
  .kd-text { font-size: 14px; }
  .clip-item { font-size: 12px; padding: 6px 10px; }
}
</style>
