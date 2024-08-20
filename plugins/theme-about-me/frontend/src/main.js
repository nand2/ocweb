import { createApp } from 'vue'
import { createRouter, createWebHashHistory } from 'vue-router'
import { QueryClient, VueQueryPlugin } from '@tanstack/vue-query'
import './style.css'
import App from './App.vue'
import MarkdownPage from './components/MarkdownPage.vue'


// Fetch the config of the theme, located at /themes/about-me/config.json
const themeConfig = await fetch('/themes/about-me/config.json')
const themeConfigJson = await themeConfig.json()

// Create the router, based on the config above
const routes = themeConfigJson.menu.map(page => {
  return {
    path: page.path,
    component: MarkdownPage,
    props: { page }
  }
})
const router = createRouter({
  history: createWebHashHistory(),
  routes: routes
})


// Create the vue app
const app = createApp(App)

// Tanstack Vue Query
const queryClient = new QueryClient()
app.use(VueQueryPlugin, { queryClient })
// Router
app.use(router)
// Inject theme config
app.provide('themeConfig', themeConfigJson)

app.mount('#app')

