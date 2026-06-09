<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useSkinStore, SKINS } from '@/stores/skin'
import axios from 'axios'

const router = useRouter()
const auth = useAuthStore()
const skin = useSkinStore()

interface MySubmission { id: number; title: string; status: string; audit_comment: string | null; created_at: string | null }
interface Favorite { id: number; title: string; view_count: number; knowledge_base: string }

const points = ref(0)
const companyRank = ref(0)
const deptRank = ref(0)
const submissions = ref<MySubmission[]>([])
const favorites = ref<Favorite[]>([])
const loading = ref(true)
const showSkinPanel = ref(false)

const kbLabel: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }
const statusLabel: Record<string, string> = { draft: '草稿', pending: '待审', approved: '已通过', rejected: '已驳回', archived: '已归档' }

async function fetchData() {
  try {
    const [dr, sr, fr] = await Promise.all([
      axios.get('/api/dashboard/personal'),
      // 获取我的提交（用搜索接口查 source_person）
      axios.get('/api/knowledge', { params: { page_size: 50, sort_by: 'created_at' } }),
      // 收藏列表（localStorage）
      Promise.resolve(),
    ])
    const d = dr.data.data
    points.value = d.my_points
    companyRank.value = d.company_rank
    deptRank.value = d.dept_rank
    // 筛选我的提交
    const all = sr.data.data.items || []
    submissions.value = all
      .filter((i: any) => i.source_person === auth.user?.real_name)
      .map((i: any) => ({
        id: i.id, title: i.title, status: i.status || 'draft',
        audit_comment: null, created_at: i.created_at,
      }))

    // 收藏
    const favIds: number[] = JSON.parse(localStorage.getItem('favorites') || '[]')
    if (favIds.length > 0) {
      const favItems: Favorite[] = []
      for (const id of favIds.slice(0, 10)) {
        try {
          const { data } = await axios.get(`/api/knowledge/${id}`)
          favItems.push({ id, title: data.data.title, view_count: data.data.view_count, knowledge_base: data.data.knowledge_base })
        } catch { /* skip */ }
      }
      favorites.value = favItems
    }
  } finally {
    loading.value = false
  }
}

function goKnowledge(id: number) { router.push(`/knowledge/${id}`) }
function selectSkin(id: number) {
  skin.applySkin(id)
  showSkinPanel.value = false
}
function doLogout() {
  auth.logout()
  router.push('/login')
}

onMounted(fetchData)
</script>

<template>
  <div class="pf-page">
    <h2 class="page-title">个人中心</h2>
    <div v-if="loading" class="pf-loading">加载中...</div>

    <template v-else>
      <!-- 头部信息 -->
      <div class="pf-header card">
        <div class="pf-avatar">{{ auth.user?.real_name?.charAt(0) || 'U' }}</div>
        <div class="pf-info">
          <h3>{{ auth.user?.real_name }}</h3>
          <p>{{ auth.user?.username }} | {{ auth.isBoss ? '老板' : auth.isAdmin ? '管理员' : '职员' }}</p>
          <p v-if="auth.user?.phone">{{ auth.user.phone }}</p>
        </div>
        <button class="btn btn-sm btn-outline" @click="showSkinPanel = !showSkinPanel">🎨 皮肤</button>
      </div>

      <!-- 皮肤选择面板 -->
      <div class="card" v-if="showSkinPanel" style="margin-top:8px;padding:12px">
        <div class="skin-grid">
          <div v-for="s in SKINS" :key="s.id" class="skin-item"
            :class="{ active: skin.skinId === s.id }"
            :style="{ background: s.color }"
            @click="selectSkin(s.id)"
            :title="s.name"
          >
            <span class="skin-name">{{ s.name }}</span>
            <span v-if="skin.skinId === s.id" class="skin-check">✓</span>
          </div>
        </div>
      </div>

      <!-- 积分区 -->
      <div class="pf-points">
        <div class="pf-pt card">
          <div class="pf-pt-num">{{ points }}</div>
          <div class="pf-pt-label">总积分</div>
        </div>
        <div class="pf-pt card">
          <div class="pf-pt-num">#{{ companyRank }}</div>
          <div class="pf-pt-label">全公司排名</div>
        </div>
        <div class="pf-pt card">
          <div class="pf-pt-num">#{{ deptRank }}</div>
          <div class="pf-pt-label">本部门排名</div>
        </div>
      </div>

      <!-- 我的提交 -->
      <div class="card" style="margin-top:12px">
        <div class="section-head">
          <h3>📝 我的提交</h3>
          <router-link to="/submit-experience" class="btn btn-sm">+ 提交经验</router-link>
        </div>
        <div v-if="submissions.length === 0" class="empty-hint">暂无提交记录</div>
        <div v-else class="sub-list">
          <div v-for="s in submissions.slice(0, 10)" :key="s.id" class="sub-item" @click="goKnowledge(s.id)">
            <span class="sub-title">{{ s.title }}</span>
            <span class="sub-tag" :style="{
              color: s.status === 'approved' ? 'var(--success)' : s.status === 'rejected' ? 'var(--danger)' : 'var(--accent)'
            }">{{ statusLabel[s.status] || s.status }}</span>
            <span class="sub-date">{{ s.created_at?.slice(0, 10) || '-' }}</span>
          </div>
        </div>
      </div>

      <!-- 我的收藏 -->
      <div class="card" style="margin-top:12px">
        <h3>⭐ 我的收藏</h3>
        <div v-if="favorites.length === 0" class="empty-hint">暂无收藏</div>
        <div v-else class="fav-list">
          <div v-for="f in favorites" :key="f.id" class="fav-item" @click="goKnowledge(f.id)">
            <span>{{ f.title }}</span>
            <span class="fav-meta">{{ kbLabel[f.knowledge_base] || f.knowledge_base }} | 👁 {{ f.view_count }}</span>
          </div>
        </div>
      </div>

      <!-- 退出 -->
      <div style="text-align:center;margin-top:24px">
        <button class="btn btn-outline" @click="doLogout">退出登录</button>
      </div>
    </template>
  </div>
