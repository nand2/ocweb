<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useQueryClient } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';
import PencilSquareIcon from '../../../icons/PencilSquareIcon.vue';
import ArrowRightIcon from '../../../icons/ArrowRightIcon.vue';
import PlayCircleIcon from '../../../icons/PlayCircleIcon.vue';
import LockFillIcon from '../../../icons/LockFillIcon.vue';
import UnlockFillIcon from '../../../icons/UnlockFillIcon.vue';
import BoxArrowUpRightIcon from '../../../icons/BoxArrowUpRightIcon.vue';
import EyeIcon from '../../../icons/EyeIcon.vue';
import EyeSlashIcon from '../../../icons/EyeSlashIcon.vue';

import { useLiveFrontendVersion, invalidateLiveFrontendVersionQuery, invalidateFrontendVersionsQuery } from '../../../utils/queries.js';

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
const { data: liveFrontendVersionData, isLoading: liveFrontendVersionLoading, isFetching: liveFrontendVersionFetching, isError: liveFrontendVersionIsError, error: liveFrontendVersionError, isSuccess: liveFrontendVersionLoaded } = useLiveFrontendVersion(queryClient, props.contractAddress, props.chainId)


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
    return await invalidateFrontendVersionsQuery(queryClient, props.contractAddress, props.chainId)
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

// Lock
const { isPending: lockIsPending, isError: lockIsError, error: lockError, isSuccess: lockIsSuccess, mutate: lockMutate, reset: lockReset } = useMutation({
  mutationFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    const transaction = await props.websiteClient.prepareLockFrontendVersionTransaction(props.frontendVersionIndex);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    return await invalidateFrontendVersionsQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const lock = async () => {
  if(confirm("WARNING: You are about to lock this version *permanently*. You will no longer be able to edit it (edit files, ...). Continue?") == false) {
    return
  }

  lockMutate()
}

// Toggle is viewable
const { isPending: toggleIsViewableIsPending, isError: toggleIsViewableIsError, error: toggleIsViewableError, isSuccess: toggleIsViewableIsSuccess, mutate: toggleIsViewableMutate, reset: toggleIsViewableReset } = useMutation({
  mutationFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    const transaction = await props.websiteClient.prepareEnableViewerForFrontendVersionTransaction(props.frontendVersionIndex, !props.frontendVersion.isViewable);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    return await invalidateFrontendVersionsQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const toggleIsViewable = async () => {
  if(props.frontendVersion.isViewable == false && confirm("You are about to make publicly accessible a non-live version, via a separate web3:// address. It can be useful to preview a change, or to make an historical version accessible. Continue?") == false) {
    return
  }

  if(props.frontendVersion.isViewable && confirm("You are about to disable the web3:// address for this non-live version. Continue?") == false) {
    return
  }

  toggleIsViewableMutate()
}

const viewerAddress = computed(() => {
  return `web3://${props.frontendVersion.viewer}:${props.chainId}/`
})
</script>

<template>
  <div>
    <div class="frontend-version">
      <div>
        <PencilSquareIcon v-if="renameIsPending == true" class="anim-pulse" />
        <PlayCircleIcon v-else-if="setLiveIsPending == true" class="anim-pulse" />
        <LockFillIcon v-else-if="lockIsPending == true" class="anim-pulse" />
        <EyeIcon v-else-if="toggleIsViewableIsPending == true && frontendVersion.isViewable == false" class="anim-pulse" />
        <EyeSlashIcon v-else-if="toggleIsViewableIsPending == true && frontendVersion.isViewable == true" class="anim-pulse" />
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
          <LockFillIcon v-if="frontendVersion.locked" />
          <span class="badge" v-if="liveFrontendVersionLoaded && frontendVersionIndex == liveFrontendVersionData.frontendIndex">
            Live
          </span>
        </span>
      </div>
      <div class="text-80">
        <a :href="viewerAddress" target="_blank" style="display: flex; max-width: 100%; align-items: center;" v-if="(liveFrontendVersionLoaded && frontendVersionIndex != liveFrontendVersionData.frontendIndex) && frontendVersion.isViewable">
          <span style="white-space: nowrap; overflow:hidden; text-overflow: ellipsis;">
            {{ viewerAddress }} 
          </span>
          <BoxArrowUpRightIcon style="flex: 0 0 auto; margin-left: 0.5em" />
        </a>
        <span v-else-if="(liveFrontendVersionLoaded && frontendVersionIndex != liveFrontendVersionData.frontendIndex) && frontendVersion.isViewable == false" style="margin:auto;">
          <EyeSlashIcon class="text-muted" />
        </span>
      </div>
      <div style="justify-content: right">
        <a @click.stop.prevent="showRenameForm = !showRenameForm; newDescription = frontendVersion.description" class="white" v-if="frontendVersion.locked == false && renameIsPending == false && setLiveIsPending == false && lockIsPending == false && toggleIsViewableIsPending == false">
          <PencilSquareIcon />
        </a>
        <a @click.stop.prevent="setLive()" class="white" v-if="liveFrontendVersionLoaded && frontendVersionIndex != liveFrontendVersionData.frontendIndex && renameIsPending == false && setLiveIsPending == false && lockIsPending == false && toggleIsViewableIsPending == false">
          <PlayCircleIcon />
        </a>
        <a @click.stop.prevent="toggleIsViewable()" class="white" v-if="(liveFrontendVersionLoaded && frontendVersionIndex != liveFrontendVersionData.frontendIndex) && renameIsPending == false && setLiveIsPending == false && lockIsPending == false && toggleIsViewableIsPending == false">
          <EyeIcon v-if="frontendVersion.isViewable == false" />
          <EyeSlashIcon v-else />
        </a>
        <a @click.stop.prevent="lock()" class="white" v-if="frontendVersion.locked == false && renameIsPending == false && setLiveIsPending == false && lockIsPending == false && toggleIsViewableIsPending == false">
          <LockFillIcon />
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

    <div v-if="toggleIsViewableIsError" class="mutation-error">
      <span>
        Error toggling visibility: {{ toggleIsViewableError.shortMessage || toggleIsViewableError.message }} <a @click.stop.prevent="toggleIsViewableReset()">Hide</a>
      </span>
    </div>

    <div v-if="lockIsError" class="mutation-error">
      <span>
        Error locking the version: {{ lockError.shortMessage || lockError.message }} <a @click.stop.prevent="lockReset()">Hide</a>
      </span>
    </div>
  </div>
</template>

<style scoped>
.frontend-version {
  display: grid;
  grid-template-columns: minmax(3em, max-content) 3fr minmax(0, 2fr) 1fr;
  padding: 0.5em 0.5em;
  align-items: center;
}

.frontend-version > div {
  display: flex;
  line-height: 1em;
  gap: 0.5em;
  padding: 0em 0.5em;
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