<script setup>
import { useConnect, useAccount, useDisconnect, useBalance, useChainId, useChains } from '@wagmi/vue';
import { ref, computed, defineModel, defineEmits } from 'vue';

import Modal from './Modal.vue';

const show = defineModel('show', {
  type: Boolean,
  required: true,
})
const emit = defineEmits(['connected']);


const { connectors, connect } = useConnect({
  mutation: {
    onSuccess: () => {
      show.value = false;
      emit('connected');
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
  <Modal
    v-model:show="show"
    title="Connect wallet">
    <div class="connect-buttons">
      <button @click="connect({ connector, chainId })" v-for="connector in filteredConnectors" :key="connector.name">
        Connect with {{ connector.name }}
      </button>
    </div>
  </Modal>
</template>

<style scoped>
.connect-buttons {
  display: flex;
  gap: 1em;
  max-width: 80vh;
  flex-wrap: wrap;
  justify-content: center;
}
</style>