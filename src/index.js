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

  async getFrontendFilesExtraMetadataFromStorageBackend(frontendVersion) {
    // Gather the filename and content keys
    const fileInfos = frontendVersion.files.map(file => {
      return {
        filePath: file.filePath,
        contentKey: file.contentKey,
      }
    })
    const contentKeys = fileInfos.map(fileInfo => fileInfo.contentKey)

    // Get the storage backend
    const storageBackendContract = getContract({
      address: frontendVersion.storageBackend,
      abi: storageBackendABI,
      client: this.#viemClient,
    })

    // Get the sizes
    const sizes = await storageBackendContract.read.sizes([this.#websiteContractAddress, contentKeys])
    // Get the uploaded sizes
    const uploadedSizes = await storageBackendContract.read.uploadedSizes([this.#websiteContractAddress, contentKeys])
    // Get the completion status
    const areComplete = await storageBackendContract.read.areComplete([this.#websiteContractAddress, contentKeys])

    // Fill all this metadata into the fileInfos
    for (let i = 0; i < fileInfos.length; i++) {
      fileInfos[i].size = sizes[i]
      fileInfos[i].uploadedSize = uploadedSizes[i]
      fileInfos[i].complete = areComplete[i]
    }
  
    return fileInfos;
  }

  /**
   * Prepare the addition of several files to a frontend version
   * fileUploadInfos: An array of objects with the following properties:
   * - filePath: The path of the file, without leading /. E.g. "index.html", "assets/logo.png"
   * - size: The size of the file
   * - contentType: The content type of the file. E.g. "text/html", "image/png"
   * - data: Uint8Array of the data of the file
   * @returns An array of transactions to execute
   *          Each transaction is an object with the necessary fields to execute it
   *          Exception: "metadata", which is data meant to be displayed to the user to review
   *          the transactions before executing them
   */
  async prepareAddFilesToFrontendVersionTransactions(frontendIndex, fileInfos) {
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

    // Compress the files
    const compressionAlgorithm = "gzip"
    const compressedFilesInfos = []
    for (const fileInfo of fileInfos) {
      if(compressionAlgorithm == "gzip") {
        const compressionStream = new CompressionStream('gzip')
        const readableStream = new Response(new Blob([fileInfo.data])).body;
        const compressedData = await new Response(readableStream.pipeThrough(compressionStream)).arrayBuffer();

        compressedFilesInfos.push({
          filePath: fileInfo.filePath,
          originalSize: fileInfo.data.byteLength,
          size: compressedData.byteLength,
          contentType: fileInfo.contentType,
          compressionAlgorithm: 1, // Solidity enum, 1 is for gzip
          data: new Uint8Array(compressedData),
        })
      }
      // No compression
      else {
        compressedFilesInfos.push({
          filePath: fileInfo.filePath,
          originalSize: fileInfo.data.byteLength,
          size: fileInfo.data.byteLength,
          contentType: fileInfo.contentType,
          compressionAlgorithm: 0, // Solidity enum, 0 is for none
          data: fileInfo.data,
        })
      }
    }

    // Prepare the batch of transactions 
    const transactions = []
    let currentFileUploadInfos = []
    let currentFileUploadInfosMetadata = []
    for (const fileInfo of compressedFilesInfos) {
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
          transactions.push({
            functionName: 'addFilesToFrontendVersion',
            args: [frontendIndex, currentFileUploadInfos],
            metadata: { files: currentFileUploadInfosMetadata },
          })
          currentFileUploadInfos = []
          currentFileUploadInfosMetadata = []
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

        // Send the chunks
        let processedSize = 0
        for(const [chunkId, chunkSize] of chunkSizes.entries()) {
          const dataStart = processedSize;
          const dataEnd = processedSize + chunkSize;
          const chunk = fileInfo.data.slice(dataStart, dataEnd);

          if(processedSize == 0) {
            currentFileUploadInfos.push({
              filePath: fileInfo.filePath,
              fileSize: fileInfo.size,
              contentType: fileInfo.contentType,
              compressionAlgorithm: fileInfo.compressionAlgorithm,
              data: toHex(chunk),
            })
            currentFileUploadInfosMetadata.push({
              originalSize: fileInfo.originalSize,
              sizeSent: chunkSize,
              chunkId,
              chunksCount: chunkSizes.length,
            })

            // More than 1 chunk? We finalize the addFilesToFrontendVersion batch
            if(chunkSizes.length > 1) {
              transactions.push({
                functionName: 'addFilesToFrontendVersion',
                args: [frontendIndex, currentFileUploadInfos],
                metadata: { files: currentFileUploadInfosMetadata },
              })
              currentFileUploadInfos = []
              currentFileUploadInfosMetadata = []
            }
          }
          else {
            transactions.push({
              functionName: 'appendToFileInFrontendVersion',
              args: [frontendIndex, fileInfo.filePath, toHex(chunk)],
              metadata: {
                sizeSent: chunkSize,
                chunkId,
                chunksCount: chunkSizes.length,
              },
            })
          }
          
          processedSize = dataEnd;
        }

      }
    }

    // If the current currentFileUploadInfos batch is not empty, add it to the transactions
    if (currentFileUploadInfos.length > 0) {
      transactions.push({
        functionName: 'addFilesToFrontendVersion',
        args: [frontendIndex, currentFileUploadInfos],
        metadata: { files: currentFileUploadInfosMetadata },
      })
    }

    return transactions
  }

  /**
   * Prepare the renaming of a files
   */
  async prepareRenameFilesInFrontendVersionTransaction(frontendIndex, oldFilePaths, newFilePaths) {
    return {
      functionName: 'renameFilesInFrontendVersion',
      args: [frontendIndex, oldFilePaths, newFilePaths],
    }
  }

  /**
   * Prepare the deletion of a file
   * filePaths: An array of strings, each string being the path of a file, without leading /. E.g. "index.html", "assets/logo.png"
   */
  async prepareRemoveFilesFromFrontendVersionTransaction(frontendIndex, filePaths) {
    return {
      functionName: 'removeFilesFromFrontendVersion',
      args: [frontendIndex, filePaths],
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

export { VersionableStaticWebsiteClient };
