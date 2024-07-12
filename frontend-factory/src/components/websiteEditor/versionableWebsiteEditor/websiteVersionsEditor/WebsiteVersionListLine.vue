<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useQueryClient } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';
import PencilSquareIcon from '../../../../icons/PencilSquareIcon.vue';
import ArrowRightIcon from '../../../../icons/ArrowRightIcon.vue';
import PlayCircleIcon from '../../../../icons/PlayCircleIcon.vue';
import LockFillIcon from '../../../../icons/LockFillIcon.vue';
import UnlockFillIcon from '../../../../icons/UnlockFillIcon.vue';
import BoxArrowUpRightIcon from '../../../../icons/BoxArrowUpRightIcon.vue';
import EyeIcon from '../../../../icons/EyeIcon.vue';
import EyeSlashIcon from '../../../../icons/EyeSlashIcon.vue';

import { useLiveWebsiteVersion, invalidateLiveWebsiteVersionQuery, invalidateWebsiteVersionsQuery, invalidateWebsiteVersionQuery, useIsLocked } from '../../../../utils/queries.js';

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
    type: [Object, null],
    required: true,
  },
})

const queryClient = useQueryClient()
const { switchChainAsync } = useSwitchChain()

// Fetch the live website infos
const { data: liveWebsiteVersionData, isLoading: liveWebsiteVersionLoading, isFetching: liveWebsiteVersionFetching, isError: liveWebsiteVersionIsError, error: liveWebsiteVersionError, isSuccess: liveWebsiteVersionLoaded } = useLiveWebsiteVersion(queryClient, props.contractAddress, props.chainId)

// Get the lock status
const { data: isGlobalLocked, isLoading: isGlobalLockedLoading, isFetching: isGlobalLockedFetching, isError: isGlobalLockedIsError, error: isGlobalLockedError, isSuccess: isGlobalLockedLoaded } = useIsLocked(props.contractAddress, props.chainId)


