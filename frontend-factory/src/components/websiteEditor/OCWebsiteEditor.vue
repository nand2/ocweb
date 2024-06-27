<script setup>
import { ref, computed, defineProps } from 'vue';

import FilesTab from './FilesTab.vue';
import PreviewTab from './PreviewTab.vue';
import SettingsTab from './SettingsTab.vue';

const props = defineProps({
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
})

const activeTab = ref('files');

const activeComponent = computed(() => {
  switch (activeTab.value) {
    case 'files':
      return FilesTab;
    case 'preview':
      return PreviewTab;
    case 'settings':
      return SettingsTab;
  }
});
</script>

<template>
  <div class="oc-website-editor">
    <div class="tabs">
      <a @click="activeTab = 'files'" :class="{tabFiles: true, active: activeTab == 'files'}">Files</a>
      <a @click="activeTab = 'preview'" :class="{tabPreview: true, active: activeTab == 'preview'}">Preview</a>
      <a @click="activeTab = 'settings'" :class="{tabSettings: true, active: activeTab == 'settings'}">Settings</a>
    </div>
    
    <FilesTab :contractAddress :chainId v-show="activeTab == 'files'" />
    <PreviewTab :contractAddress :chainId v-show="activeTab == 'preview'" />
    <SettingsTab :contractAddress :chainId v-show="activeTab == 'settings'" />
  </div>
</template>

<style scoped>
.oc-website-editor {
  background-color: #eee;
  overflow-y:hidden;
  width: 100%;
  background-color: #303030;
}

.tabs {
  display: flex;
  gap: 1em;
  padding-left: 1em;
  padding-right: 1em;
  background-color: #303030;
  justify-content: space-between;
  border-bottom: 1px solid var(--color-divider);
}

.tabs a {
  color: var(--color-text);
  cursor: pointer;
  padding-top: 1em;
  padding-bottom: calc(1em - 3px);
}

.tabs a:hover {
  color: var(--color-bglink-hover);
}

.tabs a.active {
  border-bottom: 3px solid var(--color-link);

}

.tabSettings {
  margin-left: auto;
}
</style>