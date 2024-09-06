<script setup>
import { computed, defineProps } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useQueryClient } from '@tanstack/vue-query'
import { useAccount } from '@wagmi/vue';

import { useContractAddresses } from '../../../src/tanstack-vue.js';
import OCWebsite from '../components/OCWebsite.vue';


const props = defineProps({
  chain: {
    type: Object,
    required: true,
  },
})

const queryClient = useQueryClient()
const { address, isConnected } = useAccount();
const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()

// Determine the factory address and chain id for the current chain
const factoryAddress = computed(() => contractAddresses.value?.factories.find(f => f.chainId === props.chain.id)?.address)
const factoryChainId = computed(() => props.chain.id)


// Fetch the OCWebsites owned by the user
const { data: ocWebsites, isSuccess: ocWebsitesLoaded } = useQuery({
  queryKey: ['OCWebsiteOwnedList', factoryAddress, factoryChainId, address],
  queryFn: async () => {
    const response = await fetch(`web3://${factoryAddress.value}:${factoryChainId.value}/detailedTokensOfOwner/${address.value}/0/0?returns=((uint256,address,string,string)[])`)
    if (!response.ok) {
      throw new Error('Network response was not ok')
    }
    const decodedResponse = await response.json()
    const entries = decodedResponse[0].map(([tokenId, contractAddress, subdomain, tokenSVG]) => ({ tokenId: parseInt(tokenId, 16), contractAddress, subdomain, tokenSVG }))

    // Prefill the tanstack cache with the individual entries
    entries.forEach(entry => {
      queryClient.setQueryData(['OCWebsiteDetailedToken', factoryAddress, factoryChainId, entry.tokenId], entry)
    })

    return entries;
  },
  staleTime: 24 * 3600 * 1000,
  enabled: computed(() => contractAddressesLoaded.value && isConnected.value),
})
</script>


<template>
  <div>
    <div v-if="ocWebsitesLoaded == false">
      Loading...
    </div>

    <div v-else-if="ocWebsites.length == 0" class="not-owing-ocwebsites-message">
      You don't have any OCWebsites yet. <RouterLink to="/mint">Mint one</RouterLink>!
    </div>

    <div v-else class="oc-websites">
      <OCWebsite v-for="ocWebsite in ocWebsites" 
        :key="ocWebsite.tokenId" 
        :tokenId="ocWebsite.tokenId" 
        :chainId="factoryChainId" />
    </div>
  </div>
</template>

<style scoped>
.oc-websites {
  display: flex;
  flex-wrap: wrap;
  gap: 2em;
}

@media (max-width: 700px) {
  .oc-websites {
    justify-content: center;
  }
}

</style>