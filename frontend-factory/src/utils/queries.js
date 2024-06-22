import { useQuery } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { computed } from 'vue'

// Fetch the contract addresses advertised by the website
// Group the factories together
function useContractAddresses() {
  return useQuery({
    queryKey: ['contractAddresses'],
    queryFn: async () => {
      const response = await fetch('/contractAddresses.json')
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      const decodedResponse = await response.json()

      // Factories on various chains are stored with the key "factory-<chainShortName>"
      const factories = []
      for (const [key, value] of Object.entries(decodedResponse)) {
        if (key.startsWith('factory-')) {
          factories.push({...value, chainShortName: key.slice(8)})
        }
      }

      const result = {
        self: decodedResponse.self,
        factories: factories,
      }

      return result
    },
    staleTime: 365 * 24 * 3600 * 1000,
  })
}


export { useContractAddresses }

