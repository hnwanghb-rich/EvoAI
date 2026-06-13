<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import axios from 'axios'

interface UserItem {
  id: number; username: string; real_name: string; role: string
  position: string | null; dept_id: number | null; store_id: number | null
  phone: string | null; status: number; created_at: string | null
}

const activeTab = ref<'users' | 'capability'>('users')

// ===== 用户管理 =====
const loading = ref(true)
const items = ref<UserItem[]>([])
const total = ref(0)
const page = ref(1)
const keyword = ref('')
const roleFilter = ref('')
const posFilter = ref('')
const showForm = ref(false)
const editing = ref<any>({})
const isEdit = ref(false)

const roleLabel: Record<string, string> = { boss: '老板', admin: '管理员', staff: '职员' }
const posLabel: Record<string, string> = { sales: '销售', tech: '技术', service: '客服', clerk: '文员' }

async function fetchList() {
  loading.value = true
  const params: any = { page: page.value, page_size: 20 }
  if (keyword.value) params.keyword = keyword.value
  if (roleFilter.value) params.role = roleFilter.value
  if (posFilter.value) params.position = posFilter.value
  const { data } = await axios.get('/api/users/list', { params })
  items.value = data.data.items; total.value = data.data.total
  loading.value = false
}
function search() { page.value = 1; fetchList() }
function openCreate() { isEdit.value = false; editing.value = { username: '', real_name: '', password: 'hequn123', role: 'staff', position: '', dept_id: null, store_id: null, phone: '' }; showForm.value = true }
function openEdit(u: UserItem) { isEdit.value = true; editing.value = { ...u, password: '' }; showForm.value = true }
async function saveForm() {
  const body: any = { real_name: editing.value.real_name, role: editing.value.role, position: editing.value.position || null, dept_id: editing.value.dept_id || null, store_id: editing.value.store_id || null, phone: editing.value.phone || null }
  if (editing.value.password) body.password = editing.value.password
  if (isEdit.value) { await axios.put(`/api/users/${editing.value.id}`, body) }
  else { await axios.post('/api/users', { ...body, username: editing.value.username, password: editing.value.password || 'hequn123' }) }
  showForm.value = false; fetchList()
}
async function toggleStatus(id: number) { const r = await axios.put(`/api/users/${id}/status`); const u = items.value.find(i => i.id === id); if (u) u.status = r.data.data.status }

// ===== 岗位知识能力 =====
interface CatItem { id: number; name: string; knowledge_base: string; icon: string | null; description: string | null }
const allCats = ref<CatItem[]>([])
const capabilities = ref<Record<string, number[]>>({})
const selectedPosition = ref('sales')
const checkedCats = ref<Set<number>>(new Set())
const capLoading = ref(false)
const capSaving = ref(false)

const positions = [
  { key: 'sales', label: '销售', icon: '💼' },
  { key: 'tech', label: '技术', icon: '🔧' },
  { key: 'service', label: '客服', icon: '📞' },
  { key: 'clerk', label: '文员', icon: '📋' },
]

const kbLabel: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }
const catExpanded = ref<Record<string, boolean>>({ public: true, sales: true, tech: true, service: true })

const selectedCount = computed(() => {
  const pos = selectedPosition.value
  return (capabilities.value[pos] || []).length
})

async function fetchCapabilities() {
  try {
    const [catRes, capRes] = await Promise.all([
      axios.get('/api/categories'),
      axios.get('/api/position-capabilities'),
    ])
    allCats.value = catRes.data.data
    capabilities.value = capRes.data.data
    selectPosition(selectedPosition.value)
  } catch { /* */ }
}

function selectPosition(pos: string) {
  selectedPosition.value = pos
  checkedCats.value = new Set(capabilities.value[pos] || [])
}

function toggleCat(cid: number) {
  if (checkedCats.value.has(cid)) checkedCats.value.delete(cid)
  else checkedCats.value.add(cid)
}

async function saveCapabilities() {
  capSaving.value = true
  try {
    await axios.put(`/api/position-capabilities/${selectedPosition.value}`, {
      category_ids: Array.from(checkedCats.value)
    })
    // 更新本地缓存
    capabilities.value[selectedPosition.value] = Array.from(checkedCats.value)
  } catch (e: any) { alert(e.response?.data?.detail || '保存失败') }
  finally { capSaving.value = false }
}

