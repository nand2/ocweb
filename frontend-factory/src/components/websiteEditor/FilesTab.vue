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
      <div>
        Internal compression
      </div>
    </div>

    <VersionableStaticWebsiteEditor :contractAddress :chainId />
  </div>
</template>

<style scoped>
.table-header {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr 1fr 3em;
  padding: 0.5em 1em;
  font-weight: bold;
  border-bottom: 1px solid #555;
  background-color: var(--color-root-bg)
}
</style>