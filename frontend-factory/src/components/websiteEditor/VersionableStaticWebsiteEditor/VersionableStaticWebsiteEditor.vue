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
const { data: frontendVersion, isLoading: frontendVersionLoading, isError: frontendVersionError, error, isSuccess: frontendVersionLoaded } = useQuery({
  queryKey: ['OCWebsiteLiveFrontend', props.contractAddress, props.chainId],
  queryFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })
    
    return await websiteClient.value.getLiveFrontendVersion()
  },
  staleTime: 3600 * 1000,
  enabled: websiteClientLoaded,
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
      contentType: files[i].type,
      data: new Uint8Array(fileData),
    });
  }
  // Sort by size, so that the smallest files are uploaded first
  // Since files are grouped together in transactions, this help optimize the nb of calls
  fileInfos.sort((a, b) => a.size - b.size);
 
  // Prepare the request to upload the files
  const requests = await websiteClient.value.prepareAddFilesToFrontendVersionRequests(0, fileInfos);
  console.log(requests);

  for(const request of requests) {
    const hash = await websiteClient.value.executeRequest(request);
    console.log(hash);

    // Wait for the transaction to be mined
    const receipt = await websiteClient.value.waitForTransactionReceipt(hash);

    // Refresh the frontend version
    queryClient.invalidateQueries({ queryKey: ['OCWebsiteLiveFrontend', props.contractAddress, props.chainId] })
  }
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

        <FolderChildren :folderChildren="rootFolderChildren" :contractAddress :chainId />

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