function switchTab(tab: 'users' | 'capability') {
  activeTab.value = tab
  if (tab === 'capability') fetchCapabilities()
}

onMounted(fetchList)
</script>

<template>
  <div class="um-page">
    <!-- Tab 切换 -->
    <div class="um-tabs">
      <button :class="{ active: activeTab === 'users' }" @click="switchTab('users')">👥 用户管理</button>
      <button :class="{ active: activeTab === 'capability' }" @click="switchTab('capability')">🎯 岗位知识能力</button>
    </div>

    <!-- ==================== Tab 1: 用户管理 ==================== -->
    <div v-if="activeTab === 'users'">
      <div class="um-head">
        <h2 class="page-title">用户管理</h2>
        <button class="btn btn-sm" @click="openCreate">+ 新增用户</button>
      </div>

      <div class="um-tools">
        <input v-model="keyword" placeholder="搜索用户名/姓名" class="form-input" style="width:180px" @keydown.enter="search" />
        <select v-model="roleFilter" @change="search" class="form-input" style="width:auto"><option value="">全部角色</option><option value="boss">老板</option><option value="admin">管理员</option><option value="staff">职员</option></select>
        <select v-model="posFilter" @change="search" class="form-input" style="width:auto"><option value="">全部岗位</option><option value="sales">销售</option><option value="tech">技术</option><option value="service">客服</option><option value="clerk">文员</option></select>
        <button class="btn btn-sm" @click="search">搜索</button>
      </div>

      <div class="table-responsive" v-if="!loading">
        <table class="um-table"><thead><tr><th>ID</th><th>用户名</th><th>姓名</th><th>角色</th><th>岗位</th><th>手机</th><th>状态</th><th>操作</th></tr></thead>
          <tbody>
            <tr v-for="u in items" :key="u.id">
              <td>{{ u.id }}</td><td>{{ u.username }}</td><td>{{ u.real_name }}</td>
              <td>{{ roleLabel[u.role] || u.role }}</td><td>{{ posLabel[u.position || ''] || '-' }}</td><td>{{ u.phone || '-' }}</td>
              <td><span :style="{ color: u.status === 1 ? 'var(--success)' : 'var(--danger)', fontWeight: 600 }">{{ u.status === 1 ? '启用' : '停用' }}</span></td>
              <td class="um-ops"><button class="btn btn-sm btn-outline" @click="openEdit(u)">编辑</button><button class="btn btn-sm" :class="u.status === 1 ? 'btn-danger' : ''" :style="u.status === 0 ? 'background:var(--success)' : ''" @click="toggleStatus(u.id)">{{ u.status === 1 ? '停用' : '启用' }}</button></td>
            </tr>
            <tr v-if="items.length === 0"><td colspan="8" style="text-align:center;padding:40px;color:var(--text-sub)">暂无用户</td></tr>
          </tbody>
        </table>
      </div>
      <div class="um-pager" v-if="total > 20">
        <button :disabled="page<=1" @click="page--;fetchList()" class="btn btn-sm btn-outline">上一页</button>
        <span>{{ page }}/{{ Math.ceil(total/20) }}</span>
        <button :disabled="page>=Math.ceil(total/20)" @click="page++;fetchList()" class="btn btn-sm btn-outline">下一页</button>
      </div>
    </div>

    <!-- ==================== Tab 2: 岗位知识能力 ==================== -->
    <div v-if="activeTab === 'capability'" class="cap-layout">
      <!-- 左侧：岗位列表 -->
      <div class="cap-left">
        <div v-for="p in positions" :key="p.key" class="cap-pos-card" :class="{ active: selectedPosition === p.key }" @click="selectPosition(p.key)">
          <span class="cap-pos-icon">{{ p.icon }}</span>
          <div>
            <div class="cap-pos-label">{{ p.label }}</div>
            <div class="cap-pos-count">{{ (capabilities[p.key] || []).length }} 个分类</div>
          </div>
        </div>
      </div>

      <!-- 右侧：知识分类树 -->
      <div class="cap-right">
        <div class="cap-right-head">
          <h3>{{ positions.find(p => p.key === selectedPosition)?.icon }} {{ positions.find(p => p.key === selectedPosition)?.label }} — 需掌握的知识分类</h3>
          <span style="font-size:12px;color:var(--text-sub)">已选 {{ checkedCats.size }} 个</span>
        </div>

        <div class="cap-tree">
          <div v-for="kb in ['public','sales','tech','service']" :key="kb" class="cap-tree-group">
            <div class="cap-tree-root" @click="catExpanded[kb] = !catExpanded[kb]">
              <span>{{ catExpanded[kb] ? '▼' : '▶' }}</span>
              <span style="font-weight:600">{{ kbLabel[kb] }}</span>
            </div>
            <div v-if="catExpanded[kb]" class="cap-tree-children">
              <label v-for="c in allCats.filter(x => x.knowledge_base === kb)" :key="c.id" class="cap-check-item" :class="{ checked: checkedCats.has(c.id) }">
                <input type="checkbox" :checked="checkedCats.has(c.id)" @change="toggleCat(c.id)" />
                <span>{{ c.icon || '📄' }} {{ c.name }}</span>
              </label>
            </div>
          </div>
        </div>

        <div class="cap-actions">
          <button class="btn btn-sm btn-outline" @click="selectPosition(selectedPosition)" :disabled="capLoading">重置</button>
          <button class="btn" @click="saveCapabilities" :disabled="capSaving">{{ capSaving ? '保存中...' : `💾 保存（${checkedCats.size} 个分类）` }}</button>
        </div>
      </div>
    </div>

    <!-- 编辑弹窗 -->
    <Teleport to="body">
      <div v-if="showForm" class="modal-overlay" @click.self="showForm=false">
        <div class="modal-panel">
          <div class="modal-header"><h3>{{ isEdit ? '编辑' : '新增' }}用户</h3><button @click="showForm=false" class="btn btn-sm">×</button></div>
          <div class="modal-body">
            <div class="form-group" v-if="!isEdit"><label>用户名 <span style="color:var(--danger)">*</span></label><input v-model="editing.username" class="form-input" style="width:100%" /></div>
            <div class="form-group"><label>真实姓名 <span style="color:var(--danger)">*</span></label><input v-model="editing.real_name" class="form-input" style="width:100%" /></div>
            <div class="form-group"><label>密码 {{ isEdit ? '(留空不修改)' : '' }}</label><input v-model="editing.password" type="password" class="form-input" style="width:100%" /></div>
            <div class="form-row">
              <div class="form-group"><label>角色</label><select v-model="editing.role" class="form-input" style="width:100%"><option value="staff">职员</option><option value="admin">管理员</option><option value="boss">老板</option></select></div>
              <div class="form-group"><label>岗位</label><select v-model="editing.position" class="form-input" style="width:100%"><option value="">不限</option><option value="sales">销售</option><option value="tech">技术</option><option value="service">客服</option><option value="clerk">文员</option></select></div>
            </div>
            <div class="form-row"><div class="form-group"><label>部门ID</label><input v-model.number="editing.dept_id" type="number" class="form-input" style="width:100%" /></div><div class="form-group"><label>门店ID</label><input v-model.number="editing.store_id" type="number" class="form-input" style="width:100%" /></div></div>
            <div class="form-group"><label>手机号</label><input v-model="editing.phone" class="form-input" style="width:100%" /></div>
          </div>
          <div class="modal-footer"><button class="btn btn-outline" @click="showForm=false">取消</button><button class="btn" @click="saveForm">保存</button></div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.um-page { max-width: 1100px; margin: 0 auto; }
