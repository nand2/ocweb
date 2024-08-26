<script setup>
import { ref, watch, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useSwitchChain, useAccount } from '@wagmi/vue'
import { useQueryClient } from '@tanstack/vue-query'

import FilesTab from './FilesTab.vue';
import PreviewTab from './PreviewTab.vue';
import SettingsTab from './SettingsTab.vue';
import PluginsTab from './PluginsTab.vue';
import WebsiteVersionEditor from './staticFrontendPluginEditor/StaticFrontendEditor.vue';
import WebsiteVersionsConfigEditor from './websiteVersionsEditor/WebsiteVersionsConfigEditor.vue';
import { useVersionableWebsiteClient, useLiveWebsiteVersion, useWebsiteVersions, useWebsiteVersionPlugins } from '../../../../../src/tanstack-vue.js';
import GearIcon from '../../../icons/GearIcon.vue';
import ChevronDownIcon from '../../../icons/ChevronDownIcon.vue';
import PagesTab from './PagesTab.vue';
import RemoteAsyncComponent from '../../utils/RemoteAsyncComponent.vue';
import AdminPanel from '../../../../../../ocweb-theme-about-me/admin/src/components/AdminPanel.vue';

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

const { switchChainAsync } = useSwitchChain()
const queryClient = useQueryClient()

// Tabs handling. Default value will be set once the plugin list was loaded
const activeTab = ref('');

// Reference to the preview tab
const previewTabRef = ref(null)

// Fetch the website client
const { data: websiteClient, isSuccess: websiteClientLoaded } = useVersionableWebsiteClient
(props.contractAddress)


// Fetch the live website infos
const { data: liveWebsiteVersionData, isLoading: liveWebsiteVersionLoading, isFetching: liveWebsiteVersionFetching, isError: liveWebsiteVersionIsError, error: liveWebsiteVersionError, isSuccess: liveWebsiteVersionLoaded } = useLiveWebsiteVersion(queryClient, props.contractAddress, props.chainId)

const userSelectedWebsiteVersionBeingEditedIndex = ref(-1)
// The index of the website version being edited is by default the live version
// and then can be changed by the select form
const websiteVersionBeingEditedIndex = computed(() => {
  if(userSelectedWebsiteVersionBeingEditedIndex.value != -1) {
    return userSelectedWebsiteVersionBeingEditedIndex.value
  }
  if(liveWebsiteVersionLoaded.value) {
    return liveWebsiteVersionData.value.websiteVersionIndex
  }
  return -1;
})

// Get the website version being edited
const { data: websiteVersionBeingEdited, isLoading: websiteVersionBeingEditedLoading, isFetching: websiteVersionBeingEditedFetching, isError: websiteVersionBeingEditedIsError, error: websiteVersionBeingEditedError, isSuccess: websiteVersionBeingEditedLoaded } = useQuery({
  queryKey: ['OCWebsiteVersion', props.contractAddress, props.chainId, websiteVersionBeingEditedIndex],
  queryFn: async () => {
    // Switch chain if necessary
    await switchChainAsync({ chainId: props.chainId })

    return await websiteClient.value.getWebsiteVersion(websiteVersionBeingEditedIndex.value)
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => websiteClientLoaded.value && liveWebsiteVersionLoaded.value),
})

// Get the list of installed plugins of the version being edited
const { data: websiteVersionBeingEditedPlugins, isLoading: websiteVersionBeingEditedPluginsLoading, isFetching: websiteVersionBeingEditedPluginsFetching, isError: websiteVersionBeingEditedPluginsIsError, error: websiteVersionBeingEditedPluginsError, isSuccess: websiteVersionBeingEditedPluginsLoaded } = useWebsiteVersionPlugins(props.contractAddress, props.chainId, websiteVersionBeingEditedIndex) 

const staticFrontendInstalledPlugin = computed(() => {
  if(websiteVersionBeingEditedPluginsLoaded.value == false) {
    return null
  }

  return websiteVersionBeingEditedPlugins.value.find(plugin => plugin.infos.name == 'staticFrontend')
})

const ocWebAdminInstalledPlugin = computed(() => {
  if(websiteVersionBeingEditedPluginsLoaded.value == false) {
    return null
  }

  return websiteVersionBeingEditedPlugins.value.find(plugin => plugin.infos.name == 'ocWebAdmin')
})

// Get the list of admin panels of the plugins
const pluginPrimaryAdminPanels = computed(() => {
  if(websiteVersionBeingEditedPluginsLoaded.value == false) {
    return []
  }

  // Fetch all the panels (1+ per plugin)
  return websiteVersionBeingEditedPlugins.value.flatMap(plugin => plugin.infos.adminPanels.map((panel, panelIndex) => {
    // Keep a link to the plugin
    return {
      panel: panel,
      panelIndex: panelIndex,
      plugin: plugin,
      tabKey: 'plugin-' + plugin.plugin + '-' + panelIndex
    }
  }))
    // Only the primary panels
    .filter(panel => panel.panel.panelType == 0 /* Primary */)
    // Either the panel is a module for ocWebAdmin, or it's not a module (will be iframed)
    .filter(panel => panel.panel.moduleForGlobalAdminPanel == null || panel.panel.moduleForGlobalAdminPanel == ocWebAdminInstalledPlugin.value.plugin)
})

