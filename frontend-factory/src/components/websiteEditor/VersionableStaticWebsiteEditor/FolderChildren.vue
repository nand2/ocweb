<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQueryClient, useMutation } from '@tanstack/vue-query'

import File from './File.vue';
import Folder from './Folder.vue';
import UploadIcon from '../../../icons/UploadIcon.vue';
import FolderPlusIcon from '../../../icons/FolderPlusIcon.vue';
import SendIcon from '../../../icons/SendIcon.vue';
import FileZipIcon from '../../../icons/FileZipIcon.vue';

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

// Execute an upload transaction
const { isPending: addFilesIsPending, isError: addFilesIsError, error: addFilesError, isSuccess: addFilesIsSuccess, mutate: addFilesMutate } = useMutation({
  mutationFn: async (transaction) => {
    const hash = await props.websiteClient.executeTransaction(transaction);
    console.log(hash);

    // Wait for the transaction to be mined
    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  scope: {
    // This scope will make the mutations run serially
    id: 'addFilesToFrontendVersion'
  },
  onSuccess: (data) => {
    // Refresh the frontend version
    queryClient.invalidateQueries({ queryKey: ['OCWebsiteLiveFrontend', props.contractAddress, props.chainId] })
  }
})
const executePreparedAddFilesTransactions = async () => {
  for(const transaction of filesAdditionTransactions.value) {
    addFilesMutate(transaction)
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
          <span class="button-text">
            <UploadIcon /> Pick a file or drag and drop
          </span>
          <input type="file" id="files" name="files" multiple @change="prepareAddFilesTransactions">
        </div>
        <div class="form-area" v-if="filesAdditionTransactions.length > 0">
          <div v-if="prepareAddFilesIsPending">
            Preparing files...
          </div>
          <div v-else-if="prepareAddFilesIsError">
            Error preparing the files: {{ prepareAddFilesError.shortMessage || prepareAddFilesError.message }}
          </div>
          <div v-else-if="prepareAddFilesIsSuccess">
            <div class="transactions-count">
              {{ filesAdditionTransactions.length }} transaction{{ filesAdditionTransactions.length > 1 ? "s" : "" }} will be needed
            </div>
            <div v-for="(transaction, index) in filesAdditionTransactions" :key="transaction.id" class="transaction">
              <div class="icon">
                <SendIcon />
              </div>
              <div class="transaction-inner">
                <div class="transaction-title">
                  Transaction #{{ index + 1 }}: 
                  <span v-if="transaction.functionName == 'addFilesToFrontendVersion'">
                    Uploading files
                  </span>
                  <span v-else-if="transaction.functionName == 'appendToFileInFrontendVersion'">
                    Add data to file
                  </span>
                </div>
                <div v-if="transaction.functionName == 'addFilesToFrontendVersion'" class="transaction-details">
                  <div v-for="(file, index) in transaction.args[1]" :key="index">
                    <code class="filename">{{ file.filePath }}</code>
                    <span class="text-muted" style="font-size: 0.9em">
                      <span v-if="transaction.metadata.files[index].chunksCount > 1">
                        {{ Math.round(transaction.metadata.files[index].sizeSent / 1024) }} /
                      </span>
                      {{ Math.round(file.fileSize / 1024) }} KB
                      <span v-if="file.compressionAlgorithm > 0" class="zip-infos">
                        (zipped
                        from {{ Math.round(transaction.metadata.files[index].originalSize / 1024) }} KB)
                      </span>
                      <span v-if="transaction.metadata.files[index].chunksCount > 1">
                        (chunk 1 / {{ transaction.metadata.files[index].chunksCount }})
                      </span>
                    </span>
                  </div>
                </div>
                <div v-else-if="transaction.functionName == 'appendToFileInFrontendVersion'" class="transaction-details">
                  <div>
                    <code class="filename">{{ transaction.args[1] }}</code>
                    <span class="text-muted" style="font-size: 0.9em">
                      +{{ Math.round(transaction.metadata.sizeSent / 1024) }} KB
                      (chunk {{ transaction.metadata.chunkId + 1 }} / {{ transaction.metadata.chunksCount }})
                    </span>
                  </div>
                </div>
              </div>
            </div>
            <button type="button" @click="executePreparedAddFilesTransactions" style="width: 100%">Upload files</button>
          </div>
        </div>
      </div>
      <div class="op-new-folder">
        <div class="button-area">
          <span class="button-text">
            <FolderPlusIcon />
            New folder
          </span>
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
@media (max-width: 700px) {
  .operations {
    flex-direction: column;
  }
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

.operations .button-area .button-text {
  display: flex;
  gap: 0.5em;
  align-items: center;
  justify-content: center;
}

.operations .form-area {
  border-left: 1px solid #555;
  border-right: 1px solid #555;
  border-bottom: 1px solid #555;
  background-color: var(--color-popup-bg);
  font-size: 0.9em;
}

.op-upload {
  flex: 1 0;
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


/**
 * op-upload form
 */
.transactions-count {
  font-weight: bold;
  margin-bottom: 0.4em;
}

.transaction {
  padding: 0.5em 0em;
  border-top: 1px solid #555;
  display: flex;
  gap: 0.75em;
}

.transaction .icon {
  padding-top: 0.25em;
}

.transaction-title {
  font-weight: bold;
  margin-bottom: 0.3em;
}

.transaction-details .filename {
  margin-right: 0.4em;
}

@media (max-width: 700px) {
  .transaction-details .zip-infos {
    display: none;
  }
}
</style>