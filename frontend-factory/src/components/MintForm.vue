<script setup>
import { ref } from 'vue'
import { fetchEip1193Provider } from '../utils/ethereum'

defineProps({
  msg: String,
})

const mintInProgress = ref(false)
const errorMessage = ref('')

function mint() {
  mintInProgress.value = true
  errorMessage.value = ''
  console.log('Minting...')

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
      <button type="button" @click="mint" v-bind:disabled="mintInProgress">{{ mintInProgress ? "Minting in progress..." : "Mint OCWebsite" }}</button>

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

.error {
  color: var(--color-text-error);
  margin-top: 0.5em;
}
</style>
