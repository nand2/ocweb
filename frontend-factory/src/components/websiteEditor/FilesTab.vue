<script setup>
import { ref, computed, defineProps } from 'vue';
import VersionableStaticWebsiteEditor from './VersionableStaticWebsiteEditor/VersionableStaticWebsiteEditor.vue';

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
  <div>
    <VersionableStaticWebsiteEditor :contractAddress :chainId />
  </div>
</template>

<style scoped>

</style>