// When the plugins are loaded, now set the default tab
watch(websiteVersionBeingEditedPluginsLoaded, () => {
  if(activeTab.value != '') {
    return;
  }

  if(staticFrontendInstalledPlugin.value) {
    activeTab.value = 'files'
  }
  else {
    activeTab.value = 'preview'
  }
})

// Get the list website versions : Only when the user display the form to select a version
const showEditedWebsiteVersionSelector = ref(false)
const { data: websiteVersionsData, isLoading: websiteVersionsLoading, isFetching: websiteVersionsFetching, isError: websiteVersionsIsError, error: websiteVersionsError, isSuccess: websiteVersionsLoaded } = useWebsiteVersions(queryClient, props.contractAddress, props.chainId, showEditedWebsiteVersionSelector)

const showConfigPanel = ref(false)
</script>

<template>
  <div class="versionable-static-website-editor">
    <div class="header">
      <div class="header-inner">
        <span v-if="websiteVersionBeingEditedLoading">
          Loading version...
        </span>
        <span v-else-if="websiteVersionBeingEditedIsError">
          Error loading version: {{ websiteVersionBeingEditedError.shortMessage || websiteVersionBeingEditedError.message }}
        </span>
        <a v-else-if="websiteVersionBeingEditedLoaded" class="bg" @click.prevent.stop="showEditedWebsiteVersionSelector = !showEditedWebsiteVersionSelector">
          
          <span class="selected-version-label">
            <span>
              Version #{{ websiteVersionBeingEditedIndex }}: 
              {{ websiteVersionBeingEdited.description }} 
              <span class="badge" v-if="websiteVersionBeingEditedIndex == liveWebsiteVersionData.websiteVersionIndex">
                Live
              </span>
            </span>
            <ChevronDownIcon />
          </span>

          <div class="form-select-website-version-popup" v-if="showEditedWebsiteVersionSelector">
            <div class="form-select-website-version-popup-inner">
              <span v-if="websiteVersionsLoading" class="text-muted text-90">
                Loading website versions...
              </span>
              <span v-else-if="websiteVersionsIsError" class="text-danger text-90">
                Error loading website versions: {{ websiteVersionsError.message }}
              </span>
              <div v-else-if="websiteVersionsLoaded" class="entries">
                <a v-for="(websiteVersion, index) in websiteVersionsData.versions" :key="index" class="bg entry" @click.prevent.stop="userSelectedWebsiteVersionBeingEditedIndex = index; showEditedWebsiteVersionSelector = false">
                  Version #{{ index }}: 
                  {{ websiteVersion.description }}
                  <span class="badge" v-if="index == liveWebsiteVersionData.websiteVersionIndex">
                    Live
                  </span>
                </a>
              </div>
            </div>
          </div>

        </a>
        <a class="bg" style="display: flex; align-items: center; padding: 0.5em 1em;" @click.prevent.stop="showConfigPanel = !showConfigPanel">
          <GearIcon />
        </a>
      </div>

      <div class="versions-config-panel" v-if="showConfigPanel">
        <WebsiteVersionsConfigEditor
          :contractAddress
          :chainId
          :websiteClient="websiteClient"
          />
      </div>
    </div>

    <div class="tabs">
      <a v-for="(panel, index) in pluginPrimaryAdminPanels" :key="index" @click="activeTab = panel.tabKey" :class="{tabPages: true, active: activeTab == panel.tabKey}">{{ panel.panel.title }}</a>

      <a v-if="staticFrontendInstalledPlugin" @click="activeTab = 'pages'" :class="{tabPages: true, active: activeTab == 'pages'}">Pages</a>
      
      <a @click="activeTab = 'preview'; previewTabRef.refreshPreviewIframe()" :class="{tabPreview: true, active: activeTab == 'preview'}">Preview</a>

      <span class="separator" style="margin: auto"></span>

      <a v-if="staticFrontendInstalledPlugin" @click="activeTab = 'files'" :class="{tabFiles: true, active: activeTab == 'files'}">Files</a>
      <a @click="activeTab = 'plugins'" :class="{tabPlugins: true, active: activeTab == 'plugins'}">Plugins</a>
      <a @click="activeTab = 'settings'" :class="{tabSettings: true, active: activeTab == 'settings'}">Settings</a>
    </div>

    <!-- <AdminPanel
      v-if="websiteVersionBeingEditedLoaded && websiteClientLoaded && websiteVersionBeingEditedPluginsLoaded"
      :websiteVersion="websiteVersionBeingEdited"
      :websiteVersionIndex="websiteVersionBeingEditedIndex"
      :contractAddress 
      :chainId 
      :websiteClient
      :pluginsInfos="websiteVersionBeingEditedPlugins"
      :pluginInfos="websiteVersionBeingEditedPlugins.find(plugin => plugin.infos.name == 'themeAboutMe')" /> -->

    <div v-for="(panel, index) in pluginPrimaryAdminPanels" :key="index" class="tab">
      <!-- Plugin mode -->
      <RemoteAsyncComponent
        v-if="activeTab == panel.tabKey && panel.panel.moduleForGlobalAdminPanel" 
        
        :umdModuleUrl="panel.panel.url.startsWith('web3://') ? panel.panel.url : 'web3://' + props.contractAddress + ':' + props.chainId + panel.panel.url"
        :moduleName="panel.plugin.infos.name + 'Admin' + panel.panelIndex"
        :cssUrl="(panel.panel.url.startsWith('web3://') ? panel.panel.url : 'web3://' + props.contractAddress + ':' + props.chainId + panel.panel.url).replace('.umd.js', '.css')"

        :websiteVersion="websiteVersionBeingEditedLoaded ? websiteVersionBeingEdited : null"
        :websiteVersionIndex="websiteVersionBeingEditedIndex"
        :contractAddress 
        :chainId 
        :websiteClient
        :pluginsInfos="websiteVersionBeingEditedPlugins"
        :pluginInfos="panel.plugin"
        />

      <!-- Iframe mode -->
      <iframe
        v-else-if="activeTab == panel.tabKey"
        :src="panel.panel.url.startsWith('web3://') ? panel.panel.url : 'web3://' + props.contractAddress + ':' + props.chainId + panel.panel.url"
        style="width: 100%; height: 400px; border: none;"
        ></iframe>
    </div>
    
    <PagesTab
      v-if="staticFrontendInstalledPlugin"
      :websiteVersion="websiteVersionBeingEditedLoaded ? websiteVersionBeingEdited : null"
      :websiteVersionIndex="websiteVersionBeingEditedIndex"
      :contractAddress 
      :chainId 
      :websiteClient="websiteClient"
      :pluginInfos="staticFrontendInstalledPlugin"
      class="tab" v-show="activeTab == 'pages'" />
    <FilesTab 
      v-if="staticFrontendInstalledPlugin"
      :websiteVersion="websiteVersionBeingEditedLoaded ? websiteVersionBeingEdited : null"
      :websiteVersionIndex="websiteVersionBeingEditedIndex"
      :contractAddress 
      :chainId 
      :websiteClient="websiteClient"
      :pluginInfos="staticFrontendInstalledPlugin"
      class="tab" v-show="activeTab == 'files'" />
    <PreviewTab 
      ref="previewTabRef"
      :websiteVersion="websiteVersionBeingEditedLoaded ? websiteVersionBeingEdited : null"
      :websiteVersionIndex="websiteVersionBeingEditedIndex"
      :contractAddress 
      :chainId 
      :websiteClient="websiteClient"
      class="tab" v-show="activeTab == 'preview'" />
    <SettingsTab 
      :websiteVersion="websiteVersionBeingEditedLoaded ? websiteVersionBeingEdited : null"
      :websiteVersionIndex="websiteVersionBeingEditedIndex"
      :contractAddress 
      :chainId 
      :websiteClient="websiteClient"
      class="tab" v-show="activeTab == 'settings'" />
    <PluginsTab
      :websiteVersion="websiteVersionBeingEditedLoaded ? websiteVersionBeingEdited : null"
      :websiteVersionIndex="websiteVersionBeingEditedIndex"
      :contractAddress 
      :chainId 
      :websiteClient="websiteClient"
      class="tab" v-show="activeTab == 'plugins'" />

  </div>
