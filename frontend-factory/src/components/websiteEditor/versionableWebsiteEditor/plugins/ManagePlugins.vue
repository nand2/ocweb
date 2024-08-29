<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useSwitchChain, useAccount, useConnectorClient } from '@wagmi/vue'
import { getContract, publicActions } from 'viem'

import { useContractAddresses, invalidateWebsiteVersionQuery, useWebsiteVersionPlugins, invalidateWebsiteVersionPluginsQuery, useSupportedPluginInterfaces, useIsLocked } from '../../../../../../src/tanstack-vue.js';
import SettingsProxiedWebsites from './SettingsPluginProxiedWebsites.vue';
import SettingsInjectedVariables from './SettingsPluginInjectedVariables.vue';
import SettingsPlugin from './SettingsPlugin.vue';
import TrashIcon from '../../../../icons/TrashIcon.vue';
import PlusLgIcon from '../../../../icons/PlusLgIcon.vue';
import ExclamationTriangleIcon from '../../../../icons/ExclamationTriangleIcon.vue';
import { abi as factoryABI } from '../../../../../../src/abi/factoryABI.js';
import ChevronDownIcon from '../../../../icons/ChevronDownIcon.vue';
import ChevronUpIcon from '../../../../icons/ChevronUpIcon.vue';

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
})

const { switchChainAsync } = useSwitchChain()
const queryClient = useQueryClient()
const { data: viemClient, isSuccess: viemClientLoaded } = useConnectorClient()

// Get the lock status
const { data: isLocked, isLoading: isLockedLoading, isFetching: isLockedFetching, isError: isLockedIsError, error: isLockedError, isSuccess: isLockedLoaded } = useIsLocked(props.contractAddress, props.chainId)

// Prepare a contract client for the factory
const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()
const factoryContractClient = computed(() => {
  if(viemClientLoaded.value == false || contractAddressesLoaded.valuye == false) {
    return null;
  }

  const factoryAddress = contractAddresses.value.factories.find(f => f.chainId === props.chainId)?.address

  return getContract({
    address: factoryAddress,
    abi: factoryABI,
    client: viemClient.value,
  })
})

// Get the list of installed plugins
const { data: websiteVersionPlugins, isLoading: websiteVersionPluginsLoading, isFetching: websiteVersionPluginsFetching, isError: websiteVersionPluginsIsError, error: websiteVersionPluginsError, isSuccess: websiteVersionPluginsLoaded } = useWebsiteVersionPlugins(props.contractAddress, props.chainId, computed(() => props.websiteVersionIndex)) 

// Fetch the list of supported plugin interfaces
const { data: supportedPluginInterfaces, isLoading: supportedPluginInterfacesLoading, isFetching: supportedPluginInterfacesFetching, isError: supportedPluginInterfacesIsError, error: supportedPluginInterfacesError, isSuccess: supportedPluginInterfacesLoaded } = useSupportedPluginInterfaces(props.contractAddress, props.chainId)

// Fetch the list of available plugins from the factory
const { data: availablePlugins, isLoading: availablePluginsLoading, isFetching: availablePluginsFetching, isError: availablePluginsIsError, error: availablePluginsError, isSuccess: availablePluginsLoaded } = useQuery({
  queryKey: ['availablePlugins', props.contractAddress, props.chainId],
  queryFn: async () => {
    let result = await factoryContractClient.value.read.getWebsitePlugins([supportedPluginInterfaces.value]);
    // Filter out the ones with interfaceValid == false
    result = result.filter(backend => backend.interfaceValid)
    return result
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => factoryContractClient.value != null && supportedPluginInterfacesLoaded.value),
})

// Compute the list of availabe plugins not yet installed
const availablePluginsNotInstalled = computed(() => {
  if (websiteVersionPluginsLoaded.value == false || availablePluginsLoaded.value == false) {
    return []
  }

  const result = availablePlugins.value.filter(plugin => !websiteVersionPlugins.value.find(p => p.plugin === plugin.plugin))
  return result;
})

