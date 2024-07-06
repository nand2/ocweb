<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';

import { useLiveFrontendVersion, invalidateFrontendVersionQuery } from '../../../utils/queries';
import SettingsProxiedWebsites from './SettingsProxiedWebsites.vue';
import SettingsInjectedVariables from './SettingsInjectedVariables.vue';
import EyeIcon from '../../../icons/EyeIcon.vue';

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
  return props.frontendVersionIndex == liveFrontendVersionData.value.frontendIndex
})

const url = computed(() => {
  if(props.frontendVersion == null || liveFrontendVersionLoaded.value == false) {
    return ''
  }
  if(frontendIsLiveVersion.value) {
    return `web3://${props.contractAddress}${props.chainId > 1 ? ':' + props.chainId : ''}`
  }
  if(props.frontendVersion.isViewable) {
    return `web3://${props.frontendVersion.viewer}${props.chainId > 1 ? ':' + props.chainId : ''}`
  }
  return ''
})

// Temporary hack while I figure out why EVM browser require a trailing slash
const urlWithEndingSlash = computed(() => {
  return url.value.length > 0 && url.value.endsWith('/') == false ? url.value + '/' : url.value
})


// Set isViewable
const { isPending: setIsViewableIsPending, isError: setIsViewableIsError, error: setIsViewableError, isSuccess: setIsViewableIsSuccess, mutate: setIsViewableMutate, reset: setIsViewableReset } = useMutation({
  mutationFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    const transaction = await props.websiteClient.prepareEnableViewerForFrontendVersionTransaction(props.frontendVersionIndex, !props.frontendVersion.isViewable);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    return await invalidateFrontendVersionQuery(queryClient, props.contractAddress, props.chainId, props.frontendVersionIndex)
  }
})
const setIsViewable = async () => {
  setIsViewableMutate()
}
</script>

<template>
  <div>
    <div class="url">
      <span v-if="frontendVersion != null && liveFrontendVersionLoaded && frontendIsLiveVersion == false && frontendVersion.isViewable == false" class="text-muted">
        Version not viewable
      </span>
      <span v-else>
        {{ url }}
      </span>
    </div>
    <div v-if="frontendVersion != null && liveFrontendVersionLoaded && frontendIsLiveVersion == false && frontendVersion.isViewable == false" class="version-not-viewable">
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

.url {
  padding: 0.5em 1em;
  border-bottom: 1px solid #ccc;
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