</template>

<style scoped>
.versionable-static-website-editor {
  min-height: 500px;
  display: flex;
  flex-direction: column;
}


.tabs {
  display: flex;
  gap: 1em;
  padding-left: 1em;
  padding-right: 1em;
  background-color: var(--color-light-bg);
  justify-content: space-between;
  border-bottom: 1px solid var(--color-divider);
}

.tabs a {
  color: var(--color-text);
  padding-top: 1em;
  padding-bottom: calc(1em - 3px);
}

.tabs a:hover {
  color: var(--color-bglink-hover);
}

.tabs a.active {
  border-bottom: 3px solid var(--color-link);

}



.header {

}

.header .header-inner {
  border-bottom: 1px solid var(--color-divider);
  display: flex;
  align-items: stretch;
  justify-content: space-between;
  background-color: var(--color-root-bg);
  user-select: none;
}

.selected-version-label {
  padding: 0.5em 1em;
  display: flex;
  gap: 1em;
  align-items: center;
}

.form-select-website-version-popup {
  position: relative;
}

.form-select-website-version-popup-inner {
  position: absolute;
  top: 0;
  background-color: var(--color-root-bg);
  border-top: 1px solid var(--color-divider);
  border-right: 1px solid var(--color-divider);
  border-bottom: 1px solid var(--color-divider-secondary);
  width: 100%;
  z-index: 1;
}

.form-select-website-version-popup-inner > span {
  padding: 0.5em 1em;
  display: block;
}

.form-select-website-version-popup-inner .entries {
  display: flex;
  flex-direction: column;
}

.form-select-website-version-popup-inner .entry {
  padding: 0.5em 1em;
  display: block;
}

.form-select-website-version-popup-inner .entries .entry {

}

.versions-config-panel {
  border-bottom: 1px solid var(--color-divider);
}

</style>