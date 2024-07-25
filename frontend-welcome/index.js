
async function getWeb3Address() {
  const response = await fetch('/variables.json')
  if (!response.ok) {
    throw new Error('variables.json not found')
  }
  const decodedResponse = await response.json()
  
  let [selfAddress, selfChainId] = decodedResponse.self.split(':')
  selfChainId = parseInt(selfChainId)

  let web3Url = `web3://${selfAddress}`
  if (selfChainId > 1) {
    web3Url += `:${selfChainId}`
  }

  return web3Url
}

export {
  getWeb3Address
}