<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useQueryClient } from '@tanstack/vue-query'

import FrontendVersionList from './FrontendVersionList.vue';
import FrontendVersionListLine from './FrontendVersionListLine.vue';

const props = defineProps({
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
})

// Create frontendVersion
const newFrontendVersionDescription = ref("")
const { isPending: newfrontendversionIsPending, isError: newfrontendversionIsError, error: newfrontendversionError, isSuccess: newfrontendversionIsSuccess, mutate: newfrontendversionMutate, reset: newfrontendversionReset } = useMutation({
  mutationFn: async () => {
    // Prepare the transaction
    const transaction = await props.websiteClient.prepareAddFrontendVersionTransaction("0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB", newFrontendVersionDescription.value);

    const hash = await props.websiteClient.executeTransaction(transaction);

    return await props.websiteClient.waitForTransactionReceipt(hash);
  },
  onSuccess: async (data, variables, context) => {
    // Refresh the frontend version
    return await queryClient.invalidateQueries({ queryKey: ['OCWebsiteFrontendVersion', props.contractAddress, props.chainId, props.frontendVersionIndex] })
  }
})
const newfrontendversionFile = async () => {
  // // Check that the name is not already taken
  // if(props.folderParentChildren.find(child => child.name === newFileName.value)) {
  //   preNewFrontendVersionError.value = 'A file with this name already exists in this folder'
  //   return
  // }

  newfrontendversionMutate()
}
</script>

<template>
  <div class="versions-body">
        
    <div class="versions-list">
      <FrontendVersionList 
        :contractAddress
        :chainId
        :websiteClient="websiteClient"
        />
    </div>

    <div class="versions-actions">
      <div class="versions-add-new-form">
        <div>
          <input type="text" v-model="newFrontendVersionDescription" placeholder="Version description" />
          <br />
          <button @click="newfrontendversionFile">Add new version</button>
        </div>
        <span v-if="newfrontendversionIsError">
          Error adding new version: {{ newfrontendversionError.shortMessage || newfrontendversionError.message }}
        </span>
      </div>
      <div class="versions-global-lock-form">
        <button>Lock all versions</button>
      </div>
    </div>

  </div>
</template>

<style scoped>
.versions-body {
  display: flex;
  border-top: 1px solid var(--color-divider-secondary);
  gap: 1em;
}

.versions-list {
  flex: 1;
}

.versions-actions {
  display: flex;
  flex-direction: column;
  gap: 1em;
  border-left: 1px solid var(--color-divider);
}

</style>