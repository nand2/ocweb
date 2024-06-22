import { useQuery } from '@tanstack/vue-query'
import { useAccount, useSwitchChain, useWriteContract, useWaitForTransactionReceipt } from '@wagmi/vue';
import { computed } from 'vue'

function useContractAddresses() {
  return useQuery({
    queryKey: ['contractAddresses'],
    queryFn: async () => {
      const response = await fetch('/contractAddresses.json')
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      return response.json()
    },
    staleTime: 365 * 24 * 3600 * 1000,
  })
}

function useOCWebsiteListByOwner() {
  const { isConnected, address } = useAccount();
  const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()

  const factoryAddress = computed(() => contractAddresses.value?.factory.address)

  return useQuery({
    queryKey: ['OCWebsiteList', factoryAddress, address],
    queryFn: async () => {
      const response = await fetch(`web3://${factoryAddress.value}:31337/detailedTokensOfOwner/${address.value}?returns=((uint256,address)[])`)
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      const decodedResponse = await response.json()
      return decodedResponse[0].map(([tokenId, contractAddress]) => ({ tokenId: parseInt(tokenId, 16), contractAddress }))
    },
    staleTime: 3600 * 1000,
    enabled: computed(() => contractAddressesLoaded.value && isConnected.value),
  })
}

export { useContractAddresses, useOCWebsiteListByOwner }

