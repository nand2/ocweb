<script setup>
import { ref, computed, defineProps } from 'vue';

import VersionableWebsiteEditor from './VersionableWebsiteEditor.vue';
import FrontendVersionEditor from './staticFrontendPluginEditor/StaticFrontendEditor.vue';

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
  pluginInfos: {
    type: Object,
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
        :pluginInfos
        />
  </div>
</template>

<style scoped>

</style>