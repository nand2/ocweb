<script setup>
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { computed } from 'vue';
import { useRouter } from 'vue-router';

import { useInjectedVariables, useContractAddresses } from '../../../src/tanstack-vue.js';
import MintedOCWebsite from '../components/MintedOCWebsite.vue';
import Faq from '../components/utils/Faq.vue';

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

  const [tokenId, chainId] = variable[1].split(':')
  return {
    tokenId: parseInt(tokenId),
    chainId: parseInt(chainId),
  }
})

const faqEntries = [
  {
    question: 'Is <code>web3://</code> a standard?',
    answer: '<p>The <code>web3://</code> protocol is made of several <a href="https://github.com/ethereum/ERCs" target="_blank">Ethereum ERCs</a>, whose aim is to standardize and provide high-quality documentation for the Ethereum application layer.</p><p>The base ERC for <code>web3://</code> is <a href="https://eips.ethereum.org/EIPS/eip-4804" target="_blank">ERC-4804</a> (final). You can find all the others <code>web3://</code> ERCs at <a href="https://docs.web3url.io/web3-url-structure/base#standards" target="_blank">this documentation page</a>.</p>',
  },
  {
    question: 'How does a <code>web3://</code> website work?',
    answer: '<p>A <code>web3://</code> website is a smart contract which advertise a <a href="https://docs.web3url.io/web3-url-structure/resolve-mode" target="_blank"><code>web3://</code> resolve mode</a> and implements some specific methods to reply to browser requests.</p><p>You can experiment with <code>web3://</code> by using the <a href="web3://w3-sandbox.eth/" target="_blank"><code>web3://</code> sandbox</a>.</p>',
  },
  {
    question: 'Can I read any existing smart contract with <code>web3://</code>?',
    answer: '<p>Yes. By default, existing smart contracts are considered as <a href="https://docs.web3url.io/web3-url-structure/resolve-mode/mode-auto" target="_blank">auto <code>web3://</code> resolve mode</a> and you can query its methods.</p><p>You can experiment with this by using the <a href="web3://w3-sandbox.eth/" target="_blank"><code>web3://</code> sandbox</a>.</p>',
  },
  {
    question: 'I am currently accessing this website via a normal <code>https://</code> URL. How come?',
    answer: 'A HTTPS gateway server has been developed to allow users to easily access <code>web3://</code> websites with a normal browser. You can also download a native <code>web3://</code> client, see the <a href="https://docs.web3url.io/" target="_blank">web3:// protocol documentation</a>.',
  },
  {
    question: 'What chains are supported by the <code>web3://</code> protocol?',
    answer: 'The <code>web3://</code> protocol works on all EVM-compatible chains.',
  },
  {
    question: 'Where can I learn more about the web3:// protocol?',
    answer: 'You can go to the <a href="web3://web3url.eth" target="_blank"><code>web3://</code> protocol homepage</a>, to the <a href="https://docs.web3url.io/" target="_blank"><code>web3://</code> documentation</a> and experiment live with the <a href="web3://w3-sandbox.eth/" target="_blank"><code>web3://</code> sandbox</a>.',
  },
  {
    question: "What is the difference between the <code>web3://</code> protocol and OCWebsites?",
    answer: 'The <code>web3://</code> protocol is a standard for accessing websites built on the blockchain, OCWebsites are <code>web3://</code> websites prepackaged with a plugin system and an admin interface. Think <code>https://</code> vs. WordPress.',
  },
  {
    question: "An OCWebsite is a NFT. Are all <code>web3://</code> websites NFTs?",
    answer: 'No. A <code>web3://</code> website is a smart contract, and works without being an NFT. The NFT part is optional and can be useful to manage the ownership of the website.',
  }
]
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
          <MintedOCWebsite
            :tokenId="exampleOCWebsiteInfos.tokenId" 
            :chainId="exampleOCWebsiteInfos.chainId"
            title="Newly minted OCWebsite"
            :isOpened="false"
            :showLinkAndCloseIcons="true" />
        </div>
        <div v-if="contractAddressesLoaded">
          <MintedOCWebsite
            :tokenId="0" 
            :chainId="contractAddresses.self.chainId"
            title="OCWeb.eth itself"
            :isOpened="false"
            :showLinkAndCloseIcons="true" />
        </div>
      </div>
    </div>

    <div class="mint-yours">
      <button @click="router.push({ path: '/mint' })" class="lg">Mint your own OCWebsite</button>
    </div>

    <div class="faq">
      <Faq :entries="faqEntries" />
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

.mint-yours {
  text-align: center;
  font-size: 1.2em;
  margin-bottom: 2em;
}

.faq {
  margin-bottom: 5em;
}
</style>