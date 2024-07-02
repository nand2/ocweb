<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useQueryClient } from '@tanstack/vue-query'

import FrontendVersionListLine from './FrontendVersionListLine.vue';

const props = defineProps({
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
})


// Get frontend versions
const { data: frontendVersionsData, isLoading: frontendVersionsLoading, isFetching: frontendVersionsFetching, isError: frontendVersionsIsError, error: frontendVersionsError, isSuccess: frontendVersionsLoaded } = useQuery({
  queryKey: ['OCWebsiteFrontendVersions', props.contractAddress, props.chainId],
  queryFn: async () => {
    return await props.websiteClient.getFrontendVersions(0, 0)
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => props.websiteClient != null),
})
</script>

<template>
  <div>
    <div v-if="frontendVersionsLoading">
      Loading frontend versions...
    </div>
    <div v-else-if="frontendVersionsIsError" class="text-danger">
      Error loading frontend versions: {{ frontendVersionsError.message }}
    </div>
    <div v-else-if="frontendVersionsLoaded">
      <div v-for="(frontendVersion, index) in frontendVersionsData[0]" :key="index">
        <FrontendVersionListLine
          :frontendVersion="frontendVersion"
          :frontendVersionIndex="index"
          :contractAddress
          :chainId
          :websiteClient />
      </div>
    </div>
  </div>
</template>

<style scoped>

</style>