<script setup>
import { ref } from 'vue'
import { useAccount, useSwitchChain } from '@wagmi/vue';

defineProps({
  msg: String,
})

const { isConnected, chainId } = useAccount();
const { chains, switchChain } = useSwitchChain()

const mintInProgress = ref(false)
const errorMessage = ref('')

function mint() {
  mintInProgress.value = true
  errorMessage.value = ''
  console.log('Minting...')

  switchChain({ chainId: 31337 })

  // setTimeout(() => {
  //   errorMessage.value = 'Minting failed'
  // }, 3000)

  setTimeout(() => {
    mintInProgress.value = false
    console.log('Minted!')
  }, 2000)
}
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
      <button type="button" class="mint-button" @click="mint" v-bind:disabled="isConnected == false || mintInProgress">
        {{ isConnected == false ? "Connect your wallet first" : mintInProgress ? "Minting in progress..." : "Mint OCWebsite" }}
      </button>

      <div class="error">
        {{ errorMessage }}
      </div>
    </div>
  </div>
</template>


<style scoped>
.mint-area {
  text-align: center;
}

.mint-button {
  font-size: 1.2em;;
}

.error {
  color: var(--color-text-error);
  margin-top: 0.5em;
}
</style>
