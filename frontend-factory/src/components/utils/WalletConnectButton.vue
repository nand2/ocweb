<script setup>
import { useConnect, useAccount, useDisconnect, useBalance, useChainId, useChains } from '@wagmi/vue';
import { ref, computed } from 'vue';

import WalletConnectModal from './WalletConnectModal.vue';

const { isConnected, address, connector, chainId } = useAccount();

const showModal = ref(false);
const { connectors, connect } = useConnect({
  mutation: {
    onSuccess: () => {
      showModal.value = false;
    },
  },
});
</script>

<template>
  
  <button
    v-if="isConnected == false && connectors.length == 1"
    @click="connect({ connector: connectors[0], chainId })"
  >
    <span v-if="connectors[0].type == 'injected'">
      Connect
    </span>
    <span v-else>
      Connect with {{ connectors[0].name }}
    </span>
  </button>
  <button
    v-else-if="isConnected == false && connectors.length > 1"
    @click="showModal = true"
  >
    Connect
  </button>
  
  <WalletConnectModal v-model:show="showModal" />
</template>

