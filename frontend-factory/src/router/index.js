import { createRouter, createWebHashHistory } from 'vue-router'
import MyWebsitesView from '../views/MyWebsitesView.vue'
import MintWebsiteView from '../views/MintWebsiteView.vue'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: '/',
      name: 'home',
      component: MyWebsitesView
    },
    {
      path: '/mint',
      name: 'mint',
      component: MintWebsiteView
    }
  ]
})

export default router