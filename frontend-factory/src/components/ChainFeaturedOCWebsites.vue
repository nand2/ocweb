<script setup>
import { computed, defineProps } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useAccount } from '@wagmi/vue';

import { useContractAddresses } from '../../../src/tanstack-vue.js';
import OCWebsiteByTokenId from './OCWebsiteByTokenId.vue';


const props = defineProps({
  chain: {
    type: Object,
    required: true,
  },
  tokenIds: {
    type: Array,
    required: true,
  },
})
</script>


<template>
  <div class="oc-websites">
    <OCWebsiteByTokenId v-for="tokenId in tokenIds" 
      :key="tokenId" 
      :chain="chain" 
      :tokenId="tokenId" />
  </div>
</template>

<style scoped>
.oc-websites {
  display: flex;
  flex-wrap: wrap;
  gap: 2em;
}
</style>