<script setup>
import { ref, computed, defineProps } from 'vue';
import FrontendLibraryEditor from './FrontendLibraryEditor/FrontendLibraryEditor.vue';

const props = defineProps({
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
})
</script>

<template>
  <FrontendLibraryEditor :contractAddress :chainId />
</template>