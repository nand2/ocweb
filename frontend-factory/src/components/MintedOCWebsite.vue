<script setup>
import { ref, computed, defineProps } from 'vue';
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { useQuery } from '@tanstack/vue-query'

import { useContractAddresses } from '../../../src/tanstack-vue.js';
import OCWebsiteEditor from './websiteEditor/OCWebsiteEditor.vue';
import WalletConnectModal from './utils/WalletConnectModal.vue';
import XCircleIcon from '../icons/XCircleIcon.vue';
import CopyIcon from '../icons/CopyIcon.vue';
import BoxArrowUpRightIcon from '../icons/BoxArrowUpRightIcon.vue';
import OCWebsite from './OCWebsite.vue';


const props = defineProps({
  tokenId: {
    type: Number,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
  title: {
    type: String,
    default: null,
  },
  isOpened: {
    type: Boolean,
    default: false,
  },
  showLinkAndCloseIcons: {
    type: Boolean,
    default: true,
  },
})
const isOpened = ref(props.isOpened)

const { isConnected, address } = useAccount();
const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()

const factoryAddress = computed(() => contractAddresses.value?.factories.find(f => f.chainId === props.chainId)?.address)

// Fetch the details of the token (contract address, subdomain, SVG)
const { data: detailedToken, isSuccess: detailedTokenLoaded, error: detailedTokenError } = useQuery({
  queryKey: ['OCWebsiteDetailedToken', factoryAddress, props.chainId, props.tokenId],
  queryFn: async () => {
    const response = await fetch(`web3://${factoryAddress.value}:${props.chainId}/detailedToken/${props.tokenId}?returns=((uint256,address,string,string))`)
    if (!response.ok) {
      throw new Error('Network response was not ok')
    }
    const decodedResponse = await response.json()
    return { tokenId: parseInt(decodedResponse[0][0], 16), contractAddress: decodedResponse[0][1], subdomain: decodedResponse[0][2], tokenSVG: decodedResponse[0][3] }
  },
  staleTime: 24 * 3600 * 1000,
  enabled: computed(() => contractAddressesLoaded.value),
})

</script>

<template>
  <OCWebsite
    v-if="detailedTokenLoaded"
    :contractAddress="detailedToken.contractAddress"
    :chainId
    :backgroundSVG="detailedToken.tokenSVG"
    :title
    :isOpened
    :showLinkAndCloseIcons
    />

</template>


<style scoped>


</style>