.page-title { font-size: 20px; margin: 0; color: var(--text-main); }
.um-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }

/* Tabs */
.um-tabs { display: flex; gap: 0; margin-bottom: 16px; }
.um-tabs button { padding: 8px 24px; border: 1px solid var(--border); background: var(--bg-card); font-size: 14px; cursor: pointer; color: var(--text-sub); }
.um-tabs button:first-child { border-radius: 6px 0 0 6px; }
.um-tabs button:last-child { border-radius: 0 6px 6px 0; }
.um-tabs button.active { background: var(--primary); color: #fff; border-color: var(--primary); }

.um-tools { display: flex; gap: 8px; margin-bottom: 12px; align-items: center; flex-wrap: wrap; }
.um-table { width: 100%; border-collapse: collapse; font-size: 13px; background: var(--bg-card); border-radius: 8px; overflow: hidden; }
.um-table th, .um-table td { padding: 10px 12px; text-align: left; border-bottom: 1px solid var(--border); }
.um-table th { background: var(--bg-main); font-size: 12px; color: var(--text-sub); font-weight: 600; }
.um-ops { display: flex; gap: 4px; }
.um-pager { display: flex; justify-content: center; gap: 12px; align-items: center; margin-top: 16px; }

/* 岗位知识能力 */
.cap-layout { display: flex; gap: 16px; align-items: flex-start; }
.cap-left { width: 180px; flex-shrink: 0; display: flex; flex-direction: column; gap: 6px; }
.cap-pos-card { padding: 12px 14px; border: 1px solid var(--border); border-radius: 10px; cursor: pointer; display: flex; align-items: center; gap: 10px; transition: all 0.15s; }
.cap-pos-card:hover { border-color: var(--primary); }
.cap-pos-card.active { border-color: var(--primary); background: rgba(var(--primary-rgb, 74,144,226), 0.06); }
.cap-pos-icon { font-size: 22px; }
.cap-pos-label { font-size: 14px; font-weight: 600; color: var(--text-main); }
.cap-pos-count { font-size: 11px; color: var(--text-sub); margin-top: 1px; }

.cap-right { flex: 1; border: 1px solid var(--border); border-radius: 10px; padding: 16px; background: var(--bg-card); }
.cap-right-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
.cap-right-head h3 { margin: 0; font-size: 15px; color: var(--text-main); }

.cap-tree { max-height: 55vh; overflow-y: auto; margin-bottom: 14px; }
.cap-tree-group { margin-bottom: 6px; }
.cap-tree-root { display: flex; align-items: center; gap: 6px; padding: 5px 8px; cursor: pointer; font-size: 13px; color: var(--text-main); border-radius: 6px; user-select: none; }
.cap-tree-root:hover { background: var(--bg-main); }
.cap-tree-children { padding: 2px 0 4px 20px; display: flex; flex-direction: column; gap: 2px; }
.cap-check-item { display: flex; align-items: center; gap: 6px; padding: 5px 10px; border-radius: 6px; cursor: pointer; font-size: 13px; color: var(--text-main); transition: background 0.1s; }
.cap-check-item:hover { background: var(--bg-main); }
.cap-check-item.checked { color: var(--primary); }
.cap-check-item input { accent-color: var(--primary); }
.cap-actions { display: flex; gap: 8px; justify-content: flex-end; }

.modal-overlay { position: fixed; inset: 0; z-index: 8500; background: rgba(0,0,0,0.4); display: flex; align-items: center; justify-content: center; }
.modal-panel { width: 520px; max-width: 95vw; max-height: 90vh; background: var(--bg-card); border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.2); display: flex; flex-direction: column; }
.modal-header { display: flex; justify-content: space-between; align-items: center; padding: 14px 18px; border-bottom: 1px solid var(--border); }
.modal-header h3 { margin: 0; font-size: 16px; }
.modal-body { padding: 16px 18px; overflow-y: auto; flex: 1; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 12px 18px; border-top: 1px solid var(--border); }
.form-group { margin-bottom: 10px; }
.form-group label { display: block; font-size: 12px; color: var(--text-sub); margin-bottom: 3px; }
.form-row { display: flex; gap: 12px; }
.form-row .form-group { flex: 1; }

@media (max-width: 768px) {
  .um-tools { flex-direction: column; }
  .form-row { flex-direction: column; }
  .cap-layout { flex-direction: column; }
  .cap-left { width: 100%; flex-direction: row; flex-wrap: wrap; }
  .cap-pos-card { flex: 1 1 40%; }
}
</style>
