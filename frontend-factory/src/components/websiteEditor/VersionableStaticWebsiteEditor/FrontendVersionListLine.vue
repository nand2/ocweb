<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useQueryClient } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';
import PencilSquareIcon from '../../../icons/PencilSquareIcon.vue';
import ArrowRightIcon from '../../../icons/ArrowRightIcon.vue';

import { useLiveFrontendVersion } from '../../../utils/queries.js';

const props = defineProps({
  frontendVersion: {
    type: null,
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
const { switchChainAsync } = useSwitchChain()

// Fetch the live frontend infos
const { data: liveFrontendVersionData, isLoading: liveFrontendVersionLoading, isFetching: liveFrontendVersionFetching, isError: liveFrontendVersionIsError, error: liveFrontendVersionError, isSuccess: liveFrontendVersionLoaded } = useLiveFrontendVersion(props.contractAddress, props.chainId)


// Rename version
const showRenameForm = ref(false)
const newDescription = ref(props.frontendVersion.description)
const preRenameError = ref('')
const { isPending: renameIsPending, isError: renameIsError, error: renameError, isSuccess: renameIsSuccess, mutate: renameMutate, reset: renameReset } = useMutation({
  mutationFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    // Prepare the transaction to rename the file
    const transaction = await props.websiteClient.prepareRenameFrontendVersion(props.frontendVersionIndex, newDescription.value);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    // Refresh the frontend versions
    return await queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersions', props.contractAddress, props.chainId] })
  }
})
const renameFrontendVersion = async () => {
  preRenameError.value = ''

  if(newDescription.value.trim() === '') {
    return
  }

  if(newDescription.value.trim() === props.frontendVersion.description) {
    showRenameForm.value = false
    return
  }

  showRenameForm.value = false

  renameMutate()
}
</script>

<template>
  <div class="frontend-version">
    <div>
      <PencilSquareIcon v-if="renameIsPending == true" class="anim-pulse" />
      <span v-else>
        #{{ frontendVersionIndex }} 
      </span>
    </div>
    <div>
      <span v-if="showRenameForm" class="rename-form">
        <input v-model="newDescription" type="text" />
        <button @click="renameFrontendVersion()" :disabled="renameIsPending" class="sm">Rename</button>
      </span>
      <span v-else class="description">
        <span :class="{'text-muted': renameIsPending}">
          {{ frontendVersion.description }}
        </span>
        <span v-if="renameIsPending">
          <ArrowRightIcon />
        </span>
        <span v-if="renameIsPending">
          {{ newDescription }}
        </span>
        <span class="text-muted" style="font-size: 0.8em">
          {{ frontendVersion.files.length }} files
        </span>
      </span>
    </div>
    <div>
      <span class="badge" v-if="liveFrontendVersionLoaded && frontendVersionIndex == liveFrontendVersionData.frontendIndex">
        Live
      </span>
      <button v-if="liveFrontendVersionLoaded && frontendVersionIndex != liveFrontendVersionData.frontendIndex" class="sm">
        Set live
      </button>
    </div>
    <div>
      locked:{{ frontendVersion.locked }}
    </div>
    <div>
      <a @click.stop.prevent="showRenameForm = !showRenameForm; preRenameError = ''; newDescription = frontendVersion.description" class="white" v-if="renameIsPending == false">
        <PencilSquareIcon />
      </a>
    </div>
  </div>
</template>

<style scoped>
.frontend-version {
  display: grid;
  grid-template-columns: max-content 3fr 1.5fr 1fr 1fr;
  padding: 0.5em 0em;
  align-items: center;
}

.frontend-version > div {
  display: flex;
  line-height: 1em;
  gap: 0.5em;
  padding: 0em 1em;
  word-break: break-all;
}

.description {
  display: flex;
  gap: 0.5em;
}

.rename-form {
  display: flex;
  gap: 0.5em;
  align-items: center;
}

.rename-form input {
  padding: 0.2em 0.5em;
  max-width: 50%;
}
</style>