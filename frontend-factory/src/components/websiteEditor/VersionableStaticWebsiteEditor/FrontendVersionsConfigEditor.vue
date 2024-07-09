<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useQueryClient } from '@tanstack/vue-query'

import FrontendVersionList from './FrontendVersionList.vue';
import FrontendVersionListLine from './FrontendVersionListLine.vue';
import LockFillIcon from '../../../icons/LockFillIcon.vue';
import PlusLgIcon from '../../../icons/PlusLgIcon.vue';
import ExclamationTriangleIcon from '../../../icons/ExclamationTriangleIcon.vue';
import { useContractAddresses, invalidateFrontendVersionsQuery, useFrontendVersions } from '../../../utils/queries';

const props = defineProps({
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

const queryClient = useQueryClient()

// Fetch the list of storage backends from the factory
const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()
const { data: storageBackendsData, isLoading: storageBackendsLoading, isFetching: storageBackendsFetching, isError: storageBackendsIsError, error: storageBackendsError, isSuccess: storageBackendsLoaded } = useQuery({
  queryKey: ['storageBackends', props.contractAddress, props.chainId],
  queryFn: async () => {
    const factoryAddress = contractAddresses.value.factories.find(f => f.chainId === props.chainId)?.address

    const response = await fetch(`web3://${factoryAddress}:${props.chainId}/getStorageBackends?returns=((address,string)[])`)
    if (!response.ok) {
      throw new Error('Network response was not ok')
    }
    const decodedResponse = await response.json()
    const result = decodedResponse[0].map(([address, name]) => ({ address, name }))

    return result
  },
  staleTime: 3600 * 1000,
  enabled: contractAddressesLoaded,
})

// Get the list frontend versions
const showEditedFrontendVersionSelector = ref(false)
const { data: frontendVersionsData, isLoading: frontendVersionsLoading, isFetching: frontendVersionsFetching, isError: frontendVersionsIsError, error: frontendVersionsError, isSuccess: frontendVersionsLoaded } = useFrontendVersions(queryClient, props.contractAddress, props.chainId)

// Create frontendVersion
const showNewFrontendVersionForm = ref(false)
const newFrontendVersionDescription = ref("")
const newFrontendVersionStorageBackend = ref(null)
const { isPending: newfrontendversionIsPending, isError: newfrontendversionIsError, error: newfrontendversionError, isSuccess: newfrontendversionIsSuccess, mutate: newfrontendversionMutate, reset: newfrontendversionReset } = useMutation({
  mutationFn: async () => {
    // Prepare the transaction
    const transaction = await props.websiteClient.prepareAddFrontendVersionAndCopyPluginsTransaction(newFrontendVersionStorageBackend.value, newFrontendVersionDescription.value, frontendVersionsData.value.totalCount - 1);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    newFrontendVersionDescription.value = ""
    showNewFrontendVersionForm.value = false

    // Refresh the frontend version
    return await invalidateFrontendVersionsQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const newfrontendversionFile = async () => {
  newfrontendversionMutate()
}

// Global lock
const showGlobalLockForm = ref(false)
const { isPending: globalLockIsPending, isError: globalLockIsError, error: globalLockError, isSuccess: globalLockIsSuccess, mutate: globalLockMutate, reset: globalLockReset } = useMutation({
  mutationFn: async () => {
    // Prepare the transaction
    const transaction = await props.websiteClient.prepareLockTransaction();

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    showGlobalLockForm.value = false

    // Refresh the frontend version
    return await invalidateFrontendVersionsQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const activateGlobalLock = async () => {
  globalLockMutate()
}
</script>

<template>
  <div class="versions-body">
        
    <div class="list">
      <FrontendVersionList 
        :contractAddress
        :chainId
        :websiteClient="websiteClient"
        />
    </div>

    <div class="operations">
      <div class="op-add-new">

        <div class="button-area" @click="showNewFrontendVersionForm = !showNewFrontendVersionForm; newFolderErrorLabel = ''">
          <span class="button-text">
            <PlusLgIcon />
            Add new version
          </span>
        </div>
        <div class="form-area" v-if="showNewFrontendVersionForm">
          <input type="text" v-model="newFrontendVersionDescription" placeholder="Version description" />

          <select v-model="newFrontendVersionStorageBackend">
            <option :value="null">- Select a storage backend -</option>
            <option v-for="storageBackend in storageBackendsData" :key="storageBackend.address" :value="storageBackend.address">
              {{ storageBackend.name }}
            </option>
          </select>
          <div v-if="storageBackendsIsError" class="text-danger text-90">
            Error loading storage backends: {{ storageBackendsError.shortMessage || storageBackendsError.message }}
          </div>

          <button @click="newfrontendversionFile" :disabled="newFrontendVersionDescription == '' || newFrontendVersionStorageBackend == null">Add new version</button>

          <div v-if="newfrontendversionIsError" class="text-danger text-90">
            Error adding new version: {{ newfrontendversionError.shortMessage || newfrontendversionError.message }}
            <a @click.stop.prevent="newfrontendversionReset()" style="color: inherit; text-decoration: underline;">Hide</a>
          </div>
        </div>
      </div>
      <div class="op-global-lock">

        <div class="button-area" @click="showGlobalLockForm = !showGlobalLockForm; newFolderErrorLabel = ''">
          <span class="button-text">
            <LockFillIcon />
            Global lock
          </span>
        </div>
        <div class="form-area" v-if="showGlobalLockForm">
          <div class="text-danger" style="display: flex; align-items: center; gap: 1em;">
            <div>
              <LockFillIcon v-if="globalLockIsPending" style="scale: 2; margin: 0em 1em;" class="anim-pulse" />
              <ExclamationTriangleIcon v-else style="scale: 2; margin: 0em 1em;" />
            </div>
            <div>
              Once the global lock is set, nothing can be edited anymore, and the website become immutable. It cannot be undone. <br />
               Are you sure you want to proceed?
            </div>
          </div>
          <div>
            <button type="button" style="width: 100%" @click="activateGlobalLock"><LockFillIcon /> Lock everything permanently</button>
          </div>
          <div v-if="globalLockIsError" class="text-danger" style="font-size: 0.9em">
            Error activating the global lock: {{ globalLockError.shortMessage || globalLockError.message }} <a @click.stop.prevent="globalLockReset()" style="color: inherit; text-decoration: underline;">Hide</a>
          </div>

        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>
.versions-body {
  display: flex;
  flex-direction: column;
  border-top: 1px solid var(--color-divider-secondary);
  gap: 1em;
}

.list {
  flex: 1;
}

.operations {
  display: flex;
  gap: 1em;
  margin: 0em 1em 1em 1em;
  align-items: flex-start;
}
@media (max-width: 700px) {
  .operations {
    flex-direction: column;
  }
}

.operations .button-area {
  text-align: center;
  position: relative;
  background-color: var(--color-input-bg);
  border: 1px solid #555;
  padding: 0.5em 1em;
  cursor: pointer;
}

.operations .button-area .button-text {
  display: flex;
  gap: 0.5em;
  align-items: center;
  justify-content: center;
}

.operations .form-area {
  border-left: 1px solid #555;
  border-right: 1px solid #555;
  border-bottom: 1px solid #555;
  background-color: var(--color-popup-bg);
  font-size: 0.9em;
  padding: 0.75em 1em;
  display: flex;
  flex-direction: column;
  gap: 0.5em;
}

</style>