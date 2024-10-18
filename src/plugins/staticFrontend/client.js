import { getContract, toHex, walletActions, publicActions, fromHex } from 'viem'

import { abi as versionableWebsiteABI } from '../../abi/versionableStaticWebsiteABI.js'
import { abi as staticFrontendPluginABI } from './abi.js'
import { abi as storageBackendABI } from '../../abi/storageBackendABI.js'


class StaticFrontendPluginClient {
  #viemClient = null
  #websiteContractAddress = null
  #viemWebsiteContract = null
  #pluginContractAddress = null
  #viemPluginContract = null

  constructor(viemClient, websiteContractAddress, pluginContractAddress) {
    this.#viemClient = viemClient.extend(publicActions).extend(walletActions)

    this.#websiteContractAddress = websiteContractAddress
    this.#viemWebsiteContract = getContract({
      address: this.#websiteContractAddress,
      abi: versionableWebsiteABI,
      client: this.#viemClient,
    })

    this.#pluginContractAddress = pluginContractAddress
    this.#viemPluginContract = getContract({
      address: this.#pluginContractAddress,
      abi: staticFrontendPluginABI,
      client: this.#viemClient,
    })
  }

  async getStaticFrontend(websiteVersionIndex) {
    return await this.#viemPluginContract.read.getStaticFrontend([this.#websiteContractAddress, websiteVersionIndex])
  }

  async getStaticFrontendFilesSizesFromStorageBackend(websiteVersionIndex, staticFrontend) {
    // If the static frontend was not even initialized, return an empty array
    if(staticFrontend.storageBackend == "0x0000000000000000000000000000000000000000") {
      return []
    }

    // Gather the filename and content keys
    const fileInfos = staticFrontend.files.map(file => {
      return {
        filePath: file.filePath,
        contentType: file.contentType,
        contentKey: file.contentKey,
        compressionAlgorithm: file.compressionAlgorithm,
      }
    })
    const contentKeys = fileInfos.map(fileInfo => fileInfo.contentKey)

    // // Get the storage backend
    // const storageBackendContract = getContract({
    //   address: staticFrontend.storageBackend,
    //   abi: storageBackendABI,
    //   client: this.#viemClient,
    // })

    // Get the sizes
    const sizeAndUploadedSizes = await this.#viemPluginContract.read.filesSizeAndUploadSizes([this.#websiteContractAddress, websiteVersionIndex, contentKeys])

    // Fill all this metadata into the fileInfos
    for (let i = 0; i < fileInfos.length; i++) {
      fileInfos[i].size = sizeAndUploadedSizes[i].size
      fileInfos[i].uploadedSize = sizeAndUploadedSizes[i].uploadedSize
    }
  
    return fileInfos;
  }

  // Read a file fully. This will make multiple calls to readFile until the whole file is read
  // Returns a Uint8Array of the file data
  async readFileFully(websiteVersionIndex, fileInfos, decompress) {
    let chunkId = 0
    let data = new Uint8Array(0)

    while(true) {
      const {data: chunkData, nextChunkId} = await this.readFile(websiteVersionIndex, fileInfos.filePath, chunkId)
      data = new Uint8Array([...data, ...chunkData])
      if(nextChunkId == 0) {
        break
      }
      chunkId = nextChunkId
    }

    if(decompress) {
      const compressionAlgorithm = fileInfos.compressionAlgorithm
      if(compressionAlgorithm == 1 /* gzip */) {
        const decompressedStream = new DecompressionStream('gzip')
        const readableStream = new Response(new Blob([data])).body;
        data = new Uint8Array(await new Response(readableStream.pipeThrough(decompressedStream)).arrayBuffer());
      }
      else if(compressionAlgorithm != 0 /* none */) {
        throw new Error(`Unsupported compression algorithm: ${compressionAlgorithm == 2 ? "brotli" : compressionAlgorithm}`)
      }
    }

    return data
  }

  // Read a file. Return the data and the next chunk id, if any (0 if no more chunks)
  // (So multiple calls can be needed to read a file)
  async readFile(websiteVersionIndex, filePath, chunkId)  {
    const result = await this.#viemPluginContract.read.readFile([this.#websiteContractAddress, websiteVersionIndex, filePath, chunkId])

    return {
      data: fromHex(result[0], 'bytes'),
      nextChunkId: Number(result[1]),
    }
  }

  async getStorageBackends() {
    return await this.#viemPluginContract.read.getStorageBackends([])
  }

  async prepareSetStorageBackendTransaction(websiteVersionIndex, storageBackend) {
    return {
      functionName: 'setStorageBackend',
      args: [this.#websiteContractAddress, websiteVersionIndex, storageBackend],
    }
  }

  /**
   * Prepare the addition of several files to a frontend websiteVersionIndex
   * @param fileInfos: An array of objects with the following properties:
   *   - filePath: The path of the file, without leading /. E.g. "index.html", "assets/logo.png"
   *   - size: The size of the file
   *   - contentType: The content type of the file. E.g. "text/html", "image/png"
   *   - data: Uint8Array of the data of the file
   * @param opts: An object with the following optional properties:
   *   - includeRemoveTransactionsToSync: If true, the files that are not in the fileInfos array will 
   *                                      be removed from the frontend.
   * @returns 2 arrays : 
   *          - One array of transactions to execute
   *            Each transaction is an object with the necessary fields to execute it
   *            Exception: "metadata", which is data meant to be displayed to the user to review
   *            the transactions before executing them
   *          - One array of fileInfos that were skipped because they were already uploaded
   */
  async prepareAddFilesTransactions(websiteVersionIndex, fileInfos, opts) {
    // Default options
    opts = opts || {
      includeRemoveTransactionsToSync: false,
    }

    // Get the website version
    const websiteVersion = await this.#viemWebsiteContract.read.getWebsiteVersion([websiteVersionIndex])
    // Get the live website version
    const liveWebsiteVersionIndex = await this.#viemWebsiteContract.read.liveWebsiteVersionIndex()

    // Fetch the staticFrontend for this websiteVersionIndex
    const staticFrontend = await this.getStaticFrontend(websiteVersionIndex)

    // If there is a storage backend set, get the storage backend name
    let storageBackendName;
    if(staticFrontend.storageBackend != "0x0000000000000000000000000000000000000000") {
      const storageBackendContract = getContract({
        address: staticFrontend.storageBackend,
        abi: storageBackendABI,
        client: this.#viemClient,
      })
      storageBackendName = await storageBackendContract.read.name()
    }
    // Otherwise get the first available storage backend, which is going to be used by default
    else {
      const storageBackends = await this.getStorageBackends()
      storageBackendName = storageBackends[0].name;
    }

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

    // Filter out the files that are already uploaded, and identical
    // If already uploaded, but not identical, flag them as such
    let compressedFilesInfosToUpload = [];
    let skippedCompressedFilesInfos = [];
    // If the website version is not viewable, we cannot download the files to check, so process all
    if(liveWebsiteVersionIndex != websiteVersionIndex && websiteVersion.isViewable == false) {
      compressedFilesInfosToUpload = compressedFilesInfos;
    }
    // If the website version is viewable or live, we can download the files to check
    else {
      // For existing files collision check optimization : Fetch all the sizes of files
      const fileInfosWithSize = await this.getStaticFrontendFilesSizesFromStorageBackend(websiteVersionIndex, staticFrontend);
      // Do the filtering
      for(const compressedFileInfo of compressedFilesInfos) {
        // Find the file in the existing files
        const existingFileInfo = fileInfosWithSize.find(fileInfo => fileInfo.filePath == compressedFileInfo.filePath);
        // Add a flag indicating if the file is already present
        compressedFileInfo.alreadyExists = (existingFileInfo != undefined);
        
        // File not present in remote frontend, or file present in remote frontend, 
        // but different size: we need to upload it
        if(compressedFileInfo.alreadyExists == false || existingFileInfo.size != compressedFileInfo.size) {
          compressedFilesInfosToUpload.push(compressedFileInfo);
          continue;
        }

        // Check if the file to upload is identical to the remote file. If different, we need to upload it
        let isIdentical = true;
        // Fetching remote file content
        let remoteFileData = null;
        try {
          remoteFileData = await this.readFileFully(websiteVersionIndex, compressedFileInfo, false);
        } catch (e) {
          // It could fail if e.g. the file is not completely uploaded yet
          isIdentical = false;
        }
        if(isIdentical) {
          if (remoteFileData.length !== compressedFileInfo.data.length) {
            // Theorically we should not enter here, but just in case
            isIdentical = false;
          } else {
            for (let i = 0; i < remoteFileData.length; i++) {
              if (remoteFileData[i] !== compressedFileInfo.data[i]) {
                isIdentical = false;
                break;
              }
            }
          }
        }
        
        if (!isIdentical) {
          compressedFilesInfosToUpload.push(compressedFileInfo);
          continue;
        }

        // Otherwise : we add it to the list of skipped files
        skippedCompressedFilesInfos.push(compressedFileInfo);
      }
    }

    // Prepare the batch of transactions 
    const transactions = []
    let currentFileUploadInfos = []
    let currentFileUploadInfosMetadata = []
    for (const fileInfo of compressedFilesInfosToUpload) {
      // SSTORE2 handling
      if (storageBackendName.startsWith('sstore2')) {
        // Determine how much bytes do we already have in the current addFiles batch
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
            functionName: 'addFiles',
            args: [this.#websiteContractAddress, websiteVersionIndex, currentFileUploadInfos],
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
              alreadyExists: fileInfo.alreadyExists,
            })

            // More than 1 chunk? We finalize the addFiles batch
            if(chunkSizes.length > 1) {
              transactions.push({
                functionName: 'addFiles',
                args: [this.#websiteContractAddress, websiteVersionIndex, currentFileUploadInfos],
                metadata: { files: currentFileUploadInfosMetadata },
              })
              currentFileUploadInfos = []
              currentFileUploadInfosMetadata = []
            }
          }
          else {
            transactions.push({
              functionName: 'appendToFile',
              args: [this.#websiteContractAddress, websiteVersionIndex, fileInfo.filePath, toHex(chunk)],
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
        functionName: 'addFiles',
        args: [this.#websiteContractAddress, websiteVersionIndex, currentFileUploadInfos],
        metadata: { files: currentFileUploadInfosMetadata },
      })
    }

    // If the includeRemoveTransactionsToSync option is set, remove the files that are not in the fileInfos array
    if(opts.includeRemoveTransactionsToSync) {
      const filesToRemove = staticFrontend.files.filter(file => !fileInfos.find(fileInfo => fileInfo.filePath == file.filePath))
      if(filesToRemove.length > 0) {
        let renameFilesTransaction = await this.prepareRemoveFilesTransaction(websiteVersionIndex, filesToRemove.map(file => file.filePath))
        // Add an empty metadata field
        renameFilesTransaction.metadata = {}
        transactions.push(renameFilesTransaction)
      }
    }

    return { transactions, skippedFiles: skippedCompressedFilesInfos }
  }

  async prepareRenameFilesTransaction(websiteVersion, oldFilePaths, newFilePaths) {
    return {
      functionName: 'renameFiles',
      args: [this.#websiteContractAddress, websiteVersion, oldFilePaths, newFilePaths],
    }
  }

  /**
   * filePaths: An array of strings, each string being the path of a file, without leading /. E.g. "index.html", "assets/logo.png"
   */
  async prepareRemoveFilesTransaction(websiteVersion, filePaths) {
    return {
      functionName: 'removeFiles',
      args: [this.#websiteContractAddress, websiteVersion, filePaths],
    }
  }

  async prepareRemoveAllFilesTransaction(websiteVersion) {
    return {
      functionName: 'removeAllFiles',
      args: [this.#websiteContractAddress, websiteVersion],
    }
  }
  


  /**
   * Execute a transaction prepared by one of the prepare* methods
   */
  async executeTransaction(transaction) {
    const { request } = await this.#viemClient.simulateContract({
      address: this.#pluginContractAddress,
      abi: staticFrontendPluginABI,
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

export { StaticFrontendPluginClient };