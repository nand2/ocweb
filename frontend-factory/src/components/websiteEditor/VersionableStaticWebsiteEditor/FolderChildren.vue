<script setup>
import { ref, computed, defineProps } from 'vue';

import File from './File.vue';
import Folder from './Folder.vue';
import ChevronRightIcon from '../../../icons/ChevronRightIcon.vue';
import ChevronDownIcon from '../../../icons/ChevronDownIcon.vue';

const props = defineProps({
  folderChildren: {
    type: Array,
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
  websiteClient: {
    type: Object,
    required: true,
  },
})

</script>

<template>
  <div class="folder-children">
    <div v-for="child in folderChildren" :key="child.name">
      
      <Folder 
        :folder="child" 
        :folderLevel="folderLevel + 1" 
        :contractAddress
        :chainId
        :websiteClient
        v-if="child.type == 'folder'" />
      <File 
        :file="child" 
        :folderLevel 
        :contractAddress
        :chainId
        :websiteClient
        v-else-if="child.type == 'file'" />

    </div>
  </div>
</template>

<style scoped>

</style>