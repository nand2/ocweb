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
    <FolderChildren :folderChildren="folder.children" :folderLevel="folderLevel + 1" v-if="isOpened" />
  </div>
</template>

<style scoped>
.folder-name {
  padding: 0.5em 1em;
}

.folder-name span {
  cursor: pointer;
  display: flex;
  gap: 0.5em;
  line-height: 1em;
}
</style>