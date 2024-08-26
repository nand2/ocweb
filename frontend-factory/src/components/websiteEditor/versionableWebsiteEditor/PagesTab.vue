<script setup>
import { ref, computed, defineProps } from 'vue';

import PageEditorIndex from './pageEditor/PageEditorIndex.vue';

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
    <PageEditorIndex 
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