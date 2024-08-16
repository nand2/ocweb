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
import FilesUploadOperation from './FilesUploadOperation.vue';

const props = defineProps({
  folderChildren: {
    type: Array,
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
  globalEmptyFolders: {
    type: Array,
    required: true,
  },
})

const queryClient = useQueryClient()

const operationsPaddingLeftForCSS = computed(() => {
  return `${1 + props.folderParents.length * 1.5}em`;
})


//
// New folder
//

const showNewFolderForm = ref(false)
const newFolderName = ref('')
const newFolderErrorLabel = ref('')
const addNewFolder = async () => {
  newFolderErrorLabel.value = ''

  if(newFolderName.value == '') {
    return;
  }

  // Check if the name is already used
  if(props.folderChildren.find(child => child.name == newFolderName.value)) {
    newFolderErrorLabel.value = 'Already exists'
    return;
  }

  props.globalEmptyFolders.push(props.folderParents.concat([newFolderName.value]).join('/'))
  
  newFolderName.value = ''
  showNewFolderForm.value = false
}
</script>

<template>
  <div>
    <div class="folder-children">
      <div v-for="child in folderChildren" :key="child.name">
        
        <Folder 
          :folder="child" 
          :folderParents="folderParents.concat([child.name])" 
          :locked
          :contractAddress
          :chainId
          :websiteVersionIndex
          :staticFrontendPluginClient
          :globalEmptyFolders
          v-if="child.type == 'folder'" />
        <File 
          :file="child" 
          :folderParents 
          :locked
          :contractAddress
          :chainId
          :websiteVersionIndex
          :staticFrontendPluginClient
          :folderParentChildren="folderChildren"
          v-else-if="child.type == 'file'" />

      </div>
    </div>
    <div class="operations" v-if="locked == false">
      
      <FilesUploadOperation 
        :uploadFolder="folderParents.map(parent => parent + '/').join('')" 
        :contractAddress
        :chainId
        :websiteVersionIndex
        :staticFrontendPluginClient />

      <div class="op-new-folder">
        <div class="button-area" @click="showNewFolderForm = !showNewFolderForm; newFolderErrorLabel = ''">
          <span class="button-text">
            <FolderPlusIcon />
            New folder
          </span>
        </div>
        <div class="form-area" v-if="showNewFolderForm">
          <div>
            <input type="text" class="form-control" placeholder="Folder name" v-model="newFolderName" />
          </div>
          <div class="text-danger" style="font-size: 0.9em">
            {{ newFolderErrorLabel }}
          </div>
          <div>
            <button type="button" style="width: 100%" @click="addNewFolder">Create folder</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.operations {
  margin-top: 0em;
  margin-right: 1em;
  margin-left: v-bind('operationsPaddingLeftForCSS');
  margin-bottom: 0.5em;
}

.op-new-folder {
  flex: 0 0 20%;
}


/**
 * op-new-folder form
 */
.op-new-folder .form-area {
  display: flex;
  flex-direction: column;
  gap: 0.5em;
}
</style>