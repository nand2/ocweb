<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'

import WebsiteVersionListLine from './WebsiteVersionListLine.vue';
import { useWebsiteVersions } from '../../../../utils/queries.js';

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

const queryClient = useQueryClient()

// Get frontend versions
const { data: frontendVersionsData, isLoading: frontendVersionsLoading, isFetching: frontendVersionsFetching, isError: frontendVersionsIsError, error: frontendVersionsError, isSuccess: frontendVersionsLoaded } = useWebsiteVersions(queryClient, props.contractAddress, props.chainId)

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
      <div v-for="(frontendVersion, index) in frontendVersionsData.versions" :key="index">
        <WebsiteVersionListLine
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