// Get a plugin name from an address: Lookup in the available plugins, then in the installed plugins
const getPluginInfosFromAddress = (pluginAddress) => {
  if(websiteVersionPluginsLoaded.value == false || availablePluginsLoaded.value == false) {
    return '';
  }

  const plugin = websiteVersionPlugins.value.find(p => p.plugin === pluginAddress) || availablePlugins.value.find(p => p.plugin === pluginAddress)
  return plugin?.infos;
}

// Has a plugin installed dependents?
const pluginHasInstalledDependents = (pluginAddress) => {
  if(websiteVersionPluginsLoaded.value == false) {
    return false;
  }

  return websiteVersionPlugins.value.find(p => p.infos.dependencies.includes(pluginAddress)) != null
}


// Add item
const showAdditionForm = ref(false)
const additionAddress = ref('')
const { isPending: additionIsPending, isError: additionIsError, error: additionError, isSuccess: additionIsSuccess, mutate: additionMutate, reset: additionReset, variables: additionVariables } = useMutation({
  mutationFn: async (pluginAddress) => {

    // Prepare the transaction
    const transaction = await props.websiteClient.prepareAddPluginTransaction(props.websiteVersionIndex, pluginAddress, websiteVersionPlugins.value.length);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    additionAddress.value = ''
    showAdditionForm.value = false

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

// Reorder item
const showReorderForm = ref(false)
const reorderedPluginIndex = ref(-1)
const reorderedPluginNewPosition = ref(-1)
const reorderedWebsiteVersionPlugins = computed(() => {
  if (websiteVersionPluginsLoaded.value == false) {
    return []
  }

  // Clone the array
  const result = websiteVersionPlugins.value.slice()
  // Reorder the array
  if(reorderedPluginIndex.value != -1 && reorderedPluginNewPosition.value != -1) {
    const plugin = result.splice(reorderedPluginIndex.value, 1)[0]
    result.splice(reorderedPluginNewPosition.value, 0, plugin)
  }

  return result
})
const reorderPlugin = (pluginIndex, direction) => {
  // If reorderedPluginIndex was not set, initialize it
  if(reorderedPluginIndex.value == -1) {
    reorderedPluginIndex.value = pluginIndex
    reorderedPluginNewPosition.value = pluginIndex + direction
    return
  }

  reorderedPluginNewPosition.value = reorderedPluginNewPosition.value + direction

  // If we are back to the original position, reset the reorder
  if(reorderedPluginIndex.value == reorderedPluginNewPosition.value) {
    reorderedPluginIndex.value = -1
    reorderedPluginNewPosition.value = -1
  }
}
const { isPending: reorderIsPending, isError: reorderIsError, error: reorderError, isSuccess: reorderIsSuccess, mutate: reorderMutate, reset: reorderReset, variables: reorderVariables } = useMutation({
  mutationFn: async () => {

    // Prepare the transaction
    const transaction = await props.websiteClient.prepareReorderPluginTransaction(props.websiteVersionIndex, websiteVersionPlugins.value[reorderedPluginIndex.value].plugin, reorderedPluginNewPosition.value);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    reorderedPluginIndex.value = -1
    reorderedPluginNewPosition.value = -1
    showReorderForm.value = false

    return await invalidateWebsiteVersionPluginsQuery(queryClient, props.contractAddress, props.chainId, props.websiteVersionIndex);
  }
})
const reorderItem = async () => {
  reorderMutate()
}

</script>

<template>
  <div>

    <!-- <div class="title">
      Manage plugins
    </div> -->

    <div class="plugins-lists">
      <div class="plugins-list">
        <div class="title2">
          Installed plugins
        </div>

        <div v-if="websiteVersionPluginsIsError" class="text-danger text-90" style="text-align: center; padding: 1em;">
          Error loading the installed plugins: {{ websiteVersionPluginsError.shortMessage || websiteVersionPluginsError.message }}
        </div>
        <div v-else-if="websiteVersionPluginsLoaded && websiteVersionPlugins.length == 0" class="no-entries">
          No plugins installed
        </div>
        <div v-else-if="websiteVersionPluginsLoaded" class="plugins-info">
          <div v-for="pluginInfos in websiteVersionPlugins" :key="pluginInfos.plugin" class="plugin-info">
            
            <div class="plugin-description">
              <div class="plugin-description-title">
                {{ pluginInfos.infos.title }} <small>{{ pluginInfos.infos.version }}</small>
              </div>
              <div class="plugin-description-others">
                {{ pluginInfos.infos.subTitle }}
              </div>
              <div class="plugin-description-others">
                Author: {{ pluginInfos.infos.author }}
              </div>
              <div class="plugin-description-others">
                Homepage: 
                  <a v-if="pluginInfos.infos.homepage" :href="pluginInfos.infos.homepage" target="_blank">
                    {{ pluginInfos.infos.homepage }}
                  </a>
                  <span v-else class="text-muted">
                    Not provided
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
              <div class="plugin-description-others">
                Address: <small>{{ pluginInfos.plugin }}</small>
              </div>
              <div v-if="removeIsError && removeVariables == pluginInfos.plugin" class="mutation-error">
                Error removing the plugin: {{ removeError.shortMessage || removeError.message }} <a @click.stop.prevent="removeReset()">Hide</a>
              </div>
            </div>

            <div class="plugin-operations">
              <a @click.stop.prevent="removeItem(pluginInfos.plugin)" class="white" v-if="isLockedLoaded && isLocked == false && websiteVersion != null && websiteVersion.locked == false && pluginHasInstalledDependents(pluginInfos.plugin) == false && removeIsPending == false">
                <TrashIcon />
              </a>
              <TrashIcon class="anim-pulse" v-if="removeIsPending && removeVariables == pluginInfos.plugin" />
            </div>

          </div>
        </div>

        <div class="operations" v-if="isLockedLoaded && isLocked == false && websiteVersion != null && websiteVersion.locked == false">
          <div class="op-reorder">

            <div class="button-area" @click="showReorderForm = !showReorderForm">
              <span class="button-text">
                <ChevronDownIcon />
                <ChevronUpIcon />
                Reorder plugins
              </span>
            </div>
            <div class="form-area" v-if="showReorderForm">
              <div class="text-90">
                The plugins are executed in the order they are listed.
              </div>

              <div v-if="websiteVersionPluginsLoaded" class="plugins-info">
                <div v-for="(pluginInfos, pluginIndex) in reorderedWebsiteVersionPlugins" :key="pluginInfos.plugin" class="plugin-info" style="display: flex; gap: 0.5em;">
                  <a @click.stop.prevent="reorderPlugin(pluginIndex, 1)" class="white" :style="{visibility: pluginIndex < websiteVersionPlugins.length - 1 && (reorderedPluginNewPosition == -1 || reorderedPluginNewPosition == pluginIndex) ? 'visible' : 'hidden'}">
                    <ChevronDownIcon />
                  </a>
                  <a @click.stop.prevent="reorderPlugin(pluginIndex, -1)" class="white" :style="{visibility: pluginIndex > 0 && (reorderedPluginNewPosition == -1 || reorderedPluginNewPosition == pluginIndex) ? 'visible' : 'hidden'}">
                    <ChevronUpIcon />
                  </a>
                  <span :style="{'font-weight': reorderedPluginNewPosition == pluginIndex ? 'bold' : 'normal'}">
                    {{ pluginInfos.infos.title }}
                  </span>
                </div>
              </div>
              
              <button v-if="reorderedPluginIndex >= 0" @click="reorderItem()" :disabled="reorderIsPending">
                Reorder the <strong>{{ websiteVersionPlugins[reorderedPluginIndex].infos.title }}</strong> plugin
              </button>

              <div v-if="reorderIsError" class="text-danger text-90">
                Error reordering plugin: {{ reorderError.shortMessage || reorderError.message }}
                <a @click.stop.prevent="reorderReset()" style="color: inherit; text-decoration: underline;">Hide</a>
              </div>
            </div>

          </div>
          <div class="op-add-new">

            <div class="button-area" @click="showAdditionForm = !showAdditionForm">
              <span class="button-text">
                <PlusLgIcon />
                Install custom plugin
              </span>
            </div>
            <div class="form-area" v-if="showAdditionForm">
              <div class="text-warning text-90">
                <ExclamationTriangleIcon />
                The plugin must implement one of the following interfaces: 
                <code v-for="itf in supportedPluginInterfaces"> {{ itf }} </code>
              </div>

              <input type="text" v-model="additionAddress" placeholder="Plugin address" />

              <button @click="additionItem(additionAddress)" :disabled="additionAddress == '' || additionIsPending">Install custom plugin</button>

              <div v-if="additionIsError && additionVariables == additionAddress" class="text-danger text-90">
                Error adding the custom plugin: {{ additionError.shortMessage || additionError.message }}
                <a @click.stop.prevent="additionReset()" style="color: inherit; text-decoration: underline;">Hide</a>
              </div>
            </div>

          </div>
        </div>

      </div>
      <div class="plugins-list">
        <div class="title2">
          Available plugins
        </div>

        <div v-if="availablePluginsIsError" class="text-danger text-90" style="text-align: center; padding: 1em;">
          Error loading the available plugins: {{ availablePluginsError.shortMessage || availablePluginsError.message }}
        </div>
        <div v-else-if="availablePluginsLoaded && websiteVersionPluginsLoaded && availablePluginsNotInstalled.length == 0" class="no-entries">
          No plugins available
        </div>
        <div v-else-if="availablePluginsNotInstalled.length > 0" class="plugins-info">
          <div v-for="pluginInfos in availablePluginsNotInstalled" :key="pluginInfos.plugin" class="plugin-info">
            
            <div class="plugin-description">
              <div class="plugin-description-title">
                {{ pluginInfos.infos.title }} <small>{{ pluginInfos.infos.version }}</small>
              </div>
              <div class="plugin-description-others">
                {{ pluginInfos.infos.subTitle }}
              </div>
              <div class="plugin-description-others">
                Author: {{ pluginInfos.infos.author }}
              </div>
              <div class="plugin-description-others">
                Homepage: 
                  <a v-if="pluginInfos.infos.homepage" :href="pluginInfos.infos.homepage" target="_blank">
                    {{ pluginInfos.infos.homepage }}
                  </a>
                  <span v-else class="text-muted">
                    Not provided
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
              <div class="plugin-description-others">
                Address: <small>{{ pluginInfos.plugin }}</small>
              </div>
              <div v-if="additionIsError && additionVariables == pluginInfos.plugin" class="mutation-error">
                Error adding the plugin: {{ additionError.shortMessage || additionError.message }} <a @click.stop.prevent="additionReset()">Hide</a>
              </div>
            </div>

            <div class="plugin-operations">
              <a @click.stop.prevent="additionItem(pluginInfos.plugin)" class="white" v-if="isLockedLoaded && isLocked == false && websiteVersion != null && websiteVersion.locked == false && additionIsPending == false">
                <PlusLgIcon />
              </a>
              <PlusLgIcon class="anim-pulse" v-if="additionIsPending && additionVariables == pluginInfos.plugin" />
            </div>

          </div>
        </div>

      </div>
    </div>
  </div>

</template>

<style scoped>


.title {
  font-size: 1.1em;
  font-weight: bold;
  margin-bottom: 1em;
}


.no-entries {
  padding: 1.5em;
  text-align: center;
  color: var(--color-text-muted);
}

.plugins-lists {
  display: flex;
  gap: 1em;
}
@media (max-width: 700px) {
  .plugins-lists {
    flex-direction: column;
  }
}

.plugins-list {
  flex: 1;
}

.title2 {
  font-weight: bold;
  margin-bottom: 0.7em;
}

.plugins-info {
  border: 1px solid var(--color-divider-secondary);
}

.plugin-info {
  font-size: 0.9em;
  padding: 0.75em 1em;
  display: flex;
  align-items: center;
}

.plugin-info + .plugin-info {
  border-top: 1px solid var(--color-divider-secondary);
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

.operations {
  flex-direction: column;
}

</style>