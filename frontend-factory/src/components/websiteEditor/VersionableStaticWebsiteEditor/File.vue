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
})

const paddingLeftForCSS = computed(() => {
  return `${props.folderLevel * 0.75}em`;
})
</script>

<template>
  <div class="file">
    <div class="filename">
      <FileEarmarkIcon />
      {{ file.name }}
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

.file div {
  display: flex;
  line-height: 1em;
  gap: 0.5em;
}

.filename {
  padding-left: v-bind('paddingLeftForCSS');
}
</style>