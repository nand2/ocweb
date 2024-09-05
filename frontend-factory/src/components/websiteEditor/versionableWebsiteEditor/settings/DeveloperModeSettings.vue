<script setup>
import { ref, defineProps, watch } from 'vue';

import { store } from '../../../../utils/store';


const props = defineProps({
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
  websiteVersion: {
    type: Object,
    required: true
  },
  websiteVersionIndex: {
    type: Number,
    required: true,
  },
  websiteClient: {
    type: Object,
    required: true,
  },
})

const developerMode = ref(store.devMode)
watch(developerMode, (value) => {
  store.setDevMode(value)
})

</script>

<template>
  <div class="title">
    Developer mode
    <!-- <small class="text-muted" style="font-weight: normal; font-size:0.7em;">
      Ways to access your website
    </small> -->
  </div>

  <div class="switch-container">
    <label class="switch">
      <input type="checkbox" v-model="developerMode" />
      <span class="slider round"></span>
    </label>
    <span class="switch-label">{{ developerMode ? 'On' : 'Off' }}</span>
  </div>

  <div class="text-90" style="margin-top: 0.75em;">
    Developer mode will show more technical configuration options.
  </div>
  

</template>

<style scoped>
.title {
  font-size: 1.1em;
  font-weight: bold;
  margin-bottom: 0.75em;
}




</style>