import { useQuery } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';
import { computed, shallowRef } from 'vue'

import { VersionableStaticWebsiteClient } from '../../../src/index.js';

function useInjectedVariables() {
  return useQuery({
    queryKey: ['injectedVariables'],
    queryFn: async () => {
      const response = await fetch('/variables.json')
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      const decodedResponse = await response.json()
      return decodedResponse
    },
    staleTime: 24 * 3600 * 1000,
  })
}

// Fetch the contract addresses advertised by the website
// Group the factories together
function useContractAddresses() {
  const { data: injectedVariables, isLoading, isSuccess, isError, error } = useInjectedVariables()

  return useQuery({
    queryKey: ['contractAddresses'],
    queryFn: async () => {

      // Factories on various chains are stored with the key "factory-<chainShortName>"
      const factories = []
      for (const [key, value] of Object.entries(injectedVariables.value)) {
        if (key.startsWith('factory-')) {
          const [address, chainId] = value.split(':')
          factories.push({address, chainId: parseInt(chainId), chainShortName: key.slice(8)})
        }
      }

      const result = {
        self: injectedVariables.self,
        factories: factories,
      }

      return result
    },
    staleTime: 24 * 3600 * 1000,
    enabled: isSuccess
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
      await queryClient.prefetchQuery({
        queryKey: ['OCWebsiteFrontendVersion', contractAddress, chainId, result.frontendIndex],
        queryFn: () => { return result.frontendVersion },
      })

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
      return {
        versions: result[0],
        totalCount: Number(result[1]),
      };
    },
    staleTime: 3600 * 1000,
    enabled: computed(() => websiteClientLoaded.value && (condition ? condition.value : true)),
  });
}

function invalidateFrontendVersionsQuery(queryClient, contractAddress, chainId) {
  return queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersions', contractAddress, chainId] })
}

// FrontendIndex is a computed value
function useFrontendVersionPlugins(contractAddress, chainId, frontendIndex) {
  const { data: websiteClient, isSuccess: websiteClientLoaded} = useVersionableStaticWebsiteClient(contractAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['OCWebsiteFrontendVersionPlugins', contractAddress, chainId, frontendIndex],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })

      const result = await websiteClient.value.getFrontendVersionPlugins(frontendIndex.value)
      return result;
    },
    staleTime: 3600 * 1000,
    enabled: computed(() => websiteClientLoaded.value != null && frontendIndex.value >= 0),
  })
}

function invalidateFrontendVersionPluginsQuery(queryClient, contractAddress, chainId, frontendIndex) {
  return queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersionPlugins', contractAddress, chainId, frontendIndex] })
}

function useFrontendVersionsViewer(contractAddress, chainId) {
  const { data: websiteClient, isSuccess: websiteClientLoaded} = useVersionableStaticWebsiteClient(contractAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['OCWebsiteFrontendVersionsViewer', contractAddress, chainId],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })

      const result = await websiteClient.value.getFrontendVersionsViewer()
      return result;
    },
    staleTime: 3600 * 1000,
    enabled: websiteClientLoaded,
  })
}

function invalidateFrontendVersionsViewerQuery(queryClient, contractAddress, chainId) {
  return queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersionsViewer', contractAddress, chainId] })
}

function useSupportedStorageBackendInterfaces(contractAddress, chainId) {
  const { data: websiteClient, isSuccess: websiteClientLoaded} = useVersionableStaticWebsiteClient(contractAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['OCWebsiteSupportedStorageBackendInterfaces', contractAddress, chainId],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })

      const result = await websiteClient.value.getSupportedStorageBackendInterfaces()
      return result;
    },
    staleTime: 3600 * 1000,
    enabled: websiteClientLoaded,
  })
}

function useSupportedPluginInterfaces(contractAddress, chainId) {
  const { data: websiteClient, isSuccess: websiteClientLoaded} = useVersionableStaticWebsiteClient(contractAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['OCWebsiteSupportedPluginInterfaces', contractAddress, chainId],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })

      const result = await websiteClient.value.getSupportedPluginInterfaces()
      return result;
    },
    staleTime: 3600 * 1000,
    enabled: websiteClientLoaded,
  })
}

export { 
  useInjectedVariables,
  useContractAddresses, 
  useVersionableStaticWebsiteClient, 
  useLiveFrontendVersion, invalidateLiveFrontendVersionQuery, 
  invalidateFrontendVersionQuery,
  useFrontendVersions, invalidateFrontendVersionsQuery,
  useFrontendVersionPlugins, invalidateFrontendVersionPluginsQuery,
  useFrontendVersionsViewer, invalidateFrontendVersionsViewerQuery,
  useSupportedStorageBackendInterfaces,
  useSupportedPluginInterfaces
}

