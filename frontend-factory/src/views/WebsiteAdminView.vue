<script setup>
import { useAccount } from '@wagmi/vue';
import { useEmbeddorContractAddress } from '../../../src/tanstack-vue';
import OCWebsite from '../components/OCWebsite.vue';
import OCWebsiteEditor from '../components/websiteEditor/OCWebsiteEditor.vue';

const { isConnected } = useAccount();
const { data: embeddorContractAddress, isLoading: embeddorContractAddressLoading, isSuccess: embeddorContractAddressLoaded, isError: embeddorContractAddressIsError, error: embeddorContractAddressError } = useEmbeddorContractAddress()
</script>

<template>
  <div class="website-admin">
    <div v-if="isConnected == false" class="main-message">
      Please connect your wallet
    </div>

    <div v-else-if="embeddorContractAddressLoaded == false" class="main-message">
      Loading...
      <div v-if="embeddorContractAddressIsError" class="text-danger">
          Error loading contract addresses: {{ embeddorContractAddressError.message }}
      </div>
    </div>

    <div v-else class="oc-website">
      <OCWebsite 
        :contractAddress="embeddorContractAddress.address" 
        :chainId="embeddorContractAddress.chainId"
        :isOpened="true"
        :showLinkAndCloseIcons="false" />
    </div>
  </div>
</template>

<style scoped>
.website-admin {
  
}

.main-message {
  margin-top: 20vh;
  text-align: center;
}

.oc-website {
  display: flex;
  justify-content: center;
  margin-top: 2em;
}
</style>