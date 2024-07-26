<script setup>
import { computed, ref } from 'vue'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { useQueryClient } from '@tanstack/vue-query'

import { abi as factoryABI } from '../../../src/abi/factoryABI.js';
import { useContractAddresses } from '../utils/queries.js';
import { useSupportedChains } from '../utils/ethereum.js';

defineProps({
  msg: String,
})

const { isConnected, address } = useAccount();
const { switchChainAsync, isPending: switchChainIsPending, error: switchChainError } = useSwitchChain()
const { data: hash, isPending, error, writeContract, reset } = useWriteContract()
const queryClient = useQueryClient()

const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()
const { isSuccess: supportedChainsLoaded, data: supportedChains } = useSupportedChains()

const mintChainId = ref(null);
const factoryAddress = computed(() => contractAddresses.value?.factories.find(f => f.chainId === mintChainId.value)?.address)

const subdomain = ref("");
const subdomainError = computed(() => {
  if(subdomain.value.length == 0) {
    return null
  }
  if (subdomain.value.length < 3) {
    return "Subdomain must be at least 3 characters long"
  }
  if (!/^[a-z0-9-]+$/.test(subdomain.value)) {
    return "Subdomain must only contain lowercase letters, numbers and hyphens"
  }
  return null
})

async function mint() {
  await switchChainAsync({ chainId: mintChainId.value })

  writeContract({ 
    abi: factoryABI,
    address: factoryAddress.value,
    functionName: 'mintWebsite',
    args: [subdomain.value],
  })

  // Unable to find how to call that on transaction reception
  queryClient.invalidateQueries({ queryKey: ['OCWebsiteList', factoryAddress.value, mintChainId.value, address] })
}

