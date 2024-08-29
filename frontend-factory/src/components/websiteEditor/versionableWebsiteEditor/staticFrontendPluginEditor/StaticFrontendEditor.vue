<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useConnectorClient } from '@wagmi/vue'
import { useSwitchChain, useAccount } from '@wagmi/vue'
import { useQueryClient } from '@tanstack/vue-query'
import { useIsLocked } from '../../../../../../src/tanstack-vue.js';
import { useStaticFrontendPluginClient, useStaticFrontend } from '../../../../../../src/plugins/staticFrontend/tanstack-vue.js';

import FolderChildren from './FolderChildren.vue';

const props = defineProps({
  websiteVersion: {
    type: Object,
    required: true
  },
  websiteVersionIndex: {
    type: Number,
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
    type: Object,
    required: true,
  },
  pluginInfos: {
    type: Object,
    required: true,
  },
})

const { switchChainAsync } = useSwitchChain()
const queryClient = useQueryClient()
const { data: viemClient, isSuccess: viemClientLoaded } = useConnectorClient()

// Get the staticFrontendPluginClient
const { data: staticFrontendPluginClient, isLoading: staticFrontendPluginClientLoading, isFetching: staticFrontendPluginClientFetching, isError: staticFrontendPluginClientIsError, error: staticFrontendPluginClientError, isSuccess: staticFrontendPluginClientLoaded } = useStaticFrontendPluginClient(props.contractAddress, props.pluginInfos.plugin)

// Get the lock status
const { data: isLocked, isLoading: isLockedLoading, isFetching: isLockedFetching, isError: isLockedIsError, error: isLockedError, isSuccess: isLockedLoaded } = useIsLocked(props.contractAddress, props.chainId)

// Folders are not stored in the backend, like git
// We keep track of the empty folders to display them
const globalEmptyFolders = ref([])

// Fetch the static frontend
const { data: staticFrontend, isLoading: staticFrontendLoading, isFetching: staticFrontendFetching, isError: staticFrontendIsError, error: staticFrontendError, isSuccess: staticFrontendLoaded } = useStaticFrontend(queryClient, props.contractAddress, props.chainId, props.pluginInfos.plugin, computed(() => props.websiteVersionIndex))


// Fetch the frontend files extra metadata from the storage backend
const { data: frontendFilesSizes, isLoading: frontendFilesSizesLoading, isError: frontendFilesSizesIsError, error: frontendFilesSizesError, isSuccess: frontendFilesSizesLoaded } = useQuery({
  queryKey: ['StaticFrontendPluginStaticFrontendFileSizes', props.contractAddress, props.chainId, computed(() => props.websiteVersionIndex)],
  queryFn: async () => {

    return await staticFrontendPluginClient.value.getStaticFrontendFilesSizesFromStorageBackend(props.websiteVersionIndex, staticFrontend.value)
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => props.websiteVersion != null && staticFrontendPluginClient.value != null && staticFrontendLoaded.value == true && staticFrontendFetching.value == false),
})


// websiteVersion.files is a flat list of files with their folder structure encoded in 
// their file path
// We convert this flat list into a hierarchical structure
const rootFolderChildren = computed(() => {
  if(staticFrontend.value == null) {
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
  for(const file of staticFrontend.value.files) {
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

    <div v-if="websiteVersion == null || staticFrontendPluginClientLoading || staticFrontendLoading">
      Loading...
    </div>
<!-- 
    <div v-else-if="websiteVersionError == true">
      Error loading the files: {{ error.shortMessage || error.message }}
    </div> -->

    <div v-else-if="staticFrontendPluginClientLoaded && staticFrontendLoaded">
      <div v-if="staticFrontend.files.length == 0" class="no-files">
        No files<br />
        Start by uploading an index.html file!
      </div>

      <FolderChildren 
        class="folder-chidren-root"
        :folderChildren="rootFolderChildren" 
        :locked="isLockedLoaded && isLocked || websiteVersion.locked"
        :contractAddress 
        :chainId 
        :websiteVersion
        :websiteVersionIndex 
        :pluginInfos
        :staticFrontendPluginClient
        :globalEmptyFolders />

    </div>
  </div>
</template>

<style scoped>
.frontend-version-editor {
  margin-bottom: 1em;
}

.table-header {
  grid-template-columns: 5fr 2fr 1.5fr 1fr 1fr;
  padding: 0.5em 0em;
  gap: 0rem;
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
}

.no-files {
  text-align: center;
  padding: 2em 0em;
  color: var(--color-text-muted);
}

.folder-chidren-root {
  margin-top: 0.25em;
}
</style>