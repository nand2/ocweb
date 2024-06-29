<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQueryClient, useMutation } from '@tanstack/vue-query'

import FileEarmarkIcon from '../../../icons/FileEarmarkIcon.vue';
import PencilSquareIcon from '../../../icons/PencilSquareIcon.vue';
import TrashIcon from '../../../icons/TrashIcon.vue';
import ExclamationTriangleIcon from '../../../icons/ExclamationTriangleIcon.vue';

const props = defineProps({
  file: {
    type: Object,
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


const fileUrl = computed(() => {
  return `web3://${props.contractAddress}${props.chainId > 1 ? ":" + props.chainId : ""}/${props.file.filePath}`;
})

const paddingLeftForCSS = computed(() => {
  return `${1 + props.folderParents.length * 1.5}em`;
})


// Delete file
const { isPending: deleteIsPending, isError: deleteIsError, error: deleteError, isSuccess: deleteIsSuccess, mutate: deleteMutate } = useMutation({
  mutationFn: async () => {
    // Prepare the request to delete the file
    const request = await props.websiteClient.prepareRemoveFilesFromFrontendVersionRequest(0, [props.file.filePath]);

    const hash = await props.websiteClient.executeRequest(request);
    console.log(hash);

    // Wait for the transaction to be mined
    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    // Refresh the frontend version
    return await queryClient.invalidateQueries({ queryKey: ['OCWebsiteLiveFrontend', props.contractAddress, props.chainId] })
  }
})
const deleteFile = async () => {
  deleteMutate()
}


</script>

<template>
  <div>
    <div :class="{file: true, 'delete-pending': deleteIsPending}">
      <div class="filename">
        <a :href="fileUrl" class="white" target="_blank">
          <span>
            <TrashIcon v-if="deleteIsPending == true" class="pulse-icon" />
            <ExclamationTriangleIcon v-else-if="file.complete == false" class="danger" />
            <FileEarmarkIcon v-else />
          </span>
          <span>
            {{ file.name }}
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
        <span v-else-if="file.complete == true">
          {{ Math.round(Number(props.file.size) / 1024) }} KB
        </span>
        <div v-else-if="file.complete == false">
          {{ Math.round(Number(props.file.uploadedSize) / 1024) }} / {{ Math.round(Number(props.file.size) / 1024) }} KB
          <div class="danger" style="font-size: 80%">
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
        <a @click.stop.prevent="deleteFile(file)" class="white" v-if="deleteIsPending == false">
          <PencilSquareIcon />
        </a>
        <a @click.stop.prevent="deleteFile(file)" class="white" v-if="deleteIsPending == false">
          <TrashIcon />
        </a>
      </div>
    </div>

    <div v-if="deleteIsError" class="mutation-error">
      Error deleting the file: {{ deleteError.shortMessage || deleteError.message }}
    </div>
  </div>
</template>

<style scoped>
.file {
  display: grid;
  grid-template-columns: 5fr 2fr 1.5fr 1fr 1fr;
  padding: 0.5em 0em;
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

.file > .filename .pulse-icon {
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.2);
  }
  100% {
    transform: scale(1);
  }
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

.file.delete-pending {
  opacity: 0.5;
  text-decoration: line-through;
}

.mutation-error {
  padding: 0em 1em 0.5em 1em;
  color: var(--color-text-danger);
  font-size: 80%;
}
</style>