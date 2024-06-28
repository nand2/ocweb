<script setup>
import { ref, computed, defineProps } from 'vue';

import FileEarmarkIcon from '../../../icons/FileEarmarkIcon.vue';
import PencilSquareIcon from '../../../icons/PencilSquareIcon.vue';
import TrashIcon from '../../../icons/TrashIcon.vue';
import ExclamationTriangleIcon from '../../../icons/ExclamationTriangleIcon.vue';

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
  return `${1 + props.folderLevel * 0.6}em`;
})
</script>

<template>
  <div class="file">
    <div class="filename">
      <a :href="fileUrl" class="white" target="_blank">
        <span>
          <FileEarmarkIcon />
        </span>
        <span>
          {{ file.name }}
        </span>
      </a>
    </div>
    <div class="content-type">
      {{ file.contentType }}
    </div>
    <div class="size">
      <span v-if="file.size === undefined">
        ...
      </span>
      <span v-else-if="file.complete == true">
        {{ Math.round(Number(props.file.size) / 1024) }} KB
      </span>
      <div v-else-if="file.complete == false">
        {{ Math.round(Number(props.file.uploadedSize) / 1024) }} / {{ Math.round(Number(props.file.size) / 1024) }} KB
        <div class="danger" style="font-size: 80%">
          <ExclamationTriangleIcon style="height: 0.8em" />Incomplete
        </div>
      </div>
    </div>
    <div class="compression">
      <span v-if="file.compressionAlgorithm == 0">
        none
      </span>
      <span v-else-if="file.compressionAlgorithm == 1">
        gzip
      </span>
      <span v-else-if="file.compressionAlgorithm == 2">
        brotli
      </span>
    </div>
    <div class="actions">
      <PencilSquareIcon />
      <TrashIcon />
    </div>
  </div>
</template>

<style scoped>
.file {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 4em max-content;
  padding: 0.5em 0em;
}

.file > div {
  display: flex;
  line-height: 1em;
  gap: 0.5em;
  padding: 0em 1em;
}

.file > .filename {
  padding-left: v-bind('paddingLeftForCSS');
}

.file > .filename a {
  display: flex;
  gap: 0.5em;
}

@media (max-width: 700px) {
  .file {
    grid-template-columns: 2fr max-content;
  }

  .file > .content-type,
  .file > .compression,
  .file > .size {
    display: none;
  }
}
</style>