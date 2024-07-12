<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useSwitchChain, useAccount } from '@wagmi/vue'

import { useContractAddresses, invalidateWebsiteVersionQuery, useWebsiteVersionPlugins } from '../../../utils/queries';
import SettingsProxiedWebsites from './plugins/SettingsPluginProxiedWebsites.vue';
import SettingsInjectedVariables from './plugins/SettingsPluginInjectedVariables.vue';
import SettingsPlugin from './plugins/SettingsPlugin.vue';
import SettingsManagePlugins from './plugins/ManagePlugins.vue';

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
    <div v-else-if="websiteVersionPluginsLoaded" class="settings">

      <div v-for="pluginInfos in websiteVersionPlugins" :key="pluginInfos.plugin" class="settings-item">
        <SettingsPlugin
          :websiteVersion
          :websiteVersionIndex
          :contractAddress
          :chainId
          :websiteClient 
          :pluginInfos="pluginInfos" />
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