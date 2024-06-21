import { useQuery } from '@tanstack/vue-query'

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
    staleTime: 1000 * 60 * 60 * 24,
  })
}

export { useContractAddresses }

