<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';

import { useContractAddresses, invalidateWebsiteVersionQuery, useIsLocked } from '../../../../utils/queries.js';
import { useStaticFrontendPluginClient, useStaticFrontend, useStaticFrontendStorageBackends, invalidateStaticFrontendQuery } from '../../../../utils/pluginStaticFrontendQueries.js';
import { InjectedVariablesPluginClient } from '../../../../../../src/plugins/injectedVariablesPluginClient.js';
import PlusLgIcon from '../../../../icons/PlusLgIcon.vue';
import ArrowRightIcon from '../../../../icons/ArrowRightIcon.vue';
import TrashIcon from '../../../../icons/TrashIcon.vue';
import PencilSquareIcon from '../../../../icons/PencilSquareIcon.vue';

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
  pluginInfos: {
    type: Object,
    required: true,
  },
})

const queryClient = useQueryClient()
const { data: viemClient, isSuccess: viemClientLoaded } = useConnectorClient()

const injectedVariablesPluginClient = computed(() => {
  return viemClientLoaded.value ? new InjectedVariablesPluginClient(viemClient.value, props.contractAddress, props.pluginInfos.plugin) : null;
})

// Get the lock status
const { data: isLocked, isLoading: isLockedLoading, isFetching: isLockedFetching, isError: isLockedIsError, error: isLockedError, isSuccess: isLockedLoaded } = useIsLocked(props.contractAddress, props.chainId)

// Ge the staticFrontendPluginClient
const { data: staticFrontendPluginClient, isLoading: staticFrontendPluginClientLoading, isFetching: staticFrontendPluginClientFetching, isError: staticFrontendPluginClientIsError, error: staticFrontendPluginClientError, isSuccess: staticFrontendPluginClientLoaded } = useStaticFrontendPluginClient(props.contractAddress, props.pluginInfos.plugin)

// Fetch the static frontend
const { data: staticFrontend, isLoading: staticFrontendLoading, isFetching: staticFrontendFetching, isError: staticFrontendIsError, error: staticFrontendError, isSuccess: staticFrontendLoaded } = useStaticFrontend(queryClient, props.contractAddress, props.chainId, props.pluginInfos.plugin, computed(() => props.websiteVersionIndex))

// Fetch the storage backend plugins
const { data: storageBackendsData, isLoading: storageBackendsLoading, isFetching: storageBackendsFetching, isError: storageBackendsIsError, error: storageBackendsError, isSuccess: storageBackendsLoaded } = useStaticFrontendStorageBackends(props.contractAddress, props.chainId, props.pluginInfos.plugin);

// Determine the storage backend used
const usedStorageBackend = computed(() => {
  if (staticFrontendLoaded.value && storageBackendsLoaded.value) {
    // If the storage backend is not set, the first available one will be used
    let storageBackend;
    if(staticFrontend.value.storageBackend == "0x0000000000000000000000000000000000000000") {
      storageBackend = storageBackendsData.value[0]
    } else {
      storageBackend = storageBackendsData.value.find(backend => backend.storageBackend == staticFrontend.value.storageBackend)
    }

    return storageBackend;
  }
  return null
})

const usedStorageBackendAddress = computed(() => {
  return usedStorageBackend.value ? usedStorageBackend.value.storageBackend : null
})

const usedStorageBackendTitleAndVersion = computed(() => {
  return usedStorageBackend.value ? `${usedStorageBackend.value.title} (${usedStorageBackend.value.version})` : ''
})



// Edit the storage backend
const showForm = ref(false)
const newStorageBackend = ref(null)
const { isPending: editStorageBackendIsPending, isError: editStorageBackendIsError, error: editStorageBackendError, isSuccess: editStorageBackendIsSuccess, mutate: editStorageBackendMutate, reset: editStorageBackendReset, variables: editStorageBackendVariables } = useMutation({
  mutationFn: async () => {

    // Prepare the transaction
    const transaction = await staticFrontendPluginClient.value.prepareSetStorageBackendTransaction(props.websiteVersionIndex, newStorageBackend.value);

    const hash = await staticFrontendPluginClient.value.executeTransaction(transaction);

    return await staticFrontendPluginClient.value.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    showForm.value = false;

    return await invalidateStaticFrontendQuery(queryClient, props.contractAddress, props.chainId, props.websiteVersionIndex)
  }
})
const editStorageBackend = async () => {
  editStorageBackendMutate()
}
</script>

<template>
  <div style="font-size: 0.9em;">

    <div style="display: flex; gap: 0.75em; margin-bottom: 0em;">
      <label style="font-weight: bold">
        Storage backend
      </label>
      <div>
        <div v-if="showForm == false">
          <span v-if="usedStorageBackendTitleAndVersion == ''">
            Loading...
          </span>
          <span v-else>
            {{ usedStorageBackendTitleAndVersion }}
          </span>
        </div>
        <div v-else style="display: flex; gap: 0.5em;">
          <select v-model="newStorageBackend" style="padding: 0.2em 0.5em;">
            <option :value="null">- Select a storage backend -</option>
            <option v-for="storageBackendInfo in storageBackendsData" :key="storageBackendInfo.storageBackend" :value="storageBackendInfo.storageBackend">
              {{ storageBackendInfo.title }} ({{ storageBackendInfo.version }})
            </option>
          </select>
          <button @click="editStorageBackend()" :disabled="editStorageBackendIsPending" class="sm">Save</button>
        </div>
      </div>
      <div>
        <a v-if="isLockedLoaded && isLocked == false && staticFrontendLoaded && staticFrontend.files.length == 0 && showForm == false" @click.stop.prevent="showForm = true" class="white">
          <PencilSquareIcon />
        </a>
      </div>
    </div>

    <div v-if="editStorageBackendIsError" class="mutation-error">
      <span>
        Error saving the storage backend: {{ editStorageBackendError.shortMessage || editStorageBackendError.message }} <a @click.stop.prevent="editStorageBackendReset()">Hide</a>
      </span>
    </div>

    <div v-if="isLockedLoaded && isLocked == false && staticFrontendLoaded && staticFrontend.files.length > 0" class="text-90 text-muted">
      The storage backend can only be edited when there are no files uploaded.
    </div>

  </div>
</template>

<style scoped>





.mutation-error {
  padding: 0em 1em 0.5em 0em;
  color: var(--color-text-danger);
  line-height: 1em;
}

.mutation-error span {
  font-size: 0.9em;
}

.mutation-error a {
  color: var(--color-text-danger);
  text-decoration: underline;
}
</style>