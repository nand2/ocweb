<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useSwitchChain, useAccount } from '@wagmi/vue'

import { useContractAddresses, invalidateWebsiteVersionQuery, useWebsiteVersionPlugins } from '../../../utils/queries';
import ManagePlugins from './plugins/ManagePlugins.vue';

const props = defineProps({
  websiteVersion: {
    type: [Object, null],
    required: true
  },
  websiteVersionIndex: {
    type: Number,
    required: true,
  },
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
  websiteClient: {
    type: [Object, null],
    required: true,
  },
})

const { switchChainAsync } = useSwitchChain()


const { data: websiteVersionPlugins, isLoading: websiteVersionPluginsLoading, isFetching: websiteVersionPluginsFetching, isError: websiteVersionPluginsIsError, error: websiteVersionPluginsError, isSuccess: websiteVersionPluginsLoaded } = useWebsiteVersionPlugins(props.contractAddress, props.chainId, computed(() => props.websiteVersionIndex)) 

</script>

<template>
  <div>
    <div v-if="websiteVersionPluginsLoading" style="text-align: center; margin: 2em;">
      Loading plugin infos...
    </div>
    <div v-else-if="websiteVersionPluginsIsError">
      <div class="text-danger text-90" style="text-align: center; margin: 2em;">
        <span>Failed to load plugin infos: {{ websiteVersionPluginsError.shortMessage || websiteVersionPluginsError.message }}</span>
      </div>
    </div>
    <div v-else-if="websiteVersionPluginsLoaded" style="margin: 1em;">

      <ManagePlugins
        :websiteVersion
        :websiteVersionIndex
        :contractAddress
        :chainId
        :websiteClient />

    </div>
  </div>
</template>

<style scoped>


</style>