<script setup lang="ts">
// FW-02 飞轮运营总览 —— 势能/转速/加速度/摩擦力/北极星
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface Trend { day: string; hit_rate: number; total: number }
interface TopMiss { question: string; count: number }
interface Data {
  north_star: { hit_satisfied_rate: number | null; total_30d: number; label: string }
  momentum: { total_approved: number; by_kb: Record<string, number>; label: string }
  velocity: { hit_rate_30d: number | null; hit_total_30d: number; useful_total: number; label: string }
  acceleration: { new_experience_this_week: number; gaps_closed_30d: number; gaps_open: number; label: string }
  friction: { expired_count: number | null; note: string }
  trend_7d: Trend[]
  top_miss_30d: TopMiss[]
}

const loading = ref(false)
const data = ref<Data | null>(null)
const error = ref('')

const KB_LABEL: Record<string, string> = { public: '公共', sales: '销售', tech: '技术', service: '客服' }

function kbLabel(k: string) { return KB_LABEL[k] || k }

function rateColor(r: number | null) {
  if (r === null) return 'var(--text-sub, #999)'
  if (r >= 75) return '#3a8f3a'
  if (r >= 50) return '#c77700'
  return '#c73a3a'
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/flywheel/metrics/summary')
    data.value = res.data.data
  } catch {
    error.value = '加载失败，请确认已用管理员账号登录'
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="fw-overview">
    <div class="page-head">
      <h2>飞轮运营总览</h2>
      <p class="sub">知识飞轮四象限健康度 · 数据实时聚合</p>
      <button class="refresh-btn" @click="load" :disabled="loading">{{ loading ? '加载中…' : '刷新' }}</button>
    </div>

    <div v-if="error" class="err">{{ error }}</div>
    <div v-if="loading && !data" class="loading">加载中…</div>

    <template v-if="data">
      <!-- 北极星 -->
      <div class="north-star-row">
        <div class="north-star-card">
          <div class="ns-label">⭐ 北极星指标 · 近30天命中满意率</div>
          <div class="ns-value" :style="{ color: rateColor(data.north_star.hit_satisfied_rate) }">
            {{ data.north_star.hit_satisfied_rate !== null ? data.north_star.hit_satisfied_rate + '%' : '暂无数据' }}
          </div>
          <div class="ns-sub">基于 {{ data.north_star.total_30d.toLocaleString() }} 次问答 · 越高飞轮越健康</div>
        </div>
      </div>

      <!-- 四象限 -->
      <div class="quadrant-grid">
        <!-- 势能 -->
        <div class="quad-card">
          <div class="quad-title">▲ 势能 · 知识储量</div>
          <div class="quad-main">{{ data.momentum.total_approved.toLocaleString() }}</div>
          <div class="quad-sub">条有效知识</div>
          <div class="kb-breakdown">
            <span v-for="(cnt, kb) in data.momentum.by_kb" :key="kb" class="kb-tag">
              {{ kbLabel(String(kb)) }} <b>{{ cnt }}</b>
            </span>
          </div>
        </div>

        <!-- 转速 -->
        <div class="quad-card">
          <div class="quad-title">↺ 转速 · 复用频率</div>
          <div class="quad-main" :style="{ color: rateColor(data.velocity.hit_rate_30d) }">
            {{ data.velocity.hit_rate_30d !== null ? data.velocity.hit_rate_30d + '%' : '—' }}
          </div>
          <div class="quad-sub">近30天问答命中率（{{ data.velocity.hit_total_30d.toLocaleString() }} 次）</div>
          <div class="quad-extra">知识累计被引用 <b>{{ data.velocity.useful_total.toLocaleString() }}</b> 次</div>
        </div>

        <!-- 加速度 -->
        <div class="quad-card">
          <div class="quad-title">▶ 加速度 · 进化速度</div>
          <div class="quad-main">{{ data.acceleration.new_experience_this_week }}</div>
          <div class="quad-sub">本周新沉淀经验</div>
          <div class="quad-extra">
            近30天缺口闭合 <b>{{ data.acceleration.gaps_closed_30d }}</b> 个 ·
            待处理 <b>{{ data.acceleration.gaps_open }}</b> 个
          </div>
        </div>

        <!-- 摩擦力 -->
        <div class="quad-card friction">
          <div class="quad-title">⊗ 摩擦力 · 知识污染</div>
          <div class="quad-main pending">—</div>
          <div class="quad-sub pending-note">{{ data.friction.note }}</div>
          <div class="quad-extra">
            <router-link to="/flywheel/gap" class="link">查看未命中缺口</router-link>
          </div>
        </div>
      </div>

      <!-- 7天趋势 -->
      <div class="block">
        <div class="block-title">近7天命中率趋势</div>
        <div v-if="data.trend_7d.length === 0" class="empty">暂无数据</div>
        <div v-else class="trend-list">
          <div v-for="t in data.trend_7d" :key="t.day" class="trend-row">
            <span class="trend-day">{{ t.day.slice(5) }}</span>
            <div class="trend-bar-wrap">
              <div class="trend-bar" :style="{ width: t.hit_rate + '%', background: rateColor(t.hit_rate) }"></div>
            </div>
            <span class="trend-rate" :style="{ color: rateColor(t.hit_rate) }">{{ t.hit_rate }}%</span>
            <span class="trend-total">{{ t.total }}次</span>
          </div>
        </div>
      </div>

      <!-- 高频未命中TOP5 -->
      <div class="block">
        <div class="block-title">近30天高频未命中问题 TOP5
          <router-link to="/flywheel/gap" class="link-sm">→ 去知识缺口工作台处理</router-link>
        </div>
        <div v-if="data.top_miss_30d.length === 0" class="empty">近30天无未命中记录</div>
        <table v-else>
          <thead><tr><th>#</th><th>问题</th><th>未命中次数</th></tr></thead>
          <tbody>
            <tr v-for="(m, i) in data.top_miss_30d" :key="i">
              <td class="rank">{{ i + 1 }}</td>
              <td class="q">{{ m.question }}</td>
              <td class="cnt">{{ m.count }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </div>
</template>

<style scoped>
.fw-overview { padding: 20px; max-width: 70%; margin: 0; }
.page-head { display: flex; align-items: baseline; gap: 12px; margin-bottom: 16px; flex-wrap: wrap; }
.page-head h2 { margin: 0; color: var(--text-main, #1a1a1a); }
.page-head .sub { margin: 0; color: var(--text-sub, #888); font-size: 13px; flex: 1; }
.refresh-btn { padding: 4px 14px; border: 1px solid var(--border, #ccc); border-radius: 4px; background: var(--bg-card, #fff); cursor: pointer; font-size: 12px; }
.refresh-btn:hover { border-color: var(--primary, #6B7B8B); color: var(--primary); }
.loading, .err { padding: 12px 0; color: var(--text-sub, #999); font-size: 13px; }
.err { color: #c73a3a; }

/* 北极星 */
.north-star-row { margin-bottom: 16px; }
.north-star-card { background: var(--bg-card, #fff); border: 2px solid var(--primary, #6B7B8B); border-radius: 10px; padding: 20px 28px; display: flex; align-items: center; gap: 28px; flex-wrap: wrap; }
.ns-label { font-size: 13px; color: var(--text-sub, #888); min-width: 200px; }
.ns-value { font-size: 42px; font-weight: 700; line-height: 1; }
.ns-sub { font-size: 12px; color: var(--text-sub, #999); }

/* 四象限 */
.quadrant-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 14px; margin-bottom: 16px; }
@media (max-width: 700px) { .quadrant-grid { grid-template-columns: 1fr; } }
.quad-card { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 16px 18px; }
.quad-title { font-size: 13px; color: var(--text-sub, #888); margin-bottom: 8px; font-weight: 600; }
.quad-main { font-size: 36px; font-weight: 700; color: var(--primary, #6B7B8B); line-height: 1.1; }
.quad-main.pending { color: var(--text-sub, #bbb); }
.quad-sub { font-size: 12px; color: var(--text-sub, #999); margin-top: 4px; }
.quad-extra { font-size: 12px; color: var(--text-sub, #999); margin-top: 6px; }
.pending-note { font-size: 11px; color: var(--text-sub, #bbb); font-style: italic; }
.kb-breakdown { margin-top: 8px; display: flex; gap: 6px; flex-wrap: wrap; }
.kb-tag { background: var(--bg-main, #f6f6f6); border-radius: 4px; padding: 2px 8px; font-size: 12px; color: var(--text-sub, #666); }
.kb-tag b { color: var(--primary, #6B7B8B); margin-left: 2px; }
.link { font-size: 12px; color: var(--primary, #6B7B8B); text-decoration: none; }

/* 趋势 + TOP5 */
.block { background: var(--bg-card, #fff); border: 1px solid var(--border, #e5e5e5); border-radius: 8px; padding: 16px; margin-bottom: 16px; }
.block-title { font-size: 14px; font-weight: 600; color: var(--text-main, #1a1a1a); margin-bottom: 12px; display: flex; align-items: center; gap: 10px; }
.link-sm { font-size: 12px; color: var(--primary, #6B7B8B); text-decoration: none; font-weight: normal; }
.empty { font-size: 13px; color: var(--text-sub, #999); }

.trend-list { display: flex; flex-direction: column; gap: 6px; }
.trend-row { display: flex; align-items: center; gap: 10px; font-size: 13px; }
.trend-day { width: 36px; color: var(--text-sub, #888); font-size: 12px; }
.trend-bar-wrap { flex: 1; height: 14px; background: var(--bg-main, #f0f0f0); border-radius: 7px; overflow: hidden; }
.trend-bar { height: 100%; border-radius: 7px; transition: width 0.4s; }
.trend-rate { width: 42px; text-align: right; font-weight: 600; font-size: 12px; }
.trend-total { width: 44px; color: var(--text-sub, #999); font-size: 11px; }

table { width: 100%; border-collapse: collapse; font-size: 13px; }
th, td { text-align: left; padding: 7px 10px; border-bottom: 1px solid var(--border, #eee); }
th { color: var(--text-sub, #888); font-weight: 600; }
td.rank { width: 30px; font-weight: 700; color: var(--primary, #6B7B8B); }
td.q { max-width: 500px; }
td.cnt { font-weight: 600; color: #c77700; }
</style>
