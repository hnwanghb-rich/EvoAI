import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

export interface UserInfo {
  id: number
  username: string
  real_name: string
  role: string
  position: string | null
  dept_id: number | null
  store_id: number | null
  phone: string | null
  avatar_url: string | null
  status: number
}

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string>(localStorage.getItem('token') || '')
  const user = ref<UserInfo | null>(null)
  const skinId = ref<number>(1)

  const isLoggedIn = computed(() => !!token.value)
  const isAdmin = computed(() => user.value?.role === 'admin' || user.value?.role === 'boss')
  const isBoss = computed(() => user.value?.role === 'boss')
  const isStaff = computed(() => user.value?.role === 'staff')

  // axios 拦截器：自动带 token
  axios.interceptors.request.use((config) => {
    if (token.value) {
      config.headers.Authorization = `Bearer ${token.value}`
    }
    return config
  })

  axios.interceptors.response.use(
    (res) => res,
    (err) => {
      if (err.response?.status === 401) {
        logout()
        window.location.href = '/login'
      }
      return Promise.reject(err)
    }
  )

  async function login(username: string, password: string, agreeConsent: boolean) {
    const res = await axios.post('/api/auth/login', { username, password })
    const d = res.data.data
    token.value = d.token
    skinId.value = d.skin_id || 1
    localStorage.setItem('token', d.token)
    localStorage.setItem('consent_agreed', String(agreeConsent))
    await fetchMe()
    return d
  }

  async function fetchMe() {
    if (!token.value) return
    try {
      const res = await axios.get('/api/auth/me')
      user.value = res.data.data
    } catch {
      logout()
    }
  }

  async function saveSkin(id: number) {
    skinId.value = id
    document.body.setAttribute('data-skin', String(id))
    localStorage.setItem('skin_id', String(id))
    if (token.value) {
      try { await axios.put('/api/auth/skin', { skin_id: id }) } catch { /* 静默 */ }
    }
  }

  function logout() {
    token.value = ''
    user.value = null
    localStorage.removeItem('token')
  }

  // 初始化恢复
  async function init() {
    const savedSkin = localStorage.getItem('skin_id')
    if (savedSkin) {
      skinId.value = Number(savedSkin)
      document.body.setAttribute('data-skin', savedSkin)
    }
    if (token.value) {
      await fetchMe()
    }
  }

  return { token, user, skinId, isLoggedIn, isAdmin, isBoss, isStaff, login, fetchMe, saveSkin, logout, init }
})
