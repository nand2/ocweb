<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useSwitchChain, useAccount } from '@wagmi/vue'

import { useContractAddresses, invalidateFrontendVersionQuery } from '../../../utils/queries';
import SettingsProxiedWebsites from './SettingsProxiedWebsites.vue';
import SettingsInjectedVariables from './SettingsInjectedVariables.vue';

const props = defineProps({
  frontendVersion: {
    type: Object,
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

</script>

<template>
  <div>
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
      {{ pluginInfos.infos.name }}
      External plugin
    </div>
  </div>
</template>