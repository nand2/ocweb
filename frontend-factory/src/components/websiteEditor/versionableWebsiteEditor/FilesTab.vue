<script setup>
import { ref, computed, defineProps } from 'vue';

import VersionableWebsiteEditor from './VersionableWebsiteEditor.vue';
import WebsiteVersionEditor from './staticFrontendPluginEditor/StaticFrontendEditor.vue';

const props = defineProps({
  websiteVersion: {
    type: [Object, null],
    required: true
  },
  websiteVersionIndex: {
    type: Number,
    required: true,
  },
  websiteVersionIsFetching: {
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
    <WebsiteVersionEditor 
        :websiteVersion
        :websiteVersionIndex
        :websiteVersionIsFetching
        :contractAddress
        :chainId
        :websiteClient
        :pluginInfos
        />
  </div>
</template>

<style scoped>

</style>