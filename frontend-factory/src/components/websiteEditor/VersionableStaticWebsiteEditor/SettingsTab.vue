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
    <div v-else-if="frontendVersionPluginsLoaded" class="settings">

      <div v-for="pluginInfos in frontendVersionPlugins" :key="pluginInfos.plugin" class="settings-item">
        <SettingsPlugin
          :frontendVersion
          :frontendVersionIndex
          :contractAddress
          :chainId
          :websiteClient 
          :pluginInfos="pluginInfos" />
      </div>

      <div class="settings-item">

        <SettingsManagePlugins
          :frontendVersion
          :frontendVersionIndex
          :contractAddress
          :chainId
          :websiteClient />

      </div>

    </div>
  </div>
</template>

<style scoped>
.settings {
  display: flex;
  flex-direction: column;
}

.settings-item {
  padding: 1em;
}

.settings-item + .settings-item {
  border-top: 1px solid var(--color-divider-secondary);
}

.title {
  font-size: 1.1em;
  font-weight: bold;
  margin-bottom: 1em;
}


.operations {
  display: flex;
  gap: 1em;
  margin-top: 1em;
  align-items: flex-start;
}
@media (max-width: 700px) {
  .operations {
    flex-direction: column;
  }
}

.no-entries {
  padding: 1.5em;
  text-align: center;
  color: var(--color-text-muted);
}

</style>