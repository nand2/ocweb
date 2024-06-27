<script setup>
import { computed, ref } from 'vue'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { useQueryClient } from '@tanstack/vue-query'

import { abi as FactoryABI } from '../utils/factoryABI.js';
import { useContractAddresses } from '../utils/queries.js';
import { useSupportedChains } from '../utils/ethereum.js';

defineProps({
  msg: String,
})

const { isConnected, address } = useAccount();
const { switchChainAsync, isPending: switchChainIsPending, error: switchChainError } = useSwitchChain()
const { data: hash, isPending, error, writeContract } = useWriteContract()
const queryClient = useQueryClient()

const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()
const { isSuccess: supportedChainsLoaded, data: supportedChains } = useSupportedChains()

const mintChainId = ref(null);
const factoryAddress = computed(() => contractAddresses.value?.factories.find(f => f.chainId === mintChainId.value)?.address)

async function mint() {
  await switchChainAsync({ chainId: mintChainId.value })

  writeContract({ 
    abi: FactoryABI,
    address: factoryAddress.value,
    functionName: 'mintWebsite',
    args: ["0x0000000000000000000000000000000000000000"],
  })

  // Unable to find how to call that on transaction reception
  queryClient.invalidateQueries({ queryKey: ['OCWebsiteList', factoryAddress.value, mintChainId.value, address] })
}

const { isLoading: isConfirming, isSuccess: isConfirmed } = 
  useWaitForTransactionReceipt({ 
    hash,
  })
</script>


<template>
  <div class="mint-area">
    <h1>Mint your OCWebsite</h1>

    <p>
      An OCWebsite is an on-chain website hosted on the blockchain, and accessible via the <a href="web3://web3url.eth/">web3:// protocol</a>.
    </p>

    <p>
      Once minted, you can manage it via the <RouterLink to="/">My OCWebsites</RouterLink> section : upload files, configure it, etc.
    </p>

    <p>
      The whole thing is free except for the blockchain gas fees.
    </p>

    <div class="form">
      <select v-model="mintChainId" class="chain-selector" v-if="isConnected" v-bind:disabled="isPending || isConfirming">
        <option :value="null" disabled>Select a chain</option>
        <option v-for="chain in supportedChains" :value="chain.id">{{ chain.name }}</option>
      </select>

      <button type="button" class="mint-button" @click="mint" 
        v-bind:disabled="contractAddressesLoaded == false || supportedChainsLoaded == false || isConnected == false || mintChainId == null || isPending || isConfirming">
        {{ (contractAddressesLoaded || supportedChainsLoaded) == false ? "Loading..." : isConnected == false ? "Connect your wallet first" : (isPending || isConfirming) ? "Minting in progress..." : "Mint OCWebsite" }}
      </button>
    </div>

    <div>
      <div v-if="isConfirming">
        Waiting for confirmation...
      </div>
      <div v-if="isConfirmed" class="transaction-confirmed">
        <strong>🎉 Transaction Confirmed! 🎉</strong><br />
         Your OCWebsite is now in your wallet and ready to be managed on the <RouterLink to="/">My OCWebsites</RouterLink> section.
      </div>
      <div class="error" v-if="switchChainIsPending == false && switchChainError">
        Switching chain error: {{ switchChainError.shortMessage || switchChainError.message }}
      </div>

      <div class="error" v-if="isPending == false && error">
        Error: {{ error.shortMessage || error.message }}
      </div>
    </div>
  </div>
</template>


<style scoped>
.mint-area {
  text-align: center;
}

.form {
  display: flex;
  gap: 1em;
  justify-content: center;
}

.chain-selector {
  font-size: 1em;
  margin-bottom: 1.2em;
}

.mint-button {
  font-size: 1.2em;
  margin-bottom: 1em;
}

.transaction-confirmed {
  border: 1px solid var(--color-divider);
  padding: 1em 2em;
  border-radius: 1em;
}

.error {
  color: var(--color-text-error);
}
</style>
