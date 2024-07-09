<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';

import { useLiveFrontendVersion, invalidateFrontendVersionQuery, useFrontendVersionsViewer, invalidateFrontendVersionsViewerQuery } from '../../../utils/queries';
import SettingsProxiedWebsites from './SettingsProxiedWebsites.vue';
import SettingsInjectedVariables from './SettingsInjectedVariables.vue';
import EyeIcon from '../../../icons/EyeIcon.vue';
import BoxArrowUpRightIcon from '../../../icons/BoxArrowUpRightIcon.vue';
import CopyIcon from '../../../icons/CopyIcon.vue';

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
const { switchChainAsync } = useSwitchChain()

// Fetch the live frontend infos
const { data: liveFrontendVersionData, isLoading: liveFrontendVersionLoading, isFetching: liveFrontendVersionFetching, isError: liveFrontendVersionIsError, error: liveFrontendVersionError, isSuccess: liveFrontendVersionLoaded } = useLiveFrontendVersion(queryClient, props.contractAddress, props.chainId)

const frontendIsLiveVersion = computed(() => {
  return liveFrontendVersionLoaded.value && props.frontendVersionIndex == liveFrontendVersionData.value.frontendIndex
})

// Get the list of frontend versions viewer
const { data: frontendVersionsViewer, isLoading: frontendVersionsViewerLoading, isFetching: frontendVersionsViewerFetching, isError: frontendVersionsViewerIsError, error: frontendVersionsViewerError, isSuccess: frontendVersionsViewerLoaded } = useFrontendVersionsViewer( props.contractAddress, props.chainId)

const url = computed(() => {
  if(props.frontendVersion == null || liveFrontendVersionLoaded.value == false || frontendVersionsViewerLoaded.value == false) {
    return ''
  }
  if(frontendIsLiveVersion.value) {
    return `web3://${props.contractAddress}${props.chainId > 1 ? ':' + props.chainId : ''}`
  }
  if(frontendVersionsViewer.value[props.frontendVersionIndex].isViewable) {
    return `web3://${frontendVersionsViewer.value[props.frontendVersionIndex].viewer}${props.chainId > 1 ? ':' + props.chainId : ''}`
  }
  return ''
})

// Temporary hack while I figure out why EVM browser require a trailing slash
const urlWithEndingSlash = computed(() => {
  return url.value.length > 0 && url.value.endsWith('/') == false ? url.value + '/' : url.value
})

// Copy the web3 address to the clipboard
const showCopiedIndicator = ref(false)
function copyWeb3AddressToClipboard() {
  navigator.clipboard.writeText(url.value)

  // Show a success message
  showCopiedIndicator.value = true
  setTimeout(() => {
    showCopiedIndicator.value = false
  }, 1000)
}


// Set isViewable
const { isPending: setIsViewableIsPending, isError: setIsViewableIsError, error: setIsViewableError, isSuccess: setIsViewableIsSuccess, mutate: setIsViewableMutate, reset: setIsViewableReset } = useMutation({
  mutationFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    const transaction = await props.websiteClient.prepareEnableViewerForFrontendVersionTransaction(props.frontendVersionIndex, !frontendVersionsViewer.value[props.frontendVersionIndex].isViewable);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    return await invalidateFrontendVersionsViewerQuery(queryClient, props.contractAddress, props.chainId)
  }
})
const setIsViewable = async () => {
  setIsViewableMutate()
}
</script>

<template>
  <div>
    <div class="url-bar" v-if="frontendIsLiveVersion == false">
      <span v-if="frontendVersion != null && liveFrontendVersionLoaded && frontendVersionsViewerLoaded && frontendVersionsViewer[frontendVersionIndex].isViewable == false" class="text-muted" style="display: block; padding: 0.5em 1em;">
        Version not viewable
      </span>
      <div v-else-if="frontendVersion != null && frontendVersionsViewerLoaded && frontendVersionsViewer[frontendVersionIndex].isViewable == true" class="url-bar-with-url">
        <a @click.stop.prevent="copyWeb3AddressToClipboard()" :class="{'url': true, copied: showCopiedIndicator}">
          {{ url }}
          <CopyIcon />
          <span class="copy-indicator">
            Copied!
          </span>
        </a>
        <a :href="urlWithEndingSlash" target="_blank" class="white header-icon">
          <BoxArrowUpRightIcon />
        </a>
      </div>
    </div>
    <div v-if="frontendVersion != null && liveFrontendVersionLoaded && frontendIsLiveVersion == false && frontendVersionsViewerLoaded && frontendVersionsViewer[frontendVersionIndex].isViewable == false" class="version-not-viewable">
      <div style="padding: 1em; text-align: center; max-width: 70%;">
        <div style="font-weight: bold; margin-bottom: 0.5em;">
          Version not viewable
        </div>
        <div class="text-90">
          You need to make this version publicly viewable in order to preview it.
        </div>
        <div class="text-90">
          It will have its own separate web3:// URL, and you can disable it later anytime (unless you activate the global lock).
        </div>
        <div style="margin-top: 1em;">
          <button @click="setIsViewable" :disabled="setIsViewableIsPending">
            <EyeIcon :class="{'anim-pulse': setIsViewableIsPending}" />
            Make it viewable
          </button>
          <div v-if="setIsViewableIsError" class="mutation-error">
          <span>
            Error enabling visibility: {{ setIsViewableError.shortMessage || setIsViewableError.message }} <a @click.stop.prevent="setIsViewableReset()">Hide</a>
          </span>
        </div>
        </div>
      </div>
    </div>
    <iframe
      v-else-if="frontendVersion != null && liveFrontendVersionLoaded"
      ref="iframe"
      class="preview"
      :src="urlWithEndingSlash" />
  </div>
</template>

<style scoped>
.url-bar {
  border-bottom: 1px solid #ccc;
  background-color: var(--color-root-bg);
}

.url-bar-with-url {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.url {
  display: block;
  padding: 0.5em 1em;
  color: var(--color-text);
  transition: color 0.25s;
  position: relative;
}

.url:hover {
  background-color: rgba(0, 0, 0, 0.2);
}

.url .copy-indicator {
  color: var(--color-text);
  position: absolute;
  left: 50%;
  opacity: 0;
  transition: opacity 0.25s;
}

.url.copied {
  color: transparent;
  transition: color 0.25s;
}

.url.copied .copy-indicator {
  opacity: 1;
  transition: opacity 0.25s;
}

.url-bar-with-url .header-icon {
  padding: 0.25em 0.75em;
  line-height: 1em;
}

.url-bar-with-url .header-icon svg {
  height: 20px;
  width: 20px;
  cursor: pointer;
}

.preview {
  display: block;
  width: calc(100% - 4px);
  height: 400px;
  border: 2px solid #ccc;
}

.version-not-viewable {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 404px;
}

.mutation-error {
  padding-top: 0.2em;
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