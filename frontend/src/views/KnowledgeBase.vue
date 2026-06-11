<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import axios from 'axios'

const router = useRouter()
const auth = useAuthStore()

interface UnifiedItem {
  id: number; title: string; content: string
  knowledge_base: string; category_id: number
  view_count: number; difficulty_level: number
  tags: string | null; created_at: string | null
  item_type: 'knowledge' | 'question'
  question_type?: string
}

interface Category {
  id: number; name: string; knowledge_base: string
  sort_order: number; icon: string | null
  knowledge_count: number; question_count: number
}

const items = ref<UnifiedItem[]>([])
const total = ref(0)
const loading = ref(false)
const keyword = ref('')
const selectedKb = ref('')
const selectedCat = ref(0)
const itemType = ref('all')
const categories = ref<Category[]>([])
const showFilter = ref(false)

const kbLabel: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }
const kbList = computed(() => {
  const pos = auth.user?.position
  if (auth.isAdmin) return ['public','sales','tech','service']
  if (pos === 'sales') return ['public','sales']
  if (pos === 'tech') return ['public','tech']
  if (pos === 'service') return ['public','service']
  return ['public']
})

const catTree = computed(() => {
  const map: Record<string, { kb: string; cats: Category[] }> = {}
  for (const c of categories.value) {
    if (!map[c.knowledge_base]) map[c.knowledge_base] = { kb: c.knowledge_base, cats: [] }
    map[c.knowledge_base].cats.push(c)
  }
  return Object.values(map)
})

async function fetchCategories() {
  try {
    const { data } = await axios.get('/api/settings/categories')
    categories.value = data.data || []
  } catch { /* fallback to /api/categories */ }
}

async function fetchList() {
  loading.value = true
  try {
    const params: any = { page_size: 20, item_type: itemType.value }
    if (keyword.value) params.keyword = keyword.value
    if (selectedKb.value) params.knowledge_base = selectedKb.value
    if (selectedCat.value > 0) params.category_id = selectedCat.value
    const { data } = await axios.get('/api/knowledge/unified', { params })
    items.value = data.data.items
    total.value = data.data.total
  } finally { loading.value = false }
}

function search() { fetchList() }
function selectKb(kb: string) {
  selectedKb.value = selectedKb.value === kb ? '' : kb
  selectedCat.value = 0
  search()
}
function selectCat(id: number) { selectedCat.value = selectedCat.value === id ? 0 : id; search() }
function goDetail(item: UnifiedItem) {
  if (item.item_type === 'question') {
    router.push('/question')
  } else {
    router.push(`/knowledge/${item.id}`)
  }
}
function difficultyDots(n: number) { return '★'.repeat(n) + '☆'.repeat(5 - n) }
function typeLabel(t: string) {
  const m: Record<string,string> = { single_choice:'单选', multi_choice:'多选', true_false:'判断', fill_blank:'填空' }
  return m[t] || t
}

onMounted(async () => {
  await fetchCategories()
  fetchList()
})
</script>

<template>
  <div class="kb-page">
    <div class="kb-toolbar">
      <form @submit.prevent="search" class="kb-search">
        <input v-model="keyword" placeholder="搜索知识或试题…" class="form-input" style="flex:1" />
        <select v-model="itemType" @change="search" class="form-input" style="width:auto;font-size:12px">
          <option value="all">全部内容</option>
          <option value="knowledge">仅知识</option>
          <option value="question">仅试题</option>
        </select>
        <button type="submit" class="btn btn-sm">搜索</button>
      </form>
      <button class="btn btn-sm btn-outline filter-toggle" @click="showFilter = !showFilter">筛选</button>
    </div>

    <div class="kb-body">
      <!-- 分类侧栏 -->
      <aside class="kb-cats" :class="{ open: showFilter }">
        <div class="cat-header" v-if="showFilter">
          <span>分类筛选</span><button @click="showFilter = false" class="btn btn-sm">×</button>
        </div>
        <div class="kb-tags">
          <button :class="{ active: !selectedKb }" @click="selectKb('')">全部</button>
          <button v-for="kb in kbList" :key="kb" :class="{ active: selectedKb === kb }" @click="selectKb(kb)">{{ kbLabel[kb] || kb }}</button>
        </div>
        <ul class="cat-tree">
          <li v-for="cat in categories.filter(c => kbList.includes(c.knowledge_base))" :key="cat.id"
            :class="{ active: selectedCat === cat.id }" @click="selectCat(cat.id)">
            <span class="cat-icon">{{ cat.icon || '📄' }}</span>
            <span class="cat-name">{{ cat.name }}</span>
            <span class="cat-counts">
              <span v-if="cat.knowledge_count" class="cc-k">📚{{ cat.knowledge_count }}</span>
              <span v-if="cat.question_count" class="cc-q">❓{{ cat.question_count }}</span>
            </span>
          </li>
        </ul>
      </aside>
      <div v-if="showFilter" class="drawer-overlay" @click="showFilter = false"></div>

      <!-- 结果列表 -->
      <section class="kb-list">
        <div class="kb-list-head">
          <span>共 {{ total }} 条</span>
        </div>

        <div v-if="loading" class="kb-loading">加载中...</div>
        <template v-else>
          <article v-for="item in items" :key="item.item_type + '-' + item.id" class="kb-card card" @click="goDetail(item)">
            <div class="kb-card-header">
              <h3>{{ item.title }}</h3>
              <div class="kb-badges">
                <span v-if="item.item_type === 'knowledge'" class="kb-badge kb-badge-doc">📄 知识</span>
                <span v-else class="kb-badge kb-badge-q">❓ 试题 · {{ typeLabel(item.question_type || '') }}</span>
                <span class="kb-badge kb-badge-kb">{{ kbLabel[item.knowledge_base] || item.knowledge_base }}</span>
              </div>
            </div>
            <p class="kb-card-desc">{{ item.content }}</p>
            <div class="kb-card-meta">
              <span v-if="item.tags" class="kb-card-tags">{{ item.tags }}</span>
              <span class="kb-card-stats" v-if="item.view_count > 0">👁 {{ item.view_count }}</span>
              <span>{{ difficultyDots(item.difficulty_level) }}</span>
              <span class="kb-card-date">{{ item.created_at?.slice(0, 10) }}</span>
            </div>
          </article>
          <div v-if="items.length === 0 && !loading" class="kb-empty">暂无内容</div>
        </template>
      </section>
    </div>
  </div>
