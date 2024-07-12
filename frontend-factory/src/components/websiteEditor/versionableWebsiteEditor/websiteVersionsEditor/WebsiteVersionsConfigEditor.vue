<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useQueryClient } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';
import { getContract, publicActions } from 'viem'

import WebsiteVersionList from './WebsiteVersionList.vue';
import LockFillIcon from '../../../../icons/LockFillIcon.vue';
import PlusLgIcon from '../../../../icons/PlusLgIcon.vue';
import ExclamationTriangleIcon from '../../../../icons/ExclamationTriangleIcon.vue';
import { useContractAddresses, invalidateWebsiteVersionsQuery, useWebsiteVersions, useIsLocked, invalidateIsLockedQuery } from '../../../../utils/queries.js';
import { abi as factoryABI } from '../../../../../../src/abi/factoryABI.js';

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
const { data: viemClient, isSuccess: viemClientLoaded } = useConnectorClient()


// Get the list of website versions
const showEditedWebsiteVersionSelector = ref(false)
const { data: websiteVersionsData, isLoading: websiteVersionsLoading, isFetching: websiteVersionsFetching, isError: websiteVersionsIsError, error: websiteVersionsError, isSuccess: websiteVersionsLoaded } = useWebsiteVersions(queryClient, props.contractAddress, props.chainId)

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


// Create websiteVersion
const showNewWebsiteVersionForm = ref(false)
const newWebsiteVersionDescription = ref("")
const { isPending: newwebsiteversionIsPending, isError: newwebsiteversionIsError, error: newwebsiteversionError, isSuccess: newwebsiteversionIsSuccess, mutate: newwebsiteversionMutate, reset: newwebsiteversionReset } = useMutation({
  mutationFn: async () => {
    // Prepare the transaction
    const transaction = await props.websiteClient.prepareAddWebsiteVersionTransaction(newWebsiteVersionDescription.value, websiteVersionsData.value.totalCount - 1);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    newWebsiteVersionDescription.value = ""
    showNewWebsiteVersionForm.value = false

    return await invalidateWebsiteVersionsQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const newwebsiteversionFile = async () => {
  newwebsiteversionMutate()
}

// Lock
const showLocklForm = ref(false)
const { isPending: locklIsPending, isError: locklIsError, error: locklError, isSuccess: locklIsSuccess, mutate: locklMutate, reset: locklReset } = useMutation({
  mutationFn: async () => {
    // Prepare the transaction
    const transaction = await props.websiteClient.prepareLockTransaction();

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    showLocklForm.value = false
    return await invalidateIsLockedQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const activateLockl = async () => {
  locklMutate()
}
</script>

<template>
  <div class="versions-body">
    <div class="list">
      <WebsiteVersionList 
        :contractAddress
        :chainId
        :websiteClient="websiteClient"
        />
    </div>

    <div class="operations" v-if="isLockedLoaded && isLocked == false">
      <div class="op-add-new">

        <div class="button-area" @click="showNewWebsiteVersionForm = !showNewWebsiteVersionForm; newFolderErrorLabel = ''">
          <span class="button-text">
            <PlusLgIcon />
            Add new version
          </span>
        </div>
        <div class="form-area" v-if="showNewWebsiteVersionForm">
          <input type="text" v-model="newWebsiteVersionDescription" placeholder="Version description" />

          <button @click="newwebsiteversionFile" :disabled="newWebsiteVersionDescription == ''">Add new version</button>

          <div v-if="newwebsiteversionIsError" class="text-danger text-90">
            Error adding new version: {{ newwebsiteversionError.shortMessage || newwebsiteversionError.message }}
            <a @click.stop.prevent="newwebsiteversionReset()" style="color: inherit; text-decoration: underline;">Hide</a>
          </div>
        </div>
      </div>
      <div class="op-global-lock">

        <div class="button-area" @click="showLocklForm = !showLocklForm; newFolderErrorLabel = ''">
          <span class="button-text">
            <LockFillIcon />
            Global lock
          </span>
        </div>
        <div class="form-area" v-if="showLocklForm">
          <div class="text-danger" style="display: flex; align-items: center; gap: 1em;">
            <div>
              <LockFillIcon v-if="locklIsPending" style="scale: 2; margin: 0em 1em;" class="anim-pulse" />
              <ExclamationTriangleIcon v-else style="scale: 2; margin: 0em 1em;" />
            </div>
            <div>
              Once the global lock is set, nothing can be edited anymore, and the website become immutable. It cannot be undone. <br />
               Are you sure you want to proceed?
            </div>
          </div>
          <div>
            <button type="button" style="width: 100%" @click="activateLockl"><LockFillIcon /> Lock everything permanently</button>
          </div>
          <div v-if="locklIsError" class="text-danger" style="font-size: 0.9em">
            Error activating the global lock: {{ locklError.shortMessage || locklError.message }} <a @click.stop.prevent="locklReset()" style="color: inherit; text-decoration: underline;">Hide</a>
          </div>

        </div>
      </div>
    </div>

    <div v-else-if="isLockedLoaded && isLocked" class="text-danger" style="display: flex; align-items: center; gap: 1em; margin: 0em 1em 1em 1em;">
        <div>
          <LockFillIcon style="height: 1.5em; width: 1.5em;" />
        </div>
        <div>
          The website is locked. No further changes can be made.
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
  padding-top: 0.25em;
}

.operations {
  margin: 0em 1em 1em 1em;
}

</style>