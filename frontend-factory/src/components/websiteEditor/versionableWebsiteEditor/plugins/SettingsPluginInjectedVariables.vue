<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';

import { useContractAddresses, invalidateWebsiteVersionQuery, useIsLocked } from '../../../../../../src/tanstack-vue.js';
import { InjectedVariablesPluginClient } from '../../../../../../src/plugins/injectedVariables/client.js';
import PlusLgIcon from '../../../../icons/PlusLgIcon.vue';
import ArrowRightIcon from '../../../../icons/ArrowRightIcon.vue';
import TrashIcon from '../../../../icons/TrashIcon.vue';

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
})

const queryClient = useQueryClient()
const { data: viemClient, isSuccess: viemClientLoaded } = useConnectorClient()

const injectedVariablesPluginClient = computed(() => {
  return viemClientLoaded.value ? new InjectedVariablesPluginClient(viemClient.value, props.contractAddress, props.pluginInfos.plugin) : null;
})

// Get the lock status
const { data: isLocked, isLoading: isLockedLoading, isFetching: isLockedFetching, isError: isLockedIsError, error: isLockedError, isSuccess: isLockedLoaded } = useIsLocked(props.contractAddress, props.chainId)

// Get variables
const { data: injectedVariables, isLoading: injectedVariablesLoading, isFetching: injectedVariablesFetching, isError: injectedVariablesIsError, error: injectedVariablesError, isSuccess: injectedVariablesLoaded } = useQuery({
  queryKey: ['OCWebsiteVersionPluginInjectedVariables', props.contractAddress, props.chainId, computed(() => props.websiteVersionIndex)],
  queryFn: async () => {
    const result = await injectedVariablesPluginClient.value.getVariables(props.websiteVersionIndex);
    return result;
  },
  enabled: computed(() => injectedVariablesPluginClient.value != null),
})

// Add new var
const showForm = ref(false)
const additionName = ref('')
const additionValue = ref('')
const preAdditionError = ref('')
const { isPending: additionIsPending, isError: additionIsError, error: additionError, isSuccess: additionIsSuccess, mutate: additionMutate, reset: additionReset } = useMutation({
  mutationFn: async () => {
    // Prepare the transaction
    const transaction = await injectedVariablesPluginClient.value.prepareAddVariableTransaction(props.websiteVersionIndex, additionName.value, additionValue.value);

    const hash = await injectedVariablesPluginClient.value.executeTransaction(transaction);

    return await injectedVariablesPluginClient.value.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    additionName.value = ""
    additionValue.value = ""
    showForm.value = false

    return queryClient.invalidateQueries({ queryKey: ['OCWebsiteVersionPluginInjectedVariables', props.contractAddress, props.chainId, props.websiteVersionIndex] })
  }
})
const additionFile = async () => {
  preAdditionError.value = ''

  // Check that the name is not a reserved name : 'self'
  if (additionName.value == 'self') {
    preAdditionError.value = "The name 'self' is reserved"
    return
  }

  // Check that the name is not one of the existing
  if (injectedVariables.value.find(v => v.key == additionName.value)) {
    preAdditionError.value = "The name is already in use"
    return
  }

  additionMutate()
}

// Remove new proxied website
const { isPending: removeIsPending, isError: removeIsError, error: removeError, isSuccess: removeIsSuccess, mutate: removeMutate, reset: removeReset, variables: removeVariables } = useMutation({
  mutationFn: async (key) => {

    // Prepare the transaction
    const transaction = await injectedVariablesPluginClient.value.prepareRemoveVariableTransaction(props.websiteVersionIndex, key);

    const hash = await injectedVariablesPluginClient.value.executeTransaction(transaction);

    return await injectedVariablesPluginClient.value.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    return queryClient.invalidateQueries({ queryKey: ['OCWebsiteVersionPluginInjectedVariables', props.contractAddress, props.chainId, props.websiteVersionIndex] })
  }
})
const removeItem = async (key) => {
  removeMutate(key)
}
</script>

<template>
  <div>
    <div class="text-90" style="margin-bottom: 0.75em;">
      These variables are exposed in the <code>/variables.json</code> path.
    </div>
    
    <div class="table-header">
      <div>
        Name
      </div>
      <div>
        Value
      </div>
      <div>

      </div>
    </div>

    <div v-if="injectedVariablesLoading" class="text-muted" style="text-align: center; margin: 1em;">
      Loading...
    </div>
    <div v-if="injectedVariablesIsError" class="text-danger text-90" style="text-align: center; margin: 1em;">
      Error loading the variables: {{ injectedVariablesError.shortMessage || injectedVariablesError.message }}
    </div>

    <div v-if="injectedVariablesLoaded" class="table-row">
      <div>
        <code>
          self
        </code>
      </div>
      <div>
        <code>
          {{ contractAddress }}:{{ chainId }}
        </code>
      </div>
      <div>
      </div>
    </div>

    <div v-if="injectedVariablesLoaded" v-for="(injectedVariable, index) in injectedVariables">
      <div :class="{'table-row': true, 'delete-pending': removeIsPending && removeVariables == injectedVariable.key}">
        <div>
          <code>
            {{ injectedVariable.key }}
          </code>
        </div>
        <div>
          <code>
            {{ injectedVariable.value }}
          </code>
        </div>
        <div style="text-align: right">
          <a @click.stop.prevent="removeItem(injectedVariable.key)" class="white" v-if="isLockedLoaded && isLocked == false && websiteVersion != null && websiteVersion.locked == false && removeIsPending == false">
            <TrashIcon />
          </a>
          <TrashIcon class="anim-pulse" v-if="removeIsPending && removeVariables == injectedVariable.key" />
        </div>
      </div>

      <div v-if="removeIsError && removeVariables == injectedVariable.key" class="mutation-error">
        <span>
          Error removing the variable: {{ removeError.shortMessage || removeError.message }} <a @click.stop.prevent="removeReset()">Hide</a>
        </span>
      </div>
    </div>


    <div class="operations" v-if="isLockedLoaded && isLocked == false && websiteVersion != null && websiteVersion.locked == false">
      <div class="op-add-new">

        <div class="button-area" @click="showForm = !showForm; preAdditionError = ''">
          <span class="button-text">
            <PlusLgIcon />
            Add new variable
          </span>
        </div>
        <div class="form-area" v-if="showForm">
          <input type="text" v-model="additionName" placeholder="Name" />
          <input type="text" v-model="additionValue" placeholder="Value" />

          <div v-if="preAdditionError" class="text-danger text-90">
            <span>
              {{ preAdditionError }}
            </span>
          </div>

          <button @click="additionFile" :disabled="additionName == '' || additionValue == '' || additionIsPending">Add variable</button>

          <div v-if="additionIsError" class="text-danger text-90">
            Error adding the variable: {{ additionError.shortMessage || additionError.message }}
            <a @click.stop.prevent="additionReset()" style="color: inherit; text-decoration: underline;">Hide</a>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>





.table-header {
  display: grid;
  grid-template-columns: 1fr 3fr 2em;
  padding: 0.5em;
  font-weight: bold;
  border-bottom: 1px solid var(--color-divider-secondary);
  background-color: var(--color-root-bg);
  font-size: 0.9em;
}

.table-header > div {
  padding: 0em 0.5em;
  word-break: break-all;
}

.table-row {
  display: grid;
  grid-template-columns: 1fr 3fr 2em;
  padding: 0.5em;
}

.table-row > div {
  padding: 0em 0.5em;
  word-break: break-all;
}

.mutation-error span {
  font-size: 0.8em;
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