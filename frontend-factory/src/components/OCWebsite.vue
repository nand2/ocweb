<script setup>
import { ref, computed, defineProps } from 'vue';
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { useQuery } from '@tanstack/vue-query'

import { useContractAddresses } from '../utils/queries.js';
import OCWebsiteEditor from './websiteEditor/Editor.vue';
import XCircleIcon from '../icons/XCircleIcon.vue';
import CopyIcon from '../icons/CopyIcon.vue';


const props = defineProps({
  tokenId: {
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
})
const isOpened = ref(false)

const { isConnected, address } = useAccount();
const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()

const factoryAddress = computed(() => contractAddresses.value?.factories.find(f => f.chainId === props.chainId)?.address)

// Load the token SVG template
const { isSuccess: tokenTemplateLoaded, data: tokenSVGTemplate } = useQuery({
  queryKey: ['OCWebsiteTokenTemplate', factoryAddress, props.chainId],
  queryFn: async () => {
    const response = await fetch(`web3://${factoryAddress.value}:${props.chainId}/tokenSVGTemplate?returns=(string)`)
    if (!response.ok) {
      throw new Error('Network response was not ok')
    }
    const decodedResponse = await response.json()
    return decodedResponse[0]
  },
  staleTime: 3600 * 1000,
  enabled: computed(() => contractAddressesLoaded.value),
})

// Inject vars in the token SVG template, encode it as a data URL for CSS
const tokenSVGTemplateDataUrlForCSS = computed(() => {
  if (tokenSVGTemplate.value == null) {
    return null
  }

  // Inject vars
  const addressPart1 = props.contractAddress.toLowerCase().slice(0, 24);
  const addressPart2 = props.contractAddress.toLowerCase().slice(24) + ":" + props.chainId;
  const svg = tokenSVGTemplate.value
    .replace(/{addressPart1}/g, addressPart1)
    .replace(/{addressPart2}/g, addressPart2)

  // Encode as data URL
  const base64EncodedSVG = btoa(svg);
  return `url('data:image/svg+xml;base64,${base64EncodedSVG}')`
})

// Copy the web3 address to the clipboard
function copyWeb3AddressToClipboard() {
  navigator.clipboard.writeText(`web3://${props.contractAddress}:${props.chainId}`)  
}
</script>

<template>
  <div :class="{ocwebsite: true, isOpened: isOpened}" @click="isOpened == false ? isOpened = true : null">
    <div class="header">
      <div class="web3-address">
        <a @click.stop.prevent="copyWeb3AddressToClipboard()">
          web3://{{ contractAddress }}:{{ chainId }} <CopyIcon />
        </a>
      </div>
      <XCircleIcon class="close" @click.stop="isOpened = false" />
    </div>
    <OCWebsiteEditor class="editor" />
    <div class="footer">

    </div>
  </div>
</template>


<style scoped>
.ocwebsite {
  width: 200px;
  height: min-content;
  background-image: v-bind('tokenSVGTemplateDataUrlForCSS');
  background-size: cover;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  transition: width 0.5s;
}

.ocwebsite .header {
  height: 100px;
  padding: 0px 15px;
  display: flex;
  justify-content: space-between;
  gap: 1em;
  align-items: center;
  transition: height 0.5s;
}

.ocwebsite .web3-address {
  flex: 1;
  font-weight: bold;
  visibility: hidden;
  opacity: 0;
  font-size: 1px;
  transition: visibility 0.25s, opacity 0.25s, font-size 0.25s 0.25s;
  cursor: pointer;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.ocwebsite .web3-address a {
  color: var(--color-text);
}

.ocwebsite .web3-address a:hover {
  background-color: rgb(255, 255, 255, 0.2);
}

.ocwebsite .header svg.close {
  height: 25px;
  width: 25px;
  cursor: pointer;
  visibility: hidden;
  opacity: 0;
  transition: visibility 0.5s, opacity 0.5s;
}

.ocwebsite .editor {
  height: 0px;
  width: 100%;
  transition: height 0.5s;
}

.ocwebsite .footer {
  height: 100px;
  width: 100%;
  transition: height 0.5s;
}


.ocwebsite.isOpened {
  width: 700px;
  cursor: default;
  transition: width 0.5s;
}

@media (max-width: 870px) {
  .ocwebsite.isOpened {
    width: 100%;
  }
}

.ocwebsite.isOpened .header {
  height: 50px;
  transition: height 0.5s;
}

.ocwebsite.isOpened .web3-address {
  visibility: visible;
  opacity: 1;
  font-size: 1em;
  transition: visibility 0.25s 0.25s, opacity 0.25s 0.25s, font-size 0.25s;
}

.ocwebsite.isOpened .header svg.close {
  visibility: visible;
  opacity: 1;
  transition: visibility 0.5s, opacity 0.5s;
}

.ocwebsite.isOpened .editor {
  height: 600px;
  transition: height 0.5s;
}

.ocwebsite.isOpened .footer {
  height: 50px;
  transition: height 0.5s;
}

</style>