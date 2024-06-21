<script setup>
import { ref } from 'vue'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { abi as FactoryABI } from '../utils/factoryABI.js';

defineProps({
  msg: String,
})

const { isConnected, chainId } = useAccount();
const { chains, switchChain } = useSwitchChain()
const { data: hash, isPending, error, writeContract } = useWriteContract()


function mint() {
  switchChain({ chainId: 31337 })

  writeContract({ 
    abi: FactoryABI,
    address: '0xe6e340d132b5f46d1e472debcd681b2abc16e57e', //TODO
    functionName: 'mintWebsite',
    args: [],
  })
}

const { isLoading: isConfirming, isSuccess: isConfirmed } = 
  useWaitForTransactionReceipt({ hash })
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

    <div>
      <button type="button" class="mint-button" @click="mint" v-bind:disabled="isConnected == false || isPending || isConfirming">
        {{ isConnected == false ? "Connect your wallet first" : (isPending || isConfirming) ? "Minting in progress..." : "Mint OCWebsite" }}
      </button>

      <div v-if="isConfirming">
        Waiting for confirmation...
      </div>
      <div v-if="isConfirmed" class="transaction-confirmed">
        <strong>🎉 Transaction Confirmed! 🎉</strong><br />
         Your OCWebsite is now in your wallet and ready to be managed on the <RouterLink to="/">My OCWebsites</RouterLink> section.
      </div>

      <div class="error" v-if="isPending == false && error">
        Error: {{ error.shortMessage || error.message }} {{  error  }}
      </div>
    </div>
  </div>
</template>


<style scoped>
.mint-area {
  text-align: center;
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
