<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQueryClient, useMutation } from '@tanstack/vue-query'

import File from './File.vue';
import Folder from './Folder.vue';
import UploadIcon from '../../../../icons/UploadIcon.vue';
import FolderPlusIcon from '../../../../icons/FolderPlusIcon.vue';
import SendIcon from '../../../../icons/SendIcon.vue';
import CheckLgIcon from '../../../../icons/ChecLgkIcon.vue';
import ExclamationTriangleIcon from '../../../../icons/ExclamationTriangleIcon.vue';
import XCircleIcon from '../../../../icons/XCircleIcon.vue';
import { invalidateWebsiteVersionQuery } from '../../../../utils/queries.js';

const props = defineProps({
  uploadFolder: {
    type: String,
    default: [],
  },
  contentTypeAccept: {
    type: String,
    default: "*/*",
  },
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
  websiteVersionIndex: {
    type: Number,
    required: true,
  },
  staticFrontendPluginClient: {
    type: Object,
    required: true,
  },
})
const emit = defineEmits([
  // The list of transactions to be done is computed and is shown to the user
  'transactionListComputed', 
  // A full file has been uploaded
  'completeFileUploaded', 
  // All files were uploaded (without error)
  'allFilesUploaded', 
  // The form was reinitialized
  'formReinitialized'])

const queryClient = useQueryClient()


//
// Addition of files
//

// Prepare the addition of files
const filesAdditionTransactions = ref([])
const skippedFilesAdditions = ref([])
const { isPending: prepareAddFilesIsPending, isError: prepareAddFilesIsError, error: prepareAddFilesError, isSuccess: prepareAddFilesIsSuccess, mutate: prepareAddFilesMutate, reset: prepareAddFilesReset } = useMutation({
  mutationFn: async () => {
    // Reset any previous upload
    addFileTransactionBeingExecutedIndex.value = -1
    addFileTransactionResults.value = []

    const files = document.getElementById('files').files
    if(files.length == 0) {
      return [];
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
        filePath: props.uploadFolder + files[i].name,
        size: files[i].size,
        contentType: files[i].type,
        data: new Uint8Array(fileData),
      });
    }
    // Sort by size, so that the smallest files are uploaded first
    // Since files are grouped together in transactions, this help optimize the nb of calls
    fileInfos.sort((a, b) => a.size - b.size);
  
    // Prepare the transaction to upload the files
    const transactionsData = await props.staticFrontendPluginClient.prepareAddFilesTransactions(props.websiteVersionIndex, fileInfos);
    console.log(transactionsData);

    return transactionsData;
  },
  onSuccess: (data) => {
    filesAdditionTransactions.value = data.transactions
    skippedFilesAdditions.value = data.skippedFiles

    // Emit the fact that we just computed the list of transactions
    emit('transactionListComputed', data)
  }
})
const prepareAddFilesTransactions = async () => {
  prepareAddFilesMutate()
}

// Execute an upload transaction
const addFileTransactionBeingExecutedIndex = ref(-1)
const addFileTransactionResults = ref([])
const { isPending: addFilesIsPending, isError: addFilesIsError, error: addFilesError, isSuccess: addFilesIsSuccess, mutate: addFilesMutate } = useMutation({
  mutationFn: async ({index, transaction}) => {
    // Store infos about the state of the transaction
    addFileTransactionResults.value.push({status: 'pending'})
    addFileTransactionBeingExecutedIndex.value = index

    const hash = await props.staticFrontendPluginClient.executeTransaction(transaction);
    console.log(hash);

    // Wait for the transaction to be mined
    return await props.staticFrontendPluginClient.waitForTransactionReceipt(hash);
  },
  scope: {
    // This scope will make the mutations run serially
    id: 'addFiles'
  },
  onSuccess: async (data, {index, transaction}) => {
    // Mark the transaction as successful
    addFileTransactionResults.value[addFileTransactionBeingExecutedIndex.value] = {status: 'success'}

    // Refresh the static frontend
    await queryClient.invalidateQueries({ queryKey: ['StaticFrontendPluginStaticFrontend', props.contractAddress, props.chainId, props.websiteVersionIndex] })

    // Emit the completeFileUploaded event when a file, with all his chunks, is uploaded
    if(transaction.functionName == 'addFiles') {
      transaction.metadata.files.forEach((file, fileIndex) => {
        if(file.chunksCount == 1) {
          emit('completeFileUploaded', transaction.args[2][fileIndex].filePath)
        }
      })
    }
    else if(transaction.functionName == 'appendToFile' && transaction.metadata.chunkId == transaction.metadata.chunksCount - 1) {
      emit('completeFileUploaded', transaction.args[2])
    }

    // Emit allFilesUploaded when all transactions are done and were successful
    if(addFileTransactionBeingExecutedIndex.value == filesAdditionTransactions.value.length - 1) {
      emit('allFilesUploaded')
    }
  },
  onError: (error) => {
    // Mark the transaction as failed
    addFileTransactionResults.value[addFileTransactionBeingExecutedIndex.value] = {status: 'error', error}
  }
})
const executePreparedAddFilesTransactions = async () => {
  for(const [index, transaction] of filesAdditionTransactions.value.entries()) {
    addFilesMutate({index, transaction})
  }
}

// Clear the addFiles form completely, including the executed transactions
const clearAddFilesForm = () => {
  prepareAddFilesReset()
  document.getElementById('files').value = ''

  // Emit the fact that the form was reinitialized
  emit('formReinitialized')
}


