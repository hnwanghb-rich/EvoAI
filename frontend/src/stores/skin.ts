import { defineStore } from 'pinia'
import { ref, watch } from 'vue'
import axios from 'axios'

export const SKINS = [
  { id: 1, name: '朱砂红', color: '#C0403B' },
  { id: 2, name: '琥珀金', color: '#B8860B' },
  { id: 3, name: '檀木棕', color: '#8B5E3C' },
  { id: 4, name: '汝窑青', color: '#6B8E7B' },
  { id: 5, name: '霁蓝釉', color: '#4A688B' },
  { id: 6, name: '水墨灰', color: '#6B7B8B' },
  { id: 7, name: '素白',   color: '#4A4A4A' },
  { id: 8, name: '墨韵黑', color: '#1A1A1A' },
]

export const useSkinStore = defineStore('skin', () => {
  const skinId = ref<number>(Number(localStorage.getItem('skin_id') || '1'))

  function applySkin(id: number) {
    skinId.value = id
    document.body.setAttribute('data-skin', String(id))
    localStorage.setItem('skin_id', String(id))
  }

  function saveToServer(token: string | null) {
    if (!token) return
    axios.put('/api/auth/skin', { skin_id: skinId.value }).catch(() => {})
  }

  // 初始化
  applySkin(skinId.value)

  return { skinId, SKINS, applySkin, saveToServer }
})
