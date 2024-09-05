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

const showWebsiteVersionsSection = ref(store.showWebsiteVersionsSection)
watch(showWebsiteVersionsSection, (value) => {
  store.setShowWebsiteVersionsSection(value)
})

</script>

<template>
  <div class="title">
    Website versioning
    <!-- <small class="text-muted" style="font-weight: normal; font-size:0.7em;">
      Ways to access your website
    </small> -->
  </div>

  <div class="switch-container">
    <label class="switch">
      <input type="checkbox" v-model="showWebsiteVersionsSection" />
      <span class="slider round"></span>
    </label>
    <span class="switch-label">{{ showWebsiteVersionsSection ? 'On' : 'Off' }}</span>
  </div>

  <div class="text-90" style="margin-top: 0.75em;">
    Allows you to create and manage different versions of your website.
  </div>
  

</template>

<style scoped>
.title {
  font-size: 1.1em;
  font-weight: bold;
  margin-bottom: 0.75em;
}




</style>