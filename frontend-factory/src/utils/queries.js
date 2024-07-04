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

function useLiveFrontendVersion(queryClient,contractAddress, chainId) {
  const { data: websiteClient, isSuccess: websiteClientLoaded} = useVersionableStaticWebsiteClient(contractAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['OCWebsiteLiveFrontend', contractAddress, chainId],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })
      
      const result = await websiteClient.value.getLiveFrontendVersion()

      // We got a frontend version, prefill the cache of the individual frontend version
      // await queryClient.prefetchQuery({
      //   queryKey: ['OCWebsiteFrontendVersion', contractAddress, chainId, result.frontendIndex],
      //   queryFn: () => { return result.frontendVersion },
      // })

      return result
    },
    staleTime: 3600 * 1000,
    enabled: websiteClientLoaded,
  });
}

function invalidateLiveFrontendVersionQuery(queryClient, contractAddress, chainId) {
  return queryClient.invalidateQueries({ queryKey: ['OCWebsiteLiveFrontend', contractAddress, chainId] })
}

function invalidateFrontendVersionQuery(queryClient, contractAddress, chainId, version) {
  return queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersion', contractAddress, chainId, version] })
}

function useFrontendVersions(queryClient, contractAddress, chainId, condition) {
  const { data: websiteClient, isSuccess: websiteClientLoaded} = useVersionableStaticWebsiteClient(contractAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['OCWebsiteFrontendVersions', contractAddress, chainId],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })
  
      const result = await websiteClient.value.getFrontendVersions(0, 0)
      return result;
    },
    staleTime: 3600 * 1000,
    enabled: computed(() => websiteClientLoaded.value && (condition ? condition.value : true)),
  });
}

function invalidateFrontendVersionsQuery(queryClient, contractAddress, chainId) {
  return queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersions', contractAddress, chainId] })
}

export { 
  useContractAddresses, 
  useVersionableStaticWebsiteClient, 
  useLiveFrontendVersion, invalidateLiveFrontendVersionQuery, 
  invalidateFrontendVersionQuery,
  useFrontendVersions, invalidateFrontendVersionsQuery}

