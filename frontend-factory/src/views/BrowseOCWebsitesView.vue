<script setup>
import { useAccount } from '@wagmi/vue';
import { computed, watch, ref } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useQueryClient } from '@tanstack/vue-query'

import { useSupportedChains } from '../utils/ethereum.js';
import { useContractAddresses } from '../../../src/tanstack-vue.js';
import ChainOCWebsites from '../components/ChainMyOCWebsites.vue';
import MintedOCWebsite from '../components/MintedOCWebsite.vue';


const { isConnected } = useAccount();
const queryClient = useQueryClient()
const { isSuccess: supportedChainsLoaded, data: supportedChains } = useSupportedChains()
const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()



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

const browsedChainId = ref(supportedChainsLoaded.value ? supportedChains.value[0].id : null)
watch(supportedChainsLoaded, () => {
  browsedChainId.value = supportedChainsLoaded ? supportedChains.value[0].id : null
})

// Determine the factory address and chain id for the current chain
const browsedChainFactoryAddress = computed(() => {
  if(browsedChainId.value == null || contractAddressesLoaded.value == false) {
    return null
  }

  return contractAddresses.value.factories.find(f => f.chainId === browsedChainId.value).address
})

// Determine the size of the OCWebsite collection for the browsed chain
const { isSuccess: chainOCWebsiteCollectionLengthLoaded, data: chainOCWebsiteCollectionLength } = useQuery({
  queryKey: ['chainOCWebsiteCollectionLength', browsedChainId],
  queryFn: async () => {
    const response = await fetch(`web3://${browsedChainFactoryAddress.value}:${browsedChainId.value}/totalSupply?returns=(uint256)`)
    if (!response.ok) {
      throw new Error('Network response was not ok')
    }
    const decodedResponse = await response.json()
    return parseInt(decodedResponse[0], 16)
  },
  enabled: computed(() => browsedChainId.value > 0 && browsedChainFactoryAddress.value != null),
  // staleTime: 3600 * 1000,
})

const numberPerPage = 10;
const page = ref(1);

const startTokenId = computed(() => (page.value - 1) * numberPerPage)

// Get the detailed tokens for the current page
// (Prefetch all infos in one go, more efficient)
const { data: ocWebsites, isSuccess: ocWebsitesLoaded } = useQuery({
  queryKey: ['OCWebsiteList', browsedChainFactoryAddress, browsedChainId.value, startTokenId],
  queryFn: async () => {
    const response = await fetch(`web3://${browsedChainFactoryAddress.value}:${browsedChainId.value}/detailedTokens/${startTokenId.value}/${numberPerPage}?returns=((uint256,address,string,string)[])`)
    if (!response.ok) {
      throw new Error('Network response was not ok')
    }
    const decodedResponse = await response.json()
    const entries = decodedResponse[0].map(([tokenId, contractAddress, subdomain, tokenSVG]) => ({ tokenId: parseInt(tokenId, 16), contractAddress, subdomain, tokenSVG }))

    // Prefill the tanstack cache with the individual entries
    entries.forEach(entry => {
      queryClient.setQueryData(['OCWebsiteDetailedToken', browsedChainFactoryAddress.value, browsedChainId.value, entry.tokenId], entry)
    })

    return entries;
  },
  staleTime: 24 * 3600 * 1000,
  enabled: computed(() => chainOCWebsiteCollectionLengthLoaded.value),
})

</script>


<template>
  <div class="browse-area">
      
    <h2 style="margin-top: 0; margin-bottom: 1em">
      Browse OCWebsites
    </h2>

    <div v-if="supportedChainsLoaded == false">
      Loading...
    </div>

    <div v-else>

      <div class="chain-selector">
        <div v-for="chain in orderedSupportedChains" :key="chain.id" class="chain" :class="{selected: chain.id == browsedChainId}" @click.stop.prevent="browsedChainId = chain.id; page = 1">
          {{ chain.name }} <span v-if="chain.testnet">(testnet)</span>
        </div>
      </div>

      <div v-if="ocWebsitesLoaded == false">
        Loading...
      </div>
      <div v-else class="oc-websites">
        <MintedOCWebsite
          v-for="ocWebsite in ocWebsites"
          :key="ocWebsite.tokenId"
          :chainId="browsedChainId"
          :tokenId="ocWebsite.tokenId"
        />

      </div>

      <div class="pager">
        <button @click="page--" :disabled="page == 1">Previous</button>
        <div>Page {{ page }} / {{ Math.ceil(chainOCWebsiteCollectionLength / numberPerPage) }}</div>
        <button @click="page++" :disabled="page * numberPerPage >= chainOCWebsiteCollectionLength">Next</button>
      </div>
    </div>
  </div>
</template>


<style scoped>
.browse-area {
  padding: 2em;
}

.chain-selector {
  display: flex;
  flex-wrap: wrap;
  border: 1px solid var(--color-divider);
  margin-bottom: 2em;
}

.chain-selector .chain {
  cursor: pointer;
  padding: 0.5em 1em;
}

.chain-selector .chain.selected {
  border-bottom: 3px solid var(--color-primary);
  color: white;
}

.oc-websites {
  display: flex;
  flex-wrap: wrap;
  gap: 2em;
  margin-bottom: 2em;
}
@media (max-width: 700px) {
  .oc-websites {
    justify-content: center;
  }
}

.pager {
  display: flex;
  gap: 1em;
  justify-content: center;
  align-items: center
}
</style>