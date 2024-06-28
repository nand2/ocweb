<script setup>
import { ref, computed, defineProps } from 'vue';

import FolderChildren from './FolderChildren.vue';
import ChevronRightIcon from '../../../icons/ChevronRightIcon.vue';
import ChevronDownIcon from '../../../icons/ChevronDownIcon.vue';

const props = defineProps({
  folder: {
    type: Object,
    required: true,
  },
  folderLevel: {
    type: Number,
    default: 0,
  },
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
})

const isOpened = ref(false);
</script>

<template>
  <div class="folder">
    <div class="folder-name">
      <span @click="isOpened = !isOpened">
        <ChevronRightIcon v-show="isOpened == false" />
        <ChevronDownIcon v-show="isOpened" />
        {{ folder.name }}
      </span>
    </div>
    <FolderChildren 
      :folderChildren="folder.children" 
      :folderLevel="folderLevel + 1" 
      :contractAddress
      :chainId
      v-if="isOpened" />
  </div>
</template>

<style scoped>
.folder {
  padding: 0em 0em;
}

.folder-name {
  display: flex;
  padding: 0.5em 1em;
  line-height: 1em;
}

.folder-name span {
  display: flex;
  gap: 0.5em;
  cursor: pointer;
  justify-content: flex-start;
}
</style>