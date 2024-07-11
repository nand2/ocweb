<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useSwitchChain, useAccount } from '@wagmi/vue'

import { useContractAddresses, invalidateWebsiteVersionQuery } from '../../../utils/queries';
import SettingsProxiedWebsites from './SettingsProxiedWebsites.vue';
import SettingsInjectedVariables from './SettingsInjectedVariables.vue';
import BoxArrowUpRightIcon from '../../../icons/BoxArrowUpRightIcon.vue';

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
  pluginInfos: {
    type: Object,
    required: true,
  },
})

const openHomepageWithArgs = () => {
  let url = props.pluginInfos.infos.homepage;
  // If we count only 2 slashes, we assume there is no / after the domain name
  // We need to add a / after the domain name before adding the args
  if (url.split('/').length == 3) {
    url += '/';
  }
  url += '?websiteAddress=' + props.contractAddress + '&websiteChainId=' + props.chainId;
  window.open(url, '_blank');
}

</script>

<template>
  <div>
    <div class="title">
      {{ pluginInfos.infos.title }}
      <small v-if="pluginInfos.infos.subTitle" class="text-muted" style="font-weight: normal; font-size:0.7em;">
        {{ pluginInfos.infos.subTitle }}
      </small>
    </div>

    <SettingsProxiedWebsites 
      v-if="pluginInfos.infos.name == 'proxiedWebsites'"
      :frontendVersion
      :frontendVersionIndex
      :contractAddress
      :chainId
      :websiteClient
      :pluginInfos />

    <SettingsInjectedVariables
      v-else-if="pluginInfos.infos.name == 'injectedVariables'"
      :frontendVersion
      :frontendVersionIndex
      :contractAddress
      :chainId
      :websiteClient
      :pluginInfos />

    <div v-else>
      <div v-if="pluginInfos.infos.homepage">
        <button @click="openHomepageWithArgs()" class="sm">Configure <BoxArrowUpRightIcon /></button>
      </div>
      <div v-else>
        <div class="text-muted text-90">
          The plugin did not provide an interface to configure it.
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.title {
  font-size: 1.1em;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>