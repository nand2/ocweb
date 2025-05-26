<script setup>
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt, useConnectorClient } from '@wagmi/vue';

import { useContractAddresses, invalidateWebsiteVersionQuery, invalidateWebsiteVersionsQuery, useWebsiteVersionPlugins, useLiveWebsiteVersion, useWebsiteVersions, useIsLocked } from '../../../../../../src/tanstack-vue';
import ExclamationTriangleIcon from '../../../../icons/ExclamationTriangleIcon.vue';
import EyeIcon from '../../../../icons/EyeIcon.vue';

const props = defineProps({
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
  websiteVersion: {
    type: Object,
    required: true
  },
  websiteVersionIndex: {
    type: Number,
    required: true,
  },
  websiteClient: {
    type: Object,
    required: true,
  },
})

const queryClient = useQueryClient()
const { switchChainAsync } = useSwitchChain()

// Fetch the live website infos
const { data: liveWebsiteVersionData, isLoading: liveWebsiteVersionLoading, isFetching: liveWebsiteVersionFetching, isError: liveWebsiteVersionIsError, error: liveWebsiteVersionError, isSuccess: liveWebsiteVersionLoaded } = useLiveWebsiteVersion(queryClient, props.contractAddress, props.chainId)

// Get the lock status
const { data: isLocked, isLoading: isLockedLoading, isFetching: isLockedFetching, isError: isLockedIsError, error: isLockedError, isSuccess: isLockedLoaded } = useIsLocked(props.contractAddress, props.chainId)

// A list of chain short names (unfortunately not packaged with Viem)
// Infos from https://chainid.network/chains.json
const chainShortNames = {
  1: 'eth',
  11155111: 'sep',
  17000: 'holesky',
  10: 'oeth',
  11155420: 'opsep',
  42161: 'arb1',
  42170: 'arb-nova',
  421614: 'arb-sep',
  8543: 'base',
  85432: 'basesep',
  31337: 'hardhat'
}


// Set isViewable
const { isPending: setIsViewableIsPending, isError: setIsViewableIsError, error: setIsViewableError, isSuccess: setIsViewableIsSuccess, mutate: setIsViewableMutate, reset: setIsViewableReset } = useMutation({
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
const setIsViewable = async () => {
  setIsViewableMutate()
}
</script>

<template>
  <div class="title">
    Website address
    <small class="text-muted" style="font-weight: normal; font-size:0.7em;">
      Ways to access your website
    </small>
  </div>

  <div v-if="liveWebsiteVersionLoaded && liveWebsiteVersionData.websiteVersionIndex == websiteVersionIndex">
    <div class="text-90" style="font-weight: bold;">
      Default <code>web3://</code> address
    </div>
    <div>
      <code style="word-break: break-all;">web3://{{ contractAddress }}{{ chainId > 1 ? ':' + chainId : '' }}</code>
    </div>
    
    <div v-if="chainShortNames[chainId]" style="margin-top: 1em;">
      <div style="font-size: 0.9em; font-weight: bold; margin-bottom: 0.2em">
        Using your own ENS domain name
      </div>

      <div class="text-90" style="margin-bottom: 0.7em">
        To access this website with <code style="font-weight: bold;">web3://my-domain.eth</code>, edit <code style="font-weight: bold;">my-domain.eth</code> in the official ENS app, and add the following Text Record:
      </div>

      <div class="table-header">
        <div>
          Text Record Name
        </div>
        <div>
          Text Record Value
        </div>
      </div>

      <div class="table-row">
        <div>
          <code>
            contentcontract
          </code>
        </div>
        <div>
          <code>
            {{ chainShortNames[chainId] }}:{{ contractAddress }}
          </code>
        </div>
      </div>
    </div>

    <div class="text-90" style="font-weight: bold; margin-top: 1em;">
      Using a general purpose <code>web3://</code> HTTPS gateway
    </div>
    <div style="margin-bottom: 0.2em">
      <code style="word-break: break-all;">https://{{ contractAddress }}.{{ chainId }}.<span class="text-muted">gateway-domain.tld</span></code>
    </div>
    <div class="text-90">
      Known <code>web3://</code> gateways:
    </div>
    <div>
      <ul style="margin:0">
        <li>
          <code style="word-break: break-all;">
            <a :href="`https://${contractAddress}.${chainId}.web3gateway.dev`" target="_blank">
              https://{{ contractAddress }}.{{ chainId }}.web3gateway.dev
            </a>
          </code>
        </li>
      </ul>
    </div>

    <div class="text-90" style="font-weight: bold; margin-top: 1em; margin-bottom: 0.2em">
      Using your own DNS domain name
    </div>
    <div class="text-90">
      To access this website with <code style="font-weight: bold;">https://my-domain.tld</code>, you can host your own <code>web3://</code> HTTPS gateway (such as <a href="https://github.com/web3-protocol/web3protocol-http-gateway-js" target="_blank">web3protocol-http-gateway</a>), and point your DNS domain name to it.
    </div>

  </div>

  
  <div v-else>
    <div class="text-90" style="margin-bottom: 0.5em">
      This website version is not the live version.
    </div>

    <div v-if="websiteVersion.isViewable == false">
      <div class="text-90" style="margin-bottom: 0.5em">
        The website version is not viewable. 
        <span v-if="isLockedLoaded && isLocked == false">
          You can make it viewable: it will have its own separate <code>web3://</code> URL, and you can disable it later anytime (unless you activate the global lock).
        </span>
      </div>

      <div v-if="isLockedLoaded && isLocked == false">
        <div class="text-90 text-warning" style="margin-bottom: 0.5em">
          <ExclamationTriangleIcon /> Don't store private data, even in a non-viewable version: All data in a blockchain can be read one way or another.
        </div>
        <div style="text-align: center;">
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
    <div v-else>
      <div class="text-90" style="font-weight: bold;">
        Website version <code>web3://</code> address
      </div>
      <div>
        <code>web3://{{ websiteVersion.viewer }}{{ chainId > 1 ? ':' + chainId : '' }}</code>
      </div>
    </div>
  </div>
</template>

<style scoped>
.title {
  font-size: 1.1em;
  font-weight: bold;
  margin-bottom: 0.75em;
}

.table-header,
.table-row {
  grid-template-columns: 1fr 3fr;
}

.mutation-error {
  margin-top: 0.25em;
}
</style>