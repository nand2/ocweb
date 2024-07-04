<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useSwitchChain, useAccount } from '@wagmi/vue'
import { useQueryClient } from '@tanstack/vue-query'

import FrontendVersionEditor from './FrontendVersionEditor.vue';
import FrontendVersionsConfigEditor from './FrontendVersionsConfigEditor.vue';
import { useVersionableStaticWebsiteClient } from '../../../utils/queries.js';
import GearIcon from '../../../icons/GearIcon.vue';
import ChevronUpIcon from '../../../icons/ChevronUpIcon.vue';

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


// Fetch the live frontend infos
const { data: liveFrontendVersionData, isLoading: liveFrontendVersionLoading, isFetching: liveFrontendVersionFetching, isError: liveFrontendVersionIsError, error: liveFrontendVersionError, isSuccess: liveFrontendVersionLoaded } = useQuery({
  queryKey: ['OCWebsiteLiveFrontend', props.contractAddress, props.chainId],
  queryFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })
    
    const result = await websiteClient.value.getLiveFrontendVersion()

    return result
  },
  staleTime: 3600 * 1000,
  enabled: websiteClientLoaded,
})

const userSelectedFrontendVersionBeingEditedIndex = ref(-1)
// The index of the frontend version being edited is by default the live version
// and then can be changed by the select form
const frontendVersionBeingEditedIndex = computed(() => {
  if(userSelectedFrontendVersionBeingEditedIndex.value != -1) {
    return userSelectedFrontendVersionBeingEditedIndex.value
  }
  if(liveFrontendVersionLoaded.value) {
    return liveFrontendVersionData.value.frontendIndex
  }
  return -1;
})

// Get a frontend version
const { data: frontendVersionBeingEdited, isLoading: frontendVersionBeingEditedLoading, isFetching: frontendVersionBeingEditedFetching, isError: frontendVersionBeingEditedIsError, error: frontendVersionBeingEditedError, isSuccess: frontendVersionBeingEditedLoaded } = useQuery({
  queryKey: ['OCWebsiteFrontendVersion', props.contractAddress, props.chainId, frontendVersionBeingEditedIndex],
  queryFn: async () => {
    // Invalidate dependent query : sizes
    queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersionFilesSizes', props.contractAddress, props.chainId, frontendVersionBeingEditedIndex.value] })

    // If the user has not selected a version yet, the default is the live version
    // Skip that and reuse liveFrontendVersionData directly
    if(userSelectedFrontendVersionBeingEditedIndex.value == -1) {
      return liveFrontendVersionData.value.frontendVersion
    }

    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    return await websiteClient.value.getFrontendVersion(frontendVersionBeingEditedIndex.value)
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => websiteClientLoaded.value && liveFrontendVersionLoaded.value),
})

const showEditedFrontendVersionSelector = ref(false)

// Get the list frontend versions
const { data: frontendVersionsData, isLoading: frontendVersionsLoading, isFetching: frontendVersionsFetching, isError: frontendVersionsIsError, error: frontendVersionsError, isSuccess: frontendVersionsLoaded } = useQuery({
  queryKey: ['OCWebsiteFrontendVersions', props.contractAddress, props.chainId],
  queryFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

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

    <div class="footer">
      <div class="footer-inner">
        <span v-if="frontendVersionBeingEditedLoading">
          Loading version...
        </span>
        <span v-else-if="frontendVersionBeingEditedIsError">
          Error loading version: {{ frontendVersionBeingEditedError.shortMessage || frontendVersionBeingEditedError.message }}
        </span>
        <a v-else-if="frontendVersionBeingEditedLoaded" class="bg" @click.prevent.stop="showEditedFrontendVersionSelector = !showEditedFrontendVersionSelector">
            
          <div class="form-select-frontend-version-popup" v-if="showEditedFrontendVersionSelector">
            <div class="form-select-frontend-version-popup-inner">
              <span v-if="frontendVersionsLoading" class="text-muted text-90">
                Loading frontend versions...
              </span>
              <span v-else-if="frontendVersionsIsError" class="text-danger text-90">
                Error loading frontend versions: {{ frontendVersionsError.message }}
              </span>
              <div v-else-if="frontendVersionsLoaded" class="entries">
                <a v-for="(frontendVersion, index) in frontendVersionsData[0]" :key="index" class="bg entry" @click.prevent.stop="userSelectedFrontendVersionBeingEditedIndex = index; showEditedFrontendVersionSelector = false">
                  Version #{{ index }}: 
                  {{ frontendVersion.description }}
                  <span class="badge" v-if="index == liveFrontendVersionData.frontendIndex">
                    Live
                  </span>
                </a>
              </div>
            </div>
          </div>

          <span class="selected-version-label">
            <span>
              Version #{{ frontendVersionBeingEditedIndex }}: 
              {{ frontendVersionBeingEdited.description }} 
              <span class="badge" v-if="frontendVersionBeingEditedIndex == liveFrontendVersionData.frontendIndex">
                Live
              </span>
            </span>
            <ChevronUpIcon />
          </span>

        </a>
        <a class="bg" style="display: flex; align-items: center; padding: 0.5em 1em;" @click.prevent.stop="showConfigPanel = !showConfigPanel">
          <GearIcon />
        </a>
      </div>

      <div class="versions-config-panel" v-if="showConfigPanel">
        <FrontendVersionsConfigEditor
          :contractAddress
          :chainId
          :websiteClient="websiteClient"
          />
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

.footer .footer-inner {
  border-top: 1px solid var(--color-divider);
  display: flex;
  align-items: stretch;
  justify-content: space-between;
  background-color: var(--color-root-bg);
  user-select: none;
}

.selected-version-label {
  padding: 0.5em 1em;
  display: flex;
  gap: 1em;
}

.form-select-frontend-version-popup {
  position: relative;
}

.form-select-frontend-version-popup-inner {
  position: absolute;
  bottom: 0;
  background-color: var(--color-root-bg);
  border-top: 1px solid var(--color-divider);
  border-right: 1px solid var(--color-divider);
  border-bottom: 1px solid var(--color-divider-secondary);
  width: 100%;
}

.form-select-frontend-version-popup-inner > span {
  padding: 0.5em 1em;
  display: block;
}

.form-select-frontend-version-popup-inner .entries {
  display: flex;
  flex-direction: column;
}

.form-select-frontend-version-popup-inner .entry {
  padding: 0.5em 1em;
  display: block;
}

.form-select-frontend-version-popup-inner .entries .entry {

}

</style>