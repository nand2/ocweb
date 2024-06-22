<script setup>
import { computed } from 'vue';
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { useQuery } from '@tanstack/vue-query'
import { useContractAddresses } from '../utils/queries.js';
import OCWebsite from '../components/OCWebsite.vue';


const { isConnected, address } = useAccount();
const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()

const factoryAddress = computed(() => contractAddresses.value?.factories[0].address)

// Fetch the OCWebsites owned by the user
const { data: ocWebsites, isSuccess: ocWebsitesLoaded } =  useQuery({
  queryKey: ['OCWebsiteList', factoryAddress, address],
  queryFn: async () => {
    const response = await fetch(`web3://${factoryAddress.value}:31337/detailedTokensOfOwner/${address.value}?returns=((uint256,address)[])`)
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
  <div v-if="isConnected == false" class="please-connect-wallet-message">
    Please connect your wallet
  </div>

  <div v-else-if="ocWebsitesLoaded == false">
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
.please-connect-wallet-message, .not-owing-ocwebsites-message {
  margin-top: 20vh;
  text-align: center;
}

.oc-websites {
  display: flex;
  flex-wrap: wrap;
  gap: 2em;
  padding: 2em;
}
</style>