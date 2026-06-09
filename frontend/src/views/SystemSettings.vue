<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface SettingRow { id?: number; value: string; type: string; description: string; updated_at?: string | null }
interface LogItem { id: number; user_id: number | null; username: string | null; action: string; target_type: string | null; target_id: number | null; detail: string | null; ip_address: string | null; created_at: string | null }

const activeTab = ref<'points' | 'flywheel' | 'logs' | 'export'>('points')

// 积分规则
const pointsConfig = ref<Record<string, SettingRow>>({})
const pointKeys = ['points_submit', 'points_approved', 'points_useful', 'points_monthly_top5', 'points_daily_question', 'points_complete_course']
const pointLabels: Record<string, string> = {
  points_submit: '提交经验', points_approved: '审核通过', points_useful: '被标记有用',
  points_monthly_top5: '月度TOP5', points_daily_question: '每日一题答对', points_complete_course: '完成课程',
}

// 飞轮阈值
const flywheelConfig = ref<Record<string, SettingRow>>({})
const flywheelKeys = ['flywheel_view_threshold', 'flywheel_month_threshold', 'flywheel_effective_month', 'flywheel_dead_month']
const flywheelLabels: Record<string, string> = {
  flywheel_view_threshold: '低效经验浏览阈值（少于N次）',
  flywheel_month_threshold: '知识更新周期（月）',
  flywheel_effective_month: '有效经验有用率阈值',
  flywheel_dead_month: '待优化经验有用率阈值',
}

// 审计日志
const logs = ref<LogItem[]>([])
const logsTotal = ref(0)
const logsPage = ref(1)
const logsAction = ref('')
const logsKeyword = ref('')

// 导出
const exporting = ref(false)

const actionLabels: Record<string, string> = {
  login: '登录', logout: '退出', create_knowledge: '新增知识', edit_knowledge: '编辑知识',
  delete_knowledge: '归档知识', review_approve: '审核通过', review_reject: '驳回',
  create_user: '新建用户', edit_user: '编辑用户', toggle_user: '启用/停用用户',
  update_settings: '修改设置', submit_experience: '提交经验',
}

async function fetchSettings() {
  const { data } = await axios.get('/api/settings')
  const all = data.data || {}
  const pts: Record<string, SettingRow> = {}
  pointKeys.forEach(k => { pts[k] = all[k] || { value: '0', type: 'int', description: pointLabels[k] || k } })
  pointsConfig.value = pts

  const fw: Record<string, SettingRow> = {}
  flywheelKeys.forEach(k => { fw[k] = all[k] || { value: '0', type: 'float', description: flywheelLabels[k] || k } })
  flywheelConfig.value = fw
}

async function saveSetting(key: string, value: string) {
  await axios.put(`/api/settings?config_key=${encodeURIComponent(key)}&config_value=${encodeURIComponent(value)}`)
  fetchSettings()
}

async function fetchLogs() {
  const params: any = { page: logsPage.value, page_size: 20 }
  if (logsAction.value) params.action = logsAction.value
  if (logsKeyword.value) params.keyword = logsKeyword.value
  const { data } = await axios.get('/api/logs/audit', { params })
  logs.value = data.data.items
  logsTotal.value = data.data.total
}

async function exportCSV() {
  exporting.value = true
  try {
    const { data } = await axios.get('/api/knowledge', { params: { page_size: 9999 } })
    const items = data.data.items || []
    const headers = ['ID', '标题', '知识库', '分类ID', '车型', '标签', '浏览', '有用', '状态']
    const rows = items.map((i: any) => [
      i.id, i.title, i.knowledge_base, i.category_id, i.car_brand || '',
      i.tags || '', i.view_count, i.useful_count, i.status,
    ])

    let csv = '﻿' + headers.join(',') + '\n'
    rows.forEach((r: any[]) => { csv += r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(',') + '\n' })

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url; a.download = `knowledge_export_${new Date().toISOString().slice(0,10)}.csv`
    a.click(); URL.revokeObjectURL(url)
  } finally {
    exporting.value = false
  }
}

onMounted(() => { fetchSettings(); fetchLogs() })
</script>

