<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useClient } from '@wagmi/vue'
import { useSwitchChain, useAccount } from '@wagmi/vue'

import FolderChildren from './FolderChildren.vue';
import { VersionableStaticWebsiteClient } from '../../../../../src/index.js';
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

// Prepare the client
const viemClient = useClient({
  chainId: props.chainId, 
})
const { address } = useAccount()
const websiteClient = new VersionableStaticWebsiteClient(viemClient.value, address.value, props.contractAddress)

// Fetch the live frontend
const { data: frontendVersion, isLoading: frontendVersionLoading, isError: frontendVersionError, error, isSuccess: frontendVersionLoaded } = useQuery({
  queryKey: ['OCWebsiteLiveFrontend', props.contractAddress, props.chainId],
  queryFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    return await websiteClient.getLiveFrontendVersion()
  },
  staleTime: 3600 * 1000,
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

  return root.children;
})

// Upload files
const uploadFiles = async () => {
  const files = document.getElementById('files').files
  if(files.length == 0) {
    return
  }

  // Helper function to read the binary data of a file
  const readFileData = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => {
        resolve(reader.result);
      };
      reader.onerror = (error) => {
        reject(error);
      };
      reader.readAsArrayBuffer(file);
    });
  };

  // Prepare the files for upload
  const fileInfos = []
  for(let i = 0; i < files.length; i++) {
    console.log(files[i])
    // Get binary data of the file
    const fileData = await readFileData(files[i]);
    console.log(fileData);

    fileInfos.push({
      filePath: files[i].name,
      size: files[i].size,
      data: new Uint8Array(fileData),
    });
  }
 
  // Upload the files
  await websiteClient.addFilesToFrontendVersion(0, fileInfos);
}
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

      <input type="file" id="files" name="files" multiple>
      <button type="button" @click="uploadFiles">Upload</button>
    </div>
  </div>
</template>

<style scoped>
.folder-chidren-root {
  margin-top: 0.5em;
}
</style>