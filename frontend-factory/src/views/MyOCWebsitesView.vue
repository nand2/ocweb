<script setup>
import { useAccount } from '@wagmi/vue';
import { computed } from 'vue';

import { useSupportedChains } from '../utils/ethereum.js';
import ChainOCWebsites from '../components/ChainMyOCWebsites.vue';


const { isConnected } = useAccount();
const { isSuccess: supportedChainsLoaded, data: supportedChains } = useSupportedChains()

// Order the supported chains: Put the testnets last
const orderedSupportedChains = computed(() => {
  if(supportedChainsLoaded.value == false) {
    return []
  }

  return [...supportedChains.value].sort((a, b) => {
    if(a.testnet && !b.testnet) {
      return 1
    } else if(!a.testnet && b.testnet) {
      return -1
    } else {
      return 0
    }
  })
})
</script>


<template>
  <div class="my-websites">
    <div v-if="isConnected == false" class="please-connect-wallet-message">
      Please connect your wallet
    </div>

    <div v-else-if="supportedChainsLoaded == false">
      Loading...
    </div>

    <div v-else class="chains-oc-websites">
      
      <h2 style="margin-top: 0; margin-bottom: 0">
        My OCWebsites
      </h2>

      <div v-for="chain in orderedSupportedChains" :key="chain.id" class="chain-oc-websites">
        <h3>
          {{ chain.name }} <span v-if="chain.testnet">(testnet)</span>
        </h3>
        <ChainOCWebsites :chain="chain" />
      </div>
    </div>
  </div>
</template>


<style scoped>
.my-websites {
  padding: 2em;
}

.please-connect-wallet-message {
  margin-top: 20vh;
  text-align: center;
}

.chains-oc-websites {
  display: flex;
  flex-direction: column;
  gap: 1.5em;
}

.chain-oc-websites h3 {
  margin-top: 0;
  margin-bottom: 0.5em;
}

</style>