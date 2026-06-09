import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from './stores/auth'

const routes = [
  { path: '/login', name: 'Login', component: () => import('./views/Login.vue'), meta: { guest: true } },
  { path: '/', name: 'Home', component: () => import('./views/Home.vue') },
  { path: '/knowledge', name: 'KnowledgeBase', component: () => import('./views/KnowledgeBase.vue') },
  { path: '/knowledge/:id', name: 'KnowledgeDetail', component: () => import('./views/KnowledgeDetail.vue') },
  { path: '/knowledge-manage', name: 'KnowledgeManage', component: () => import('./views/KnowledgeManage.vue'), meta: { admin: true } },
  { path: '/review', name: 'ReviewCenter', component: () => import('./views/ReviewCenter.vue'), meta: { admin: true } },
  { path: '/submit-experience', name: 'ExperienceSubmit', component: () => import('./views/ExperienceSubmit.vue'), meta: { staff: true } },
  { path: '/personal-dashboard', name: 'PersonalDashboard', component: () => import('./views/PersonalDashboard.vue'), meta: { staff: true } },
  { path: '/team-dashboard', name: 'TeamDashboard', component: () => import('./views/TeamDashboard.vue'), meta: { admin: true } },
  { path: '/bi-board', name: 'BIBoard', component: () => import('./views/BIBoard.vue'), meta: { boss: true } },
  { path: '/learning', name: 'LearningCenter', component: () => import('./views/LearningCenter.vue'), meta: { staff: true } },
  { path: '/question', name: 'QuestionAnswer', component: () => import('./views/QuestionAnswer.vue'), meta: { staff: true } },
  { path: '/exam-manage', name: 'ExamManage', component: () => import('./views/ExamManage.vue'), meta: { admin: true } },
  { path: '/profile', name: 'Profile', component: () => import('./views/Profile.vue') },
  { path: '/user-manage', name: 'UserManage', component: () => import('./views/UserManage.vue'), meta: { admin: true } },
  { path: '/llm-settings', name: 'LLMSettings', component: () => import('./views/LLMSettings.vue'), meta: { admin: true } },
  { path: '/system-settings', name: 'SystemSettings', component: () => import('./views/SystemSettings.vue'), meta: { admin: true } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to, _from, next) => {
  const auth = useAuthStore()

  // 登录页：已登录用户直接跳首页
  if (to.meta.guest) {
    if (auth.isLoggedIn) return next('/')
    return next()
  }

  // 其他页面：必须登录
  if (!auth.isLoggedIn) {
    return next('/login')
  }

  // 管理员页面
  if (to.meta.admin && !auth.isAdmin) {
    return next('/')
  }

  // 老板专属
  if (to.meta.boss && !auth.isBoss) {
    return next('/')
  }

  // 职员专属
  if (to.meta.staff && !auth.isStaff) {
    return next('/')
  }

  next()
})

export default router
