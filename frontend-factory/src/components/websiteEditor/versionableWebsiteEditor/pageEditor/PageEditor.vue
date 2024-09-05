<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useQueryClient, useMutation } from '@tanstack/vue-query'
import TextEditor from './TextEditor.vue';

import { useStaticFrontendFileContent, invalidateStaticFrontendFileContentQuery } from '../../../../../../src/plugins/staticFrontend/tanstack-vue';


const emit = defineEmits(['editCancelled', 'pageSaved'])

const props = defineProps({
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
  pluginInfos: {
    type: Object,
    required: true,
  },
  websiteVersion: {
    type: Object,
    required: true
  },
  websiteVersionIndex: {
    type: Number,
    required: true,
  },
  staticFrontendPluginClient: {
    type: Object,
    required: true,
  },
  // If editing an existing file, provide the file infos
  fileInfos: {
    type: Object,
    default: null
  },
  // Otherwise, infos about the new file
  newFileContentType: {
    type: String,
    default: "text/markdown"
  },
  newFileFolder: {
    type: String,
    default: "pages/"
  }
})


const queryClient = useQueryClient()

// Fetch the file content
const { data: fileContent, isLoading: fileContentLoading, isFetching: fileContentFetching, isError: fileContentIsError, error: fileContentError, isSuccess: fileContentLoaded } = useStaticFrontendFileContent(props.contractAddress, props.chainId, props.pluginInfos.plugin, computed(() => props.websiteVersionIndex), computed(() => props.fileInfos))
const decodeFileContentAsText = (fileContent) => {
  return fileContent ? new TextDecoder().decode(fileContent) : '';
}

const name = ref(props.fileInfos ? props.fileInfos.filePath.split('/').pop().slice(0, -3) : '')
const text = ref(fileContentLoaded.value ? decodeFileContentAsText(fileContent.value) : "")
// When the file content is fetched, set the text
watch(fileContent, (newValue) => {
  text.value = decodeFileContentAsText(newValue)
});

const nameIsValid = computed(() => {
  return name.value !== '' && name.value !== null && !name.value.includes('/');
});


// Prepare the addition of files
const filesAdditionTransactions = ref([])
const skippedFilesAdditions = ref([])
const { isPending: prepareAddFilesIsPending, isError: prepareAddFilesIsError, error: prepareAddFilesError, isSuccess: prepareAddFilesIsSuccess, mutate: prepareAddFilesMutate, reset: prepareAddFilesReset } = useMutation({
  mutationFn: async () => {
    // Reset any previous upload
    addFileTransactionBeingExecutedIndex.value = -1
    addFileTransactionResults.value = []

    // Convert the text to a UInt8Array
    const textData = new TextEncoder().encode(text.value);

    // Prepare the new filepath
    let newFilePath = name.value + ".md";
    if(newFilePath.endsWith(".md.md")) {
      newFilePath = newFilePath.slice(0, -3);
    }
    if(props.fileInfos) {
      const folder = props.fileInfos.filePath.split('/').slice(0, -1).join('/');
      if(folder.length > 0) {
        newFilePath = folder + '/' + newFilePath;
      }
    }
    else {
      newFilePath = props.newFileFolder + newFilePath;
    }

    // Prepare the files for upload
    const fileInfos = [{
      // If existing file : Reuse same filePath, we rename after
      filePath: props.fileInfos ? props.fileInfos.filePath : newFilePath,
      size: textData.length,
      contentType: "text/markdown",
      data: textData,
    }]
    console.log(fileInfos)
  
    // Prepare the transaction to upload the files
    const transactionsData = await props.staticFrontendPluginClient.prepareAddFilesTransactions(props.websiteVersionIndex, fileInfos);

    // If editing a page, and the newFilePath is different than the previous one, 
    // add a transaction to rename the file
    if(props.fileInfos && props.fileInfos.filePath != newFilePath) {
      const renameTransaction = await props.staticFrontendPluginClient.prepareRenameFilesTransaction(props.websiteVersionIndex, [props.fileInfos.filePath], [newFilePath]);
      transactionsData.transactions.push(renameTransaction);
    }
    console.log(transactionsData);

    return transactionsData;
  },
  onSuccess: (data) => {
    filesAdditionTransactions.value = data.transactions
    skippedFilesAdditions.value = data.skippedFiles
    // Execute right away, don't wait for user confirmation
    executePreparedAddFilesTransactions()
  }
})
const prepareAddFilesTransactions = async () => {
  prepareAddFilesMutate()
}

