<script setup>
import { ref, computed, defineProps, defineEmits } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useSwitchChain, useAccount, useConnectorClient } from '@wagmi/vue'
import { getContract, publicActions } from 'viem'

import { useContractAddresses, invalidateWebsiteVersionQuery, useWebsiteVersionPlugins, invalidateWebsiteVersionPluginsQuery, useSupportedPluginInterfaces, useIsLocked } from '../../../../../../src/tanstack-vue.js';
import SettingsProxiedWebsites from './SettingsPluginProxiedWebsites.vue';
import SettingsInjectedVariables from './SettingsPluginInjectedVariables.vue';
import SettingsPlugin from './SettingsPlugin.vue';
import { store } from '../../../../utils/store';
import TrashIcon from '../../../../icons/TrashIcon.vue';
import PlusLgIcon from '../../../../icons/PlusLgIcon.vue';
import XCircleIcon from '../../../../icons/XCircleIcon.vue';
import ExclamationTriangleIcon from '../../../../icons/ExclamationTriangleIcon.vue';
import { abi as factoryABI } from '../../../../../../src/abi/factoryABI.js';
import ChevronDownIcon from '../../../../icons/ChevronDownIcon.vue';
import ChevronUpIcon from '../../../../icons/ChevronUpIcon.vue';
import ManagePluginItem from './ManagePluginItem.vue';
import RemoteAsyncComponent from '../../../utils/RemoteAsyncComponent.vue';
import SettingsPluginProxiedWebsites from './SettingsPluginProxiedWebsites.vue';
import SettingsPluginInjectedVariables from './SettingsPluginInjectedVariables.vue';
import SettingsPluginStaticFrontend from './SettingsPluginStaticFrontend.vue';

