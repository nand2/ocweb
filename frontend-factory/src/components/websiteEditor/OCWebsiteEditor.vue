<script setup>
import { ref, computed, defineProps } from 'vue';

import VersionableWebsiteEditor from './versionableWebsiteEditor/VersionableWebsiteEditor.vue';

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
  <div class="oc-website-editor">
    <VersionableWebsiteEditor :contractAddress :chainId />
  </div>
</template>

<style scoped>
.oc-website-editor {
  display: flex;
  flex-direction: column;
  background-color: #eee;
  width: 100%;
  background-color: var(--color-light-bg);
}
</style>