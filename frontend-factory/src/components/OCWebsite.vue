<script setup>
import { ref, computed, defineProps } from 'vue';
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { useQuery } from '@tanstack/vue-query'

import { useContractAddresses } from '../../../src/tanstack-vue.js';
import OCWebsiteEditor from './websiteEditor/OCWebsiteEditor.vue';
import WalletConnectModal from './utils/WalletConnectModal.vue';
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
  backgroundSVG: {
    type: String,
    default: null,
  },
  title: {
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


// Inject vars in the token SVG template, encode it as a data URL for CSS
const tokenSVGDataUrlForCSS = computed(() => {
  if (props.backgroundSVG == null) {
    return null
  }

  // Encode as data URL
  const base64EncodedSVG = btoa(props.backgroundSVG);
  return `url('data:image/svg+xml;base64,${base64EncodedSVG}')`
})

// Copy the web3 address to the clipboard
const showCopiedIndicator = ref(false)
function copyWeb3AddressToClipboard() {
  navigator.clipboard.writeText(`web3://${props.contractAddress}${props.chainId > 1 ? ':' + props.chainId : ''}`);

  // Show a success message
  showCopiedIndicator.value = true
  setTimeout(() => {
    showCopiedIndicator.value = false
  }, 1000)
}

const urlWithSlash = computed(() => {
  return `web3://${props.contractAddress}${props.chainId > 1 ? ':' + props.chainId : ''}/`
})

const showWalletConnectModal = ref(false)

const onClick = () => {
  if(isOpened.value) {
    return;
  }

  // Not connected? Show the wallet connect modal
  if (isConnected.value == false) {
    showWalletConnectModal.value = true
  } else {
    isOpened.value = true
  }
}
</script>

<template>
  <div :class="{ocwebsite: true, isOpened: isOpened}">
    <h4 v-if="title">
      <a :href="'web3://' + contractAddress + (chainId > 1 ? ':' + chainId : '')" class="white" target="_blank">
        {{ title }}
      </a>
    </h4>

    <div class="ocwebsite-widget" @click="onClick">
      <div class="header">
        <a @click.stop.prevent="copyWeb3AddressToClipboard()" :class="{'web3-address': true, copied: showCopiedIndicator}">
          web3://{{ contractAddress }}{{ chainId > 1 ? ':' + chainId : '' }}
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

      <OCWebsiteEditor class="editor" 
        :contractAddress="contractAddress"
        :chainId 
        v-if="isOpened" />

      <div class="footer">

      </div>
    </div>
  </div>
  <WalletConnectModal v-model:show="showWalletConnectModal" @connected="isOpened = true" />
</template>


<style scoped>
h4 {
  margin-top: 0em;
  margin-bottom: 0.5em;
  text-align: center;
}

.ocwebsite {
  width: 200px;
  /* transition: width 0.5s; */
}

.ocwebsite-widget {
  height: min-content;
  background-image: v-bind('tokenSVGDataUrlForCSS');
  background-size: cover;
  background-color: var(--color-primary);
  cursor: pointer;
  display: flex;
  flex-direction: column;
}

.ocwebsite-widget .header {
  height: 100px;
  display: flex;
  justify-content: space-between;
  align-items: stretch;
  /* transition: height 0.5s; */
  padding-right: 0.5em;
}

.ocwebsite-widget a.web3-address {
  flex: 0 1 auto;
  display: flex;
  align-items: center;
  gap: 0.5em;

  font-weight: bold;
  visibility: hidden;
  opacity: 0;
  font-size: 1px;
  /* transition: color 0.25s, visibility 0.25s, opacity 0.25s, font-size 0.25s 0.25s; */
  cursor: pointer;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  color: var(--color-text);
  position: relative;
  padding: 0.5em 1em;
  margin-right: auto;
}

.ocwebsite-widget a.web3-address:hover {
  background-color: rgb(255, 255, 255, 0.2);
}

.ocwebsite-widget a.web3-address.copied {
  color: transparent;
  /* transition: color 0.25s; */
}

.ocwebsite-widget a.web3-address .copy-indicator {
  color: var(--color-text);
  position: absolute;
  left: 50%;
  opacity: 0;
  /* transition: opacity 0.25s; */
}

.ocwebsite-widget a.web3-address.copied .copy-indicator {
  opacity: 1;
  /* transition: opacity 0.25s; */
}

.ocwebsite-widget .header .header-icon {
  display: flex;
  align-items: center;
  visibility: hidden;
  opacity: 0;
  /* transition: visibility 0.5s, opacity 0.5s; */
  padding: 0.5em 0.5em;
}

.ocwebsite-widget .header .header-icon:hover {
  color: var(--color-text);
}

.ocwebsite-widget .header .header-icon svg {
  height: 25px;
  width: 25px;
  cursor: pointer;
}

.ocwebsite-widget .editor {
  height: 0px;
  width: calc(100% - 2px);
  /* transition: height 0.5s; */
  border-left: 1px solid var(--color-divider);
  border-right: 1px solid var(--color-divider);
}

.ocwebsite-widget .footer {
  height: 100px;
  width: 100%;
  /* transition: height 0.5s; */
}


.ocwebsite.isOpened {
  width: 800px;
  /* transition: width 0.5s; */
}
@media (max-width: 970px) {
  .ocwebsite.isOpened {
    width: 100%;
  }
}

.ocwebsite.isOpened .ocwebsite-widget {
  cursor: default;
}

.ocwebsite.isOpened .header {
  height: 50px;
  /* transition: height 0.5s; */
}

.ocwebsite.isOpened .web3-address {
  visibility: visible;
  opacity: 1;
  font-size: 1em;
  /* transition: color 0.25s, visibility 0.25s 0.25s, opacity 0.25s 0.25s, font-size 0.25s; */
}

.ocwebsite.isOpened .header .header-icon {
  visibility: visible;
  opacity: 1;
  /* transition: visibility 0.5s, opacity 0.5s; */
}

.ocwebsite.isOpened .editor {
  height: auto;
  /* transition: height 0.5s; */
}

.ocwebsite.isOpened .footer {
  height: 50px;
  /* transition: height 0.5s; */
}

</style>