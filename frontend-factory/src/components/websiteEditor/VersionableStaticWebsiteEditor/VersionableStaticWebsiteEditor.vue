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

// Folders are not stored in the backend, like git
// We keep track of the empty folders to display them
const globalEmptyFolders = ref([])

// Fetch the website client
const { data: websiteClient, isSuccess: websiteClientLoaded } = useVersionableStaticWebsiteClient
(props.contractAddress)

// Fetch the live frontend
const { data: frontendVersion, isLoading: frontendVersionLoading, isFetching: frontendVersionFetching, isError: frontendVersionError, error, isSuccess: frontendVersionLoaded } = useQuery({
  queryKey: ['OCWebsiteLiveFrontend', props.contractAddress, props.chainId],
  queryFn: async () => {
    // Invalidate dependent query
    queryClient.invalidateQueries({ queryKey: ['OCWebsiteLiveFrontendFilesSizes', props.contractAddress, props.chainId] })

    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })
    
    return await websiteClient.value.getLiveFrontendVersion()
  },
  staleTime: 3600 * 1000,
  enabled: websiteClientLoaded,
})

// Fetch the frontend files extra metadata from the storage backend
const { data: frontendFilesSizes, isLoading: frontendFilesSizesLoading, isError: frontendFilesSizesError, isSuccess: frontendFilesSizesLoaded } = useQuery({
  queryKey: ['OCWebsiteLiveFrontendFilesSizes', props.contractAddress, props.chainId],
  queryFn: async () => {
    return await websiteClient.value.getFrontendFilesSizesFromStorageBackend(frontendVersion.value)
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
  // Inject the empty folders
  for(const emptyFolder of globalEmptyFolders.value) {
    const emptyFolderParts = emptyFolder.split('/')
    let currentFolder = root
    for(const folderPart of emptyFolderParts) {
      let nextFolder = currentFolder.children.find(child => child.type == 'folder' && child.name == folderPart)
      if(nextFolder == null) {
        nextFolder = { type: 'folder', name: folderPart, children: [] }
        currentFolder.children.push(nextFolder)
        currentFolder.children.sort((a, b) => a.name.localeCompare(b.name))
      }
      currentFolder = nextFolder
    }
  }

  // Inject the files
  for(const file of frontendVersion.value.files) {
    const filePathParts = file.filePath.split('/')

    // Function to sort the children: First folders in alphabetical order, then files in alphabetical order
    const sortChildren = (a, b) => {
      if(a.type == 'folder' && b.type == 'file') {
        return -1
      }
      if(a.type == 'file' && b.type == 'folder') {
        return 1
      }
      return a.name.localeCompare(b.name)
    }

    // Find or create the folder for the file
    let currentFolder = root
    for(let i = 0; i < filePathParts.length - 1; i++) {
      const folderName = filePathParts[i]
      let nextFolder = currentFolder.children.find(child => child.type == 'folder' && child.name == folderName)
      if(nextFolder == null) {
        nextFolder = { type: 'folder', name: folderName, children: [] }
        currentFolder.children.push(nextFolder)
        currentFolder.children.sort(sortChildren)
      }
      currentFolder = nextFolder
    }

    // Add the file to the folder
    let folderFile = {type: 'file', name: filePathParts[filePathParts.length - 1], ...file}
    // If loaded, add the extra metadata to the file
    if(frontendFilesSizesLoaded.value) {
      const extraMetadata = frontendFilesSizes.value.find(extraMetadata => extraMetadata.filePath == file.filePath)
      if(extraMetadata != null) {
        folderFile = {...folderFile, ...extraMetadata}
      }
    }
    currentFolder.children.push(folderFile)
    currentFolder.children.sort(sortChildren)
  }

  return root.children;
})
</script>

<template>
  <div class="versionable-static-website-editor">
    <div class="table-header">
      <div>
        Name
      </div>
      <div class="content-type">
        Type
      </div>
      <div class="size">
        Size
      </div>
      <div class="compression" style="font-size: 80%">
        Compression
      </div>
      <div>
      </div>
    </div>

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

        <FolderChildren 
          :folderChildren="rootFolderChildren" 
          :contractAddress :chainId :websiteClient :globalEmptyFolders />

      </div>
    </div>
  </div>
</template>

<style scoped>
.versionable-static-website-editor {
  margin-bottom: 1em;
}

.table-header {
  display: grid;
  grid-template-columns: 5fr 2fr 1.5fr 1fr 1fr;
  padding: 0.5em 0em;
  font-weight: bold;
  border-bottom: 1px solid #555;
  background-color: var(--color-root-bg)
}

@media (max-width: 700px) {
  .table-header {
    grid-template-columns: 2fr max-content;
  }

  .table-header > .content-type,
  .table-header > .compression,
  .table-header > .size {
    display: none;
  }
}

.table-header > div {
  padding: 0em 1em;
  word-break: break-all;
}

.folder-chidren-root {
  margin-top: 0.5em;
}
</style>