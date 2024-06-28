import { getContract, toHex, walletActions, publicActions } from 'viem'

import { abi as versionableStaticWebsiteABI } from './abi/versionableStaticWebsiteABI.js'
import { abi as storageBackendABI } from './abi/storageBackendABI.js'


class VersionableStaticWebsiteClient {
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
  async prepareAddFilesToFrontendVersionRequests(frontendIndex, fileInfos) {
    // Fetch the frontend version
    const frontendVersion = await this.#viemWebsiteContract.read.getFrontendVersion([frontendIndex])

    // Check if the frontend version is locked
    if (frontendVersion.locked) {
      throw new Error('Frontend version is locked')
    }

    // Get the storage backend name
    const storageBackendContract = getContract({
      address: frontendVersion.storageBackend,
      abi: storageBackendABI,
      client: this.#viemClient,
    })
    const storageBackendName = await storageBackendContract.read.name()

    // Prepare the batch of requests 
    const requests = []
    let currentFileUploadInfos = []
    for (const fileInfo of fileInfos) {
      // SSTORE2 handling
      if (storageBackendName.startsWith('SSTORE2')) {
        // Determine how much bytes do we already have in the current addFilesToFrontendVersion batch
        let currentBatchSize = 0
        for (const fileUploadInfos of currentFileUploadInfos) {
          // The data is stored in hex, so we divide by 2
          currentBatchSize += fileUploadInfos.data.length / 2 - 2
        }

        // We store the file in SSTORE2 chunks of (0x6000-1) bytes ((0x6000-1) being the size of 
        // a SSTORE2 chunk). All sent chunks except the last one must be a multiple of 
        // (0x6000-1) bytes. The last chunk can be any size.
        // Transaction size limit is 131072 bytes, but we also get "exceeds block gas limit" 
        // when trying to put too much, so we aim at 3 chunk max per transaction
        const maxChunkSize = 3 * (0x6000-1);

        // Determine the initial chunk size
        let maxInitialChunkSize = Math.floor((maxChunkSize - currentBatchSize) / (0x6000-1)) * (0x6000-1);
        let initialChunkSize = Math.min(fileInfo.size, maxInitialChunkSize)
        // If no more room in the current batch, start a new one
        if (initialChunkSize == 0) {
          requests.push({
            functionName: 'addFilesToFrontendVersion',
            args: [frontendIndex, currentFileUploadInfos],
          })
          currentFileUploadInfos = []
          initialChunkSize = Math.min(fileInfo.size, maxChunkSize)
        }

        // Determine the chunk sizes
        const chunkSizes = [initialChunkSize]
        let remainingSize = fileInfo.size - initialChunkSize
        while (remainingSize > 0) {
          const chunkSize = Math.min(remainingSize, maxChunkSize)
          chunkSizes.push(chunkSize)
          remainingSize -= chunkSize
        }

console.log('chunkSizes', chunkSizes)

        let processedSize = 0
        for(const chunkSize of chunkSizes) {
          const dataStart = processedSize;
          const dataEnd = processedSize + chunkSize;
          const chunk = fileInfo.data.slice(dataStart, dataEnd);

          if(processedSize == 0) {
            currentFileUploadInfos.push({
              filePath: fileInfo.filePath,
              fileSize: fileInfo.size,
              contentType: "text/plain",
              compressionAlgorithm: 0,
              data: toHex(chunk),
            })

            // More than 1 chunk? We finalize the addFilesToFrontendVersion batch
            if(chunkSizes.length > 1) {
              requests.push({
                functionName: 'addFilesToFrontendVersion',
                args: [frontendIndex, currentFileUploadInfos],
              })
              currentFileUploadInfos = []
            }
          }
          else {
            requests.push({
              functionName: 'appendToFileInFrontendVersion',
              args: [frontendIndex, fileInfo.filePath, toHex(chunk)],
            })
          }
          
          processedSize = dataEnd;
        }

      }
    }

    // If the current currentFileUploadInfos batch is not empty, add it to the requests
    if (currentFileUploadInfos.length > 0) {
      requests.push({
        functionName: 'addFilesToFrontendVersion',
        args: [frontendIndex, currentFileUploadInfos],
      })
    }

    return requests
  }

  async executeRequest(request) {
    const { request: simulatedRequest } = await this.#viemClient.simulateContract({
      address: this.#websiteContractAddress,
      abi: versionableStaticWebsiteABI,
      functionName: request.functionName,
      args: request.args,
    })

    const hash = await this.#viemClient.writeContract(simulatedRequest)

    return hash
  }

  async addFilesToFrontendVersion(frontendIndex, fileInfos) {
    // Fetch the frontend version
    const frontendVersion = await this.#viemWebsiteContract.read.getFrontendVersion([frontendIndex])

    // Check if the frontend version is locked
    if (frontendVersion.locked) {
      throw new Error('Frontend version is locked')
    }

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
    

    const { request } = await this.#viemClient.simulateContract({
      address: this.#websiteContractAddress,
      abi: versionableStaticWebsiteABI,
      functionName: 'addFilesToFrontendVersion',
      args: [frontendIndex, fileUploadInfos],
    })

    const hash = await this.#viemClient.writeContract(request)
console.log("boo", hash)
    

    console.log(frontendVersion)
  }
}

export { VersionableStaticWebsiteClient };
