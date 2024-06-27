import { abi as versionableStaticWebsiteABI } from './versionableStaticWebsiteABI.js'

class FrontendLibraryClient {
  #viemClient = null
  #contractAddress = null
  #chainId = null

  constructor(viemClient, contractAddress, chainId) {
    this.#viemClient = viemClient
    this.#contractAddress = contractAddress
    this.#chainId = chainId
  }
}