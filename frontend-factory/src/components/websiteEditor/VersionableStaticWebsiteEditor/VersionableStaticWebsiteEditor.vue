<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useSwitchChain, useAccount } from '@wagmi/vue'
import { useQueryClient } from '@tanstack/vue-query'

import FilesTab from './FilesTab.vue';
import PreviewTab from './PreviewTab.vue';
import SettingsTab from './SettingsTab.vue';
import FrontendVersionEditor from './FrontendVersionFilesEditor.vue';
import FrontendVersionsConfigEditor from './FrontendVersionsConfigEditor.vue';
import { useVersionableStaticWebsiteClient, useLiveFrontendVersion, useFrontendVersions } from '../../../utils/queries.js';
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

// Tabs handling
const activeTab = ref('files');
const activeComponent = computed(() => {
  switch (activeTab.value) {
    case 'files':
      return FilesTab;
    case 'preview':
      return PreviewTab;
    case 'settings':
      return SettingsTab;
  }
});


// Fetch the website client
const { data: websiteClient, isSuccess: websiteClientLoaded } = useVersionableStaticWebsiteClient
(props.contractAddress)


// Fetch the live frontend infos
const { data: liveFrontendVersionData, isLoading: liveFrontendVersionLoading, isFetching: liveFrontendVersionFetching, isError: liveFrontendVersionIsError, error: liveFrontendVersionError, isSuccess: liveFrontendVersionLoaded } = useLiveFrontendVersion(queryClient, props.contractAddress, props.chainId)

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

// Get the frontend version being edited
const { data: frontendVersionBeingEdited, isLoading: frontendVersionBeingEditedLoading, isFetching: frontendVersionBeingEditedFetching, isError: frontendVersionBeingEditedIsError, error: frontendVersionBeingEditedError, isSuccess: frontendVersionBeingEditedLoaded } = useQuery({
  queryKey: ['OCWebsiteFrontendVersion', props.contractAddress, props.chainId, frontendVersionBeingEditedIndex],
  queryFn: async () => {
    // Invalidate dependent query : sizes
    queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersionFilesSizes', props.contractAddress, props.chainId, frontendVersionBeingEditedIndex.value] })

    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    return await websiteClient.value.getFrontendVersion(frontendVersionBeingEditedIndex.value)
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => websiteClientLoaded.value && liveFrontendVersionLoaded.value),
})


// Get the list frontend versions : Only when the user display the form to select a version
const showEditedFrontendVersionSelector = ref(false)
const { data: frontendVersionsData, isLoading: frontendVersionsLoading, isFetching: frontendVersionsFetching, isError: frontendVersionsIsError, error: frontendVersionsError, isSuccess: frontendVersionsLoaded } = useFrontendVersions(queryClient, props.contractAddress, props.chainId, showEditedFrontendVersionSelector)

const showConfigPanel = ref(false)
</script>

<template>
  <div class="versionable-static-website-editor">
    
    <div class="tabs">
      <a @click="activeTab = 'files'" :class="{tabFiles: true, active: activeTab == 'files'}">Files</a>
      <a @click="activeTab = 'preview'" :class="{tabPreview: true, active: activeTab == 'preview'}">Preview</a>
      <a @click="activeTab = 'settings'" :class="{tabSettings: true, active: activeTab == 'settings'}">Settings</a>
    </div>
    
    <FilesTab 
      :frontendVersion="frontendVersionBeingEditedLoaded ? frontendVersionBeingEdited : null"
      :frontendVersionIndex="frontendVersionBeingEditedIndex"
      :frontendVersionIsFetching="frontendVersionBeingEditedFetching"
      :contractAddress 
      :chainId 
      :websiteClient="websiteClient"
      class="tab" v-show="activeTab == 'files'" />
    <PreviewTab 
      :frontendVersion="frontendVersionBeingEditedLoaded ? frontendVersionBeingEdited : null"
      :frontendVersionIndex="frontendVersionBeingEditedIndex"
      :contractAddress 
      :chainId 
      :websiteClient="websiteClient"
      class="tab" v-show="activeTab == 'preview'" />
    <SettingsTab 
      :frontendVersion="frontendVersionBeingEditedLoaded ? frontendVersionBeingEdited : null"
      :frontendVersionIndex="frontendVersionBeingEditedIndex"
      :contractAddress 
      :chainId 
      :websiteClient="websiteClient"
      class="tab" v-show="activeTab == 'settings'" />


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
}


.tabs {
  display: flex;
  gap: 1em;
  padding-left: 1em;
  padding-right: 1em;
  background-color: #303030;
  justify-content: space-between;
  border-bottom: 1px solid var(--color-divider);
}

.tabs a {
  color: var(--color-text);
  padding-top: 1em;
  padding-bottom: calc(1em - 3px);
}

.tabs a:hover {
  color: var(--color-bglink-hover);
}

.tabs a.active {
  border-bottom: 3px solid var(--color-link);

}

.tabSettings {
  margin-left: auto;
}


.footer {
  margin-top: auto;
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