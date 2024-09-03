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

// If there is only the injected connector, keep it, otherwise remove it
const filteredConnectors = computed(() => {
  return connectors.length > 1 ? connectors.filter((connector) => connector.name !== 'Injected') : connectors;
});
</script>

<template>
  
  <button
    v-if="isConnected == false && filteredConnectors.length == 1"
    @click="connect({ connector: filteredConnectors[0], chainId })"
  >
    <span v-if="filteredConnectors[0].name == 'Injected'">
      Connect
    </span>
    <span v-else>
      Connect with {{ filteredConnectors[0].name }}
    </span>
  </button>
  <button
    v-else-if="isConnected == false && filteredConnectors.length > 1"
    @click="showModal = true"
  >
    Connect
  </button>
  
  <WalletConnectModal v-model:show="showModal" />
</template>

