<script setup>
import { computed, defineProps } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useAccount } from '@wagmi/vue';

import { useContractAddresses } from '../utils/queries.js';
import OCWebsite from '../components/OCWebsite.vue';


const props = defineProps({
  chain: {
    type: Object,
    required: true,
  },
})

const { address, isConnected } = useAccount();
const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()

// Determine the factory address and chain id for the current chain
const factoryAddress = computed(() => contractAddresses.value?.factories.find(f => f.chainId === props.chain.id)?.address)
const factoryChainId = computed(() => props.chain.id)


// Fetch the OCWebsites owned by the user
const { data: ocWebsites, isSuccess: ocWebsitesLoaded } = useQuery({
  queryKey: ['OCWebsiteList', factoryAddress, factoryChainId, address],
  queryFn: async () => {
    const response = await fetch(`web3://${factoryAddress.value}:${factoryChainId.value}/detailedTokensOfOwner/${address.value}?returns=((uint256,address)[])`)
    if (!response.ok) {
      throw new Error('Network response was not ok')
    }
    const decodedResponse = await response.json()
    return decodedResponse[0].map(([tokenId, contractAddress]) => ({ tokenId: parseInt(tokenId, 16), contractAddress }))
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => contractAddressesLoaded.value && isConnected.value),
})
</script>


<template>
  <div v-if="ocWebsitesLoaded == false">
    Loading...
  </div>

  <div v-else-if="ocWebsites.length == 0" class="not-owing-ocwebsites-message">
    You don't have any OCWebsite yet. <RouterLink to="/mint">Mint one</RouterLink>!
  </div>

  <div v-else class="oc-websites">
    <OCWebsite v-for="ocWebsite in ocWebsites" :key="ocWebsite.tokenId" :tokenId="ocWebsite.tokenId" :contractAddress="ocWebsite.contractAddress" :chainId="31337" />
  </div>
</template>

<style scoped>
.oc-websites {
  display: flex;
  flex-wrap: wrap;
  gap: 2em;
}
</style>