<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQueryClient, useMutation } from '@tanstack/vue-query'

import FileEarmarkIcon from '../../../../icons/FileEarmarkIcon.vue';
import PencilSquareIcon from '../../../../icons/PencilSquareIcon.vue';
import TrashIcon from '../../../../icons/TrashIcon.vue';
import ExclamationTriangleIcon from '../../../../icons/ExclamationTriangleIcon.vue';
import ArrowRightIcon from '../../../../icons/ArrowRightIcon.vue';
import Modal from '../../../utils/Modal.vue';
import FilePreview from './FilePreview.vue';

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
  file: {
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
  folderParentChildren: {
    type: Array,
    required: true,
  },
})

const queryClient = useQueryClient()

const paddingLeftForCSS = computed(() => {
  return `${1 + props.folderParents.length * 1.5}em`;
})

// Trigger the modal to show the file content
const fileContentRequested = ref(false)
const fileContentModalShown = ref(false)
const showFileContent = () => {
  fileContentRequested.value = true
  fileContentModalShown.value = true
}



// Rename file
const showRenameForm = ref(false)
const newFileName = ref(props.file.name)
const preRenameError = ref('')
const { isPending: renameIsPending, isError: renameIsError, error: renameError, isSuccess: renameIsSuccess, mutate: renameMutate, reset: renameReset } = useMutation({
  mutationFn: async () => {
    // Prepare the transaction to rename the file
    const transaction = await props.staticFrontendPluginClient.prepareRenameFilesTransaction(props.websiteVersionIndex, [props.file.filePath], [props.folderParents.map(folder => folder + "/").join() + newFileName.value]);

    const hash = await props.staticFrontendPluginClient.executeTransaction(transaction);

    return await props.staticFrontendPluginClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    // Refresh the static frontend
    return await queryClient.invalidateQueries({ queryKey: ['StaticFrontendPluginStaticFrontend', props.contractAddress, props.chainId, props.websiteVersionIndex] })
  }
})
const renameFile = async () => {
  preRenameError.value = ''

  if(newFileName.value.trim() === '') {
    return
  }

  if(newFileName.value.trim() === props.file.name) {
    showRenameForm.value = false
    return
  }

  // Check that the name is not already taken
  if(props.folderParentChildren.find(child => child.name === newFileName.value)) {
    preRenameError.value = 'A file with this name already exists in this folder'
    return
  }

  showRenameForm.value = false

  renameMutate()
}

// Delete file
const { isPending: deleteIsPending, isError: deleteIsError, error: deleteError, isSuccess: deleteIsSuccess, mutate: deleteMutate, reset: deleteReset } = useMutation({
  mutationFn: async () => {
    // Prepare the transaction to delete the file
    const transaction = await props.staticFrontendPluginClient.prepareRemoveFilesTransaction(props.websiteVersionIndex, [props.file.filePath]);

    const hash = await props.staticFrontendPluginClient.executeTransaction(transaction);

    return await props.staticFrontendPluginClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    // Refresh the static frontend
    return await queryClient.invalidateQueries({ queryKey: ['StaticFrontendPluginStaticFrontend', props.contractAddress, props.chainId, props.websiteVersionIndex] })
  }
})
const deleteFile = async () => {
  showRenameForm.value = false
  deleteMutate()
}


</script>

