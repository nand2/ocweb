import { getContract, toHex, walletActions, publicActions } from 'viem'

import { abi as factoryABI } from './abi/factoryABI.js'


class FactoryClient {
  #viemClient = null
  #factoryAddress = null
  #viemWebsiteContract = null

  constructor(viemClient, factoryAddress) {
    this.#viemClient = viemClient.extend(publicActions).extend(walletActions)
    this.#factoryAddress = factoryAddress

    this.#viemWebsiteContract = getContract({
      address: this.#factoryAddress,
      abi: factoryABI,
      client: this.#viemClient,
    })
  }

  viemClient() {
    return this.#viemClient
  }

  chain() {
    return this.#viemClient.chain
  }

  async prepareMintTransaction(subdomain) {
    return {
      functionName: 'mintWebsite',
      args: [subdomain],
    }
  }

  async detailedTokensOfOwner(address) {
    return await this.#viemWebsiteContract.read.detailedTokensOfOwner([address])
  }
  


  /**
   * Execute a transaction prepared by one of the prepare* methods
   */
  async executeTransaction(transaction) {
    const simulationResult = await this.simulateTransaction(transaction)
    const hash = await this.executeSimulatedTransaction(simulationResult)

    return hash
  }

  async simulateTransaction(transaction) {
    return await this.#viemClient.simulateContract({
      address: this.#factoryAddress,
      abi: factoryABI,
      functionName: transaction.functionName,
      args: transaction.args,
    })
  }

  async executeSimulatedTransaction(simulatedTransaction) {
    return await this.#viemClient.writeContract(simulatedTransaction.request)
  }

  async waitForTransactionReceipt(hash) {
    return await this.#viemClient.waitForTransactionReceipt({
      hash
    })
  }

}

export { FactoryClient };