const props = defineProps({
  websiteVersion: {
    type: Object,
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
    type: Object,
    required: true,
  },
  pluginInfos: {
    type: Object,
    required: true,
  },
  isInstalled: {
    type: Boolean,
    required: true,
  },
  websiteVersionPlugins: {
    type: Array,
    required: true,
  },
  availablePlugins: {
    type: Array,
    required: true,
  },
  hideConfigureButton: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['configPanelShown', 'configPanelHidden'])


const { switchChainAsync } = useSwitchChain()
const queryClient = useQueryClient()
const { data: viemClient, isSuccess: viemClientLoaded } = useConnectorClient()

// Get the lock status
const { data: isLocked, isLoading: isLockedLoading, isFetching: isLockedFetching, isError: isLockedIsError, error: isLockedError, isSuccess: isLockedLoaded } = useIsLocked(props.contractAddress, props.chainId)


// Get a plugin name from an address: Lookup in the available plugins, then in the installed plugins
const getPluginInfosFromAddress = (pluginAddress) => {
  const plugin = props.websiteVersionPlugins.find(p => p.plugin === pluginAddress) || props.availablePlugins.find(p => p.plugin === pluginAddress)
  return plugin?.infos;
}

// Has a plugin installed dependents?
const pluginHasInstalledDependents = (pluginAddress) => {
  return props.websiteVersionPlugins.find(p => p.infos.dependencies.includes(pluginAddress)) != null
}

// Get the installed ocWebAdmin plugin
const ocWebAdminInstalledPlugin = computed(() => {
  return props.websiteVersionPlugins.find(plugin => plugin.infos.name == 'ocWebAdmin')
})

// Get the secondary admin panels of the plugin
const pluginSecondaryAdminPanels = computed(() => {

  // Fetch all the panels (1+ per plugin)
  return props.pluginInfos.infos.adminPanels.map((panel, panelIndex) => {
    // Keep a link to the plugin
    return {
      panel: panel,
      panelIndex: panelIndex
    }
  })
    // Only the secondary panels
    .filter(panel => panel.panel.panelType == 1 /* Secondary */)
    // Either the panel is a module for ocWebAdmin, or it's not a module (will be iframed)
    .filter(panel => panel.panel.moduleForGlobalAdminPanel == null || panel.panel.moduleForGlobalAdminPanel == ocWebAdminInstalledPlugin.value.plugin)
})


// Has the plugin some hardcoded config?
const pluginHasHardcodedSettings = computed(() => {
  if(store.devMode == false) {
    return false;
  }
  return ['proxiedWebsites', 'injectedVariables', 'staticFrontend'].includes(props.pluginInfos.infos.name)
})


const showSecondaryConfigPanels = ref(false)
const setShowSecondatyConfigPanels = (value) => {
  showSecondaryConfigPanels.value = value
  emit(value ? 'configPanelShown' : 'configPanelHidden')
}


// Add item
const { isPending: additionIsPending, isError: additionIsError, error: additionError, isSuccess: additionIsSuccess, mutate: additionMutate, reset: additionReset, variables: additionVariables } = useMutation({
  mutationFn: async (pluginAddress) => {

    // Prepare the transaction
    const transaction = await props.websiteClient.prepareAddPluginTransaction(props.websiteVersionIndex, pluginAddress, props.websiteVersionPlugins.length);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    return await invalidateWebsiteVersionPluginsQuery(queryClient, props.contractAddress, props.chainId, props.websiteVersionIndex);
  }
})
const additionItem = async (pluginAddress) => {
  additionMutate(pluginAddress)
}

// Remove item
const { isPending: removeIsPending, isError: removeIsError, error: removeError, isSuccess: removeIsSuccess, mutate: removeMutate, reset: removeReset, variables: removeVariables } = useMutation({
  mutationFn: async (pluginAddress) => {

    // Prepare the transaction
    const transaction = await props.websiteClient.prepareRemovePluginTransaction(props.websiteVersionIndex, pluginAddress);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    return await invalidateWebsiteVersionPluginsQuery(queryClient, props.contractAddress, props.chainId, props.websiteVersionIndex);
  }
})
const removeItem = async (pluginAddress) => {
  removeMutate(pluginAddress)
}

</script>

<template>
  <div class="plugin-infos">
    <div class="plugin-description">
      <div class="plugin-description-title">
        {{ pluginInfos.infos.title }} <small>{{ pluginInfos.infos.version }}</small>
      </div>
      <div class="plugin-description-others">
        {{ pluginInfos.infos.subTitle }}
      </div>
      <div class="plugin-description-others">
        Author: {{ pluginInfos.infos.author }}
        <span v-if="pluginInfos.infos.homepage">
          • <a v-if="pluginInfos.infos.homepage" :href="pluginInfos.infos.homepage" target="_blank">
            Homepage
          </a>
        </span>
      </div>
      <div class="plugin-description-others">
        Dependencies: 
          <span v-if="pluginInfos.infos.dependencies.length == 0" class="text-muted">
            None
          </span>
          <span v-for="(dep, depIndex) in pluginInfos.infos.dependencies">
            {{ getPluginInfosFromAddress(dep) ? getPluginInfosFromAddress(dep).title + ' ' + getPluginInfosFromAddress(dep).version : dep }}<span v-if="depIndex < pluginInfos.infos.dependencies.length - 1">, </span>
          </span>
      </div>
      <div class="plugin-description-others" v-if="store.devMode">
        Address: <small>{{ pluginInfos.plugin }}</small>
      </div>

      <div v-if="additionIsError && additionVariables == pluginInfos.plugin" class="mutation-error">
        Error adding the plugin: {{ additionError.shortMessage || additionError.message }} <a @click.stop.prevent="additionReset()">Hide</a>
      </div>

      <div v-if="removeIsError && removeVariables == pluginInfos.plugin" class="mutation-error">
        Error removing the plugin: {{ removeError.shortMessage || removeError.message }} <a @click.stop.prevent="removeReset()">Hide</a>
      </div>
    </div>

    <div class="plugin-operations">
      <a @click.stop.prevent="additionItem(pluginInfos.plugin)" class="white" v-if="isLockedLoaded && isLocked == false && websiteVersion != null && websiteVersion.locked == false && isInstalled == false && showSecondaryConfigPanels == false && additionIsPending == false">
        <PlusLgIcon />
      </a>
      <PlusLgIcon class="anim-pulse" v-if="additionIsPending && additionVariables == pluginInfos.plugin" />

      <a @click.stop.prevent="removeItem(pluginInfos.plugin)" class="white" v-if="isLockedLoaded && isLocked == false && websiteVersion != null && websiteVersion.locked == false && pluginHasInstalledDependents(pluginInfos.plugin) == false && isInstalled && showSecondaryConfigPanels == false && removeIsPending == false">
        <TrashIcon />
      </a>
      <TrashIcon class="anim-pulse" v-if="removeIsPending && removeVariables == pluginInfos.plugin" />
    </div>
  </div>

  <div v-if="isInstalled && (pluginSecondaryAdminPanels.length > 0 || pluginHasHardcodedSettings)" style="margin-top: 0.5em;">

    <div v-if="showSecondaryConfigPanels" class="config-panels">
      
      <div v-for="panel in pluginSecondaryAdminPanels"  class="config-panel">
        <!-- <div>
          {{ panel.panel.title }}
        </div> -->

        <!-- Plugin mode -->
        <RemoteAsyncComponent
          v-if="panel.panel.moduleForGlobalAdminPanel" 
          
          :umdModuleUrl="panel.panel.url.startsWith('web3://') ? panel.panel.url : 'web3://' + contractAddress + ':' + chainId + panel.panel.url"
          :moduleName="pluginInfos.infos.name + 'AdminPanels.Panel' + panel.panelIndex"
          :cssUrl="(panel.panel.url.startsWith('web3://') ? panel.panel.url : 'web3://' + contractAddress + ':' + chainId + panel.panel.url).replace('.umd.js', '.css')"

          :contractAddress 
          :chainId 
          :websiteVersion
          :websiteVersionIndex
          :websiteClient
          :pluginsInfos="websiteVersionPlugins"
          :pluginInfos="pluginInfos"
          />

        <!-- Iframe mode -->
        <iframe
          v-else
          :src="panel.panel.url.startsWith('web3://') ? panel.panel.url : 'web3://' + contractAddress + ':' + chainId + panel.panel.url"
          style="width: 100%; height: 400px; border: none;"
          ></iframe>
      </div>

      <div v-if="pluginHasHardcodedSettings" style="margin-top: 0.75em;">
        <SettingsPluginProxiedWebsites 
          v-if="pluginInfos.infos.name == 'proxiedWebsites'"
          :websiteVersion
          :websiteVersionIndex
          :contractAddress
          :chainId
          :websiteClient
          :pluginInfos />

        <SettingsPluginInjectedVariables
          v-else-if="pluginInfos.infos.name == 'injectedVariables'"
          :websiteVersion
          :websiteVersionIndex
          :contractAddress
          :chainId
          :websiteClient
          :pluginInfos />
        
        <SettingsPluginStaticFrontend
          v-else-if="pluginInfos.infos.name == 'staticFrontend'"
          :websiteVersion
          :websiteVersionIndex
          :contractAddress
          :chainId
          :websiteClient
          :pluginInfos />
      </div>
    </div>

    <div style="text-align: center;" v-if="hideConfigureButton == false">
      <button @click="setShowSecondatyConfigPanels(!showSecondaryConfigPanels)" class="sm">
        <span v-if="showSecondaryConfigPanels == false">Configure</span>
        <span v-else style="display: flex; gap: 0.5em;">
          <XCircleIcon /> Close configuration
        </span>
      </button>
    </div>

  </div>
</template>

<style scoped>
.plugin-infos {
  font-size: 0.9em;
  display: flex;
  align-items: center;
}

.plugin-description {
  flex: 1;
}

.plugin-description-title {
  font-weight: bold;
}

.plugin-description-others {
  font-size: 0.9em; 
  color: #ccc;
  word-break: break-all;
}

.plugin-operations {
  flex: 0 0 min-content;
}

.mutation-error {
  padding: 0em;
  font-size: 0.8em;
}

.config-panels {
  margin-top: 1em;
  margin-bottom: 1em;
}

.config-panel {
  padding-top: 1em;
  margin-top: 1em;
  border-top: 1px solid var(--color-divider-secondary);
}
</style>