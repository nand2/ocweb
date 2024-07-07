import { getContract, toHex, walletActions, publicActions } from 'viem'

import { abi as proxiedWebsitesPluginABI } from '../abi/proxiedWebsitesPluginABI.js'


class ProxiedWebsitesPluginClient {
  #viemClient = null
  #websiteContractAddress = null
  #pluginContractAddress = null
  #viemWebsiteContract = null

  constructor(viemClient, websiteContractAddress, pluginContractAddress) {
    this.#viemClient = viemClient.extend(publicActions).extend(walletActions)
    this.#websiteContractAddress = websiteContractAddress
    this.#pluginContractAddress = pluginContractAddress

    this.#viemWebsiteContract = getContract({
      address: this.#pluginContractAddress,
      abi: proxiedWebsitesPluginABI,
      client: this.#viemClient,
    })
  }

  async prepareAddProxiedWebsiteTransaction(frontendIndex, localPrefix, remoteAddress, remotePrefix) {
    // We split the local and remote prefixes into arrays of strings
    const localPrefixArray = localPrefix.split('/').filter(s => s !== '')
    const remotePrefixArray = remotePrefix.split('/').filter(s => s !== '')

    return {
      functionName: 'addProxiedWebsite',
      args: [this.#websiteContractAddress, frontendIndex, remoteAddress, localPrefixArray, remotePrefixArray],
    }
  }

  async getProxiedWebsites(frontendIndex) {
    return await this.#viemWebsiteContract.read.getProxiedWebsites([this.#websiteContractAddress, frontendIndex])
  }

  async prepareRemoveProxiedWebsiteTransaction(frontendIndex, proxiedWebsiteIndex) {
    return {
      functionName: 'removeProxiedWebsite',
      args: [this.#websiteContractAddress, frontendIndex, proxiedWebsiteIndex],
    }
  }

  /**
   * Execute a transaction prepared by one of the prepare* methods
   */
  async executeTransaction(transaction) {
    const { request } = await this.#viemClient.simulateContract({
      address: this.#pluginContractAddress,
      abi: proxiedWebsitesPluginABI,
      functionName: transaction.functionName,
      args: transaction.args,
    })

    const hash = await this.#viemClient.writeContract(request)

    return hash
  }

  async waitForTransactionReceipt(hash) {
    return await this.#viemClient.waitForTransactionReceipt({
      hash
    })
  }

}

export { ProxiedWebsitesPluginClient };