</template>

<style scoped>
.kb-page { max-width: 1100px; margin: 0 auto; }
.kb-toolbar { display: flex; gap: 10px; margin-bottom: 16px; align-items: center; }
.kb-search { display: flex; gap: 8px; flex: 1; align-items: center; }
.kb-search input { flex: 1; min-width: 0; }
.filter-toggle { display: none; }

.kb-body { display: flex; gap: 20px; }
.kb-cats {
  width: 210px; flex-shrink: 0;
  background: var(--bg-card); border-radius: 8px;
  border: 1px solid var(--border); padding: 12px;
  max-height: calc(100vh - 220px); overflow-y: auto;
  position: sticky; top: calc(var(--banner-height) + 16px);
}
.kb-tags { display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 12px; }
.kb-tags button {
  padding: 3px 8px; border: 1px solid var(--border);
  border-radius: 12px; font-size: 12px; background: none;
  color: var(--text-sub); cursor: pointer;
}
.kb-tags button.active { background: var(--primary); color: #fff; border-color: var(--primary); }
.cat-tree { list-style: none; padding: 0; margin: 0; }
.cat-tree li {
  padding: 8px 8px; cursor: pointer; border-radius: 4px;
  font-size: 13px; display: flex; align-items: center; gap: 6px;
  color: var(--text-main);
}
.cat-tree li:hover { background: var(--bg-main); }
.cat-tree li.active { background: var(--bg-main); color: var(--primary); font-weight: 600; }
.cat-icon { font-size: 14px; width: 20px; text-align: center; flex-shrink: 0; }
.cat-name { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.cat-counts { display: flex; gap: 4px; font-size: 10px; flex-shrink: 0; }
.cc-k { color: var(--primary); }
.cc-q { color: var(--accent); }

.kb-list { flex: 1; min-width: 0; }
.kb-list-head { display: flex; justify-content: space-between; align-items: center; font-size: 13px; color: var(--text-sub); margin-bottom: 12px; }
.kb-card { margin-bottom: 10px; cursor: pointer; transition: box-shadow 0.15s; }
.kb-card:hover { box-shadow: 0 4px 16px var(--shadow); }
.kb-card-header { display: flex; justify-content: space-between; align-items: flex-start; gap: 10px; }
.kb-card-header h3 { font-size: 15px; margin: 0; color: var(--text-main); line-height: 1.3; }
.kb-badges { display: flex; gap: 4px; flex-shrink: 0; flex-wrap: wrap; }
.kb-badge { padding: 2px 8px; border-radius: 8px; font-size: 11px; white-space: nowrap; }
.kb-badge-doc { background: var(--bg-main); color: var(--primary); border: 1px solid var(--border); }
.kb-badge-q { background: rgba(232,130,74,0.08); color: var(--accent); border: 1px solid rgba(232,130,74,0.3); }
.kb-badge-kb { background: var(--primary); color: #fff; }
.kb-card-desc {
  margin: 8px 0; font-size: 13px; color: var(--text-sub); line-height: 1.5;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}
.kb-card-meta { display: flex; flex-wrap: wrap; gap: 12px; font-size: 12px; color: var(--text-sub); }
.kb-card-tags { color: var(--accent); }
.kb-loading, .kb-empty { text-align: center; padding: 40px; color: var(--text-sub); }

@media (max-width: 768px) {
  .kb-toolbar { flex-wrap: wrap; }
  .filter-toggle { display: inline-flex; }
  .kb-cats { display: none; position: fixed; top:0; left:0; bottom:0; z-index:8500; width:280px; max-width:80vw; border-radius:0; padding-top:50px; }
  .kb-cats.open { display: block; }
  .cat-header { position:absolute; top:0; left:0; right:0; display:flex; justify-content:space-between; align-items:center; padding:10px 12px; border-bottom:1px solid var(--border); font-size:14px; font-weight:600; }
  .kb-body { flex-direction: column; }
  .kb-badges { font-size: 10px; }
}
</style>
