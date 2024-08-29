<script setup>
import { ref, computed, defineProps } from 'vue';

import VersionableWebsiteEditor from './VersionableWebsiteEditor.vue';
import StaticFrontendEditor from './staticFrontendPluginEditor/StaticFrontendEditor.vue';

const props = defineProps({
  websiteVersion: {
    type: Object,
    required: true
  },
  websiteVersionIndex: {
    type: Number,
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
    type: Object,
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
    <StaticFrontendEditor 
        :websiteVersion
        :websiteVersionIndex
        :contractAddress
        :chainId
        :websiteClient
        :pluginInfos
        />
  </div>
</template>

<style scoped>

</style>