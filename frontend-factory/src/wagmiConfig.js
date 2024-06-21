import { http, createConfig } from '@wagmi/vue'
import { mainnet, sepolia, hardhat } from '@wagmi/vue/chains'
import { injected, coinbaseWallet } from '@wagmi/vue/connectors'

export const config = createConfig({
  chains: [mainnet, sepolia, hardhat],
  connectors: [
    injected(),
    coinbaseWallet({
      appName: 'OCWeb.eth',
    }),
  ],
  transports: {
    [mainnet.id]: http(),
    [sepolia.id]: http(),
    [hardhat.id]: http(),
  },
})