</script>

<template>
  <div class="op-upload">
    <div class="button-area">
      <span class="button-text">
        <UploadIcon /> Pick files or drag and drop
      </span>
      <input type="file" id="files" name="files" multiple :accept="contentTypeAccept" @change="prepareAddFilesTransactions">
    </div>
    <div class="form-area" v-if="prepareAddFilesIsPending || prepareAddFilesIsError || prepareAddFilesIsSuccess">

      <div v-if="prepareAddFilesIsPending">
        Preparing files for upload ...
      </div>
      <div v-else-if="prepareAddFilesIsError" class="text-danger">
        Error preparing the files: {{ prepareAddFilesError.shortMessage || prepareAddFilesError.message }}
      </div>

      <div v-else-if="prepareAddFilesIsSuccess">
        <div class="transactions-count">
          <div>
            {{ filesAdditionTransactions.length }} transaction{{ filesAdditionTransactions.length > 1 ? "s" : "" }} will be needed
            <span class="text-muted" style="font-weight: normal; font-size: 0.9em;">
              Uploading {{ Math.round(filesAdditionTransactions.reduce((acc, tx) => acc + (tx.metadata.sizeSent || tx.metadata.files.reduce((acc, file) => acc + file.sizeSent, 0)), 0) / 1024) }} KB
            </span>
          </div>
          <div style="line-height: 1em;">
            <a @click.stop.prevent="clearAddFilesForm" class="white">
              <XCircleIcon />
            </a>
          </div>
        </div>
        <div v-for="(transaction, txIndex) in filesAdditionTransactions" :key="transaction.id" class="transaction">

          <div class="icon">
            <CheckLgIcon v-if="txIndex <= addFileTransactionBeingExecutedIndex && addFileTransactionResults[txIndex].status == 'success'" class="text-success" />
            <ExclamationTriangleIcon v-else-if="txIndex <= addFileTransactionBeingExecutedIndex && addFileTransactionResults[txIndex].status == 'error'" class="text-danger" />
            <SendIcon v-else :class="{'anim-pulse': addFilesIsPending && txIndex == addFileTransactionBeingExecutedIndex}" />
          </div>

          <div class="transaction-inner">
            <div class="transaction-title">
              Transaction #{{ txIndex + 1 }}: 
              <span v-if="transaction.functionName == 'addFiles'">
                Uploading files
              </span>
              <span v-else-if="transaction.functionName == 'appendToFile'">
                Add data to file
              </span>
            </div>
            <div v-if="transaction.functionName == 'addFiles'" class="transaction-details">
              <div v-for="(file, index) in transaction.args[2]" :key="index">
                <code class="filename">{{ file.filePath }}</code>
                <span class="text-muted filename-details">
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
                <span v-if="(txIndex <= addFileTransactionBeingExecutedIndex && addFileTransactionResults[txIndex].status == 'success') == false && transaction.metadata.files[index].alreadyExists" class="text-warning filename-details">
                  <ExclamationTriangleIcon style="width: 1.2em; height: 0.9em;" />Overwrite existing file
                </span>
              </div>
            </div>
            <div v-else-if="transaction.functionName == 'appendToFile'" class="transaction-details">
              <div>
                <code class="filename">{{ transaction.args[2] }}</code>
                <span class="text-muted  filename-details">
                  +{{ Math.round(transaction.metadata.sizeSent / 1024) }} KB
                  (chunk {{ transaction.metadata.chunkId + 1 }} / {{ transaction.metadata.chunksCount }})
                </span>
              </div>
            </div>

            <div v-if="txIndex <= addFileTransactionBeingExecutedIndex && addFileTransactionResults[txIndex].status == 'error' && addFileTransactionResults[txIndex].error" class="transaction-error text-danger">
              Error uploading files: {{ addFileTransactionResults[txIndex].error.shortMessage || addFileTransactionResults[txIndex].error.message }}
            </div>
          </div>
        </div>

        <div class="skipped-files" v-if="skippedFilesAdditions.length > 0">
          <div class="icon text-muted">
            <CheckLgIcon />
          </div>
          <div>
            <div class="skipped-files-title">
              <strong class="text-muted">Skipped files</strong> <span class="text-muted text-90">(Identical file already uploaded)</span>
            </div>
            <div v-for="file in skippedFilesAdditions" :key="file.filePath" class="skipped-file text-muted">
              <code>{{ file.filePath }}</code>
            </div>
          </div>
        </div>

        <button type="button" v-if="addFileTransactionResults.length == 0 || addFileTransactionResults.length > 0 && addFilesIsPending" @click="executePreparedAddFilesTransactions" style="width: 100%" :disabled=" filesAdditionTransactions.length == 0 || addFilesIsPending">Upload files</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
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


/**
 * op-upload form
 */
.transactions-count {
  font-weight: bold;
  margin-bottom: 0.4em;
  display: flex;
  justify-content: space-between;
  align-items: center;
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

.transaction-details .filename-details {
  font-size: 0.9em;
}

@media (max-width: 700px) {
  .transaction-details .zip-infos {
    display: none;
  }
}

.transaction-error {
  line-height: 1.2em;
  font-size: 0.9em;
  margin-top: 0.3em;
}

.skipped-files {
  padding: 0.5em 0em;
  border-top: 1px solid #555;
  display: flex;
  gap: 0.75em;
}

.skipped-files .icon {
  padding-top: 0.25em;
}

</style>