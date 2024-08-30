<script setup>
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { computed } from 'vue';

import { useInjectedVariables, useContractAddresses } from '../../../src/tanstack-vue.js';
import OCWebsite from '../components/OCWebsite.vue';

const { isConnected, address } = useAccount();
const { isSuccess: injectedVariablesLoaded, data: injectedVariables } = useInjectedVariables()
const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()

const exampleOCWebsiteInfos = computed(() => {
  if (injectedVariablesLoaded.value == false) {
    return null
  }
  
  const variable = Object.entries(injectedVariables.value).find(([key, value]) => key == 'ocwebsite-example')
  if (variable === undefined || variable[1] == '') {
    return null
  }

  const [address, chainId] = variable[1].split(':')
  return {
    address,
    chainId: parseInt(chainId),
  }
})
</script>

<template>
  <div class="ocweb">
    <h1>Build your own web3:// onchain website</h1>

    <div class="panels">
      <div>
        <h2>
          web3:// protocol
        </h2>
        <div>
          In short, <a href="web3://web3url.eth" target="_blank"><code style="font-weight: bold;">web3://</code></a> is like <code style="font-weight: bold;">https://</code>, but websites are smart contracts, and the blockchain is the server.
        </div>
      </div>
      <div>
        <h2>
          OCWebsites
        </h2>
        <div>
          OCWebsites are web3:// websites prepackaged with plugins (themes, features, ...) and an admin interface.
        </div>
      </div>
    </div>

    <div class="preview-area">
      <h2>
        See for yourself
      </h2>

      <div v-if="isConnected == false" style="text-align: center;">
        Connect your wallet to see the admin interface of example OCWebsites.
      </div>
      <div v-else class="preview-ocwebsites">
        <div v-if="exampleOCWebsiteInfos">
          <h4>Newly minted OCWebsite</h4>
          <OCWebsite
            :contractAddress="exampleOCWebsiteInfos.address" 
            :chainId="exampleOCWebsiteInfos.chainId"
            subdomain="example"
            :isOpened="false"
            :showLinkAndCloseIcons="true" />
        </div>
        <div v-if="contractAddressesLoaded">
          <h4>OCWeb.eth itself</h4>
          <OCWebsite
            :contractAddress="contractAddresses.self.address" 
            :chainId="contractAddresses.self.chainId"
            subdomain="factory"
            :isOpened="false"
            :showLinkAndCloseIcons="true" />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.ocweb {
  margin: 0em 2em;
}

h1 {
  text-align: center;
  margin-top: 2em;
  margin-bottom: 1.5em;
}

h2 {
  margin-top: 0;
  margin-bottom: 0.5em;
}

.panels {
  margin-bottom: 3em;
  display: grid; 
  grid-template-columns: 1fr 1fr; 
  gap: 2em;
  text-align: center;
}
@media (max-width: 700px) {
  .panels {
    grid-template-columns: 1fr;
  }
}


.preview-area h2 {
  text-align: center;
}

.preview-area .ocwebsite {
  margin: auto;
}

.preview-ocwebsites {
  display: flex;
  gap: 2em;
  justify-content: center;
  flex-wrap: wrap;
}

.preview-ocwebsites h4 {
  margin-top: 0em;
  margin-bottom: 0.5em;
  text-align: center;
}
</style>