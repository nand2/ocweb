import { useQuery } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';
import { computed, shallowRef } from 'vue'

import { VersionableWebsiteClient } from './versionableWebsiteClient.js';

function useInjectedVariables() {
  return useQuery({
    queryKey: ['injectedVariables'],
    queryFn: async () => {
      const response = await fetch('./variables.json')
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
      if (isError.value) {
        throw error.value
      }
      
      // Factories on various chains are stored with the key "factory-<chainShortName>"
      const factories = []
      for (const [key, value] of Object.entries(injectedVariables.value)) {
        if (key.startsWith('factory-')) {
          const [address, chainId] = value.split(':')
          factories.push({address, chainId: parseInt(chainId), chainShortName: key.slice(8)})
        }
      }

      // Self: extract the self address and chainId
      const [selfAddress, selfChainId] = injectedVariables.value.self.split(':')

      const result = {
        self: {address: selfAddress, chainId: parseInt(selfChainId)},
        factories: factories,
      }

      return result
    },
    staleTime: 24 * 3600 * 1000,
    enabled: computed(() => isLoading.value == false)
  })
}

// When embedded (e.g. in the /admin/ page), access the address and chain id of the website
function useEmbeddorInjectedVariables() {
  return useQuery({
    queryKey: ['embeddorInjectedVariables'],
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
function useEmbeddorContractAddress() {
  const { data: injectedVariables, isLoading, isSuccess, isError, error } = useEmbeddorInjectedVariables()

  return useQuery({
    queryKey: ['embeddorContractAddress'],
    queryFn: async () => {
      if (isError.value) {
        throw error.value
      }

      // Self: extract the self address and chainId
      const [selfAddress, selfChainId] = injectedVariables.value.self.split(':')

      return {address: selfAddress, chainId: parseInt(selfChainId)}
    },
    staleTime: 24 * 3600 * 1000,
    enabled: computed(() => isLoading.value == false)
  })
}


function useVersionableWebsiteClient(websiteContractAddress) {
  // Fetch the viem connector client
  const { data: viemClient, isLoading, isSuccess, isError, error } = useConnectorClient()

  return {
    data: computed(() => {
      let websiteClient = null;
      if (isSuccess.value) {
        websiteClient = new VersionableWebsiteClient(viemClient.value, websiteContractAddress)
      }
      return websiteClient
    }),
    isLoading,
    isSuccess,
    isError,
    error,
  }
}

// FrontendIndex is a reactive value
function useWebsiteVersionPlugins(contractAddress, chainId, websiteVersionIndex) {
  const { data: websiteClient, isSuccess: websiteClientLoaded} = useVersionableWebsiteClient(contractAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['OCWebsiteVersionPlugins', contractAddress, chainId, websiteVersionIndex],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })

      const result = await websiteClient.value.getFrontendVersionPlugins(websiteVersionIndex.value)
      return result;
    },
    staleTime: 3600 * 1000,
    enabled: computed(() => websiteClientLoaded.value != null && websiteVersionIndex.value >= 0),
  })
}

function invalidateWebsiteVersionPluginsQuery(queryClient, contractAddress, chainId, websiteVersionIndex) {
  return queryClient.invalidateQueries({ queryKey: ['OCWebsiteVersionPlugins', contractAddress, chainId, websiteVersionIndex] })
}



function useLiveWebsiteVersion(queryClient,contractAddress, chainId) {
  const { data: websiteClient, isSuccess: websiteClientLoaded} = useVersionableWebsiteClient(contractAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['OCWebsiteLiveFrontend', contractAddress, chainId],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })
      
      const result = await websiteClient.value.getLiveWebsiteVersion()

      // We got a frontend version, prefill the cache of the individual frontend version
      await queryClient.prefetchQuery({
        queryKey: ['OCWebsiteVersion', contractAddress, chainId, result.websiteVersionIndex],
        queryFn: () => { return result.websiteVersion },
      })

      return result
    },
    staleTime: 3600 * 1000,
    enabled: websiteClientLoaded,
  });
}

function invalidateLiveWebsiteVersionQuery(queryClient, contractAddress, chainId) {
  return queryClient.invalidateQueries({ queryKey: ['OCWebsiteLiveFrontend', contractAddress, chainId] })
}

function invalidateWebsiteVersionQuery(queryClient, contractAddress, chainId, version) {
  return queryClient.invalidateQueries({ queryKey: ['OCWebsiteVersion', contractAddress, chainId, version] })
}

function useWebsiteVersions(queryClient, contractAddress, chainId, condition) {
  const { data: websiteClient, isSuccess: websiteClientLoaded} = useVersionableWebsiteClient(contractAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['OCWebsiteVersions', contractAddress, chainId],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })
  
      const result = await websiteClient.value.getWebsiteVersions(0, 0)
      return {
        versions: result[0],
        totalCount: Number(result[1]),
      };
    },
    staleTime: 3600 * 1000,
    enabled: computed(() => websiteClientLoaded.value && (condition ? condition.value : true)),
  });
}

function invalidateWebsiteVersionsQuery(queryClient, contractAddress, chainId) {
  return queryClient.invalidateQueries({ queryKey: ['OCWebsiteVersions', contractAddress, chainId] })
}

function useSupportedPluginInterfaces(contractAddress, chainId) {
  const { data: websiteClient, isSuccess: websiteClientLoaded} = useVersionableWebsiteClient(contractAddress)
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

function useIsLocked(contractAddress, chainId) {
  const { data: websiteClient, isSuccess: websiteClientLoaded} = useVersionableWebsiteClient(contractAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['OCWebsiteIsLocked', contractAddress, chainId],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })

      const result = await websiteClient.value.isLocked()
      return result;
    },
    staleTime: 3600 * 1000,
    enabled: websiteClientLoaded,
  })
}

function invalidateIsLockedQuery(queryClient, contractAddress, chainId) {
  return queryClient.invalidateQueries({ queryKey: ['OCWebsiteIsLocked', contractAddress, chainId] })
}






export { 
  useInjectedVariables,
  useContractAddresses, 
  useEmbeddorContractAddress,
  useVersionableWebsiteClient, 
  useLiveWebsiteVersion, invalidateLiveWebsiteVersionQuery, 
  invalidateWebsiteVersionQuery,
  useWebsiteVersions, invalidateWebsiteVersionsQuery,
  useWebsiteVersionPlugins, invalidateWebsiteVersionPluginsQuery,
  useSupportedPluginInterfaces,
  useIsLocked, invalidateIsLockedQuery
}

