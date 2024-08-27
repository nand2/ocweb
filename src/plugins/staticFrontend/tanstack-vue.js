import { useQuery } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';
import { computed, shallowRef } from 'vue'

import { StaticFrontendPluginClient } from './client.js';


function useStaticFrontendPluginClient(websiteContractAddress, pluginAddress) {
  // Fetch the viem connector client
  const { data: viemClient, isLoading, isSuccess, isError, error } = useConnectorClient()

  return {
    data: computed(() => {
      let client = null;
      if (isSuccess.value) {
        client = new StaticFrontendPluginClient(viemClient.value, websiteContractAddress, pluginAddress)
      }
      return client
    }),
    isLoading,
    isSuccess,
    isError,
    error,
  }
}

// websiteVersionIndex is reactive
function useStaticFrontend(queryClient, websiteContractAddress, chainId, pluginAddress, websiteVersionIndex) {
  const { data: pluginClient, isSuccess: pluginClientLoaded} = useStaticFrontendPluginClient(websiteContractAddress, pluginAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['StaticFrontendPluginStaticFrontend', websiteContractAddress, chainId, websiteVersionIndex],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })

      // Invalidate dependent query : sizes
      queryClient.invalidateQueries({ queryKey: ['StaticFrontendPluginStaticFrontendFileSizes', websiteContractAddress, chainId, websiteVersionIndex.value] })

      const result = await pluginClient.value.getStaticFrontend(websiteVersionIndex.value);
      return result;
    },
    staleTime: 3600 * 1000,
    enabled: computed(() => pluginClientLoaded.value != null && websiteVersionIndex.value >= 0),
  })
}

function invalidateStaticFrontendQuery(queryClient, websiteContractAddress, chainId, websiteVersionIndex) {
  return queryClient.invalidateQueries({ queryKey: ['StaticFrontendPluginStaticFrontend', websiteContractAddress, chainId, websiteVersionIndex] })
}

// fileInfos is reactive
// websiteVersionIndex is reactive
// Optional: condition (reactive)
function useStaticFrontendFileContent(websiteContractAddress, chainId, pluginAddress, websiteVersionIndex, fileInfos, condition) {
  const { data: pluginClient, isSuccess: pluginClientLoaded} = useStaticFrontendPluginClient(websiteContractAddress, pluginAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['StaticFrontendPluginFileContent', websiteContractAddress, chainId, websiteVersionIndex, computed(() => fileInfos.value?.filePath)],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })

      const result = await pluginClient.value.readFileFully(websiteVersionIndex.value, fileInfos.value, true);
      return result;
    },
    staleTime: 3600 * 1000,
    enabled: computed(() => pluginClientLoaded.value && fileInfos.value != null && (condition ? condition.value : true)),
  })
}

function invalidateStaticFrontendFileContentQuery(queryClient, websiteContractAddress, chainId, websiteVersionIndex, filePath) {
  return queryClient.invalidateQueries({ queryKey: ['StaticFrontendPluginFileContent', websiteContractAddress, chainId, websiteVersionIndex, filePath] })
}


function useStaticFrontendStorageBackends(websiteContractAddress, chainId, pluginAddress) {
  const { data: pluginClient, isSuccess: pluginClientLoaded} = useStaticFrontendPluginClient(websiteContractAddress, pluginAddress)
  const { switchChainAsync } = useSwitchChain()

  return useQuery({
    queryKey: ['StaticFrontendPluginStorageBackends', websiteContractAddress, chainId],
    queryFn: async () => {
      // Switch chain if necessary
      await switchChainAsync({ chainId: chainId })

      const result = await pluginClient.value.getStorageBackends();
      return result;
    },
    staleTime: 3600 * 1000,
    enabled: computed(() => pluginClientLoaded.value != null),
  })
}

export {
  useStaticFrontendPluginClient,
  useStaticFrontend, invalidateStaticFrontendQuery,
  useStaticFrontendFileContent, invalidateStaticFrontendFileContentQuery,
  useStaticFrontendStorageBackends
}