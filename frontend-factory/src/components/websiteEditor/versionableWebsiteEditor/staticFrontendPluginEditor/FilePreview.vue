<script setup>
import { ref, computed, defineProps, watch } from 'vue';
import { useQueryClient, useMutation } from '@tanstack/vue-query'
import { useStaticFrontendFileContent, invalidateStaticFrontendFileContentQuery } from '../../../../../../src/plugins/staticFrontend/tanstack-vue.js';
import { useLiveWebsiteVersion } from '../../../../../../src/tanstack-vue.js';
import SaveIcon from '../../../../icons/SaveIcon.vue';
import DownloadIcon from '../../../../icons/DownloadIcon.vue';

import TextEditor from '../pageEditor/TextEditor.vue';

const emit = defineEmits(['fileSaved'])
 
const props = defineProps({
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
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
  fileInfos: {
    type: Object,
    required: true,
  },
  folderParents: {
    type: Array,
    default: [],
  },
  locked: {
    type: Boolean,
    required: true,
  },
  pluginInfos: {
    type: Object,
    required: true,
  },
  staticFrontendPluginClient: {
    type: Object,
    required: true,
  },
})

const queryClient = useQueryClient()

// Fetch the live website infos
const { data: liveWebsiteVersionData, isLoading: liveWebsiteVersionLoading, isFetching: liveWebsiteVersionFetching, isError: liveWebsiteVersionIsError, error: liveWebsiteVersionError, isSuccess: liveWebsiteVersionLoaded } = useLiveWebsiteVersion(queryClient, props.contractAddress, props.chainId)

// Can the file be downloaded?
const fileCanBeDownloaded = computed(() => {
  return liveWebsiteVersionLoaded.value && (liveWebsiteVersionData.value.websiteVersionIndex === props.websiteVersionIndex || props.websiteVersion.isViewable)
})

// Fetch the config file content, when requested
const { data: fileContent, isLoading: fileContentLoading, isFetching: fileContentFetching, isError: fileContentIsError, error: fileContentError, isSuccess: fileContentLoaded } = useStaticFrontendFileContent(props.contractAddress, props.chainId, props.pluginInfos.plugin, computed(() => props.websiteVersionIndex), computed(() => props.fileInfos), computed(() => fileCanBeDownloaded.value))

// Editable text content of the file
const decodeFileContentAsText = (fileContent) => {
  return fileContent ? new TextDecoder().decode(fileContent) : '';
}
const text = ref(fileContentLoaded.value && props.fileInfos.contentType.startsWith("text/") ? decodeFileContentAsText(fileContent.value) : "")
const originalText = ref(text.value)
// When the file content is fetched, set the text
watch(fileContent, (newValue) => {
  if(props.fileInfos.contentType.startsWith("text/")) {
    text.value = decodeFileContentAsText(newValue)
    originalText.value = text.value
  }
});

// Make a dataurl from the file content
const fileContentAsDataUrl = computed(() => {
  if(fileContentLoaded.value == false) {
    return ''
  }

  const contentType = props.fileInfos.contentType
  const base64Data = btoa(Array.from(fileContent.value, byte => String.fromCharCode(byte)).join(''))
  return `data:${contentType};base64,${base64Data}`
})

// Download function
const download = () => {
  const blob = new Blob([fileContent.value], { type: props.fileInfos.contentType });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = props.fileInfos.filePath.split('/').pop();
  a.click();
  URL.revokeObjectURL(url);
}


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
      filePath: props.fileInfos.filePath,
      size: textData.length,
      contentType: props.fileInfos.contentType,
      data: textData,
    }]
    console.log(fileInfos)
  
    // Prepare the transaction to upload the files
    const transactionsData = await props.staticFrontendPluginClient.prepareAddFilesTransactions(props.websiteVersionIndex, fileInfos);

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

    // Refresh the content of the file
    await invalidateStaticFrontendFileContentQuery(queryClient, props.contractAddress, props.chainId, props.websiteVersionIndex, props.fileInfos.filePath)

    // All transactions are done:
    if(addFileTransactionBeingExecutedIndex.value == filesAdditionTransactions.value.length - 1) {
      emit('fileSaved')
      originalText.value = text.value
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
  <div v-if="fileCanBeDownloaded == false">
    <div style="margin-bottom: 0.5em;">
      The website version is not publicly accessible, so the file cannot be downloaded.
    </div>
    <div>
      You can make it accessible in the website versions settings.
    </div>
  </div>
  <div v-else>
    <div v-if="fileContentLoading">
      Loading...
    </div>
    <div v-else-if="fileContentIsError" class="text-danger">
      Error loading the file content: {{ fileContentError.shortMessage || fileContentError.message }}
    </div>
    <div v-else-if="fileContentLoaded" class="preview-container">
      <div v-if="fileInfos.contentType.startsWith('text/')">
        <Suspense>
          <TextEditor 
            v-model:text="text" 
            :content-type="fileInfos.contentType"
            :contractAddress
            :chainId
            :pluginInfos
            :websiteVersion
            :websiteVersionIndex
            :staticFrontendPluginClient />
        </Suspense>
      </div>
      <div v-else-if="fileInfos.contentType.startsWith('image/')">
        <img :src="fileContentAsDataUrl" />
      </div>
      <div v-else>
        <iframe
          class="preview-iframe"
          :src="fileContentAsDataUrl" />
      </div>
    </div>

    <div v-if="addFilesIsError" class="mutation-error">
      <span>
        Error saving the file: {{ addFilesError.shortMessage || addFilesError.message }} <a @click.stop.prevent="addFilesReset()">Hide</a>
      </span>
    </div>
    <div class="buttons">
      <button @click="download" :disabled="prepareAddFilesIsPending || addFilesIsPending">
        <DownloadIcon />
        Download
      </button>

      <button v-if="fileInfos.contentType.startsWith('text/')" @click="prepareAddFilesTransactions" :disabled="text == originalText || prepareAddFilesIsPending || addFilesIsPending">
        <span v-if="prepareAddFilesIsPending || addFilesIsPending">
          <SaveIcon class="anim-pulse" />
          Saving in progress...
        </span>
        <span v-else>
          Save
        </span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.preview-container {
  margin-bottom: 1em;
}

.preview-iframe-container {
  background-color: #ccc;
  height: 70vh; 
  width: 80vw;
}

.preview-iframe {
  width: 100%;
  height: 100%;
  border: 0px solid var(--color-divider);
}

.buttons {
  display: flex;
  gap: 0.5em;
  justify-content: flex-end;
}

.buttons button {
  display: flex;
  gap: 0.5em;
  align-items: center;
}
</style>