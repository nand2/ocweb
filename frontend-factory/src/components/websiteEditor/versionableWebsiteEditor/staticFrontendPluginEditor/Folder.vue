<script setup>
import { ref, computed, defineProps } from 'vue';

import FolderChildren from './FolderChildren.vue';
import ChevronRightIcon from '../../../../icons/ChevronRightIcon.vue';
import ChevronDownIcon from '../../../../icons/ChevronDownIcon.vue';

const props = defineProps({
  folder: {
    type: Object,
    required: true,
  },
  folderParents: {
    type: Array,
    default: [],
  },
  locked: {
    type: Boolean,
    required: true,
  },
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
  websiteVersion: {
    type: Object,
    required: true
  },
  websiteVersionIndex: {
    type: Number,
    required: true,
  },
  staticFrontendPluginClient: {
    type: Object,
    required: true,
  },
  globalEmptyFolders: {
    type: Array,
    required: true,
  },
})

const isOpened = ref(false);

const paddingLeftForCSS = computed(() => {
  return `${1 + (props.folderParents.length - 1) * 1.5}em`;
})
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
      :folderParents 
      :locked
      :contractAddress
      :chainId
      :websiteVersion
      :websiteVersionIndex
      :staticFrontendPluginClient
      :globalEmptyFolders
      v-if="isOpened" />
  </div>
</template>

<style scoped>
.folder {
  padding: 0em 0em;
}

.folder-name {
  display: flex;
  line-height: 1em;
  padding: 0.5em 1em;
  padding-left: v-bind('paddingLeftForCSS');
}

.folder-name span {
  display: flex;
  gap: 0.5em;
  cursor: pointer;
  justify-content: flex-start;
}
</style>