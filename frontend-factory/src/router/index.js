import { createRouter, createWebHashHistory } from 'vue-router'
import OCWebView from '../views/HomepageView.vue'
import MyWebsitesView from '../views/MyOCWebsitesView.vue'
import MintWebsiteView from '../views/MintOCWebsiteView.vue'
import PageNotFoundView from '../views/PageNotFoundView.vue'
import FeaturedOCWebsitesView from '../views/FeaturedOCWebsitesView.vue'

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
      path: '/featured-ocwebsites',
      name: 'featured-ocwebsites',
      component: FeaturedOCWebsitesView
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: PageNotFoundView
    }
  ]
})

export default router