<script setup>
import { useAccount } from '@wagmi/vue';
import { computed } from 'vue';
import { useQuery } from '@tanstack/vue-query'
const { parse: parseYaml } = await import('yaml')

import { useSupportedChains } from '../utils/ethereum.js';
import { useInjectedVariables } from '../../../src/tanstack-vue.js';
import OCWebsite from '../components/OCWebsite.vue';


const { isConnected } = useAccount();
const { isSuccess: supportedChainsLoaded, data: supportedChains } = useSupportedChains()


// Fetch the list of featured OCWebsite tokenIds per chain
const { isSuccess: featuredOCWebsitesLoaded, data: featuredOCWebsites } = useQuery({
  queryKey: ['featuredOCWebsites'],
  queryFn: async () => {
    const response = await fetch('./config/featured.yml')
    if (!response.ok) {
      throw new Error('Network response was not ok')
    }
    const decodedResponse = parseYaml(await response.text())
    return decodedResponse
  },
  staleTime: 24 * 3600 * 1000,
})
</script>


<template>
  <div class="featured-oc-websites">
    
    <h2 style="margin-top: 0; margin-bottom: 0">
      Featured OCWebsites
    </h2>

    <div v-if="featuredOCWebsitesLoaded == false" style="text-align: center; margin: 2em;">
      Loading featured OCWebsites...
    </div>

    <div v-else class="oc-websites">
      <div class="oc-website" v-for="featuredOCWebsite in featuredOCWebsites" :key="featuredOCWebsite.tokenId">
        <OCWebsite
          :chainId="featuredOCWebsite.chainId" 
          :tokenId="featuredOCWebsite.tokenId"
          :title="featuredOCWebsite.title" />
      </div>
    </div>
  </div>
</template>


<style scoped>

.featured-oc-websites {
  padding: 2em;
  display: flex;
  flex-direction: column;
  gap: 1.5em;
}


.oc-websites {
  display: flex;
  flex-wrap: wrap;
  gap: 2em;
}


</style>