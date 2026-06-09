<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { helpContent } from '@/helpContent'
import axios from 'axios'

const router = useRouter()
const auth = useAuthStore()

interface KnowledgeItem {
  id: number; title: string; content: string; tags: string | null
  car_brand: string | null; car_model: string | null
  knowledge_base: string; category_id: number
  view_count: number; useful_count: number; difficulty_level: number
  source_person: string | null; created_at: string | null
  content_type: string
}

interface Category {
  id: number; name: string; parent_id: number | null
  knowledge_base: string; sort_order: number; icon: string | null
}

const items = ref<KnowledgeItem[]>([])
const total = ref(0)
const page = ref(1)
const loading = ref(false)
const keyword = ref('')
const selectedKb = ref('')
const selectedCat = ref(0)
const sortBy = ref('created_at')
const categories = ref<Category[]>([])
const showFilter = ref(false)

const kbLabel: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }
const kbList = computed(() => {
  if (!auth.user) return []
  const pos = auth.user.position
  if (auth.isAdmin) return ['public', 'sales', 'tech', 'service']
  if (pos === 'sales') return ['public', 'sales']
  if (pos === 'tech') return ['public', 'tech']
  if (pos === 'service') return ['public', 'service']
  return ['public']
})

const filteredCats = computed(() =>
  categories.value.filter(c => kbList.value.includes(c.knowledge_base))
)

const catTree = computed(() => {
  const map: Record<string, { kb: string; cats: Category[] }> = {}
  for (const c of filteredCats.value) {
    if (!map[c.knowledge_base]) map[c.knowledge_base] = { kb: c.knowledge_base, cats: [] }
    map[c.knowledge_base].cats.push(c)
  }
  return Object.values(map)
})

async function fetchCategories() {
  const { data } = await axios.get('/api/categories')
  categories.value = data.data || []
}

async function fetchList() {
  loading.value = true
  try {
    const params: any = { page: page.value, page_size: 20, sort_by: sortBy.value }
    if (keyword.value) params.keyword = keyword.value
    if (selectedKb.value) params.knowledge_base = selectedKb.value
    if (selectedCat.value > 0) params.category_id = selectedCat.value
    const { data } = await axios.get('/api/knowledge', { params })
    items.value = data.data.items
    total.value = data.data.total
  } finally {
    loading.value = false
  }
}

function search() { page.value = 1; fetchList() }
function selectKb(kb: string) {
  selectedKb.value = selectedKb.value === kb ? '' : kb
  selectedCat.value = 0
  search()
}
function selectCat(id: number) { selectedCat.value = id; search() }
function goDetail(id: number) { router.push(`/knowledge/${id}`) }
function difficultyDots(n: number) { return '★'.repeat(n) + '☆'.repeat(5 - n) }

onMounted(async () => {
  await fetchCategories()
  fetchList()
})
</script>

<template>
  <div class="kb-page">
    <!-- 搜索栏 -->
    <div class="kb-toolbar">
      <form @submit.prevent="search" class="kb-search">
        <input v-model="keyword" placeholder="搜索知识（车型、故障、话术…）" class="form-input" style="flex:1" />
        <button type="submit" class="btn">搜索</button>
      </form>
      <button class="btn btn-outline btn-sm filter-toggle" @click="showFilter = !showFilter" v-if="auth.isAdmin">
        筛选
      </button>
    </div>

    <div class="kb-body">
      <!-- 分类树（PC/Pad 侧边，手机抽屉） -->
      <aside class="kb-cats" :class="{ open: showFilter }">
        <div class="cat-header" v-if="showFilter">
          <span>分类筛选</span>
          <button @click="showFilter = false" class="btn btn-sm">×</button>
        </div>
        <div class="kb-tags">
          <button :class="{ active: !selectedKb }" @click="selectKb('')">全部</button>
          <button v-for="kb in kbList" :key="kb" :class="{ active: selectedKb === kb }" @click="selectKb(kb)">
            {{ kbLabel[kb] || kb }}
          </button>
        </div>
        <ul class="cat-tree">
          <li v-for="cat in filteredCats" :key="cat.id"
            :class="{ active: selectedCat === cat.id }"
            @click="selectCat(cat.id)">
            <span class="cat-icon">{{ cat.icon || '📄' }}</span>
            <span>{{ cat.name }}</span>
          </li>
        </ul>
      </aside>
      <div v-if="showFilter" class="drawer-overlay" @click="showFilter = false"></div>

      <!-- 知识列表 -->
      <section class="kb-list">
        <div class="kb-list-head">
          <span>共 {{ total }} 条知识</span>
          <select v-model="sortBy" @change="search" class="form-input" style="width:auto;font-size:13px">
            <option value="created_at">最新</option>
            <option value="view_count">最热</option>
            <option value="useful_count">最有用</option>
          </select>
        </div>

        <div v-if="loading" class="kb-loading">加载中...</div>
        <template v-else>
          <article v-for="item in items" :key="item.id" class="kb-card card" @click="goDetail(item.id)">
            <div class="kb-card-header">
              <h3>{{ item.title }}</h3>
              <span class="kb-badge">{{ kbLabel[item.knowledge_base] || item.knowledge_base }}</span>
            </div>
            <p class="kb-card-desc">{{ item.content }}</p>
            <div class="kb-card-meta">
              <span v-if="item.car_brand">🚗 {{ item.car_brand }}{{ item.car_model ? ' ' + item.car_model : '' }}</span>
              <span v-if="item.tags" class="kb-card-tags">{{ item.tags }}</span>
              <span class="kb-card-stats">👁 {{ item.view_count }} | 👍 {{ item.useful_count }}</span>
              <span>{{ difficultyDots(item.difficulty_level) }}</span>
              <span class="kb-card-date">{{ item.created_at?.slice(0, 10) }}</span>
            </div>
          </article>
          <div v-if="items.length === 0 && !loading" class="kb-empty">暂无匹配的知识内容</div>
        </template>

        <div class="kb-pager" v-if="total > 20">
          <button class="btn btn-sm btn-outline" :disabled="page <= 1" @click="page--; fetchList()">上一页</button>
          <span>{{ page }} / {{ Math.ceil(total / 20) }}</span>
          <button class="btn btn-sm btn-outline" :disabled="page >= Math.ceil(total / 20)" @click="page++; fetchList()">下一页</button>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.kb-page { max-width: 1200px; margin: 0 auto; }

