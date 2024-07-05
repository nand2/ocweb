<script setup>
import { ref, computed, defineProps } from 'vue';

import VersionableStaticWebsiteEditor from './VersionableStaticWebsiteEditor.vue';
import FrontendVersionEditor from './FrontendVersionFilesEditor.vue';

const props = defineProps({
  frontendVersion: {
    type: [Object, null],
    required: true
  },
  frontendVersionIndex: {
    type: Number,
    required: true,
  },
  frontendVersionIsFetching: {
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
  websiteClient: {
    type: [Object, null],
    required: true,
  },
})
</script>

<template>
  <div>
    <FrontendVersionEditor 
        :frontendVersion
        :frontendVersionIndex
        :frontendVersionIsFetching
        :contractAddress
        :chainId
        :websiteClient
        />
  </div>
</template>

<style scoped>

</style>