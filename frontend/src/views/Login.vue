<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

const username = ref('')
const password = ref('')
const agreeConsent = ref(false)
const loading = ref(false)
const error = ref('')
const showConsentDetail = ref(false)

async function doLogin() {
  error.value = ''
  if (!username.value || !password.value) {
    error.value = '请输入用户名和密码'
    return
  }
  if (!agreeConsent.value) {
    error.value = '请先阅读并同意个人信息授权协议'
    return
  }
  loading.value = true
  try {
    await auth.login(username.value, password.value, agreeConsent.value)
    router.push('/')
  } catch (e: any) {
    error.value = e.response?.data?.detail || '登录失败，请检查网络连接'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-page">
    <div class="login-card">
      <div class="login-brand">
        <h1>合群汽车集团</h1>
        <p>AI+业务能力知识库</p>
      </div>

      <form @submit.prevent="doLogin" class="login-form">
        <!-- 用户名 -->
        <div class="form-group">
          <label for="username">用户名</label>
          <input id="username" v-model="username" type="text" autocomplete="username" placeholder="请输入用户名" :disabled="loading" />
        </div>

        <!-- 密码 -->
        <div class="form-group">
          <label for="password">密码</label>
          <input id="password" v-model="password" type="password" autocomplete="current-password" placeholder="请输入密码" :disabled="loading" />
        </div>

        <!-- 个人信息授权（每次登录必须勾选） -->
        <div class="consent-section">
          <div class="consent-header" @click="showConsentDetail = !showConsentDetail">
            <span class="consent-arrow" :class="{ open: showConsentDetail }">▶</span>
            <span class="consent-title">个人信息收集与使用授权协议</span>
          </div>

          <!-- 可展开的协议内容 -->
          <div v-if="showConsentDetail" class="consent-body">
            <p><b>一、信息收集范围</b></p>
            <p>本系统在您使用过程中会收集以下信息：</p>
            <ul>
              <li>个人基本信息：姓名、账号、岗位、部门、手机号</li>
              <li>工作贡献数据：提交的工作经验、岗位知识、技能技巧</li>
              <li>学习行为数据：浏览记录、学习时长、每日答题、积分变动</li>
              <li>AI对话数据：与数字老师"阿能"的对话内容及反馈</li>
            </ul>
            <p><b>二、信息使用目的</b></p>
            <ul>
              <li>企业知识库建设与经验沉淀</li>
              <li>个人/团队能力评估与培训推荐</li>
              <li>AI辅助工作（阿能数字老师）</li>
              <li>系统功能优化与体验改进</li>
            </ul>
            <p><b>三、数据归属与保护</b></p>
            <ul>
              <li>您提交的知识内容版权归合群汽车集团所有</li>
              <li>个人学习记录仅您本人及直属管理员可见</li>
              <li>本系统不会将您的数据提供给第三方</li>
              <li>所有操作均有审计日志记录，可追溯</li>
            </ul>
            <p><b>四、您的权利</b></p>
            <ul>
              <li>您有权随时查看自己的个人学习数据</li>
              <li>您有权对不准确的数据提出更正申请</li>
              <li>离职后您的知识贡献将保留在企业知识库中</li>
            </ul>
          </div>

          <!-- 勾选框 -->
          <label class="consent-check">
            <input type="checkbox" v-model="agreeConsent" />
            <span>我已阅读并同意<strong>《个人信息收集与使用授权协议》</strong>的全部条款</span>
          </label>
        </div>

        <!-- 错误提示 -->
        <p v-if="error" class="login-error">{{ error }}</p>

        <!-- 登录按钮 -->
        <button type="submit" class="login-btn" :disabled="loading || !agreeConsent">
          {{ loading ? '登录中...' : '登录' }}
        </button>
      </form>

      <p class="login-hint">如忘记密码或需要账号，请联系系统管理员</p>
    </div>
  </div>
</template>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex; align-items: center; justify-content: center;
  background: var(--bg-main); padding: 20px;
}
.login-card {
  width: 440px; max-width: 100%;
  background: var(--bg-card); border-radius: 12px;
  box-shadow: 0 4px 24px var(--shadow); padding: 40px 32px;
}
.login-brand { text-align: center; margin-bottom: 28px; }
.login-brand h1 { margin: 0; font-size: 24px; color: var(--primary); letter-spacing: 2px; }
.login-brand p { margin: 6px 0 0; font-size: 14px; color: var(--text-sub); }

/* 表单 */
.form-group { margin-bottom: 14px; }
.form-group label { display: block; font-size: 13px; color: var(--text-sub); margin-bottom: 4px; }
.form-group input {
  width: 100%; padding: 10px 12px; border: 1px solid var(--border);
  border-radius: 8px; font-size: 15px; background: var(--bg-main);
  color: var(--text-main); outline: none; box-sizing: border-box;
}
.form-group input:focus { border-color: var(--primary); }

/* ---- 授权协议区 ---- */
.consent-section {
  margin: 8px 0 15px;
  border: 1px solid var(--border);
  border-radius: 8px;
  overflow: hidden;
}
.consent-header {
  display: flex; align-items: center; gap: 8px;
  padding: 10px 14px;
  background: var(--bg-main);
  cursor: pointer;
  user-select: none;
  transition: background 0.15s;
}
.consent-header:hover { background: var(--border); }
.consent-arrow {
  font-size: 10px; color: var(--text-sub);
  transition: transform 0.2s;
  flex-shrink: 0;
}
.consent-arrow.open { transform: rotate(90deg); }
.consent-title {
  font-size: 13px; font-weight: 600;
  color: var(--text-main);
}

.consent-body {
  padding: 14px 16px;
  font-size: 12px; color: var(--text-sub); line-height: 1.75;
  border-top: 1px solid var(--border);
  max-height: 260px; overflow-y: auto;
}
.consent-body p { margin: 6px 0; }
.consent-body ul { padding-left: 18px; margin: 4px 0; }
.consent-body li { margin-bottom: 2px; }

.consent-check {
  display: flex; align-items: flex-start; gap: 8px;
  padding: 10px 14px; cursor: pointer;
  font-size: 13px; color: var(--text-main);
  border-top: 1px solid var(--border);
}
.consent-check input {
  width: 16px; height: 16px; margin-top: 1px;
  accent-color: var(--primary); cursor: pointer; flex-shrink: 0;
}
.consent-check strong { color: var(--primary); }

/* 错误 + 按钮 */
.login-error { color: var(--danger); font-size: 13px; margin: 8px 0; }
.login-btn {
  width: 100%; padding: 12px; background: var(--primary); color: #fff;
  border: none; border-radius: 8px; font-size: 16px; font-weight: 600;
  cursor: pointer; letter-spacing: 1px; transition: opacity 0.2s;
  margin-top: 4px;
}
.login-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.login-btn:hover:not(:disabled) { opacity: 0.9; }
.login-hint { text-align: center; margin-top: 20px; font-size: 12px; color: var(--text-sub); }
</style>
