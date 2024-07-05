<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'

import { useContractAddresses, invalidateFrontendVersionsQuery } from '../../../utils/queries';
import PlusLgIcon from '../../../icons/PlusLgIcon.vue';
import ArrowRightIcon from '../../../icons/ArrowRightIcon.vue';
import TrashIcon from '../../../icons/TrashIcon.vue';

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

const queryClient = useQueryClient()

// Add new proxied website
const showNewProxiedWebsiteForm = ref(false)
const newProxiedWebsiteLocalPrefix = ref('')
const newProxiedWebsiteRemoteAddress = ref('')
const newProxiedWebsiteRemotePrefix = ref('')
const { isPending: newProxiedWebsiteIsPending, isError: newProxiedWebsiteIsError, error: newProxiedWebsiteError, isSuccess: newProxiedWebsiteIsSuccess, mutate: newProxiedWebsiteMutate, reset: newProxiedWebsiteReset } = useMutation({
  mutationFn: async () => {
    // Prepare the transaction
    const transaction = await props.websiteClient.prepareAddProxiedWebsiteToFrontendTransaction(props.frontendVersionIndex, newProxiedWebsiteLocalPrefix.value, newProxiedWebsiteRemoteAddress.value, newProxiedWebsiteRemotePrefix.value);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    newProxiedWebsiteLocalPrefix.value = ""
    newProxiedWebsiteRemoteAddress.value = ""
    newProxiedWebsiteRemotePrefix.value = ""
    showNewProxiedWebsiteForm.value = false

    // Refresh the frontend version
    return await invalidateFrontendVersionsQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const newProxiedWebsiteFile = async () => {
  newProxiedWebsiteMutate()
}

// Remove new proxied website
const { isPending: removeProxiedWebsiteIsPending, isError: removeProxiedWebsiteIsError, error: removeProxiedWebsiteError, isSuccess: removeProxiedWebsiteIsSuccess, mutate: removeProxiedWebsiteMutate, reset: removeProxiedWebsiteReset, variables: removeProxiedWebsiteVariables } = useMutation({
  mutationFn: async (proxiedWebsiteIndex) => {

    // Prepare the transaction
    const transaction = await props.websiteClient.prepareRemoveProxiedWebsiteFromFrontendTransaction(props.frontendVersionIndex, proxiedWebsiteIndex);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    // Refresh the frontend version
    return await invalidateFrontendVersionsQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const removeProxiedWebsiteFile = async (proxiedWebsiteIndex) => {
  removeProxiedWebsiteMutate(proxiedWebsiteIndex)
}
</script>

<template>
  <div class="settings">
    <div class="settings-item" style="flex:0 0 60%">
      <div class="title">Mappings to external websites</div>
      
      <div class="table-header">
        <div>
          Local path
        </div>
        <div>
          
        </div>
        <div>
          Destination
        </div>
        <div>

        </div>
      </div>

      <div v-if="frontendVersion" v-for="(proxiedWebsite, proxiedWebsiteIndex) in frontendVersion.proxiedWebsites">
        <div class="table-row">
          <div>
            /{{ proxiedWebsite.localPrefix.join('/') }}{{ proxiedWebsite.localPrefix.length > 0 ? "/" : "" }}
          </div>
          <div>
            <ArrowRightIcon />
          </div>
          <div class="text-80">
            web3://{{ proxiedWebsite.website }}{{ chainId > 1 ? ':' + chainId : '' }}/{{ proxiedWebsite.remotePrefix.join('/') }}{{ proxiedWebsite.remotePrefix.length > 0 ? "/" : "" }}
          </div>
          <div style="text-align: right">
            <a @click.stop.prevent="removeProxiedWebsiteFile(proxiedWebsiteIndex)" class="white" v-if="removeProxiedWebsiteIsPending == false">
              <TrashIcon />
            </a>
          </div>
        </div>

        <div v-if="removeProxiedWebsiteIsError && removeProxiedWebsiteVariables == proxiedWebsiteIndex" class="mutation-error">
          <span>
            Error renaming the version: {{ removeProxiedWebsiteError.shortMessage || removeProxiedWebsiteError.message }} <a @click.stop.prevent="removeProxiedWebsiteReset()">Hide</a>
          </span>
        </div>
      </div>


      <div class="operations">
        <div class="op-add-new">

          <div class="button-area" @click="showNewProxiedWebsiteForm = !showNewProxiedWebsiteForm; newFolderErrorLabel = ''">
            <span class="button-text">
              <PlusLgIcon />
              Add new mapping
            </span>
          </div>
          <div class="form-area" v-if="showNewProxiedWebsiteForm">
            <span style="display: flex; align-items: center; gap: 0.2em;">
              /
              <input type="text" v-model="newProxiedWebsiteLocalPrefix" placeholder="Local path prefix" />
              /
            </span>
            <ArrowRightIcon />
            <span style="display: flex; align-items: center; gap: 0.2em;">
              web3://
              <input type="text" v-model="newProxiedWebsiteRemoteAddress" placeholder="External website address" />
              <span style="display: flex">
                <span v-if="chainId > 1">:{{ chainId }}</span>
                /
              </span>
              <input type="text" v-model="newProxiedWebsiteRemotePrefix" placeholder="Remote path prefix" />
              /
            </span>


            <button @click="newProxiedWebsiteFile" :disabled="newProxiedWebsiteRemoteAddress == ''">Add mapping</button>

            <div v-if="newProxiedWebsiteIsError" class="text-danger text-90">
              Error adding the mapping: {{ newProxiedWebsiteError.shortMessage || newProxiedWebsiteError.message }}
              <a @click.stop.prevent="newProxiedWebsiteReset()" style="color: inherit; text-decoration: underline;">Hide</a>
            </div>
          </div>
        </div>
      </div>

    </div>
    <div class="settings-item">
      <div class="title">Injected contract addresses</div>
    </div>
  </div>
</template>

<style scoped>
.settings {
  display: flex;
  flex-direction: column;
}

.settings-item {
  margin: 1em;
}

.title {
  font-size: 1.1em;
  font-weight: bold;
  margin-bottom: 1em;
}


.table-header {
  display: grid;
  grid-template-columns: 1fr 0.5fr 3fr 2em;
  padding: 0.5em;
  font-weight: bold;
  border-bottom: 1px solid var(--color-divider-secondary);
  background-color: var(--color-root-bg)
}

.table-header > div {
  padding: 0em 0.5em;
  word-break: break-all;
}

.table-row {
  display: grid;
  grid-template-columns: 1fr 0.5fr 3fr 2em;
  padding: 0.5em;
}

.table-row > div {
  padding: 0em 0.5em;
  word-break: break-all;
}

.mutation-error {
  padding: 0em 1em 0.5em 1em;
  color: var(--color-text-danger);
  line-height: 1em;
}

.mutation-error span {
  font-size: 0.8em;
}

.mutation-error a {
  color: var(--color-text-danger);
  text-decoration: underline;
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

.operations input {
  max-width: 150px;
}
</style>