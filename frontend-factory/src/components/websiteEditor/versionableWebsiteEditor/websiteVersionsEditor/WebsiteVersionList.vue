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

// Get website versions
const { data: websiteVersionsData, isLoading: websiteVersionsLoading, isFetching: websiteVersionsFetching, isError: websiteVersionsIsError, error: websiteVersionsError, isSuccess: websiteVersionsLoaded } = useWebsiteVersions(queryClient, props.contractAddress, props.chainId)

</script>

<template>
  <div>
    <div v-if="websiteVersionsLoading">
      Loading website versions...
    </div>
    <div v-else-if="websiteVersionsIsError" class="text-danger">
      Error loading website versions: {{ websiteVersionsError.message }}
    </div>
    <div v-else-if="websiteVersionsLoaded">
      <div v-for="(websiteVersion, index) in websiteVersionsData.versions" :key="index">
        <WebsiteVersionListLine
          :websiteVersion="websiteVersion"
          :websiteVersionIndex="index"
          :contractAddress
          :chainId
          :websiteClient />
      </div>
    </div>
  </div>
</template>

<style scoped>

</style>