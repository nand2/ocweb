<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useSwitchChain, useAccount } from '@wagmi/vue'
import { useQueryClient } from '@tanstack/vue-query'

import FrontendVersionEditor from './FrontendVersionEditor.vue';
import FrontendVersionList from './FrontendVersionList.vue';
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
    
    return await websiteClient.value.getFrontendVersion(frontendVersionBeingEditedIndex.value)
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => websiteClientLoaded.value && liveFrontendVersionLoaded.value),
})


// Create frontendVersion
const newFrontendVersionDescription = ref("")
const { isPending: newfrontendversionIsPending, isError: newfrontendversionIsError, error: newfrontendversionError, isSuccess: newfrontendversionIsSuccess, mutate: newfrontendversionMutate, reset: newfrontendversionReset } = useMutation({
  mutationFn: async () => {
    // Prepare the transaction
    const transaction = await websiteClient.value.prepareAddFrontendVersionTransaction("0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB", newFrontendVersionDescription.value);

    const hash = await websiteClient.value.executeTransaction(transaction);

    return await websiteClient.value.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    // Refresh the frontend version
    return await queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersion', props.contractAddress, props.chainId, props.frontendVersionIndex] })
  }
})
const newfrontendversionFile = async () => {
  // // Check that the name is not already taken
  // if(props.folderParentChildren.find(child => child.name === newFileName.value)) {
  //   preNewFrontendVersionError.value = 'A file with this name already exists in this folder'
  //   return
  // }

  newfrontendversionMutate()
}

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
      <div class="versions-body" v-if="showVersionPanel">
        
        <div class="versions-list">
          <FrontendVersionList 
            :contractAddress
            :chainId
            :websiteClient="websiteClient"
            />
        </div>

        <div class="versions-actions">
          <div class="versions-add-new-form">
            <div>
              <input type="text" v-model="newFrontendVersionDescription" placeholder="Version description" />
              <br />
              <button @click="newfrontendversionFile">Add new version</button>
            </div>
            <span v-if="newfrontendversionIsError">
              Error adding new version: {{ newfrontendversionError.shortMessage || newfrontendversionError.message }}
            </span>
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