const { data: transactionReceipt, isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({ hash })

const newOCWebsiteTokenId = computed(() => {
  if(isConfirmed.value) {
    // Find the Transfer log : keccak256("Transfer(address,address,uint256)")
    const transferTopic = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef";
    const log = transactionReceipt.value.logs.find(l => l.topics[0] == transferTopic)
    return parseInt(log.topics[3], 16)
  }
  return null
})

const newOCWebsiteTokenSVGUrl = computed(() => {
  if(newOCWebsiteTokenId.value) {
    return `web3://${factoryAddress.value}:${mintChainId.value}/tokenSVG/${newOCWebsiteTokenId.value}?mime.type=svg`
  }
  return null
})

const newOCWebsiteAddress = computed(() => {
  if(isConfirmed.value) {
    // Find the WebsiteCreated log : keccak256("WebsiteCreated(uint256,address)")
    const websiteCreatedTopic = "0x0aff572d1069f7e62f493a4df8d35dc160c72a08c2749f1f3a87d08606cb3725";
    const log = transactionReceipt.value.logs.find(l => l.topics[0] == websiteCreatedTopic)
    return "0x" + log.data.substring(26, 66)
  }
  return null
})

const newOCWebsiteWeb3Address = computed(() => {
  if(newOCWebsiteAddress.value) {
    let address = `web3://${newOCWebsiteAddress.value}`
    if(mintChainId.value > 1) {
      address += `:${mintChainId.value}`
    }
    return address;
  }
  return null
})

const resetMintForm = () => {
  subdomain.value = ""
  reset()
}
</script>


<template>
  <div class="main-area">
    <div class="mint-area" v-if="isConfirmed == false">
      <h1>Mint your OCWebsite</h1>

      <div>
        An OCWebsite is a website served by a blockchain, thanks to the <a href="web3://web3url.eth/">web3:// protocol</a>.
        <br />
        Once minted, you can upload files, add/remove plugins, ...
      </div>

      <div class="form">
        <div v-if="isConnected">
          <select v-model="mintChainId" class="chain-selector" :disabled="isPending || isConfirming">
            <option :value="null" disabled>Select a blockchain</option>
            <option v-for="chain in supportedChains" :value="chain.id">{{ chain.name }}</option>
          </select>
        </div>

        <div v-if="isConnected">
          <div class="subdomain-field">
            <input type="text" v-model="subdomain" placeholder="subdomain" :disabled="isPending || isConfirming" maxlength="14" />
            <div class="suffix">
              .{{ mintChainId > 0 ? supportedChains.find(c => c.id == mintChainId).shortName : '<chain>' }}.ocweb.eth
            </div>
          </div>
          <div v-if="subdomainError" class="text-danger text-80">
            {{ subdomainError }}
          </div>
          <div v-else class="text-muted text-80">
            Note: The ocweb.eth subdomain feature is not yet working (waiting for ENS v2), but you can still use your own .eth domain name.
          </div>
        </div>

        <div>
          <button type="button" class="mint-button" @click="mint" 
            :disabled="contractAddressesLoaded == false || supportedChainsLoaded == false || isConnected == false || mintChainId == null || subdomain.length == 0 || subdomainError || isPending || isConfirming">
            {{ (contractAddressesLoaded || supportedChainsLoaded) == false ? "Loading..." : isConnected == false ? "Connect your wallet first" : (isPending || isConfirming) ? "Minting in progress..." : "Mint an OCWebsite" }}
          </button>
        </div>

        <div v-if="isConfirming">
          Waiting for confirmation...
        </div>
        
        <div class="text-danger text-90" v-if="switchChainIsPending == false && switchChainError">
          Switching chain error: {{ switchChainError.shortMessage || switchChainError.message }}
        </div>

        <div class="text-danger text-90" v-if="isPending == false && error">
          Error: {{ error.shortMessage || error.message }}
        </div>
      </div>
    </div>

    <div v-if="isConfirmed" class="transaction-confirmed">
      <h1>Your OCWebsite is ready</h1>
      <div style="margin-bottom: 2em">
        <a class="website-address" target="_blank" :href="newOCWebsiteWeb3Address + '/'">{{ newOCWebsiteWeb3Address }}</a>
      </div>
      <div class="website-infos">
        <div>
          <img :src="newOCWebsiteTokenSVGUrl" />
        </div>
        <div class="website-infos-items">
          <h3>Your OCWebsite is now in your NFT wallet</h3>
          <div>
            The owner of the NFT is the administrator of the website.
          </div>
          <h3>Manage your website</h3> 
          <div>
            Access the admin panel either by :
            <ul>
              <li>Using the <a :href="newOCWebsiteWeb3Address + '/admin/'" target="_blank">/admin/</a> page of your website</li>
              <li>Or going to the <RouterLink to="/">My OCWebsites</RouterLink> section of this website</li>
            </ul>
          </div>
        </div>
      </div>

      <div class="text-muted text-90" style="max-width: 600px; margin: 2em auto 0em auto;">
        The ocweb.eth subdomain feature is not yet working, we are awaiting ENS v2 deployment. You can still use your own .eth domain name.
      </div>
      
      <div class="text-90" style="margin-top: 1em;">
        <a @click.prevent.stop="resetMintForm" href="#">Mint another OCWebsite</a>
      </div>
    </div>
  </div>
</template>


<style scoped>
.main-area {
  text-align: center;
  max-width: 1000px;
}

.form {
  margin-top: 2em;
  display: flex;
  flex-direction: column;
  gap: 1em;
  justify-content: center;
  border: 1px solid var(--color-divider);
  padding: 1em 2em;
  border-radius: 0.5em;
}

.chain-selector {
  font-size: 1em;
}

.subdomain-field {
  display: flex;
  align-items: center;
  justify-content: center;
}

.subdomain-field input {
  border-top-right-radius: 0px;
  border-bottom-right-radius: 0px;
  font-size: 1em;
  max-width: 110px;
}

.subdomain-field .suffix {
  background-color: var(--color-input-bg);
  padding: 0.32em 1em;
  border: 1px solid var(--color-input-border);
  border-left: 0px;
  border-top-right-radius: 8px;
  border-bottom-right-radius: 8px;
}

.mint-button {
  font-size: 1.2em;
}

.transaction-confirmed {

}

.website-address {
  display: inline-block;
  font-family: monospace;
  font-size: 1.75em;
  word-break: break-all;
  border: 1px solid var(--color-divider-secondary);
  background-color: var(--color-input-bg);
  padding: 0.8em 1.3em;
}

.website-infos {
  display: flex;
  gap: 1em;
  justify-content: center;
}

.website-infos-items {
  text-align: left;
}

.website-infos-items h3 {
  margin-top: 0;
  margin-bottom: 0.3em;
}

.website-infos-items div {
  margin-bottom: 1.5em;
}
</style>
