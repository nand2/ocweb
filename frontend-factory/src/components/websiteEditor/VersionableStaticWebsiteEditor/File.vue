<script setup>
import { ref, computed, defineProps } from 'vue';

import FileEarmarkIcon from '../../../icons/FileEarmarkIcon.vue';

const props = defineProps({
  file: {
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

const fileUrl = computed(() => {
  return `web3://${props.contractAddress}${props.chainId > 1 ? ":" + props.chainId : ""}/${props.file.filePath}`;
})

const paddingLeftForCSS = computed(() => {
  return `${props.folderLevel * 0.25}em`;
})
</script>

<template>
  <div class="file">
    <div class="filename">
      <a :href="fileUrl" class="white" target="_blank">
        <FileEarmarkIcon />
        {{ file.name }}
      </a>
    </div>
    <div>
      {{ file.contentType }}
    </div>
    <div></div>
  </div>
</template>

<style scoped>
.file {
  display: grid;
  grid-template-columns: 1fr 1fr 3em;
  padding: 0.5em 1em;
}

.file > div {
  display: flex;
  line-height: 1em;
  gap: 0.5em;
}

.filename {
  padding-left: v-bind('paddingLeftForCSS');
}

.filename a {
  display: flex;
  gap: 0.5em;

}
</style>