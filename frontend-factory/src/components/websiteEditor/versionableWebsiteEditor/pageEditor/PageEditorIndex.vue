<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useConnectorClient } from '@wagmi/vue'
import { useSwitchChain, useAccount } from '@wagmi/vue'
import { useQueryClient } from '@tanstack/vue-query'
import { useIsLocked } from '../../../../../../src/tanstack-vue.js';
import { useStaticFrontendPluginClient, useStaticFrontend } from '../../../../../../src/plugins/staticFrontend/tanstack-vue.js';

import PlusLgIcon from '../../../../icons/PlusLgIcon.vue';
import PageEditor from './PageEditor.vue';
import PageEditorIndexLine from './PageEditorIndexLine.vue';

const props = defineProps({
  websiteVersion: {
    type: [Object, null],
    required: true
  },
  websiteVersionIndex: {
    type: Number,
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
  websiteClient: {
    type: [Object, null],
    required: true,
  },
  pluginInfos: {
    type: Object,
    required: true,
  },
})


const queryClient = useQueryClient()


// Ge the staticFrontendPluginClient
const { data: staticFrontendPluginClient, isLoading: staticFrontendPluginClientLoading, isFetching: staticFrontendPluginClientFetching, isError: staticFrontendPluginClientIsError, error: staticFrontendPluginClientError, isSuccess: staticFrontendPluginClientLoaded } = useStaticFrontendPluginClient(props.contractAddress, props.pluginInfos.plugin)

// Get the lock status
const { data: isLocked, isLoading: isLockedLoading, isFetching: isLockedFetching, isError: isLockedIsError, error: isLockedError, isSuccess: isLockedLoaded } = useIsLocked(props.contractAddress, props.chainId)

// Fetch the static frontend
const { data: staticFrontend, isLoading: staticFrontendLoading, isFetching: staticFrontendFetching, isError: staticFrontendIsError, error: staticFrontendError, isSuccess: staticFrontendLoaded } = useStaticFrontend(queryClient, props.contractAddress, props.chainId, props.pluginInfos.plugin, computed(() => props.websiteVersionIndex))


// Computed: Get the list of markdown files (ending by .md), ordered by folder then alphabetically
const markdownFiles = computed(() => {
  if (staticFrontend.value == null) {
    return []
  }

  return staticFrontend.value.files.filter(file => file.filePath.endsWith('.md')).sort((a, b) => {
    // Extract the folder and file name
    const folderA = a.filePath.split('/').slice(0, -1).join('/')
    const folderB = b.filePath.split('/').slice(0, -1).join('/')
    const fileA = a.filePath.split('/').slice(-1)[0]
    const fileB = b.filePath.split('/').slice(-1)[0]

    // Compare the folders
    if (folderA < folderB) {
      return -1
    } else if (folderA > folderB) {
      return 1
    }

    // Compare the files
    if (fileA < fileB) {
      return -1
    } else if (fileA > fileB) {
      return 1
    }
  })
})

// Do we show the page edition form, and if yes, which file is being edited?
const showPageEditor = ref(false)
const filePathBeingEdited = ref(null)
const fileInfosBeingEdited = computed(() => {
  if (filePathBeingEdited.value == null) {
    return null
  }

  return staticFrontend.value.files.find(file => file.filePath == filePathBeingEdited.value)
})

</script>

<template>
  <div>

    <div class="page-editor-index" v-if="showPageEditor == false">
      <div class="table-header">
        <div>
          Name
        </div>
        <div class="type">
          Folder
        </div>
        <div>
        </div>
      </div>

      <div v-if="websiteVersion == null || staticFrontendPluginClientLoading || staticFrontendLoading">
        Loading...
      </div>
      <!-- 
      <div v-else-if="websiteVersionError == true">
        Error loading the files: {{ error.shortMessage || error.message }}
      </div> -->

      <div v-else-if="staticFrontendPluginClientLoaded && staticFrontendLoaded">
        <div v-if="markdownFiles.length == 0" class="no-files">
          No pages
        </div>

        <div v-else>
          <PageEditorIndexLine
            class="page-list"
            v-for="(file, index) in markdownFiles" :key="index"
            :file="file"
            :websiteVersionIndex
            :contractAddress
            :chainId
            :staticFrontendPluginClient
            :locked="isLockedLoaded && isLocked || websiteVersion.locked"
            @page-edit-requested="() => {showPageEditor = true; filePathBeingEdited = file.filePath}"
            />
        </div>

        <div class="operations">
          <div class="op-upload">
            <div class="button-area">
              <span class="button-text" @click="showPageEditor = true; filePathBeingEdited = null">
                <PlusLgIcon /> Add new page
              </span>
            </div>
          </div>
        </div>

      </div>
    </div>

    <div class="page-editor" v-if="showPageEditor">
      <Suspense>
        <PageEditor
          :websiteVersionIndex
          :contractAddress
          :chainId
          :pluginInfos
          :staticFrontendPluginClient
          :fileInfos="fileInfosBeingEdited"
          @edit-cancelled="showPageEditor = false; filePathBeingEdited = null"
          @page-saved="showPageEditor = false; filePathBeingEdited = null"
          />
      </Suspense>
    </div>
  </div>
</template>

<style scoped>
.page-editor-index {
  margin-bottom: 1em;
}

.table-header {
  display: grid;
  grid-template-columns: 5fr 2fr 1fr;
  padding: 0.5em 0em;
  font-weight: bold;
  border-bottom: 1px solid var(--color-divider-secondary);
  background-color: var(--color-root-bg)
}

@media (max-width: 700px) {
  .table-header {
    grid-template-columns: 2fr max-content;
  }

  .table-header > .content-type,
  .table-header > .compression,
  .table-header > .size {
    display: none;
  }
}

.table-header > div {
  padding: 0em 1em;
  word-break: break-all;
}

.no-files {
  text-align: center;
  padding: 2em 0em;
  color: var(--color-text-muted);
}

.page-list {
  margin: 0.25em 1em 0em 1em;
}

.operations {
  margin: 0em 1em;
}

</style>