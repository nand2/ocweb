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
    <div class="table-header">
      <div>
        Name
      </div>
      <div>
        Type
      </div>
      <div>
        Size
      </div>
      <div style="font-size: 80%">
        Compression
      </div>
      <div>
      </div>
    </div>

    <VersionableStaticWebsiteEditor :contractAddress :chainId />
  </div>
</template>

<style scoped>
.table-header {
  display: grid;
  grid-template-columns: 5fr 2fr 1.5fr 1fr 1fr;
  padding: 0.5em 0em;
  font-weight: bold;
  border-bottom: 1px solid #555;
  background-color: var(--color-root-bg)
}

.table-header > div {
  padding: 0em 1em;
  word-break: break-all;
}
</style>