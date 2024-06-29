<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useConnectorClient } from '@wagmi/vue'
import { useSwitchChain, useAccount } from '@wagmi/vue'
import { useQueryClient } from '@tanstack/vue-query'

import FolderChildren from './FolderChildren.vue';
import { VersionableStaticWebsiteClient } from '../../../../../src/index.js';
import { useVersionableStaticWebsiteClient } from '../../../utils/queries.js';
import { size } from 'viem';

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

// Fetch the website client
const { data: websiteClient, isSuccess: websiteClientLoaded } = useVersionableStaticWebsiteClient
(props.contractAddress)

// Fetch the live frontend
const { data: frontendVersion, isLoading: frontendVersionLoading, isFetching: frontendVersionFetching, isError: frontendVersionError, error, isSuccess: frontendVersionLoaded } = useQuery({
  queryKey: ['OCWebsiteLiveFrontend', props.contractAddress, props.chainId],
  queryFn: async () => {
    // Invalidate dependent query
    queryClient.invalidateQueries({ queryKey: ['OCWebsiteLiveFrontendFilesExtraMetadata', props.contractAddress, props.chainId] })

    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })
    
    return await websiteClient.value.getLiveFrontendVersion()
  },
  staleTime: 3600 * 1000,
  enabled: websiteClientLoaded,
})

// Fetch the frontend files extra metadata from the storage backend
const { data: frontendFilesExtraMetadata, isLoading: frontendFilesExtraMetadataLoading, isError: frontendFilesExtraMetadataError, isSuccess: frontendFilesExtraMetadataLoaded } = useQuery({
  queryKey: ['OCWebsiteLiveFrontendFilesExtraMetadata', props.contractAddress, props.chainId],
  queryFn: async () => {
    return await websiteClient.value.getFrontendFilesExtraMetadataFromStorageBackend(frontendVersion.value)
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => frontendVersionLoaded.value && frontendVersionFetching.value == false),
})


// frontendVersion.files is a flat list of files with their folder structure encoded in 
// their file path
// We convert this flat list into a hierarchical structure
const rootFolderChildren = computed(() => {
  if(frontendVersionLoaded.value == false) {
    return [];
  }

  const root = { type: 'folder', name: '', children: [] }
  for(const file of frontendVersion.value.files) {
    const filePathParts = file.filePath.split('/')

    // Find or create the folder for the file
    let currentFolder = root
    for(let i = 0; i < filePathParts.length - 1; i++) {
      const folderName = filePathParts[i]
      let nextFolder = currentFolder.children.find(child => child.type == 'folder' && child.name == folderName)
      if(nextFolder == null) {
        nextFolder = { type: 'folder', name: folderName, children: [] }
        currentFolder.children.push(nextFolder)
      }
      currentFolder = nextFolder
    }

    // Add the file to the folder
    let folderFile = {type: 'file', name: filePathParts[filePathParts.length - 1], ...file}
    // If loaded, add the extra metadata to the file
    if(frontendFilesExtraMetadataLoaded.value) {
      const extraMetadata = frontendFilesExtraMetadata.value.find(extraMetadata => extraMetadata.filePath == file.filePath)
      if(extraMetadata != null) {
        folderFile = {...folderFile, ...extraMetadata}
      }
    }
    currentFolder.children.push(folderFile)

    // Sort the children: First folders in alphabetical order, then files in alphabetical order
    currentFolder.children.sort((a, b) => {
      if(a.type == 'folder' && b.type == 'file') {
        return -1
      }
      if(a.type == 'file' && b.type == 'folder') {
        return 1
      }
      return a.name.localeCompare(b.name)
    })
  }

  return root.children;
})
</script>

<template>
  <div>
    <div v-if="frontendVersionLoading == true">
      Loading...
    </div>

    <div v-else-if="frontendVersionError == true">
      Error loading the files: {{ error.shortMessage || error.message }}
    </div>

    <div v-else-if="frontendVersionLoaded">
      <div v-if="frontendVersion.files.length == 0">
        No files
      </div>
      <div v-else class="folder-chidren-root">

        <FolderChildren :folderChildren="rootFolderChildren" :contractAddress :chainId :websiteClient />

      </div>
    </div>
  </div>
</template>

<style scoped>
.folder-chidren-root {
  margin-top: 0.5em;
}
</style>