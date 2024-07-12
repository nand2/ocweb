import { getContract, toHex, walletActions, publicActions } from 'viem'

import { abi as versionableStaticWebsiteABI } from './abi/versionableStaticWebsiteABI.js'
import { abi as storageBackendABI } from './abi/storageBackendABI.js'


class VersionableWebsiteClient {
  #viemClient = null
  #websiteContractAddress = null
  #viemWebsiteContract = null

  constructor(viemClient, websiteContractAddress) {
    this.#viemClient = viemClient.extend(publicActions).extend(walletActions)
    this.#websiteContractAddress = websiteContractAddress

    this.#viemWebsiteContract = getContract({
      address: this.#websiteContractAddress,
      abi: versionableStaticWebsiteABI,
      client: this.#viemClient,
    })
  }

  async prepareAddWebsiteVersionTransaction(description, pluginsCopiedFromFrontendVersionIndex) {
    return {
      functionName: 'addWebsiteVersion',
      args: [description, pluginsCopiedFromFrontendVersionIndex],
    }
  }

  async getWebsiteVersions(startIndex, count) {
    return await this.#viemWebsiteContract.read.getWebsiteVersions([startIndex, count])
  }

  async getLiveWebsiteVersion() {
    const result = await this.#viemWebsiteContract.read.getLiveWebsiteVersion()
    return {
      websiteVersion: result[0],
      websiteVersionIndex: Number(result[1]),
    }
  }

  async getWebsiteVersion(frontendIndex) {
    return await this.#viemWebsiteContract.read.getWebsiteVersion([frontendIndex])
  }

  async getFrontendVersionsViewer() {
    return await this.#viemWebsiteContract.read.getFrontendVersionsViewer()
  }

  async getSupportedPluginInterfaces() {
    return await this.#viemWebsiteContract.read.getSupportedPluginInterfaces()
  }

  async isLocked() {
    return await this.#viemWebsiteContract.read.isLocked()
  }

  async prepareSetLiveWebsiteVersionIndexTransaction(frontendIndex) {
    return {
      functionName: 'setLiveWebsiteVersionIndex',
      args: [frontendIndex],
    }
  }

  async prepareLockWebsiteVersionTransaction(frontendIndex) {
    return {
      functionName: 'lockWebsiteVersion',
      args: [frontendIndex],
    }
  }

  async prepareEnableViewerForWebsiteVersionTransaction(frontendIndex, enable) {
    return {
      functionName: 'enableViewerForFrontendVersion',
      args: [frontendIndex, enable],
    }
  }

  async prepareRenameFrontendVersionTransaction(frontendIndex, newDescription) {
    return {
      functionName: 'renameFrontendVersion',
      args: [frontendIndex, newDescription],
    }
  }



  async getFrontendVersionPlugins(frontendIndex) {
    const result = await this.#viemWebsiteContract.read.getPlugins([frontendIndex])
    return result;     
  }

  /**
   * Prepare the global lock of the frontend library
   */
  async prepareLockTransaction() {
    return {
      functionName: 'lock',
      args: [],
    }
  }

  async prepareAddPluginTransaction(frontendIndex, pluginAddress) {
    return {
      functionName: 'addPlugin',
      args: [frontendIndex, pluginAddress],
    }
  }

  async prepareRemovePluginTransaction(frontendIndex, pluginAddress) {
    return {
      functionName: 'removePlugin',
      args: [frontendIndex, pluginAddress],
    }
  }

  /**
   * Execute a transaction prepared by one of the prepare* methods
   */
  async executeTransaction(transaction) {
    const { request } = await this.#viemClient.simulateContract({
      address: this.#websiteContractAddress,
      abi: versionableStaticWebsiteABI,
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

export { VersionableWebsiteClient };