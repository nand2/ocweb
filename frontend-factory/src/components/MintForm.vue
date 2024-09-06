<script setup>
import { computed, ref } from 'vue'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { useQueryClient } from '@tanstack/vue-query'

import { abi as factoryABI } from '../../../src/abi/factoryABI.js';
import { useContractAddresses } from '../../../src/tanstack-vue.js';
import { useSupportedChains } from '../utils/ethereum.js';
import WalletConnectButton from './utils/WalletConnectButton.vue';

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

const ensDomain = ref("")

async function mint() {
  await switchChainAsync({ chainId: mintChainId.value })

  writeContract({ 
    abi: factoryABI,
    address: factoryAddress.value,
    functionName: 'mintWebsite',
    args: [subdomain.value],
  })

  // Unable to find how to call that on transaction reception
  queryClient.invalidateQueries({ queryKey: ['OCWebsiteOwnedList', factoryAddress.value, mintChainId.value, address] })
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
  ensDomain.value = ""
  reset()
}
</script>


<template>
  <div class="main-area">
    <div class="mint-area" v-if="isConfirmed == false">
      <h1>Mint your OCWebsite</h1>

      <div v-if="isConnected == false" style="margin: 2em;">
        <WalletConnectButton />
      </div>
      <div class="form" v-else>
        <div class="form-field">
          <label>
            Blockchain
          </label>
          <div>
            <select v-model="mintChainId" class="chain-selector" :disabled="isPending || isConfirming">
              <option :value="null" disabled>- select a blockchain -</option>
              <option v-for="chain in supportedChains" :value="chain.id">{{ chain.name + (chain.testnet ? ' (testnet)' : '') }}</option>
            </select>
          </div>
        </div>

        <div class="form-field">
          <label>
            ocweb.eth subdomain
          </label>
          <div>
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
              Note: The ocweb.eth subdomain feature is not yet working (waiting for ENS v2).
            </div>
          </div>
        </div>

        <div class="form-field">
          <label>
            Your ENS domain
            <small>
              (Optional)
            </small>
          </label>
          <div>
            <div class="subdomain-field">
              <input type="text" v-model="ensDomain" placeholder="" :disabled="isPending || isConfirming" maxlength="14" />
              <div class="suffix">
                .eth
              </div>
            </div>
          </div>
        </div>

        <div class="form-field">
          <label>
            Price
          </label>
          <div>
            Free + gas fees
          </div>
        </div>

        <div>
          <button type="button" class="mint-button" @click="mint" 
            :disabled="contractAddressesLoaded == false || supportedChainsLoaded == false || isConnected == false || mintChainId == null || subdomain.length == 0 || subdomainError || isPending || isConfirming">
            {{ (contractAddressesLoaded || supportedChainsLoaded) == false ? "Loading..." : isConnected == false ? "Connect your wallet first" : (isPending || isConfirming) ? "Minting in progress..." : "Mint an OCWebsite" }}
          </button>
        </div>

        <div v-if="isConfirming" class="waiting-for-confirmation">
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
              <li>Using the <a :href="newOCWebsiteWeb3Address + '/admin'" target="_blank">/admin</a> page of your website</li>
              <li>Or going to the <RouterLink to="/my-ocwebsites">My OCWebsites</RouterLink> section of this website</li>
            </ul>
          </div>
        </div>
      </div>

      <div v-if="ensDomain" style="max-width: 800px; margin: 2em auto 0em auto;">
        <div class="website-address" style="font-size: 1.3em; margin-bottom: 1em; padding: 0.4em 0.8em;">
          web3://{{ ensDomain.endsWith('.eth') ? ensDomain : ensDomain + '.eth' }}
        </div>
        <div>
          To use your own ENS domain name, follow the instructions in the Settings tab of <a :href="newOCWebsiteWeb3Address + '/admin'" target="_blank">your admin panel</a>
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
  margin-left: 1em;
  margin-right: 1em;
}

.form {
  margin-top: 2em;
  display: flex;
  flex-direction: column;
  gap: 1em;
  justify-content: center;
  border: 1px solid var(--color-divider);
  padding: 2em 2em;
  border-radius: 0.5em;
}

.form-field {
  display: flex;
  gap: 1em;
  align-items: center;
}
@media (max-width: 700px) {
  .form-field {
    flex-direction: column;
    gap: 0.5em;
  }
}

.form-field label {
  flex: 0 0 25%;
  text-align: right;
  font-weight: bold;
  line-height: 1.2em;
}

.form-field label small {
  font-weight: normal;
  font-size: 0.8em;
  color: var(--color-text-muted);
}

.chain-selector {
  font-size: 1em;
}

.subdomain-field {
  display: flex;
  align-items: center;
}
@media (max-width: 700px) {
  .subdomain-field {
    flex-direction: column;
  }
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

.waiting-for-confirmation {
  font-size: 1.2em;
  animation: loading 1.5s infinite;
}
@keyframes loading {
  0% {
    opacity: 0.6;
  }
  50% {
    opacity: 1;
  }
  100% {
    opacity: 0.6;
  }
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

@media (max-width: 700px) {
  .website-infos {
    flex-direction: column;
  }
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
