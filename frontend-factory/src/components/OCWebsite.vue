<script setup>
import { ref, computed, defineProps } from 'vue';
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { useQuery } from '@tanstack/vue-query'

import { useContractAddresses } from '../utils/queries.js';
import OCWebsiteEditor from './websiteEditor/OCWebsiteEditor.vue';
import XCircleIcon from '../icons/XCircleIcon.vue';
import CopyIcon from '../icons/CopyIcon.vue';
import BoxArrowUpRightIcon from '../icons/BoxArrowUpRightIcon.vue';


const props = defineProps({
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
  subdomain: {
    type: String,
    default: null,
  },
  isOpened: {
    type: Boolean,
    default: false,
  },
  showLinkAndCloseIcons: {
    type: Boolean,
    default: true,
  },
})
const isOpened = ref(props.isOpened)

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
    .replace(/{subdomain}/g, props.subdomain)
    .replace(/{addressPart1}/g, addressPart1)
    .replace(/{addressPart2}/g, addressPart2)

  // Encode as data URL
  const base64EncodedSVG = btoa(svg);
  return `url('data:image/svg+xml;base64,${base64EncodedSVG}')`
})

// Copy the web3 address to the clipboard
const showCopiedIndicator = ref(false)
function copyWeb3AddressToClipboard() {
  navigator.clipboard.writeText(`web3://${props.contractAddress}:${props.chainId}`)

  // Show a success message
  showCopiedIndicator.value = true
  setTimeout(() => {
    showCopiedIndicator.value = false
  }, 1000)
}

const urlWithSlash = computed(() => {
  return `web3://${props.contractAddress}${props.chainId > 1 ? ':' + props.chainId : ''}/`
})
</script>

<template>
  <div :class="{ocwebsite: true, isOpened: isOpened}" @click="isOpened == false ? isOpened = true : null">
    <div class="header">
      <a @click.stop.prevent="copyWeb3AddressToClipboard()" :class="{'web3-address': true, copied: showCopiedIndicator}">
        web3://{{ contractAddress }}:{{ chainId }} 
        <CopyIcon />
        <span class="copy-indicator">
          Copied!
        </span>
      </a>
      <a v-if="showLinkAndCloseIcons" :href="urlWithSlash" target="_blank" class="white header-icon">
        <BoxArrowUpRightIcon />
      </a>
      <a v-if="showLinkAndCloseIcons" @click.stop.prevent="isOpened = false" class="white header-icon">
        <XCircleIcon class="close"  />
      </a>
    </div>

    <OCWebsiteEditor class="editor" :contractAddress :chainId v-if="isOpened" />

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
  display: flex;
  justify-content: space-between;
  align-items: stretch;
  transition: height 0.5s;
  padding-right: 0.5em;
}

.ocwebsite a.web3-address {
  flex: 0 1 auto;
  display: flex;
  align-items: center;
  gap: 0.5em;

  font-weight: bold;
  visibility: hidden;
  opacity: 0;
  font-size: 1px;
  transition: color 0.25s, visibility 0.25s, opacity 0.25s, font-size 0.25s 0.25s;
  cursor: pointer;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  color: var(--color-text);
  position: relative;
  padding: 0.5em 1em;
  margin-right: auto;
}

.ocwebsite a.web3-address:hover {
  background-color: rgb(255, 255, 255, 0.2);
}

.ocwebsite a.web3-address.copied {
  color: transparent;
  transition: color 0.25s;
}

.ocwebsite a.web3-address .copy-indicator {
  color: var(--color-text);
  position: absolute;
  left: 50%;
  opacity: 0;
  transition: opacity 0.25s;
}

.ocwebsite a.web3-address.copied .copy-indicator {
  opacity: 1;
  transition: opacity 0.25s;
}

.ocwebsite .header .header-icon {
  display: flex;
  align-items: center;
  visibility: hidden;
  opacity: 0;
  transition: visibility 0.5s, opacity 0.5s;
  padding: 0.5em 0.5em;
}

.ocwebsite .header .header-icon:hover {
  color: var(--color-text);
}

.ocwebsite .header .header-icon svg {
  height: 25px;
  width: 25px;
  cursor: pointer;
}

.ocwebsite .editor {
  height: 0px;
  width: calc(100% - 2px);
  transition: height 0.5s;
  border-left: 1px solid var(--color-divider);
  border-right: 1px solid var(--color-divider);
}

.ocwebsite .footer {
  height: 100px;
  width: 100%;
  transition: height 0.5s;
}


.ocwebsite.isOpened {
  width: 800px;
  cursor: default;
  transition: width 0.5s;
}

@media (max-width: 970px) {
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
  transition: color 0.25s, visibility 0.25s 0.25s, opacity 0.25s 0.25s, font-size 0.25s;
}

.ocwebsite.isOpened .header .header-icon {
  visibility: visible;
  opacity: 1;
  transition: visibility 0.5s, opacity 0.5s;
}

.ocwebsite.isOpened .editor {
  height: auto;
  transition: height 0.5s;
}

.ocwebsite.isOpened .footer {
  height: 50px;
  transition: height 0.5s;
}

</style>