<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useReadContract } from '@wagmi/vue'

import { abi } from '../../../utils/IFrontendLibraryABI.js'
import FolderChildren from './FolderChildren.vue';

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

// Fetch the frontends
const { data: frontendVersion, isLoading: frontendVersionLoading, isError: frontendVersionError, isSuccess: frontendVersionLoaded } = useReadContract({
  abi,
  address: props.contractAddress,
  chainId: props.chainId,
  functionName: 'getLiveFrontendVersion',
})

// frontendVersion.files is a flat list of files with their folder structure encoded in 
// their file path
// We convert this flat list into a hierarchical structure
const rootFolderChildren = computed(() => {
  if(frontendVersionLoaded == false) {
    return [];
  }

  const root = { type: 'folder', name: '', children: [] }
  for(const file of frontendVersion.value.files) {
    const filePathParts = file.filePath.split('/')

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
    currentFolder.children.push({type: 'file', name: filePathParts[filePathParts.length - 1], ...file})
  }
  console.log(root.children)

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

        <FolderChildren :folderChildren="rootFolderChildren" />

      </div>
    </div>
  </div>
</template>

<style scoped>
.folder-chidren-root {
  margin-top: 0.5em;
}
</style>