<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useQueryClient } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';
import PencilSquareIcon from '../../../icons/PencilSquareIcon.vue';
import ArrowRightIcon from '../../../icons/ArrowRightIcon.vue';
import PlayCircleIcon from '../../../icons/PlayCircleIcon.vue';

import { useLiveFrontendVersion, invalidateLiveFrontendVersionQuery } from '../../../utils/queries.js';

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
const { isPending: renameIsPending, isError: renameIsError, error: renameError, isSuccess: renameIsSuccess, mutate: renameMutate, reset: renameReset } = useMutation({
  mutationFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    const transaction = await props.websiteClient.prepareRenameFrontendVersionTransaction(props.frontendVersionIndex, newDescription.value);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    // Refresh the frontend versions
    return await queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersions', props.contractAddress, props.chainId] })
  }
})
const renameFrontendVersion = async () => {
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

// Set live
const { isPending: setLiveIsPending, isError: setLiveIsError, error: setLiveError, isSuccess: setLiveIsSuccess, mutate: setLiveMutate, reset: setLiveReset } = useMutation({
  mutationFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    const transaction = await props.websiteClient.prepareSetDefaultFrontendIndexTransaction(props.frontendVersionIndex);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    return await invalidateLiveFrontendVersionQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const setLive = async () => {
  if(confirm('You are about to set this version as the live version served by your website. Continue?') == false) {
    return
  }

  setLiveMutate()
}
</script>

<template>
  <div>
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
      </div>
      <div>
        locked:{{ frontendVersion.locked }}
      </div>
      <div>
        <a @click.stop.prevent="showRenameForm = !showRenameForm; newDescription = frontendVersion.description" class="white" v-if="renameIsPending == false">
          <PencilSquareIcon />
        </a>
        <a @click.stop.prevent="setLive()" class="white" v-if="liveFrontendVersionLoaded && frontendVersionIndex != liveFrontendVersionData.frontendIndex && renameIsPending == false">
          <PlayCircleIcon />
        </a>
      </div>
    </div>

    <div v-if="renameIsError" class="mutation-error">
      <span>
        Error renaming the version: {{ renameError.shortMessage || renameError.message }} <a @click.stop.prevent="renameReset()">Hide</a>
      </span>
    </div>

    <div v-if="setLiveIsError" class="mutation-error">
      <span>
        Error setting live the version: {{ setLiveError.shortMessage || setLiveError.message }} <a @click.stop.prevent="setLiveReset()">Hide</a>
      </span>
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
</style>