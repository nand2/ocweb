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
        <span>
          {{ file.name }}
        </span>
      </a>
    </div>
    <div>
      {{ file.contentType }}
    </div>
    <div>
      <span v-if="file.size === undefined">
        ...
      </span>
      <span v-else-if="file.complete == true">
        {{ Math.round(Number(props.file.size) / 1024) }} KB
      </span>
      <span v-else-if="file.complete == false">
        {{ Math.round(Number(props.file.uploadedSize) / 1024) }} / {{ Math.round(Number(props.file.size) / 1024) }} KB
      </span>
      <span v-if="file.complete == false" class="danger">
        Incomplete
      </span>
    </div>
    <div>
      <span v-if="file.compressionAlgorithm == 0">
        None
      </span>
      <span v-else-if="file.compressionAlgorithm == 1">
        Gzip
      </span>
      <span v-else-if="file.compressionAlgorithm == 2">
        Brotli
      </span>
    </div>
    <div></div>
  </div>
</template>

<style scoped>
.file {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr 1fr 3em;
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