</template>

<style scoped>
.pf-page { max-width: 640px; margin: 0 auto; }
.page-title { font-size: 20px; margin-bottom: 16px; color: var(--text-main); }
.pf-loading { text-align: center; padding: 60px; color: var(--text-sub); }

.pf-header { display: flex; align-items: center; gap: 16px; margin-bottom: 12px; }
.pf-avatar {
  width: 60px; height: 60px; border-radius: 50%;
  background: var(--primary); color: #fff;
  display: flex; align-items: center; justify-content: center;
  font-size: 24px; font-weight: 700;
}
.pf-info { flex: 1; }
.pf-info h3 { font-size: 18px; margin: 0 0 4px; color: var(--text-main); }
.pf-info p { font-size: 13px; color: var(--text-sub); margin: 2px 0; }

.skin-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
.skin-item {
  height: 48px; border-radius: 8px; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  position: relative; border: 2px solid transparent;
  transition: transform 0.15s;
}
.skin-item:hover { transform: scale(1.05); }
.skin-item.active { border-color: var(--text-main); }
.skin-name { color: #fff; font-size: 12px; font-weight: 600; text-shadow: 0 1px 2px rgba(0,0,0,0.3); }
.skin-check { position: absolute; top: 2px; right: 6px; color: #fff; font-size: 14px; }

.pf-points { display: flex; gap: 12px; margin-top: 12px; }
.pf-pt { flex: 1; text-align: center; padding: 16px; }
.pf-pt-num { font-size: 28px; font-weight: 700; color: var(--primary); }
.pf-pt-label { font-size: 12px; color: var(--text-sub); margin-top: 4px; }

.section-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
.section-head h3 { font-size: 14px; margin: 0; color: var(--text-main); }
.empty-hint { font-size: 13px; color: var(--text-sub); padding: 20px 0; text-align: center; }

.sub-list { display: flex; flex-direction: column; gap: 6px; }
.sub-item { display: flex; align-items: center; gap: 12px; padding: 8px 0; border-bottom: 1px solid var(--border); cursor: pointer; font-size: 13px; }
.sub-title { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.sub-tag { font-size: 11px; font-weight: 600; flex-shrink: 0; }
.sub-date { font-size: 11px; color: var(--text-sub); flex-shrink: 0; }

.fav-list { display: flex; flex-direction: column; gap: 6px; }
.fav-item { display: flex; justify-content: space-between; padding: 6px 0; border-bottom: 1px solid var(--border); cursor: pointer; font-size: 13px; }
.fav-meta { font-size: 11px; color: var(--text-sub); flex-shrink: 0; }

@media (max-width: 768px) {
  .pf-points { flex-direction: column; }
  .skin-grid { grid-template-columns: repeat(2, 1fr); }
}
</style>
