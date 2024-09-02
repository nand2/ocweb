<script setup>
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { computed } from 'vue';
import { useRouter } from 'vue-router';

import { useInjectedVariables, useContractAddresses } from '../../../src/tanstack-vue.js';
import OCWebsite from '../components/OCWebsite.vue';

const { isConnected, address } = useAccount();
const { isSuccess: injectedVariablesLoaded, data: injectedVariables } = useInjectedVariables()
const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()
const router = useRouter()

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

const goToMintPage = () => {
  
}
</script>

<template>
  <div class="ocweb">
    <h1>Build your <code>web3://</code> onchain website</h1>

    <div class="panels">
      <div>
        <h2>
          <code>web3://</code> protocol
        </h2>
        <div>
          In short, <code>web3://</code> is like <code>https://</code>, but websites are smart contracts, and the blockchain is the server. <a href="web3://web3url.eth" target="_blank">Learn more</a>
        </div>
      </div>
      <div>
        <h2>
          OCWebsites
        </h2>
        <div>
          OCWebsites are <code>web3://</code> websites prepackaged with a plugin system (themes, features, ...) and an admin interface. They appear as NFTs in your wallet.
        </div>
      </div>
    </div>

    <div class="preview-area">
      <h2>
        See for yourself
      </h2>
      <div class="preview-ocwebsites">
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

    <div class="mint-yours">
      <button @click="router.push({ path: '/mint' })" class="lg">Mint your own OCWebsite</button>
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

code {
  font-weight: bold;
}

.panels {
  margin-bottom: 3em;
  display: grid; 
  grid-template-columns: minmax(200px, 400px) minmax(200px, 400px); 
  justify-content: center;
  gap: 50px;
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
  margin-bottom: 3em;
}

.preview-ocwebsites h4 {
  margin-top: 0em;
  margin-bottom: 0.5em;
  text-align: center;
}

.mint-yours {
  text-align: center;
  font-size: 1.2em;
}
</style>