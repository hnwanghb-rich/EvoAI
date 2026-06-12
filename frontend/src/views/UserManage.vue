<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface UserItem {
  id: number; username: string; real_name: string; role: string
  position: string | null; dept_id: number | null; store_id: number | null
  phone: string | null; status: number; created_at: string | null
}

const loading = ref(true)
const items = ref<UserItem[]>([])
const total = ref(0)
const page = ref(1)
const keyword = ref('')
const roleFilter = ref('')
const posFilter = ref('')

// 表单
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
  items.value = data.data.items
  total.value = data.data.total
  loading.value = false
}

function search() { page.value = 1; fetchList() }

function openCreate() {
  isEdit.value = false
  editing.value = { username: '', real_name: '', password: 'hequn123', role: 'staff', position: '', dept_id: null, store_id: null, phone: '' }
  showForm.value = true
}
function openEdit(u: UserItem) {
  isEdit.value = true
  editing.value = { ...u, password: '' }
  showForm.value = true
}
async function saveForm() {
  const body: any = {
    real_name: editing.value.real_name,
    role: editing.value.role,
    position: editing.value.position || null,
    dept_id: editing.value.dept_id || null,
    store_id: editing.value.store_id || null,
    phone: editing.value.phone || null,
  }
  if (editing.value.password) body.password = editing.value.password

  if (isEdit.value) {
    await axios.put(`/api/users/${editing.value.id}`, body)
  } else {
    await axios.post('/api/users', {
      ...body,
      username: editing.value.username,
      password: editing.value.password || 'hequn123',
    })
  }
  showForm.value = false
  fetchList()
}

async function toggleStatus(id: number) {
  const r = await axios.put(`/api/users/${id}/status`)
  const u = items.value.find(i => i.id === id)
  if (u) u.status = r.data.data.status
}

onMounted(fetchList)
</script>

<template>
  <div class="um-page">
    <div class="um-head">
      <h2 class="page-title">用户管理</h2>
      <button class="btn btn-sm" @click="openCreate">+ 新增用户</button>
    </div>

    <!-- 筛选 -->
    <div class="um-tools">
      <input v-model="keyword" placeholder="搜索用户名/姓名" class="form-input" style="width:180px" @keydown.enter="search" />
      <select v-model="roleFilter" @change="search" class="form-input" style="width:auto">
        <option value="">全部角色</option>
        <option value="boss">老板</option>
        <option value="admin">管理员</option>
        <option value="staff">职员</option>
      </select>
      <select v-model="posFilter" @change="search" class="form-input" style="width:auto">
        <option value="">全部岗位</option>
        <option value="sales">销售</option>
        <option value="tech">技术</option>
        <option value="service">客服</option>
        <option value="clerk">文员</option>
      </select>
      <button class="btn btn-sm" @click="search">搜索</button>
    </div>

    <!-- 表格 -->
    <div class="table-responsive" v-if="!loading">
      <table class="um-table">
        <thead>
          <tr><th>ID</th><th>用户名</th><th>姓名</th><th>角色</th><th>岗位</th><th>手机</th><th>状态</th><th>操作</th></tr>
        </thead>
        <tbody>
          <tr v-for="u in items" :key="u.id">
            <td>{{ u.id }}</td>
            <td>{{ u.username }}</td>
            <td>{{ u.real_name }}</td>
            <td>{{ roleLabel[u.role] || u.role }}</td>
            <td>{{ posLabel[u.position || ''] || '-' }}</td>
            <td>{{ u.phone || '-' }}</td>
            <td>
              <span :style="{ color: u.status === 1 ? 'var(--success)' : 'var(--danger)', fontWeight: 600 }">
                {{ u.status === 1 ? '启用' : '停用' }}
              </span>
            </td>
            <td class="um-ops">
              <button class="btn btn-sm btn-outline" @click="openEdit(u)">编辑</button>
              <button
                class="btn btn-sm"
                :class="u.status === 1 ? 'btn-danger' : ''"
                :style="u.status === 0 ? 'background:var(--success)' : ''"
                @click="toggleStatus(u.id)"
              >
                {{ u.status === 1 ? '停用' : '启用' }}
              </button>
            </td>
          </tr>
          <tr v-if="items.length === 0">
            <td colspan="8" style="text-align:center;padding:40px;color:var(--text-sub)">暂无用户</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="um-pager" v-if="total > 20">
      <button :disabled="page<=1" @click="page--;fetchList()" class="btn btn-sm btn-outline">上一页</button>
      <span>{{ page }}/{{ Math.ceil(total/20) }}</span>
      <button :disabled="page>=Math.ceil(total/20)" @click="page++;fetchList()" class="btn btn-sm btn-outline">下一页</button>
    </div>

    <!-- 编辑弹窗 -->
    <Teleport to="body">
      <div v-if="showForm" class="modal-overlay" @click.self="showForm=false">
        <div class="modal-panel">
          <div class="modal-header"><h3>{{ isEdit ? '编辑' : '新增' }}用户</h3><button @click="showForm=false" class="btn btn-sm">×</button></div>
          <div class="modal-body">
            <div class="form-group" v-if="!isEdit">
              <label>用户名 <span style="color:var(--danger)">*</span></label>
              <input v-model="editing.username" class="form-input" style="width:100%" placeholder="登录用户名" />
            </div>
            <div class="form-group">
              <label>真实姓名 <span style="color:var(--danger)">*</span></label>
              <input v-model="editing.real_name" class="form-input" style="width:100%" />
            </div>
            <div class="form-group">
              <label>密码 {{ isEdit ? '(留空则不修改)' : '' }}</label>
              <input v-model="editing.password" type="password" class="form-input" style="width:100%" :placeholder="isEdit ? '留空不修改' : '默认 hequn123'" />
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>角色</label>
                <select v-model="editing.role" class="form-input" style="width:100%">
                  <option value="staff">职员</option>
                  <option value="admin">管理员</option>
                  <option value="boss">老板</option>
                </select>
              </div>
              <div class="form-group">
                <label>岗位</label>
                <select v-model="editing.position" class="form-input" style="width:100%">
                  <option value="">不限</option>
                  <option value="sales">销售</option>
                  <option value="tech">技术</option>
                  <option value="service">客服</option>
                  <option value="clerk">文员</option>
                </select>
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>部门ID</label>
                <input v-model.number="editing.dept_id" type="number" class="form-input" style="width:100%" />
              </div>
              <div class="form-group">
                <label>门店ID</label>
                <input v-model.number="editing.store_id" type="number" class="form-input" style="width:100%" />
              </div>
            </div>
            <div class="form-group">
              <label>手机号</label>
              <input v-model="editing.phone" class="form-input" style="width:100%" />
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-outline" @click="showForm=false">取消</button>
            <button class="btn" @click="saveForm">保存</button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.um-page { max-width: 1000px; margin: 0 auto; }
.page-title { font-size: 20px; margin: 0; color: var(--text-main); }
.um-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }

.um-tools { display: flex; gap: 8px; margin-bottom: 12px; align-items: center; flex-wrap: wrap; }

.um-table { width: 100%; border-collapse: collapse; font-size: 13px; background: var(--bg-card); border-radius: 8px; overflow: hidden; }
.um-table th, .um-table td { padding: 10px 12px; text-align: left; border-bottom: 1px solid var(--border); }
.um-table th { background: var(--bg-main); font-size: 12px; color: var(--text-sub); font-weight: 600; }
.um-ops { display: flex; gap: 4px; }

.um-pager { display: flex; justify-content: center; gap: 12px; align-items: center; margin-top: 16px; }

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
}
</style>
