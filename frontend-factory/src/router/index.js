import { createRouter, createWebHashHistory } from 'vue-router'
import MyWebsitesView from '../views/MyWebsitesView.vue'
import MintWebsiteView from '../views/MintWebsiteView.vue'
import PageNotFoundView from '../views/PageNotFoundView.vue'

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
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: PageNotFoundView
    }
  ]
})

export default router