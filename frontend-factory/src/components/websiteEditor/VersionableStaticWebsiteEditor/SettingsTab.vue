<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'

import { useContractAddresses, invalidateFrontendVersionQuery } from '../../../utils/queries';
import SettingsProxiedWebsites from './SettingsProxiedWebsites.vue';
import SettingsInjectedVariables from './SettingsInjectedVariables.vue';

const props = defineProps({
  frontendVersion: {
    type: [Object, null],
    required: true
  },
  frontendVersionIndex: {
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
})


</script>

<template>
  <div class="settings">
    <div class="settings-item" style="flex:0 0 60%">
      <SettingsProxiedWebsites 
        :frontendVersion
        :frontendVersionIndex
        :contractAddress
        :chainId
        :websiteClient />
    </div>
    <div class="settings-item">
      <SettingsInjectedVariables
        :frontendVersion
        :frontendVersionIndex
        :contractAddress
        :chainId
        :websiteClient />
    </div>
  </div>
</template>

<style scoped>
.settings {
  display: flex;
  flex-direction: column;
}

.settings-item {
  padding: 1em;
}

.settings-item + .settings-item {
  border-top: 1px solid var(--color-divider-secondary);
}

.title {
  font-size: 1.1em;
  font-weight: bold;
  margin-bottom: 1em;
}


.table-header {
  display: grid;
  grid-template-columns: 1fr 0.5fr 3fr 2em;
  padding: 0.5em;
  font-weight: bold;
  border-bottom: 1px solid var(--color-divider-secondary);
  background-color: var(--color-root-bg)
}

.table-header > div {
  padding: 0em 0.5em;
  word-break: break-all;
}

.table-row {
  display: grid;
  grid-template-columns: 1fr 0.5fr 3fr 2em;
  padding: 0.5em;
}

.table-row > div {
  padding: 0em 0.5em;
  word-break: break-all;
}

.mutation-error {
  padding: 0em 1em 0.5em 1em;
  color: var(--color-text-danger);
  line-height: 1em;
}

.mutation-error span {
  font-size: 0.8em;
}

.mutation-error a {
  color: var(--color-text-danger);
  text-decoration: underline;
}



.operations {
  display: flex;
  gap: 1em;
  margin-top: 1em;
  align-items: flex-start;
}
@media (max-width: 700px) {
  .operations {
    flex-direction: column;
  }
}

.operations .button-area {
  text-align: center;
  position: relative;
  background-color: var(--color-input-bg);
  border: 1px solid #555;
  padding: 0.5em 1em;
  cursor: pointer;
}

.operations .button-area .button-text {
  display: flex;
  gap: 0.5em;
  align-items: center;
  justify-content: center;
}

.operations .form-area {
  border-left: 1px solid #555;
  border-right: 1px solid #555;
  border-bottom: 1px solid #555;
  background-color: var(--color-popup-bg);
  font-size: 0.9em;
  padding: 0.75em 1em;
  display: flex;
  flex-direction: column;
  gap: 0.5em;
}

.operations input {
  max-width: 150px;
}

.delete-pending {
  opacity: 0.5;
  text-decoration: line-through;
}

.no-entries {
  padding: 1.5em;
  text-align: center;
  color: var(--color-text-muted);
}
</style>