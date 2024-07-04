import { useQuery } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';
import { computed, shallowRef } from 'vue'

import { VersionableStaticWebsiteClient } from '../../../src/index.js';

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
    staleTime: 24 * 3600 * 1000,
  })
}

function useVersionableStaticWebsiteClient(websiteContractAddress) {
  // Fetch the viem connector client
  const { data: viemClient, isLoading, isSuccess, isError, error } = useConnectorClient()

  return {
    data: computed(() => {
      let websiteClient = null;
      if (isSuccess.value) {
        websiteClient = new VersionableStaticWebsiteClient(viemClient.value, websiteContractAddress)
      }
      return websiteClient
    }),
    isLoading,
    isSuccess,
    isError,
    error,
  }
}

function useLiveFrontendVersion(contractAddress, chainId) {
  const { data: websiteClient, isSucces: websiteClientIsSuccess} = useVersionableStaticWebsiteClient(contractAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['OCWebsiteLiveFrontend', contractAddress, chainId],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })
      
      const result = await websiteClient.value.getLiveFrontendVersion()

      return result
    },
    staleTime: 3600 * 1000,
    enabled: websiteClientIsSuccess,
  });
}

function invalidateLiveFrontendVersionQuery(queryClient, contractAddress, chainId) {
  return queryClient.invalidateQueries({ queryKey: ['OCWebsiteLiveFrontend', contractAddress, chainId] })
}


export { useContractAddresses, useVersionableStaticWebsiteClient, useLiveFrontendVersion, invalidateLiveFrontendVersionQuery }

