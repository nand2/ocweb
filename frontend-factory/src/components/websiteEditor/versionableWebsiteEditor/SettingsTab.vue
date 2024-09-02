<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useSwitchChain, useAccount } from '@wagmi/vue'

import { useContractAddresses, invalidateWebsiteVersionQuery, useWebsiteVersionPlugins } from '../../../../../src/tanstack-vue';
import SettingsProxiedWebsites from './plugins/SettingsPluginProxiedWebsites.vue';
import SettingsInjectedVariables from './plugins/SettingsPluginInjectedVariables.vue';
import SettingsPlugin from './plugins/SettingsPlugin.vue';
import SettingsManagePlugins from './plugins/ManagePlugins.vue';
import RemoteAsyncComponent from '../../utils/RemoteAsyncComponent.vue';
import AdminSettingsPanel from '../../../../../../ocweb-theme-about-me/admin/src/components/AdminSettingsPanel.vue';

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

const { switchChainAsync } = useSwitchChain()

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
    .filter(panel => panel.panel.panelType == 1 /* Primary */)
    // Either the panel is a module for ocWebAdmin, or it's not a module (will be iframed)
    .filter(panel => panel.panel.moduleForGlobalAdminPanel == null || panel.panel.moduleForGlobalAdminPanel == ocWebAdminInstalledPlugin.value.plugin)
})

// Get the list of plugins with hardcoded settings UI
const pluginHardcodedSettings = computed(() => {
  if(websiteVersionPluginsLoaded.value == false) {
    return []
  }

  const plugins = websiteVersionPlugins.value.filter(plugin => plugin.infos.name == 'proxiedWebsites' || plugin.infos.name == 'injectedVariables' || plugin.infos.name == 'staticFrontend')

  // Sort: Put staticFrontend first (the 2 others are more technical)
  plugins.sort((a, b) => {
    if(a.infos.name == 'staticFrontend') {
      return -1
    }
    if(b.infos.name == 'staticFrontend') {
      return 1
    }
    return 0
  })

  return plugins
})

// A list of chain short names (unfortunately not packaged with Viem)
// Infos from https://chainid.network/chains.json
const chainShortNames = {
  1: 'eth',
  11155111: 'sep',
  17000: 'holesky',
  10: 'oeth',
  11155420: 'opsep',
  42161: 'arb1',
  42170: 'arb-nova',
  421614: 'arb-sep',
  8543: 'base',
  85432: 'basesep',
  31337: 'hardhat'
}

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

      <!-- <AdminSettingsPanel
      v-if="websiteVersionPluginsLoaded"
      :contractAddress 
      :chainId 
      :websiteVersion
      :websiteVersionIndex
      :websiteClient
      :pluginsInfos="websiteVersionPlugins"
      :pluginInfos="websiteVersionPlugins.find(plugin => plugin.infos.name == 'themeAboutMe')" />  -->

      <div v-for="panel in pluginSecondaryAdminPanels" class="settings-item">
        <div class="title">
          {{ panel.plugin.infos.title }}
          <small v-if="panel.plugin.infos.subTitle" class="text-muted" style="font-weight: normal; font-size:0.7em;">
            {{ panel.plugin.infos.subTitle }}
          </small>
        </div>

         <!-- Plugin mode -->
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

        <!-- Iframe mode -->
        <iframe
          v-else
          :src="panel.panel.url.startsWith('web3://') ? panel.panel.url : 'web3://' + props.contractAddress + ':' + props.chainId + panel.panel.url"
          style="width: 100%; height: 400px; border: none;"
          ></iframe>
      </div>

      <!-- Hardcoded settings UI for plugin (to be splitted later?) -->

      <div v-for="pluginInfos in pluginHardcodedSettings" class="settings-item">
        <SettingsPlugin
          :websiteVersion
          :websiteVersionIndex
          :contractAddress
          :chainId
          :websiteClient 
          :pluginInfos="pluginInfos" />
      </div>

      <div class="settings-item ens-settings" v-if="chainShortNames[chainId]">
        <div class="title">
          ENS domain name
          <small class="text-muted" style="font-weight: normal; font-size:0.7em;">
            Steps to configure your own domain
          </small>
        </div>
        
        <div class="text-90" style="margin-bottom: 0.7em">
          To access this website with <code style="font-weight: bold;">web3://my-domain.eth</code>, edit <code style="font-weight: bold;">my-domain.eth</code> in the official ENS app, and add the following Text Record:
        </div>

        <div class="table-header">
          <div>
            Text Record Name
          </div>
          <div>
            Text Record Value
          </div>
          <div>

          </div>
        </div>

        <div class="table-row">
          <div>
            <code>
              contentcontract
            </code>
          </div>
          <div>
            <code>
              {{ chainShortNames[chainId] }}:{{ contractAddress }}
            </code>
          </div>
          <div>
          </div>
        </div>

      </div>

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



.ens-settings .table-header,
.ens-settings .table-row {
  grid-template-columns: 1fr 3fr;
}
</style>