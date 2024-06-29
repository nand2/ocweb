<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQueryClient, useMutation } from '@tanstack/vue-query'

import File from './File.vue';
import Folder from './Folder.vue';
import ChevronRightIcon from '../../../icons/ChevronRightIcon.vue';
import ChevronDownIcon from '../../../icons/ChevronDownIcon.vue';

const props = defineProps({
  folderChildren: {
    type: Array,
    required: true,
  },
  folderParents: {
    type: Array,
    default: [],
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
})

const queryClient = useQueryClient()

// Prepare the addition of files
const filesAdditionTransactions = ref([])
const { isPending: prepareAddFilesIsPending, isError: prepareAddFilesIsError, error: prepareAddFilesError, isSuccess: prepareAddFilesIsSuccess, mutate: prepareAddFilesMutate } = useMutation({
  mutationFn: async () => {
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
        filePath: props.folderParents.map(parent => parent + "/").join() + files[i].name,
        size: files[i].size,
        contentType: files[i].type,
        data: new Uint8Array(fileData),
      });
    }
    // Sort by size, so that the smallest files are uploaded first
    // Since files are grouped together in transactions, this help optimize the nb of calls
    fileInfos.sort((a, b) => a.size - b.size);
  
    // Prepare the transaction to upload the files
    const transactions = await props.websiteClient.prepareAddFilesToFrontendVersionTransactions(0, fileInfos);
    console.log(transactions);

    return transactions;
  },
  onSuccess: (data) => {
    filesAdditionTransactions.value = data
  }
})
const prepareAddFilesTransactions = async () => {
  prepareAddFilesMutate()
}

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
      filePath: props.folderParents.map(parent => parent + "/").join() + files[i].name,
      size: files[i].size,
      contentType: files[i].type,
      data: new Uint8Array(fileData),
    });
  }
  // Sort by size, so that the smallest files are uploaded first
  // Since files are grouped together in transactions, this help optimize the nb of calls
  fileInfos.sort((a, b) => a.size - b.size);
 
  // Prepare the transaction to upload the files
  const transactions = await props.websiteClient.prepareAddFilesToFrontendVersionTransactions(0, fileInfos);
  console.log(transactions);

  for(const transaction of transactions) {
    const hash = await props.websiteClient.executeTransaction(transaction);
    console.log(hash);

    // Wait for the transaction to be mined
    const receipt = await props.websiteClient.waitForTransactionReceipt(hash);

    // Refresh the frontend version
    queryClient.invalidateQueries({ queryKey: ['OCWebsiteLiveFrontend', props.contractAddress, props.chainId] })
  }
}
</script>

<template>
  <div>
    <div class="folder-children">
      <div v-for="child in folderChildren" :key="child.name">
        
        <Folder 
          :folder="child" 
          :folderParents="folderParents.concat([child.name])" 
          :contractAddress
          :chainId
          :websiteClient
          v-if="child.type == 'folder'" />
        <File 
          :file="child" 
          :folderParents 
          :contractAddress
          :chainId
          :websiteClient
          v-else-if="child.type == 'file'" />

      </div>
    </div>
    <div class="operations">
      <div class="op-upload">
        <div class="button-area">
          Upload files
          <input type="file" id="files" name="files" multiple @change="prepareAddFilesTransactions">
        </div>
        <div class="form-area">
          <div v-if="prepareAddFilesIsPending">
            Preparing files...
          </div>
          <div v-else-if="prepareAddFilesIsError">
            Error preparing the files: {{ prepareAddFilesError.shortMessage || prepareAddFilesError.message }}
          </div>
          <div v-else-if="prepareAddFilesIsSuccess">
            <div>
              {{ filesAdditionTransactions.length }} transaction{{ filesAdditionTransactions.length > 1 ? "s" : "" }} will be needed :
            </div>
            <div v-for="(transaction, index) in filesAdditionTransactions" :key="transaction.id">
              <div>
                <div>
                  Transaction #{{ index + 1 }}: 
                  <span v-if="transaction.functionName == 'addFilesToFrontendVersion'">
                    Uploading files
                  </span>
                  <span v-else-if="transaction.functionName == 'appendToFileInFrontendVersion'">
                    Add data to file {{ transaction.args[1] }}
                  </span>
                </div>
                <div v-if="transaction.functionName == 'addFilesToFrontendVersion'">
                  <div v-for="(file, index) in transaction.args[1]" :key="index">
                    {{ file.filePath }} ({{ Math.round(file.fileSize / 1024) }} KB<span v-if="file.compressionAlgorithm == 1"> gziped</span>)
                  </div>
                </div>
              </div>
            </div>
            <button type="button" @click="uploadFiles">Upload</button>
          </div>
        </div>
      </div>
      <div class="op-new-folder">
        <div class="button-area">
          New folder
        </div>
        <div class="form-area">

        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.operations {
  display: flex;
  margin: 0em 1em;
  gap: 0.5em;
  align-items:flex-start;
}

.operations > div {

}

.operations > div > div {
  padding: 0.5em 1em;
}

.operations .button-area {
  text-align: center;
  position: relative;
  background-color: var(--color-input-bg);
  border: 1px solid #555;
}

.op-upload {
  flex: 1 0 auto;
}

.op-upload input {
  display: block;
  position: absolute;
  top: 0px;
  left: 0px;
  width: 100%;
  height: 100%;
  opacity: 0;
  cursor: pointer;
}

.op-new-folder {
  flex: 0 0 20%;
}
</style>