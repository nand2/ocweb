<script setup>
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { useContractAddresses, useOCWebsiteListByOwner } from '../utils/queries.js';
import OCWebsite from '../components/OCWebsite.vue';

const { isConnected, chainId, address } = useAccount();

// Fetch the contract addresses
// const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()

// Fetch the OCWebsites owned by the user
const { data: ocWebsites, isSuccess: ocWebsitesLoaded } = useOCWebsiteListByOwner()

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
    <OCWebsite v-for="ocWebsite in ocWebsites" :key="ocWebsite.tokenId" :tokenId="ocWebsite.tokenId" :contractAddress="ocWebsite.contractAddress" />
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
    gap: 1em;
    padding: 2em;
  }
</style>