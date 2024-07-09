<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useConnectorClient } from '@wagmi/vue'
import { useSwitchChain, useAccount } from '@wagmi/vue'
import { useQueryClient } from '@tanstack/vue-query'

import FolderChildren from './FolderChildren.vue';
import { size } from 'viem';

const props = defineProps({
  frontendVersion: {
    type: [Object, null],
    required: true
  },
  frontendVersionIndex: {
    type: Number,
    required: true,
  },
  frontendVersionIsFetching: {
    type: Boolean,
    required: true,
  },
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

const { switchChainAsync } = useSwitchChain()
const queryClient = useQueryClient()

// Folders are not stored in the backend, like git
// We keep track of the empty folders to display them
const globalEmptyFolders = ref([])

// Fetch the frontend files extra metadata from the storage backend
const { data: frontendFilesSizes, isLoading: frontendFilesSizesLoading, isError: frontendFilesSizesError, isSuccess: frontendFilesSizesLoaded } = useQuery({
  queryKey: ['OCWebsiteFrontendVersionFilesSizes', props.contractAddress, props.chainId, computed(() => props.frontendVersionIndex)],
  queryFn: async () => {

    return await props.websiteClient.getFrontendFilesSizesFromStorageBackend(props.frontendVersion)
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => props.frontendVersion != null && props.websiteClient != null && props.frontendVersionIsFetching == false),
})


// frontendVersion.files is a flat list of files with their folder structure encoded in 
// their file path
// We convert this flat list into a hierarchical structure
const rootFolderChildren = computed(() => {
  if(props.frontendVersion == null) {
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
  for(const file of props.frontendVersion.files) {
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
  <div class="frontend-version-editor">
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

    <div v-if="frontendVersion == null">
      Loading...
    </div>
<!-- 
    <div v-else-if="frontendVersionError == true">
      Error loading the files: {{ error.shortMessage || error.message }}
    </div> -->

    <div v-else>
      <div v-if="frontendVersion.files.length == 0" class="no-files">
        No files
      </div>

      <FolderChildren 
        :folderChildren="rootFolderChildren" 
        :locked="frontendVersion.locked"
        :contractAddress :chainId :frontendVersionIndex :websiteClient :globalEmptyFolders />

    </div>
  </div>
</template>

<style scoped>
.frontend-version-editor {
  margin-bottom: 1em;
}

.table-header {
  display: grid;
  grid-template-columns: 5fr 2fr 1.5fr 1fr 1fr;
  padding: 0.5em 0em;
  font-weight: bold;
  border-bottom: 1px solid var(--color-divider-secondary);
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

.no-files {
  text-align: center;
  padding: 2em 0em;
  color: var(--color-text-muted);
}

.folder-chidren-root {
  margin-top: 0.5em;
}
</style>