// Execute an upload transaction
const addFileTransactionBeingExecutedIndex = ref(-1)
const addFileTransactionResults = ref([])
const { isPending: addFilesIsPending, isError: addFilesIsError, error: addFilesError, isSuccess: addFilesIsSuccess, mutate: addFilesMutate, reset: addFilesReset } = useMutation({
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
  onSuccess: async (data) => {
    // Mark the transaction as successful
    addFileTransactionResults.value[addFileTransactionBeingExecutedIndex.value] = {status: 'success'}

    // Refresh the static frontend
    await queryClient.invalidateQueries({ queryKey: ['StaticFrontendPluginStaticFrontend', props.contractAddress, props.chainId, props.websiteVersionIndex] })

    // Refresh the content of the file, if it was editing an existing file
    if(props.fileInfos) {
      await invalidateStaticFrontendFileContentQuery(queryClient, props.contractAddress, props.chainId, props.websiteVersionIndex, props.fileInfos.filePath)
    }

    // Emit the event when all transactions are done
    if(addFileTransactionBeingExecutedIndex.value == filesAdditionTransactions.value.length - 1) {
      emit('pageSaved')
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

</script>

<template>
  <div class="page-editor">
    <div v-if="fileInfos != null && fileContentLoading">
      Loading...
    </div>
    <div v-if="fileInfos != null && fileContentIsError" class="text-danger">
      Error loading the file content: {{ fileContentError.shortMessage || fileContentError.message }}
    </div>

    <div v-if="fileInfos == null || fileContentLoaded">
      <h3 class="editor-title">
        <span v-if="fileInfos == null">New markdown page</span>
        <span v-else>Markdown page edition</span>
      </h3>

      <div style="margin-bottom: 1em">
        <input type="text" v-model="name" placeholder="Name" class="name-field" />
      </div>

      <div class="text-editor-area">
        <TextEditor 
          v-model:text="text" 
          :content-type="fileInfos ? fileInfos.contentType : newFileContentType"
          :contractAddress
          :chainId
          :pluginInfos
          :websiteVersion
          :websiteVersionIndex
          :staticFrontendPluginClient />
      </div>

      <div v-if="prepareAddFilesIsError" class="mutation-error">
        <span>
          Error preparing the transaction: {{ prepareAddFilesError.shortMessage || prepareAddFilesError.message }} <a @click.stop.prevent="prepareAddFilesReset()">Hide</a>
        </span>
      </div>

      <div v-if="addFilesIsError" class="mutation-error">
        <span>
          Error saving the file: {{ addFilesError.shortMessage || addFilesError.message }} <a @click.stop.prevent="addFilesReset()">Hide</a>
        </span>
      </div>

      <div class="buttons">
        <button @click="$emit('editCancelled')" :disabled="prepareAddFilesIsPending || addFilesIsPending">Cancel</button>
        <button @click="prepareAddFilesTransactions" :disabled="nameIsValid == false ||  prepareAddFilesIsPending || addFilesIsPending">Save</button>
      </div>
      
    </div>


  </div>
</template>

<style scoped>
.page-editor {
  padding: 0em 1em 1em 1em;
}

.editor-title {
  margin-bottom: 0.5em;
}

.name-field {
  width: 50%;
  font-size: 16px;
}

.text-editor-area {
  margin-bottom: 1em;
}

.buttons {
  display: flex;
  gap: 0.5em;
  justify-content: flex-end;
}
</style>