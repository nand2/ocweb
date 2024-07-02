<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useConnectorClient } from '@wagmi/vue'
import { useSwitchChain, useAccount } from '@wagmi/vue'
import { useQueryClient } from '@tanstack/vue-query'

import FrontendVersionEditor from './FrontendVersionEditor.vue';
import { useVersionableStaticWebsiteClient } from '../../../utils/queries.js';
import GearIcon from '../../../icons/GearIcon.vue';

const props = defineProps({
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
})

const { switchChainAsync } = useSwitchChain()
const queryClient = useQueryClient()

// Folders are not stored in the backend, like git
// We keep track of the empty folders to display them
const globalEmptyFolders = ref([])

// Fetch the website client
const { data: websiteClient, isSuccess: websiteClientLoaded } = useVersionableStaticWebsiteClient
(props.contractAddress)

const showVersionPanel = ref(false)

// Fetch the live frontend
const frontendVersionBeingEditedIndex = ref(-1)
const { data: liveFrontendVersionData, isLoading: liveFrontendVersionLoading, isFetching: liveFrontendVersionFetching, isError: liveFrontendVersionIsError, error: liveFrontendVersionError, isSuccess: liveFrontendVersionLoaded } = useQuery({
  queryKey: ['OCWebsiteLiveFrontend', props.contractAddress, props.chainId],
  queryFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })
    
    const result = await websiteClient.value.getLiveFrontendVersion()

    // Set the index of the frontend version being edited
    frontendVersionBeingEditedIndex.value = Number(result[1])

    return result
  },
  staleTime: 3600 * 1000,
  enabled: websiteClientLoaded,
})

// Get a frontend version
const { data: frontendVersionBeingEdited, isLoading: frontendVersionBeingEditedLoading, isFetching: frontendVersionBeingEditedFetching, isError: frontendVersionBeingEditedIsError, error: frontendVersionBeingEditedError, isSuccess: frontendVersionBeingEditedLoaded } = useQuery({
  queryKey: ['OCWebsiteFrontendVersion', props.contractAddress, props.chainId, frontendVersionBeingEditedIndex],
  queryFn: async () => {
    // Invalidate dependent query : sizes
    queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersionFilesSizes', props.contractAddress, props.chainId, frontendVersionBeingEditedIndex.value] })

    // If this is the first time we are called, we are called to fetch again the live version
    // Skip that and reuse liveFrontendVersionData directly
    if(frontendVersionBeingEditedLoaded.value == false) {
      return liveFrontendVersionData.value[0]
    }

    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })
    
    const result = await websiteClient.value.getFrontendVersion(frontendVersionBeingEditedIndex.value)
    
    return result
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => websiteClientLoaded.value && liveFrontendVersionLoaded.value),
})

</script>

<template>
  <div class="versionable-static-website-editor">
    <div>
      <FrontendVersionEditor 
        :frontendVersion="frontendVersionBeingEditedLoaded ? frontendVersionBeingEdited : null"
        :frontendVersionIndex="frontendVersionBeingEditedIndex"
        :frontendVersionIsFetching="frontendVersionBeingEditedFetching"
        :contractAddress
        :chainId
        :websiteClient="websiteClient"
        />
    </div>
    <div class="versions-panel">
      <div class="versions-body" v-show="showVersionPanel">
        <div class="versions-list">
          XX
        </div>
        <div class="versions-actions">
          <div class="versions-add-new-form">
            <input type="text" placeholder="Enter a new version name" />
            <button>Add new version</button>
          </div>
          <div class="versions-global-lock-form">
            <button>Lock all versions</button>
          </div>
        </div>
      </div>
      <div class="versions-header">
        <span v-if="liveFrontendVersionLoading">
          Loading live version...
        </span>
        <span v-else-if="liveFrontendVersionIsError">
          Error loading live version: {{ error.shortMessage || error.message }}
        </span>
        <span v-else-if="liveFrontendVersionLoaded">
          Version #{{ liveFrontendVersionData[1] }}: 
          {{ liveFrontendVersionData[0].description }}
        </span>
        <a class="white" style="line-height: 1em" @click.prevent.stop="showVersionPanel = !showVersionPanel">
          <GearIcon />
        </a>
      </div>
    </div>
  </div>
</template>

<style scoped>
.versionable-static-website-editor {
  min-height: 500px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.versions-panel {
  border-top: 1px solid var(--color-divider);
}

.versions-header {
  padding: 0.5em 1em;
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: var(--color-root-bg);
}

.versions-body {
  display: flex;
  border-bottom: 1px solid var(--color-divider-secondary);
  gap: 1em;
}

.versions-list {
  flex: 1;
}

.versions-actions {
  display: flex;
  flex-direction: column;
  gap: 1em;
  border-left: 1px solid var(--color-divider);
}


</style>