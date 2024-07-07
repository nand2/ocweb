import { getContract, toHex, walletActions, publicActions } from 'viem'

import { abi as injectedVariablesPluginABI } from '../abi/injectedVariablesPluginABI'


class InjectedVariablesPluginClient {
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
      abi: injectedVariablesPluginABI,
      client: this.#viemClient,
    })
  }

  async prepareAddVariableTransaction(frontendIndex, name, value) {
    return {
      functionName: 'addVariable',
      args: [this.#websiteContractAddress, frontendIndex, name, value],
    }
  }

  async getVariables(frontendIndex) {
    return await this.#viemWebsiteContract.read.getVariables([this.#websiteContractAddress, frontendIndex])
  }

  async prepareRemoveVariableTransaction(frontendIndex, name) {
    return {
      functionName: 'removeVariable',
      args: [this.#websiteContractAddress, frontendIndex, name],
    }
  }

  /**
   * Execute a transaction prepared by one of the prepare* methods
   */
  async executeTransaction(transaction) {
    const { request } = await this.#viemClient.simulateContract({
      address: this.#pluginContractAddress,
      abi: injectedVariablesPluginABI,
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

export { InjectedVariablesPluginClient };
