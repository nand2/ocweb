import { http, createConfig } from '@wagmi/vue'
import { mainnet, sepolia, holesky, hardhat, arbitrum, arbitrumNova, optimism, base } from '@wagmi/vue/chains'
import { injected, coinbaseWallet } from '@wagmi/vue/connectors'

export const config = createConfig({
  chains: [mainnet, sepolia, holesky, hardhat],
  connectors: [
    injected(),
    // coinbaseWallet({
    //   appName: 'OCWeb.eth',
    // }),
  ],
  // Storage: By default use localStorage, which is broken on EVM Browser
  storage: null,
  transports: {
    [mainnet.id]: http(),
    [sepolia.id]: http(),
    [holesky.id]: http(),
    [hardhat.id]: http(),
    [arbitrum.id]: http(),
    [arbitrumNova.id]: http(),
    [optimism.id]: http(),
    [base.id]: http(),
  },
})