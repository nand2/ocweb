import { createRouter, createWebHashHistory } from 'vue-router'
import OCWebView from '../views/OCWebView.vue'
import MyWebsitesView from '../views/MyWebsitesView.vue'
import MintWebsiteView from '../views/MintWebsiteView.vue'
import PageNotFoundView from '../views/PageNotFoundView.vue'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: '/',
      name: 'home',
      component: OCWebView
    },
    {
      path: '/mint',
      name: 'mint',
      component: MintWebsiteView
    },
    {
      path: '/my-ocwebsites',
      name: 'my-ocwebsites',
      component: MyWebsitesView
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: PageNotFoundView
    }
  ]
})

export default router