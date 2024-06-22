<script setup>
  import { computed, defineProps } from 'vue';
  import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
  import { useQuery } from '@tanstack/vue-query'
  import { useContractAddresses, useOCWebsiteListByOwner } from '../utils/queries.js';

  const props = defineProps({
    tokenId: {
      type: Number,
      required: true,
    },
    contractAddress: {
      type: String,
      required: true,
    }
  })

  const { isConnected, address } = useAccount();
  const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()

  const factoryAddress = computed(() => contractAddresses.value?.factory.address)

  // Load the token SVG template
  const { isSuccess: tokenTemplateLoaded, data: tokenSVGTemplate } = useQuery({
    queryKey: ['OCWebsiteTokenTemplate'],
    queryFn: async () => {
      const response = await fetch(`web3://${factoryAddress.value}:31337/tokenSVGTemplate?returns=(string)`)
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
    const addressPart2 = props.contractAddress.toLowerCase().slice(24);
    const svg = tokenSVGTemplate.value
      .replace(/{addressPart1}/g, addressPart1)
      .replace(/{addressPart2}/g, addressPart2)

    // Encode as data URL
    const base64EncodedSVG = btoa(svg);
    return `url('data:image/svg+xml;base64,${base64EncodedSVG}')`
  })
</script>

<template>
  <div class="ocwebsite">
    xx
  </div>
</template>


<style scoped>
  .ocwebsite {
    width: 200px;
    height: 200px;
    background-image: v-bind('tokenSVGTemplateDataUrlForCSS');
    background-size: cover;
  }
</style>