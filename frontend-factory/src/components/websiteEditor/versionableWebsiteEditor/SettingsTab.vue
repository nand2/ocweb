<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useSwitchChain, useAccount } from '@wagmi/vue'

import { useContractAddresses, invalidateWebsiteVersionQuery, useWebsiteVersionPlugins, useLiveWebsiteVersion, useWebsiteVersions } from '../../../../../src/tanstack-vue';
import SettingsPlugin from './plugins/SettingsPlugin.vue';
import RemoteAsyncComponent from '../../utils/RemoteAsyncComponent.vue';
import AddressSettings from './settings/AddressSettings.vue';
import DeveloperModeSettings from './settings/DeveloperModeSettings.vue';
// import AdminPanel from '../../../../../../ocweb-theme-about-me/admin/src/components/AdminPanel.vue';
// import AdminPanel from '../../../../../../ocweb-visualizevalue-mint/admin/src/components/AdminPanel.vue';
import { store } from '../../../utils/store';
import WebsiteVersionsSettings from './settings/WebsiteVersionsSettings.vue';

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
  websiteClient: {
    type: Object,
    required: true,
  },
})

const queryClient = useQueryClient()

// Fetch the list of websites versions
const { data: websiteVersionsData, isLoading: websiteVersionsLoading, isFetching: websiteVersionsFetching, isError: websiteVersionsIsError, error: websiteVersionsError, isSuccess: websiteVersionsLoaded } = useWebsiteVersions(queryClient, props.contractAddress, props.chainId)

// Get the website plugins
const { data: websiteVersionPlugins, isLoading: websiteVersionPluginsLoading, isFetching: websiteVersionPluginsFetching, isError: websiteVersionPluginsIsError, error: websiteVersionPluginsError, isSuccess: websiteVersionPluginsLoaded } = useWebsiteVersionPlugins(props.contractAddress, props.chainId, computed(() => props.websiteVersionIndex)) 

// Get the installed ocWebAdmin plugin
const ocWebAdminInstalledPlugin = computed(() => {
  if(websiteVersionPluginsLoaded.value == false) {
    return null
  }

  return websiteVersionPlugins.value.find(plugin => plugin.infos.name == 'ocWebAdmin')
})

// Get the list of secondary admin panels of the plugins
const pluginSecondaryAdminPanels = computed(() => {
  if(websiteVersionPluginsLoaded.value == false) {
    return []
  }

  // Fetch all the panels (1+ per plugin)
  return websiteVersionPlugins.value.flatMap(plugin => plugin.infos.adminPanels.map((panel, panelIndex) => {
    // Keep a link to the plugin
    return {
      panel: panel,
      panelIndex: panelIndex,
      plugin: plugin
    }
  }))
    // Only the secondary panels
    .filter(panel => panel.panel.panelType == 1 /* Secondary */)
    // Either the panel is a module for ocWebAdmin, or it's not a module (will be iframed)
    .filter(panel => panel.panel.moduleForGlobalAdminPanel == null || panel.panel.moduleForGlobalAdminPanel == ocWebAdminInstalledPlugin.value.plugin)
})

// Get the list of plugins with hardcoded settings UI
const pluginHardcodedSettings = computed(() => {
  if(websiteVersionPluginsLoaded.value == false) {
    return []
  }

  const plugins = websiteVersionPlugins.value.filter(plugin => plugin.infos.name == 'proxiedWebsites' || plugin.infos.name == 'injectedVariables' || plugin.infos.name == 'staticFrontend')

  // In non dev mode, we hide settings from these plugins
  if(store.devMode == false) {
    return []
  }

  return plugins
})


</script>

<template>
  <div>
    <div v-if="websiteVersionPluginsLoading" style="text-align: center; margin: 2em;">
      Loading plugin infos...
    </div>
    <div v-else-if="websiteVersionPluginsIsError">
      <div class="text-danger text-90" style="text-align: center; margin: 2em;">
        <span>Failed to load plugin infos: {{ websiteVersionPluginsError.shortMessage || websiteVersionPluginsError.message }}</span>
      </div>
    </div>
    <div v-else-if="websiteVersionPluginsLoaded" class="settings">

      <!-- <AdminPanel
      v-if="websiteVersionPluginsLoaded"
      :contractAddress 
      :chainId 
      :websiteVersion
      :websiteVersionIndex
      :websiteClient
      :pluginsInfos="websiteVersionPlugins"
      :pluginInfos="websiteVersionPlugins.find(plugin => plugin.infos.name == 'visualizeValueMint')" /> -->

      <!-- <AdminSettingsPanel
      v-if="websiteVersionPluginsLoaded"
      :contractAddress 
      :chainId 
      :websiteVersion
      :websiteVersionIndex
      :websiteClient
      :pluginsInfos="websiteVersionPlugins"
      :pluginInfos="websiteVersionPlugins.find(plugin => plugin.infos.name == 'themeAboutMe')" />  -->

      <div class="settings-item" v-if="websiteVersionsLoaded && websiteVersionsData.totalCount == 1">
        <WebsiteVersionsSettings
          :contractAddress
          :chainId
          :websiteVersion
          :websiteVersionIndex
          :websiteClient
          />
      </div>

      <div class="settings-item">
        <DeveloperModeSettings
          :contractAddress
          :chainId
          :websiteVersion
          :websiteVersionIndex
          :websiteClient
          />
      </div>

      <div class="settings-item">
        <AddressSettings
          :contractAddress
          :chainId
          :websiteVersion
          :websiteVersionIndex
          :websiteClient
          />
      </div>

      <!-- <div v-for="panel in pluginSecondaryAdminPanels" class="settings-item">
        <div class="title">
          {{ panel.plugin.infos.title }}
          <small v-if="panel.plugin.infos.subTitle" class="text-muted" style="font-weight: normal; font-size:0.7em;">
            {{ panel.plugin.infos.subTitle }}
          </small>
        </div>

        <RemoteAsyncComponent
          v-if="panel.panel.moduleForGlobalAdminPanel" 
          
          :umdModuleUrl="panel.panel.url.startsWith('web3://') ? panel.panel.url : 'web3://' + props.contractAddress + ':' + props.chainId + panel.panel.url"
          :moduleName="panel.plugin.infos.name + 'AdminPanels.Panel' + panel.panelIndex"
          :cssUrl="(panel.panel.url.startsWith('web3://') ? panel.panel.url : 'web3://' + props.contractAddress + ':' + props.chainId + panel.panel.url).replace('.umd.js', '.css')"

          :contractAddress 
          :chainId 
          :websiteVersion
          :websiteVersionIndex
          :websiteClient
          :pluginsInfos="websiteVersionPlugins"
          :pluginInfos="panel.plugin"
          />

        <iframe
          v-else
          :src="panel.panel.url.startsWith('web3://') ? panel.panel.url : 'web3://' + props.contractAddress + ':' + props.chainId + panel.panel.url"
          style="width: 100%; height: 400px; border: none;"
          ></iframe>
      </div> -->

      <!-- Hardcoded settings UI for plugin (to be splitted later?) -->

      <!-- <div v-for="pluginInfos in pluginHardcodedSettings" class="settings-item">
        <SettingsPlugin
          :websiteVersion
          :websiteVersionIndex
          :contractAddress
          :chainId
          :websiteClient 
          :pluginInfos="pluginInfos" />
      </div> -->



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
  margin-bottom: 0.75em;
}

</style>