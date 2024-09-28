<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQueryClient, useMutation } from '@tanstack/vue-query'

import FileEarmarkIcon from '../../../../icons/FileEarmarkIcon.vue';
import PencilSquareIcon from '../../../../icons/PencilSquareIcon.vue';
import TrashIcon from '../../../../icons/TrashIcon.vue';
import ExclamationTriangleIcon from '../../../../icons/ExclamationTriangleIcon.vue';
import ArrowRightIcon from '../../../../icons/ArrowRightIcon.vue';
import { invalidateWebsiteVersionQuery } from '../../../../../../src/tanstack-vue.js';
import { store } from '../../../../utils/store.js'

const props = defineProps({
  file: {
    type: Object,
    required: true,
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
  staticFrontendPluginClient: {
    type: Object,
    required: true,
  },
  locked: {
    type: Boolean,
    required: true,
  },
})

const emit = defineEmits(['pageEditRequested'])

const queryClient = useQueryClient()

const fileName = computed(() => {
  return props.file.filePath.split('/').pop()
})

const fileDirectory = computed(() => {
  return "/" + props.file.filePath.split('/').slice(0, -1).join('/')
})


const requestFileEdit = () => {
  if(props.locked == false) {
    emit('pageEditRequested')
  }
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
  deleteMutate()
}


</script>

<template>
  <div>
    <div :class="{file: true, 'delete-pending': deleteIsPending}">
      <div class="filename">
        <a @click.stop.prevent="requestFileEdit()" class="white">
          <span>
            <TrashIcon v-if="deleteIsPending == true" class="anim-pulse" />
            <FileEarmarkIcon v-else />
          </span>
          <span>
            {{ fileName.slice(0, -3) }}<span class="text-muted" v-if="store.devMode">{{ fileName.slice(-3) }}</span>
          </span>
        </a>
      </div>
      <div class="directory">
        <span v-if="store.devMode">{{ fileDirectory }}</span>
      </div>
      <div class="actions">
        <a @click.stop.prevent="$emit('pageEditRequested')" class="white" v-if="locked == false && deleteIsPending == false">
          <PencilSquareIcon />
        </a>
        <a @click.stop.prevent="deleteFile(file)" class="white" v-if="locked == false && deleteIsPending == false">
          <TrashIcon />
        </a>
      </div>
    </div>


    <div v-if="deleteIsError" class="mutation-error">
      <span>
        Error deleting the file: {{ deleteError.shortMessage || deleteError.message }} <a @click.stop.prevent="deleteReset()">Hide</a>
      </span>
    </div>
  </div>
</template>

<style scoped>
.file {
  display: grid;
  grid-template-columns: 5fr 2fr 1fr;
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
  padding-left: 0;
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

  .file > .directory {
    display: none;
  }
}

.file > .directory {
  font-size: 0.9em;
  color: #bbb;
}

.file > .actions {
  justify-self: end;
  padding-right: 0em;
}

.file.delete-pending {
  opacity: 0.5;
  text-decoration: line-through;
}

.mutation-error span {
  font-size: 0.8em;
}

</style>