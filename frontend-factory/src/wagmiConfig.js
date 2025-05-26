import { http, createConfig } from '@wagmi/vue'
import { mainnet, sepolia, holesky, hardhat, arbitrum, arbitrumNova, optimism, base } from '@wagmi/vue/chains'
import { injected, coinbaseWallet } from '@wagmi/vue/connectors'

export const config = createConfig({
  chains: [optimism, base, arbitrum, mainnet, sepolia, holesky, hardhat],
  connectors: [
    injected(),
    coinbaseWallet({
      appName: 'OCWeb.eth',
    }),
  ],
  // Storage: 
  // If protocol is "web3:", use no storage (localStorage+cookies are broken in EVM browser)
  // Otherwise use default localStorage storage
  storage: window.location.protocol === 'web3:' ? null : undefined,
  transports: {
    // Below RPCs are used, in the context of this website, for functions that :
    // 1/ Do not require a wallet connection (so cannot use the wallet RPC)
    // 2/ Is not provided by the web3:// protocol
    // So that includes: Balance fetching, making some transactions
    [mainnet.id]: http("https://ethereum-rpc.publicnode.com"), // Default (cloudflare) is having issues
    [sepolia.id]: http(),
    [holesky.id]: http(),
    [hardhat.id]: http(),
    [arbitrum.id]: http(),
    [optimism.id]: http(),
    [base.id]: http(),
  },
})