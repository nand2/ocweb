<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useSwitchChain, useAccount } from '@wagmi/vue'

import { useContractAddresses, invalidateFrontendVersionQuery, useFrontendVersionPlugins } from '../../../utils/queries';
import SettingsProxiedWebsites from './SettingsProxiedWebsites.vue';
import SettingsInjectedVariables from './SettingsInjectedVariables.vue';
import SettingsPlugin from './SettingsPlugin.vue';
import SettingsManagePlugins from './SettingsManagePlugins.vue';

const props = defineProps({
  frontendVersion: {
    type: [Object, null],
    required: true
  },
  frontendVersionIndex: {
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


const { data: frontendVersionPlugins, isLoading: frontendVersionPluginsLoading, isFetching: frontendVersionPluginsFetching, isError: frontendVersionPluginsIsError, error: frontendVersionPluginsError, isSuccess: frontendVersionPluginsLoaded } = useFrontendVersionPlugins(props.contractAddress, props.chainId, computed(() => props.frontendVersionIndex)) 

</script>

<template>
  <div>
    <div v-if="frontendVersionPluginsLoading" style="text-align: center; margin: 2em;">
      Loading plugin infos...
    </div>
    <div v-else-if="frontendVersionPluginsIsError">
      <div class="text-danger text-90" style="text-align: center; margin: 2em;">
        <span>Failed to load plugin infos: {{ frontendVersionPluginsError.shortMessage || frontendVersionPluginsError.message }}</span>
      </div>
    </div>
    <div v-else-if="frontendVersionPluginsLoaded" style="margin: 1em;">

      <SettingsManagePlugins
        :frontendVersion
        :frontendVersionIndex
        :contractAddress
        :chainId
        :websiteClient />

    </div>
  </div>
</template>

<style scoped>


</style>