<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';

import { useContractAddresses, invalidateFrontendVersionQuery } from '../../../utils/queries';
import { ProxiedWebsitesPluginClient } from '../../../../../src/plugins/proxiedWebsitesPluginClient.js';
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
  pluginInfos: {
    type: Object,
    required: true,
  },
})

const queryClient = useQueryClient()
const { data: viemClient, isSuccess: viemClientLoaded } = useConnectorClient()

const proxiedWebsitesPluginClient = computed(() => {
  return viemClientLoaded.value ? new ProxiedWebsitesPluginClient(viemClient.value, props.contractAddress, props.pluginInfos.plugin) : null;
})

// Get proxied websites
const { data: proxiedWebsites, isLoading: proxiedWebsitesLoading, isFetching: proxiedWebsitesFetching, isError: proxiedWebsitesIsError, error: proxiedWebsitesError, isSuccess: proxiedWebsitesLoaded } = useQuery({
  queryKey: ['OCWebsiteFrontendVersionPluginProxiedWebsites', props.contractAddress, props.chainId, computed(() => props.frontendVersionIndex)],
  queryFn: async () => {
    const result = await proxiedWebsitesPluginClient.value.getProxiedWebsites(props.frontendVersionIndex);
    return result;
  },
  enabled: computed(() => proxiedWebsitesPluginClient.value != null),
})

// Add new proxied website
const showForm = ref(false)
const additionLocalPrefix = ref('')
const additionRemoteAddress = ref('')
const additionRemotePrefix = ref('')
const preAdditionError = ref('')
const { isPending: additionIsPending, isError: additionIsError, error: additionError, isSuccess: additionIsSuccess, mutate: additionMutate, reset: additionReset } = useMutation({
  mutationFn: async () => {
    // Prepare the transaction
    const transaction = await proxiedWebsitesPluginClient.value.prepareAddProxiedWebsiteTransaction(props.frontendVersionIndex, additionLocalPrefix.value, additionRemoteAddress.value, additionRemotePrefix.value);

    const hash = await proxiedWebsitesPluginClient.value.executeTransaction(transaction);

    return await proxiedWebsitesPluginClient.value.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    additionLocalPrefix.value = ""
    additionRemoteAddress.value = ""
    additionRemotePrefix.value = ""
    showForm.value = false

    return queryClient.invalidateQueries({ queryKey:  ['OCWebsiteFrontendVersionPluginProxiedWebsites', props.contractAddress, props.chainId, props.frontendVersionIndex] })
  }
})
const additionFile = async () => {
  preAdditionError.value = ''

  // Check if additionRemoteAddress is the right format (ethereum address)
  if(additionRemoteAddress.value.match(/^0x[a-fA-F0-9]{40}$/) == null) {
    preAdditionError.value = 'The remote address is not a valid hexadecimal address ("0x...")'
    return
  }

  additionMutate()
}

// Remove new proxied website
const { isPending: removeIsPending, isError: removeIsError, error: removeError, isSuccess: removeIsSuccess, mutate: removeMutate, reset: removeReset, variables: removeVariables } = useMutation({
  mutationFn: async (index) => {

    // Prepare the transaction
    const transaction = await proxiedWebsitesPluginClient.value.prepareRemoveProxiedWebsiteTransaction(props.frontendVersionIndex, index);

    const hash = await proxiedWebsitesPluginClient.value.executeTransaction(transaction);

    return await proxiedWebsitesPluginClient.value.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    return queryClient.invalidateQueries({ queryKey:  ['OCWebsiteFrontendVersionPluginProxiedWebsites', props.contractAddress, props.chainId, props.frontendVersionIndex] })
  }
})
const removeItem = async (index) => {
  removeMutate(index)
}
</script>

<template>
  <div>
    <div class="title">Mappings to external websites <small class="text-muted" style="font-weight: normal; font-size:0.7em;">Local files have priority</small></div>
    
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

    <div v-if="proxiedWebsitesLoading" class="text-muted" style="text-align: center; margin: 1em;">
      Loading...
    </div>
    <div v-if="proxiedWebsitesIsError" class="text-danger text-90" style="text-align: center; margin: 1em;">
      Error loading the variables: {{ proxiedWebsitesError.shortMessage || proxiedWebsitesError.message }}
    </div>

    <div v-if="proxiedWebsitesLoaded" v-for="(proxiedWebsite, index) in proxiedWebsites">
      <div :class="{'table-row': true, 'delete-pending': removeIsPending && removeVariables == index}">
        <div>
          /{{ proxiedWebsite.localPrefix.join('/') }}
        </div>
        <div>
          <ArrowRightIcon />
        </div>
        <div class="text-80">
          web3://{{ proxiedWebsite.website }}{{ chainId > 1 ? ':' + chainId : '' }}/{{ proxiedWebsite.remotePrefix.join('/') }}
        </div>
        <div style="text-align: right">
          <a @click.stop.prevent="removeItem(index)" class="white" v-if="removeIsPending == false">
            <TrashIcon />
          </a>
          <TrashIcon class="anim-pulse" v-if="removeIsPending && removeVariables == index" />
        </div>
      </div>

      <div v-if="removeIsError && removeVariables == index" class="mutation-error">
        <span>
          Error renaming the version: {{ removeError.shortMessage || removeError.message }} <a @click.stop.prevent="removeReset()">Hide</a>
        </span>
      </div>
    </div>
    
    <div v-if="proxiedWebsitesLoaded && proxiedWebsites.length == 0" class="no-entries">
      No mappings
    </div>


    <div class="operations">
      <div class="op-add-new">

        <div class="button-area" @click="showForm = !showForm; preAdditionError = ''">
          <span class="button-text">
            <PlusLgIcon />
            Add new mapping
          </span>
        </div>
        <div class="form-area" v-if="showForm">
          <span style="display: flex; align-items: center; gap: 0.2em;">
            /
            <input type="text" v-model="additionLocalPrefix" placeholder="Local path prefix" />
          </span>
          <ArrowRightIcon />
          <span style="display: flex; align-items: center; gap: 0.2em;">
            web3://
            <input type="text" v-model="additionRemoteAddress" placeholder="Remote website address" />
            <span style="display: flex">
              <span v-if="chainId > 1">:{{ chainId }}</span>
              /
            </span>
            <input type="text" v-model="additionRemotePrefix" placeholder="Remote path prefix" />
          </span>

          <div v-if="preAdditionError" class="text-danger text-90">
            <span>
              {{ preAdditionError }}
            </span>
          </div>

          <button @click="additionFile" :disabled="additionRemoteAddress == '' || additionIsPending">Add mapping</button>

          <div v-if="additionIsError" class="text-danger text-90">
            Error adding the mapping: {{ additionError.shortMessage || additionError.message }}
            <a @click.stop.prevent="additionReset()" style="color: inherit; text-decoration: underline;">Hide</a>
          </div>
        </div>
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

.delete-pending {
  opacity: 0.5;
  text-decoration: line-through;
}

.no-entries {
  padding: 1.5em;
  text-align: center;
  color: var(--color-text-muted);
}
</style>