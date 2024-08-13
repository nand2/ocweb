<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery } from '@tanstack/vue-query'
import { useConnectorClient } from '@wagmi/vue'
import { useSwitchChain, useAccount } from '@wagmi/vue'
import { useQueryClient } from '@tanstack/vue-query'
import { useIsLocked } from '../../../../utils/queries.js';
import { useStaticFrontendPluginClient, useStaticFrontend } from '../../../../utils/pluginStaticFrontendQueries.js';

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

const { switchChainAsync } = useSwitchChain()
const queryClient = useQueryClient()
const { data: viemClient, isSuccess: viemClientLoaded } = useConnectorClient()

// Ge the staticFrontendPluginClient
const { data: staticFrontendPluginClient, isLoading: staticFrontendPluginClientLoading, isFetching: staticFrontendPluginClientFetching, isError: staticFrontendPluginClientIsError, error: staticFrontendPluginClientError, isSuccess: staticFrontendPluginClientLoaded } = useStaticFrontendPluginClient(props.contractAddress, props.pluginInfos.plugin)

// Get the lock status
const { data: isLocked, isLoading: isLockedLoading, isFetching: isLockedFetching, isError: isLockedIsError, error: isLockedError, isSuccess: isLockedLoaded } = useIsLocked(props.contractAddress, props.chainId)

// Folders are not stored in the backend, like git
// We keep track of the empty folders to display them
const globalEmptyFolders = ref([])

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

</script>

<template>
  <div class="frontend-version-editor">
    <div class="table-header">
      <div>
        Name
      </div>
      <div class="type">
        Type
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
          v-for="(file, index) in markdownFiles" :key="index"
          :file="file"
          :websiteVersionIndex="websiteVersionIndex"
          :staticFrontendPluginClient
          />
      </div>

      <Suspense>
        <PageEditor
          :filePath="null"
          :websiteVersionIndex
          :staticFrontendPluginClient
        />
      </Suspense>

    </div>
  </div>
</template>

<style scoped>
.frontend-version-editor {
  margin-bottom: 1em;
}

.table-header {
  display: grid;
  grid-template-columns: 5fr 2fr 1.5fr 1fr 1fr;
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


</style>