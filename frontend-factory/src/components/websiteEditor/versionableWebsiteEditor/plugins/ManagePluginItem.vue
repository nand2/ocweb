<script setup>
import { ref, computed, defineProps } from 'vue';
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
import ExclamationTriangleIcon from '../../../../icons/ExclamationTriangleIcon.vue';
import { abi as factoryABI } from '../../../../../../src/abi/factoryABI.js';
import ChevronDownIcon from '../../../../icons/ChevronDownIcon.vue';
import ChevronUpIcon from '../../../../icons/ChevronUpIcon.vue';
import ManagePluginItem from './ManagePluginItem.vue';

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
})


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
    <a @click.stop.prevent="additionItem(pluginInfos.plugin)" class="white" v-if="isLockedLoaded && isLocked == false && websiteVersion != null && websiteVersion.locked == false && isInstalled == false && additionIsPending == false">
      <PlusLgIcon />
    </a>
    <PlusLgIcon class="anim-pulse" v-if="additionIsPending && additionVariables == pluginInfos.plugin" />

    <a @click.stop.prevent="removeItem(pluginInfos.plugin)" class="white" v-if="isLockedLoaded && isLocked == false && websiteVersion != null && websiteVersion.locked == false && pluginHasInstalledDependents(pluginInfos.plugin) == false && isInstalled && removeIsPending == false">
      <TrashIcon />
    </a>
    <TrashIcon class="anim-pulse" v-if="removeIsPending && removeVariables == pluginInfos.plugin" />
  </div>
</template>

<style scoped>
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
</style>