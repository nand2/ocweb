import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import { WagmiPlugin } from '@wagmi/vue'
import { config as wagmiConfig } from './wagmiConfig'
import { QueryClient, VueQueryPlugin } from '@tanstack/vue-query'

const app = createApp(App)

// Wagmi
app.use(WagmiPlugin, { config: wagmiConfig })
// Tanstack Vue Query
const queryClient = new QueryClient()
app.use(VueQueryPlugin, { queryClient })

app.mount('#app')

