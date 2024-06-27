import { getContract, toHex, walletActions, publicActions } from 'viem'

import { abi as versionableStaticWebsiteABI } from './abi/versionableStaticWebsiteABI.js'
import { abi as storageBackendABI } from './abi/storageBackendABI.js'


class VersionableStaticWebsiteClient {
  #viemClient = null
  #accountAddress = null
  #websiteContractAddress = null
  #viemWebsiteContract = null

  constructor(viemClient, accountAddress, websiteContractAddress) {
    this.#viemClient = viemClient.extend(publicActions).extend(walletActions)
    this.#accountAddress = accountAddress
    this.#websiteContractAddress = websiteContractAddress
    this.#viemWebsiteContract = getContract({
      address: this.#websiteContractAddress,
      abi: versionableStaticWebsiteABI,
      client: this.#viemClient,
    })
  }

  async getLiveFrontendVersion() {
    return await this.#viemWebsiteContract.read.getLiveFrontendVersion()
  }

  /**
   * 
   * fileUploadInfos: An array of objects with the following properties:
   * - filePath: The path of the file, without leading /. E.g. "index.html", "assets/logo.png"
   * - size: The size of the file
   * - data: Uint8Array of the data of the file
   */
  async addFilesToFrontendVersion(frontendIndex, fileInfos) {
    // Fetch the frontend version
    const frontendVersion = await this.#viemWebsiteContract.read.getFrontendVersion([frontendIndex])

    // Check if the frontend version is locked
    if (frontendVersion.locked) {
      throw new Error('Frontend version is locked')
    }

    // Prepare the storageBackend contract instance
    // const storageBackendContract = getContract({
    //   address: frontendVersion.storageBackend,
    //   abi: storageBackendABI,
    //   client: this.#viemClient,
    // })

    // Upload the files
    const fileUploadInfos = [];
    for (const fileInfo of fileInfos) {
      const contentType = "text/plain";

      fileUploadInfos.push({
        filePath: fileInfo.filePath,
        fileSize: fileInfo.size,
        contentType: contentType,
        compressionAlgorithm: 0,
        data: toHex(fileInfo.data),
      })
    }
    console.log([frontendIndex, fileUploadInfos])
    // const hash = await this.#viemWebsiteContract.write.addFilesToFrontendVersion([frontendIndex, fileUploadInfos])
console.log(this.#viemClient)
    const { request } = await this.#viemClient.simulateContract({
      account: this.#accountAddress,
      address: this.#websiteContractAddress,
      abi: versionableStaticWebsiteABI,
      functionName: 'addFilesToFrontendVersion',
      args: [frontendIndex, fileUploadInfos],
    })
console.log(this.#viemClient)
    const hash = await this.#viemClient.writeContract(request)
console.log("boo", hash)
    // const xxx = await this.#viemClient.sendTransaction({
    //   account: this.#accountAddress,
    //   address: this.#websiteContractAddress,
    //   abi: versionableStaticWebsiteABI,
    //   functionName: 'addFilesToFrontendVersion',
    //   args: [frontendIndex, fileUploadInfos],
    // })
    // console.log("boo", xxx)

    console.log(frontendVersion)
  }
}

export { VersionableStaticWebsiteClient };
