<script setup>
import { computed, defineProps } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useAccount } from '@wagmi/vue';

import { useContractAddresses } from '../../../src/tanstack-vue.js';
import OCWebsite from '../components/OCWebsite.vue';


const props = defineProps({
  chain: {
    type: Object,
    required: true,
  },
  tokenId: {
    type: Array,
    required: true,
  },
})

const { address, isConnected } = useAccount();
const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()

// Determine the factory address and chain id for the current chain
const factoryAddress = computed(() => contractAddresses.value?.factories.find(f => f.chainId === props.chain.id)?.address)
const factoryChainId = computed(() => props.chain.id)


// Fetch the OCWebsites owned by the user
const { data: detailedToken, isSuccess: detailedTokenLoaded } = useQuery({
  queryKey: ['OCWebsiteDetailedTokenById', factoryAddress, factoryChainId, props.tokenId],
  queryFn: async () => {
    const response = await fetch(`web3://${factoryAddress.value}:${factoryChainId.value}/detailedToken/${props.tokenId}?returns=((uint256,address,string))`)
    if (!response.ok) {
      throw new Error('Network response was not ok')
    }
    const decodedResponse = await response.json()
    return { tokenId: parseInt(decodedResponse[0][0], 16), contractAddress: decodedResponse[0][1], subdomain: decodedResponse[0][2] }
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => contractAddressesLoaded.value),
})
</script>


<template>
  <div>
    <div v-if="detailedTokenLoaded == false">
      Loading...
    </div>

    <div v-else>
      <OCWebsite
        :contractAddress="detailedToken.contractAddress" 
        :chainId="factoryChainId"
        :subdomain="detailedToken.subdomain" />
    </div>
  </div>
</template>

<style scoped>
</style>