/* 工具栏 */
.kb-toolbar { display: flex; gap: 10px; margin-bottom: 16px; align-items: center; }
.kb-search { display: flex; gap: 8px; flex: 1; }
.kb-search input { flex: 1; min-width: 0; }
.filter-toggle { display: none; }

/* 分类树 */
.kb-body { display: flex; gap: 20px; }
.kb-cats {
  width: 200px; flex-shrink: 0;
  background: var(--bg-card); border-radius: 8px;
  border: 1px solid var(--border); padding: 12px;
  max-height: calc(100vh - 200px); overflow-y: auto;
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
  padding: 6px 8px; cursor: pointer; border-radius: 4px;
  font-size: 13px; display: flex; align-items: center; gap: 6px;
  color: var(--text-main);
}
.cat-tree li:hover { background: var(--bg-main); color: var(--primary); }
.cat-tree li.active { background: var(--bg-main); color: var(--primary); font-weight: 600; }
.cat-icon { font-size: 14px; width: 20px; text-align: center; }

/* 列表 */
.kb-list { flex: 1; min-width: 0; }
.kb-list-head {
  display: flex; justify-content: space-between; align-items: center;
  font-size: 13px; color: var(--text-sub); margin-bottom: 12px;
}
.kb-card {
  margin-bottom: 12px; cursor: pointer; transition: box-shadow 0.15s;
}
.kb-card:hover { box-shadow: 0 4px 16px var(--shadow); }
.kb-card-header { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; }
.kb-card-header h3 { font-size: 16px; margin: 0; color: var(--text-main); }
.kb-badge {
  padding: 2px 8px; border-radius: 10px; font-size: 11px;
  background: var(--primary); color: #fff; white-space: nowrap;
}
.kb-card-desc {
  margin: 8px 0; font-size: 13px; color: var(--text-sub);
  line-height: 1.5; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}
.kb-card-meta {
  display: flex; flex-wrap: wrap; gap: 12px; font-size: 12px; color: var(--text-sub);
}
.kb-card-tags { color: var(--accent); }
.kb-loading, .kb-empty { text-align: center; padding: 40px; color: var(--text-sub); }
.kb-pager { display: flex; justify-content: center; align-items: center; gap: 12px; margin-top: 16px; }

/* 响应式 */
@media (max-width: 768px) {
  .kb-toolbar { flex-wrap: wrap; }
  .filter-toggle { display: inline-flex; }
  .kb-cats {
    display: none; position: fixed; top: 0; left: 0; bottom: 0; z-index: 8500;
    width: 280px; max-width: 80vw; border-radius: 0; padding-top: 50px;
  }
  .kb-cats.open { display: block; }
  .cat-header {
    position: absolute; top: 0; left: 0; right: 0;
    display: flex; justify-content: space-between; align-items: center;
    padding: 10px 12px; border-bottom: 1px solid var(--border);
    font-size: 14px; font-weight: 600;
  }
  .kb-body { flex-direction: column; }
}
@media (min-width: 769px) and (max-width: 1024px) {
  .kb-cats { width: 160px; }
}
</style>