// Rename version
const showRenameForm = ref(false)
const newDescription = ref(props.websiteVersion.description)
const { isPending: renameIsPending, isError: renameIsError, error: renameError, isSuccess: renameIsSuccess, mutate: renameMutate, reset: renameReset } = useMutation({
  mutationFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    const transaction = await props.websiteClient.prepareRenameWebsiteVersionTransaction(props.websiteVersionIndex, newDescription.value);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    // Refresh the website versions
    return await invalidateWebsiteVersionsQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const renameWebsiteVersion = async () => {
  if(newDescription.value.trim() === '') {
    return
  }

  if(newDescription.value.trim() === props.websiteVersion.description) {
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

    const transaction = await props.websiteClient.prepareSetLiveWebsiteVersionIndexTransaction(props.websiteVersionIndex);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    return await invalidateLiveWebsiteVersionQuery(queryClient, props.contractAddress, props.chainId)
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

    const transaction = await props.websiteClient.prepareLockWebsiteVersionTransaction(props.websiteVersionIndex);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    await invalidateWebsiteVersionQuery(queryClient, props.contractAddress, props.chainId, props.websiteVersionIndex)
    return await invalidateWebsiteVersionsQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const lock = async () => {
  if(confirm("WARNING: You are about to lock this version *permanently*. \n\n- You will no longer be able to add/remove files and configure plugins for this version.\n- You will keep the ability to set/unset this version as the live version. \n- You will keep the ability to activate/desactivate the viewer of this version.\n\nContinue?") == false) {
    return
  }

  lockMutate()
}

// Toggle is viewable
const { isPending: toggleIsViewableIsPending, isError: toggleIsViewableIsError, error: toggleIsViewableError, isSuccess: toggleIsViewableIsSuccess, mutate: toggleIsViewableMutate, reset: toggleIsViewableReset } = useMutation({
  mutationFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    const transaction = await props.websiteClient.prepareEnableViewerForWebsiteVersionTransaction(props.websiteVersionIndex, !props.websiteVersion.isViewable);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    await invalidateWebsiteVersionQuery(queryClient, props.contractAddress, props.chainId, props.websiteVersionIndex)
    return await invalidateWebsiteVersionsQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const toggleIsViewable = async () => {
  if(props.websiteVersion.isViewable == false && confirm("You are about to make publicly accessible a non-live version, via a separate web3:// address. It can be useful to preview a change, or to make an historical version accessible. Continue?") == false) {
    return
  }

  if(props.websiteVersion.isViewable && confirm("You are about to disable the web3:// address for this non-live version. Continue?") == false) {
    return
  }

  toggleIsViewableMutate()
}

const viewerAddress = computed(() => {
  if(props.websiteVersion.viewer == "0x0000000000000000000000000000000000000000") {
    return null
  }
  return `web3://${props.websiteVersion.viewer}:${props.chainId}/`
})
</script>

<template>
  <div>
    <div class="website-version">
      <div>
        <PencilSquareIcon v-if="renameIsPending == true" class="anim-pulse" />
        <PlayCircleIcon v-else-if="setLiveIsPending == true" class="anim-pulse" />
        <LockFillIcon v-else-if="lockIsPending == true" class="anim-pulse" />
        <EyeIcon v-else-if="toggleIsViewableIsPending == true && websiteVersion.isViewable == false" class="anim-pulse" />
        <EyeSlashIcon v-else-if="toggleIsViewableIsPending == true && (websiteVersion.isViewable == true)" class="anim-pulse" />
        <span v-else>
          #{{ websiteVersionIndex }} 
        </span>
      </div>
      <div>
        <span v-if="showRenameForm" class="rename-form">
          <input v-model="newDescription" type="text" />
          <button @click="renameWebsiteVersion()" :disabled="renameIsPending" class="sm">Rename</button>
        </span>
        <span v-else class="description">
          <span :class="{'text-muted': renameIsPending}">
            {{ websiteVersion.description }}
          </span>
          <span v-if="renameIsPending">
            <ArrowRightIcon />
          </span>
          <span v-if="renameIsPending">
            {{ newDescription }}
          </span>
          <!-- <span class="text-muted" style="font-size: 0.8em">
            {{ websiteVersion.files.length }} files
          </span> -->
          <LockFillIcon v-if="websiteVersion.locked" />
          <span class="badge" v-if="liveWebsiteVersionLoaded && websiteVersionIndex == liveWebsiteVersionData.websiteVersionIndex">
            Live
          </span>
        </span>
      </div>
      <div class="text-80">
        <a :href="viewerAddress" target="_blank" style="display: flex; max-width: 100%; align-items: center;" v-if="(liveWebsiteVersionLoaded && websiteVersionIndex != liveWebsiteVersionData.websiteVersionIndex) && websiteVersion.isViewable == true">
          <span style="white-space: nowrap; overflow:hidden; text-overflow: ellipsis;">
            {{ viewerAddress }} 
          </span>
          <BoxArrowUpRightIcon style="flex: 0 0 auto; margin-left: 0.5em" />
        </a>
        <span v-else-if="(liveWebsiteVersionLoaded && websiteVersionIndex != liveWebsiteVersionData.websiteVersionIndex) && websiteVersion.isViewable == false" style="margin:auto;">
          <EyeSlashIcon class="text-muted" />
        </span>
      </div>
      <div style="justify-content: right">
        <a @click.stop.prevent="showRenameForm = !showRenameForm; newDescription = websiteVersion.description" class="white" v-if="isGlobalLockedLoaded && isGlobalLocked == false && websiteVersion.locked == false && renameIsPending == false && setLiveIsPending == false && lockIsPending == false && toggleIsViewableIsPending == false">
          <PencilSquareIcon />
        </a>
        <a @click.stop.prevent="setLive()" class="white" v-if="isGlobalLockedLoaded && isGlobalLocked == false && liveWebsiteVersionLoaded && websiteVersionIndex != liveWebsiteVersionData.websiteVersionIndex && renameIsPending == false && setLiveIsPending == false && lockIsPending == false && toggleIsViewableIsPending == false">
          <PlayCircleIcon />
        </a>
        <a @click.stop.prevent="toggleIsViewable()" class="white" v-if="isGlobalLockedLoaded && isGlobalLocked == false && (liveWebsiteVersionLoaded && websiteVersionIndex != liveWebsiteVersionData.websiteVersionIndex) && renameIsPending == false && setLiveIsPending == false && lockIsPending == false && toggleIsViewableIsPending == false">
          <EyeIcon v-if="websiteVersion.isViewable == false" />
          <EyeSlashIcon v-else-if="websiteVersion.isViewable == true" />
        </a>
        <a @click.stop.prevent="lock()" class="white" v-if="isGlobalLockedLoaded && isGlobalLocked == false && websiteVersion.locked == false && renameIsPending == false && setLiveIsPending == false && lockIsPending == false && toggleIsViewableIsPending == false">
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
.website-version {
  display: grid;
  grid-template-columns: minmax(3em, max-content) 3fr minmax(0, 2fr) 1fr;
  padding: 0.5em 0.5em;
  align-items: center;
}

.website-version > div {
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