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

// If there is only the injected connector, keep it, otherwise remove it
const filteredConnectors = computed(() => {
  return connectors.length > 1 ? connectors.filter((connector) => connector.name !== 'Injected') : connectors;
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