<template>
  <div class="ss-page">
    <h2 class="page-title">系统设置</h2>

    <!-- Tab 导航 -->
    <div class="ss-tabs">
      <button :class="{ active: activeTab === 'points' }" @click="activeTab = 'points'">积分规则</button>
      <button :class="{ active: activeTab === 'flywheel' }" @click="activeTab = 'flywheel'">飞轮阈值</button>
      <button :class="{ active: activeTab === 'logs' }" @click="activeTab = 'logs'">审计日志</button>
      <button :class="{ active: activeTab === 'export' }" @click="activeTab = 'export'">数据导出</button>
    </div>

    <!-- 积分规则 -->
    <div v-if="activeTab === 'points'" class="ss-tab card">
      <h3>积分规则配置</h3>
      <div class="ss-row" v-for="(cfg, key) in pointsConfig" :key="key">
        <span class="ss-label">{{ cfg.description }}</span>
        <div class="ss-input-group">
          <input v-model="cfg.value" type="number" class="form-input" style="width:100px" />
          <button class="btn btn-sm" @click="saveSetting(key, cfg.value)">保存</button>
        </div>
      </div>
    </div>

    <!-- 飞轮阈值 -->
    <div v-if="activeTab === 'flywheel'" class="ss-tab card">
      <h3>飞轮阈值配置</h3>
      <div class="ss-row" v-for="(cfg, key) in flywheelConfig" :key="key">
        <span class="ss-label">{{ cfg.description }}</span>
        <div class="ss-input-group">
          <input v-model="cfg.value" type="number" step="0.1" class="form-input" style="width:100px" />
          <button class="btn btn-sm" @click="saveSetting(key, cfg.value)">保存</button>
        </div>
      </div>
    </div>

    <!-- 审计日志 -->
    <div v-if="activeTab === 'logs'" class="ss-tab">
      <div class="ss-logs-tools">
        <select v-model="logsAction" @change="logsPage=1;fetchLogs()" class="form-input" style="width:auto">
          <option value="">全部操作</option>
          <option v-for="(label, key) in actionLabels" :key="key" :value="key">{{ label }}</option>
        </select>
        <input v-model="logsKeyword" placeholder="搜索用户名/详情" class="form-input" style="width:180px" @keydown.enter="logsPage=1;fetchLogs()" />
        <button class="btn btn-sm" @click="logsPage=1;fetchLogs()">搜索</button>
      </div>
      <div class="table-responsive">
        <table class="ss-table">
          <thead>
            <tr><th>ID</th><th>用户</th><th>操作</th><th>对象</th><th>详情</th><th>IP</th><th>时间</th></tr>
          </thead>
          <tbody>
            <tr v-for="l in logs" :key="l.id">
              <td>{{ l.id }}</td>
              <td>{{ l.username || '-' }}</td>
              <td><span class="ss-action-tag">{{ actionLabels[l.action] || l.action }}</span></td>
              <td>{{ l.target_type ? l.target_type + '#' + l.target_id : '-' }}</td>
              <td class="ss-detail">{{ l.detail || '-' }}</td>
              <td>{{ l.ip_address || '-' }}</td>
              <td>{{ l.created_at?.slice(0, 19)?.replace('T', ' ') || '-' }}</td>
            </tr>
            <tr v-if="logs.length === 0">
              <td colspan="7" style="text-align:center;padding:40px;color:var(--text-sub)">暂无日志</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="ss-pager" v-if="logsTotal > 20">
        <button :disabled="logsPage<=1" @click="logsPage--;fetchLogs()" class="btn btn-sm btn-outline">上一页</button>
        <span>{{ logsPage }} / {{ Math.ceil(logsTotal / 20) }}</span>
        <button :disabled="logsPage>=Math.ceil(logsTotal/20)" @click="logsPage++;fetchLogs()" class="btn btn-sm btn-outline">下一页</button>
      </div>
    </div>

    <!-- 数据导出 -->
    <div v-if="activeTab === 'export'" class="ss-tab card">
      <h3>数据导出</h3>
      <p class="ss-export-desc">导出知识库全部已通过的知识条目为 CSV 文件，可直接用 Excel 打开。</p>
      <button class="btn" @click="exportCSV" :disabled="exporting">
        {{ exporting ? '生成中...' : '📥 导出知识库 CSV' }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.ss-page { max-width: 1000px; margin: 0 auto; }
.page-title { font-size: 20px; margin-bottom: 16px; color: var(--text-main); }

.ss-tabs { display: flex; gap: 0; margin-bottom: 16px; }
.ss-tabs button {
  padding: 8px 20px; border: 1px solid var(--border); background: var(--bg-card);
  font-size: 14px; cursor: pointer; color: var(--text-sub);
}
.ss-tabs button:first-child { border-radius: 6px 0 0 6px; }
.ss-tabs button:last-child { border-radius: 0 6px 6px 0; }
.ss-tabs button.active { background: var(--primary); color: #fff; border-color: var(--primary); }

.ss-tab { padding: 24px; }
.ss-tab h3 { font-size: 16px; margin: 0 0 16px; color: var(--text-main); }

.ss-row {
  display: flex; justify-content: space-between; align-items: center;
  padding: 10px 0; border-bottom: 1px solid var(--border);
}
.ss-label { font-size: 13px; color: var(--text-main); flex: 1; }
.ss-input-group { display: flex; align-items: center; gap: 8px; }

.ss-logs-tools { display: flex; gap: 8px; margin-bottom: 12px; align-items: center; flex-wrap: wrap; }

.ss-table { width: 100%; border-collapse: collapse; font-size: 13px; background: var(--bg-card); border-radius: 8px; overflow: hidden; }
.ss-table th, .ss-table td { padding: 8px 10px; text-align: left; border-bottom: 1px solid var(--border); }
.ss-table th { background: var(--bg-main); font-size: 12px; color: var(--text-sub); font-weight: 600; }
.ss-detail { max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.ss-action-tag {
  padding: 2px 8px; border-radius: 8px; font-size: 11px;
  background: var(--bg-main); color: var(--primary); border: 1px solid var(--border);
}

.ss-pager { display: flex; justify-content: center; align-items: center; gap: 12px; margin-top: 16px; }

.ss-export-desc { font-size: 13px; color: var(--text-sub); margin-bottom: 16px; }

@media (max-width: 768px) {
  .ss-tabs { overflow-x: auto; }
  .ss-tabs button { font-size: 12px; padding: 8px 12px; white-space: nowrap; }
  .ss-row { flex-direction: column; align-items: flex-start; gap: 8px; }
  .ss-logs-tools { flex-direction: column; }
}
</style>
