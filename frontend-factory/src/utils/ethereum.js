import { useQuery } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useChains } from '@wagmi/vue';
import { computed } from 'vue'
import { useContractAddresses } from './queries'

/*
 * Return the intersection of the chains configured on the wagmi library, and the chains
 * of the factories.
 */
function useSupportedChains() {
  const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()
  const chains = useChains()

  return useQuery({
    queryKey: ['supportedChains'],
    queryFn: async () => {
      await contractAddressesLoaded

      const supportedChains = []
      for (const factory of contractAddresses.value.factories) {
        for (const chain of chains.value) {
          if (factory.chainId === chain.id) {
            supportedChains.push(chain)
          }
        }
      }

      return supportedChains
    },
    enabled: contractAddressesLoaded,
  })
}

export { useSupportedChains }