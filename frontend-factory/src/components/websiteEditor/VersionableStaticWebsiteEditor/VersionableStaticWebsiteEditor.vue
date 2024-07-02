<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useSwitchChain, useAccount } from '@wagmi/vue'
import { useQueryClient } from '@tanstack/vue-query'

import FrontendVersionEditor from './FrontendVersionEditor.vue';
import FrontendVersionsConfigEditor from './FrontendVersionsConfigEditor.vue';
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
let initialLiveFrontendValueUsed = false
const { data: frontendVersionBeingEdited, isLoading: frontendVersionBeingEditedLoading, isFetching: frontendVersionBeingEditedFetching, isError: frontendVersionBeingEditedIsError, error: frontendVersionBeingEditedError, isSuccess: frontendVersionBeingEditedLoaded } = useQuery({
  queryKey: ['OCWebsiteFrontendVersion', props.contractAddress, props.chainId, frontendVersionBeingEditedIndex],
  queryFn: async () => {
    // Invalidate dependent query : sizes
    queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersionFilesSizes', props.contractAddress, props.chainId, frontendVersionBeingEditedIndex.value] })

    // If this is the first time we are called, we are called to fetch again the live version
    // Skip that and reuse liveFrontendVersionData directly
    if(initialLiveFrontendValueUsed == false) {
      initialLiveFrontendValueUsed = true;
      return liveFrontendVersionData.value[0]
    }

    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    return await websiteClient.value.getFrontendVersion(frontendVersionBeingEditedIndex.value)
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => websiteClientLoaded.value && liveFrontendVersionLoaded.value),
})

const showEditedFrontendVersionSelector = ref(false)

// Get frontend versions
const { data: frontendVersionsData, isLoading: frontendVersionsLoading, isFetching: frontendVersionsFetching, isError: frontendVersionsIsError, error: frontendVersionsError, isSuccess: frontendVersionsLoaded } = useQuery({
  queryKey: ['OCWebsiteFrontendVersions', props.contractAddress, props.chainId],
  queryFn: async () => {
    return await websiteClient.value.getFrontendVersions(0, 0)
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => websiteClientLoaded.value && showEditedFrontendVersionSelector.value),
})

const showConfigPanel = ref(false)
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

    <div class="footer-selected-version">
      <div class="edited-frontend-version-selector" v-if="showEditedFrontendVersionSelector">
        <div class="edited-frontend-version-selector-inner">
          <div v-if="frontendVersionsLoading">
            Loading frontend versions...
          </div>
          <div v-else-if="frontendVersionsIsError" class="text-danger">
            Error loading frontend versions: {{ frontendVersionsError.message }}
          </div>
          <div v-else-if="frontendVersionsLoaded">
            <div v-for="(frontendVersion, index) in frontendVersionsData[0]" :key="index">
              <a class="white" @click.prevent.stop="frontendVersionBeingEditedIndex = index; showEditedFrontendVersionSelector = false">
                Version #{{ index}}: 
                {{ frontendVersion.description }}
              </a>
            </div>
          </div>
        </div>
      </div>

      <div class="footer-inner">
        <span v-if="frontendVersionBeingEditedLoading">
          Loading live version...
        </span>
        <span v-else-if="frontendVersionBeingEditedIsError">
          Error loading live version: {{ error.shortMessage || error.message }}
        </span>
        <a v-else-if="frontendVersionBeingEditedLoaded" class="white" @click.prevent.stop="showEditedFrontendVersionSelector = !showEditedFrontendVersionSelector">
          Version #{{ frontendVersionBeingEditedIndex }}: 
          {{ frontendVersionBeingEdited.description }}
        </a>
        <a class="white" style="line-height: 1em" @click.prevent.stop="showConfigPanel = !showConfigPanel">
          <GearIcon />
        </a>
      </div>
    </div>

    <div class="versions-config-panel" v-if="showConfigPanel">
      <FrontendVersionsConfigEditor
        :contractAddress
        :chainId
        :websiteClient="websiteClient"
        />
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

.footer-selected-version .footer-inner {
  border-top: 1px solid var(--color-divider);
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: var(--color-root-bg);
}

.footer-selected-version a, 
.footer-selected-version span {
  padding: 0.5em 1em;
}

.edited-frontend-version-selector {
  position: relative;
}

.edited-frontend-version-selector-inner {
  position: absolute;
  bottom: 0;
}




</style>