<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useSwitchChain, useAccount, useConnectorClient } from '@wagmi/vue'
import { getContract, publicActions } from 'viem'

import { useContractAddresses, invalidateFrontendVersionQuery, useFrontendVersionPlugins, invalidateFrontendVersionPluginsQuery, useSupportedPluginInterfaces, useIsLocked } from '../../../utils/queries';
import SettingsProxiedWebsites from './SettingsProxiedWebsites.vue';
import SettingsInjectedVariables from './SettingsInjectedVariables.vue';
import SettingsPlugin from './SettingsPlugin.vue';
import TrashIcon from '../../../icons/TrashIcon.vue';
import PlusLgIcon from '../../../icons/PlusLgIcon.vue';
import ExclamationTriangleIcon from '../../../icons/ExclamationTriangleIcon.vue';
import { abi as factoryABI } from '../../../../../src/abi/factoryABI.js';

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
const { data: frontendVersionPlugins, isLoading: frontendVersionPluginsLoading, isFetching: frontendVersionPluginsFetching, isError: frontendVersionPluginsIsError, error: frontendVersionPluginsError, isSuccess: frontendVersionPluginsLoaded } = useFrontendVersionPlugins(props.contractAddress, props.chainId, computed(() => props.frontendVersionIndex)) 

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
  if (frontendVersionPluginsLoaded.value == false || availablePluginsLoaded.value == false) {
    return []
  }

  const result = availablePlugins.value.filter(plugin => !frontendVersionPlugins.value.find(p => p.plugin === plugin.plugin))
  return result;
})

// Add item
const showForm = ref(false)
const additionAddress = ref('')
const { isPending: additionIsPending, isError: additionIsError, error: additionError, isSuccess: additionIsSuccess, mutate: additionMutate, reset: additionReset, variables: additionVariables } = useMutation({
  mutationFn: async (pluginAddress) => {

    // Prepare the transaction
    const transaction = await props.websiteClient.prepareAddPluginTransaction(props.frontendVersionIndex, pluginAddress);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    additionAddress.value = ''
    showForm.value = false

    return await invalidateFrontendVersionPluginsQuery(queryClient, props.contractAddress, props.chainId, props.frontendVersionIndex);
  }
})
const additionItem = async (pluginAddress) => {
  additionMutate(pluginAddress)
}

// Remove item
const { isPending: removeIsPending, isError: removeIsError, error: removeError, isSuccess: removeIsSuccess, mutate: removeMutate, reset: removeReset, variables: removeVariables } = useMutation({
  mutationFn: async (pluginAddress) => {

    // Prepare the transaction
    const transaction = await props.websiteClient.prepareRemovePluginTransaction(props.frontendVersionIndex, pluginAddress);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    return await invalidateFrontendVersionPluginsQuery(queryClient, props.contractAddress, props.chainId, props.frontendVersionIndex);
  }
})
const removeItem = async (pluginAddress) => {
  removeMutate(pluginAddress)
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

        <div v-if="frontendVersionPluginsIsError" class="text-danger text-90" style="text-align: center; padding: 1em;">
          Error loading the installed plugins: {{ frontendVersionPluginsError.shortMessage || frontendVersionPluginsError.message }}
        </div>
        <div v-else-if="frontendVersionPluginsLoaded && frontendVersionPlugins.length == 0" class="no-entries">
          No plugins installed
        </div>
        <div v-else-if="frontendVersionPluginsLoaded" class="plugins-info">
          <div v-for="pluginInfos in frontendVersionPlugins" :key="pluginInfos.plugin" class="plugin-info">
            
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
                Address: <small>{{ pluginInfos.plugin }}</small>
              </div>
              <div v-if="removeIsError && removeVariables == pluginInfos.plugin" class="mutation-error">
                Error removing the plugin: {{ removeError.shortMessage || removeError.message }} <a @click.stop.prevent="removeReset()">Hide</a>
              </div>
            </div>

            <div class="plugin-operations">
              <a @click.stop.prevent="removeItem(pluginInfos.plugin)" class="white" v-if="isLockedLoaded && isLocked == false && frontendVersion != null && frontendVersion.locked == false && removeIsPending == false">
                <TrashIcon />
              </a>
              <TrashIcon class="anim-pulse" v-if="removeIsPending && removeVariables == pluginInfos.plugin" />
            </div>

          </div>
        </div>

        <div class="operations" v-if="isLockedLoaded && isLocked == false && frontendVersion != null && frontendVersion.locked == false">
          <div class="op-add-new">

            <div class="button-area" @click="showForm = !showForm">
              <span class="button-text">
                <PlusLgIcon />
                Install custom plugin
              </span>
            </div>
            <div class="form-area" v-if="showForm">
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
        <div v-else-if="availablePluginsLoaded && frontendVersionPluginsLoaded && availablePluginsNotInstalled.length == 0" class="no-entries">
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
                Address: <small>{{ pluginInfos.plugin }}</small>
              </div>
              <div v-if="additionIsError && additionVariables == pluginInfos.plugin" class="mutation-error">
                Error adding the plugin: {{ additionError.shortMessage || additionError.message }} <a @click.stop.prevent="additionReset()">Hide</a>
              </div>
            </div>

            <div class="plugin-operations">
              <a @click.stop.prevent="additionItem(pluginInfos.plugin)" class="white" v-if="isLockedLoaded && isLocked == false && frontendVersion != null && frontendVersion.locked == false && additionIsPending == false">
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
}

.plugin-operations {
  flex: 0 0 min-content;
}

.mutation-error {
  color: var(--color-text-danger);
  font-size: 0.8em;
}

.mutation-error a {
  color: var(--color-text-danger);
  text-decoration: underline;
}


</style>