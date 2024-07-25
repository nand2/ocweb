<script setup>
import { useAccount } from '@wagmi/vue';
import { useContractAddresses } from '../utils/queries';
import OCWebsiteEditor from '../components/websiteEditor/OCWebsiteEditor.vue';

const { isConnected } = useAccount();
const { data: contractAddresses, isLoading: contractAddressesLoading, isSuccess: contractAddressesLoaded, isError: contractAddressesIsError, error: contractAddressesError } = useContractAddresses()
</script>

<template>
  <div class="website-admin">
    <div v-if="isConnected == false" class="main-message">
      Please connect your wallet
    </div>

    <div v-else-if="contractAddressesLoaded == false" class="main-message">
      Loading...
      <div v-if="contractAddressesIsError" class="text-danger">
          Error loading contract addresses: {{ contractAddressesError.message }}
      </div>
    </div>

    <div v-else>
      <OCWebsiteEditor :contractAddress="contractAddresses.self.address" :chainId="contractAddresses.self.chainId" />
    </div>
  </div>
</template>

<style scoped>
.website-admin {
  border-top: 1px solid var(--color-divider);
}

.main-message {
  margin-top: 20vh;
  text-align: center;
}
</style>