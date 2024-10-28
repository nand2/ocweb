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
    onError: (error) => {
      console.error(error);
    },
  },
});

// In the connectors of type "injected" : if there is only one of id "injected", keep it, otherwise 
// remove it (Otherwise we get some proper names such as "Metamask", and we get this UX-weird "Injected")
const filteredConnectors = computed(() => {
  const otherTypeConnectors = connectors.filter((connector) => connector.type != 'injected');
  const injectedTypeConnectors = connectors.filter((connector) => connector.type == 'injected');
  return [...otherTypeConnectors, ...injectedTypeConnectors.length == 1 ? injectedTypeConnectors : injectedTypeConnectors.filter((connector) => connector.id != 'injected')];
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