<template>
  <div>
    <div :class="{file: true, 'delete-pending': deleteIsPending}">
      <div class="filename">
        <span v-if="showRenameForm" class="rename-form">
          <PencilSquareIcon />
          <input v-model="newFileName" type="text" />
          <button @click="renameFile()" :disabled="renameIsPending" class="sm">Rename</button>
        </span>
        <a v-else @click.prevent.stop="showFileContent()" class="white" target="_blank">
          <span>
            <PencilSquareIcon v-if="renameIsPending == true" class="anim-pulse" />
            <TrashIcon v-else-if="deleteIsPending == true" class="anim-pulse" />
            <ExclamationTriangleIcon v-else-if="file.size != file.uploadedSize" class="text-danger" />
            <FileEarmarkIcon v-else />
          </span>
          <span :class="{'text-muted': renameIsPending}">
            {{ file.name }}
          </span>
          <span v-if="renameIsPending">
            <ArrowRightIcon />
          </span>
          <span v-if="renameIsPending">
            {{ newFileName }}
          </span>
        </a>
      </div>
      <div class="content-type">
        {{ file.contentType }}
      </div>
      <div class="size">
        <span v-if="file.size === undefined">
          ...
        </span>
        <span v-else-if="file.size == file.uploadedSize">
          {{ Math.round(Number(props.file.size) / 1024) }} KB
        </span>
        <div v-else>
          {{ Math.round(Number(props.file.uploadedSize) / 1024) }} / {{ Math.round(Number(props.file.size) / 1024) }} KB
          <div class="text-danger" style="font-size: 80%">
            <ExclamationTriangleIcon style="height: 0.8em" />Incomplete
          </div>
        </div>
      </div>
      <div class="compression">
        <span v-if="file.compressionAlgorithm == 0">
          none
        </span>
        <span v-else-if="file.compressionAlgorithm == 1">
          gzip
        </span>
        <span v-else-if="file.compressionAlgorithm == 2">
          brotli
        </span>
      </div>
      <div class="actions">
        <a @click.stop.prevent="showRenameForm = !showRenameForm; preRenameError = ''; newFileName = file.name" class="white" v-if="locked == false && renameIsPending == false && deleteIsPending == false">
          <PencilSquareIcon />
        </a>
        <a @click.stop.prevent="deleteFile(file)" class="white" v-if="locked == false && renameIsPending == false && deleteIsPending == false">
          <TrashIcon />
        </a>
      </div>
    </div>

    <div v-if="preRenameError" class="mutation-error">
      <span>
        {{ preRenameError }}
      </span>
    </div>

    <div v-if="renameIsError" class="mutation-error">
      <span>
        Error renaming the file: {{ renameError.shortMessage || renameError.message }} <a @click.stop.prevent="renameReset()">Hide</a>
      </span>
    </div>

    <div v-if="deleteIsError" class="mutation-error">
      <span>
        Error deleting the file: {{ deleteError.shortMessage || deleteError.message }} <a @click.stop.prevent="deleteReset()">Hide</a>
      </span>
    </div>

    <Modal 
      v-model:show="fileContentModalShown"
      title="File preview" >

      <FilePreview 
        v-if="fileContentRequested"
        :contractAddress
        :chainId
        :websiteVersion
        :websiteVersionIndex
        :fileInfos="file"
        :locked
        :pluginInfos
        :staticFrontendPluginClient />
    </Modal>
  </div>
</template>

<style scoped>
.file {
  display: grid;
  grid-template-columns: 5fr 2fr 1.5fr 1fr 1fr;
  padding: 0.5em 0em;
  align-items: center;
}

.file > div {
  display: flex;
  line-height: 1em;
  gap: 0.5em;
  padding: 0em 1em;
  word-break: break-all;
}

.file > .filename {
  padding-left: v-bind('paddingLeftForCSS');
}

.file > .filename a {
  display: flex;
  gap: 0.5em;
}

.file .rename-form {
  display: flex;
  gap: 0.5em;
  align-items: center;
}

.file .rename-form input {
  padding: 0.2em 0.5em;
  max-width: 70%;
}

@media (max-width: 700px) {
  .file {
    grid-template-columns: 2fr max-content;
  }

  .file > .content-type,
  .file > .compression,
  .file > .size {
    display: none;
  }
}

.file > .content-type,
.file > .compression,
.file > .size {
  font-size: 0.9em;
  color: #bbb;
}

.file.delete-pending {
  opacity: 0.5;
  text-decoration: line-through;
}

.mutation-error {
  padding: 0em 1em 0.5em v-bind('paddingLeftForCSS');
}

.mutation-error span {
  font-size: 0.8em;
}
</style>