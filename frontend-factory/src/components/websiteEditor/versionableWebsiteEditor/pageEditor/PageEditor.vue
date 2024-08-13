<script setup>
import { ref, onMounted } from 'vue'
import { useQueryClient, useMutation } from '@tanstack/vue-query'
import MarkdownEditor from './MarkdownEditor.vue';


const props = defineProps({
  filePath: {
    type: String,
    default: ''
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

const text = ref('sime text')



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

    // Prepare the files for upload
    const fileInfos = [{
      filePath: props.filePath || "new.md",
      size: textData.length,
      contentType: "text/markdown",
      data: textData,
    }]
    console.log(fileInfos)
  
    // Prepare the transaction to upload the files
    const transactionsData = await props.staticFrontendPluginClient.prepareAddFilesTransactions(props.websiteVersionIndex, fileInfos);
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
  onSuccess: async (data) => {
    // Mark the transaction as successful
    addFileTransactionResults.value[addFileTransactionBeingExecutedIndex.value] = {status: 'success'}

    // Refresh the static website
    return await queryClient.invalidateQueries({ queryKey: ['StaticFrontendPluginStaticFrontend', props.contractAddress, props.chainId, props.websiteVersionIndex] })
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
  <div>
    {{ text }}
    <MarkdownEditor v-model:text="text" />

{{ prepareAddFilesError }}
    <button @click="prepareAddFilesTransactions" :disabled="prepareAddFilesIsPending">Save</button>

  </div>
</template>

<style scoped>

</style>