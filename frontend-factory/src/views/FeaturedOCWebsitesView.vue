<script setup>
import { useAccount } from '@wagmi/vue';
import { computed } from 'vue';

import { useSupportedChains } from '../utils/ethereum.js';
import { useInjectedVariables } from '../../../src/tanstack-vue.js';
import ChainFeaturedOCWebsites from '../components/ChainFeaturedOCWebsites.vue';


const { isConnected } = useAccount();
const { isSuccess: supportedChainsLoaded, data: supportedChains } = useSupportedChains()


// Fetch the list of featured OCWebsite tokenIds per chain
const { isSuccess: injectedVariablesLoaded, data: injectedVariables } = useInjectedVariables()
const featuredOCWebsiteTokenIdsByChain = computed(() => {
  if(injectedVariablesLoaded.value == false || supportedChainsLoaded.value == false) {
    return []
  }

  // Order the supported chains: Put the testnets last
  const orderedSupportedChains = [...supportedChains.value].sort((a, b) => {
    if(a.testnet && !b.testnet) {
      return 1
    } else if(!a.testnet && b.testnet) {
      return -1
    } else {
      return 0
    }
  })

  const result = []
  orderedSupportedChains.forEach(chain => {
    const variable = Object.entries(injectedVariables.value).find(([key, value]) => key == `featured-${chain.shortName}`)
    if (variable === undefined || variable[1] == '') {
      return
    }

    result.push({
      chain,
      tokenIds: variable[1].split(',').map(tokenId => parseInt(tokenId))
    })
  })

  return result
})

</script>


<template>
  <div class="chains-oc-websites">
    
    <h2 style="margin-top: 0; margin-bottom: 0">
      Featured OCWebsites
    </h2>

    <div v-for="featuredOCWebsiteTokenIdsInChain in featuredOCWebsiteTokenIdsByChain" class="chain-oc-websites">
      <h3>
        {{ featuredOCWebsiteTokenIdsInChain.chain.name }} <span v-if="featuredOCWebsiteTokenIdsInChain.chain.testnet">(testnet)</span>
      </h3>
      <ChainFeaturedOCWebsites :chain="featuredOCWebsiteTokenIdsInChain.chain" :tokenIds="featuredOCWebsiteTokenIdsInChain.tokenIds" />
    </div>
  </div>
</template>


<style scoped>

.chains-oc-websites {
  padding: 2em;
  display: flex;
  flex-direction: column;
  gap: 1.5em;
}

.chain-oc-websites h3 {
  margin-top: 0;
  margin-bottom: 0.5em;
}

</style>