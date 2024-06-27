export const abi = [
  { 
    inputs: [], 
    name: "getFrontendLibrary", 
    outputs: [{ internalType: "contract IFrontendLibrary", name: "", type: "address" }], 
    stateMutability: "view", 
    type: "function" 
  }, 
  { 
    inputs: [], 
    name: "getLiveFrontendVersion", 
    outputs: [{ components: [{ components: [{ internalType: "string", name: "filePath", type: "string" }, { internalType: "string", name: "contentType", type: "string" }, { internalType: "uint256", name: "contentKey", type: "uint256" }, { internalType: "bool", name: "complete", type: "bool" }], internalType: "struct FileInfos[]", name: "files", type: "tuple[]" }, { internalType: "contract IStorageBackend", name: "storageBackend", type: "address" }, { internalType: "string", name: "description", type: "string" }, { internalType: "bool", name: "locked", type: "bool" }], internalType: "struct FrontendFilesSet", name: "", type: "tuple" }], 
    stateMutability: "view", 
    type: "function" 
  }, 

  { 
    inputs: [{ internalType: "contract IStorageBackend", name: "storageBackend", type: "address" }, { internalType: "string", name: "_description", type: "string" }],
    name: "addFrontendVersion", 
    outputs: [], 
    stateMutability: "nonpayable", 
    type: "function" 
  }, 
  { 
    inputs: [], 
    name: "getFrontendVersions", 
    outputs: [{ components: [{ components: [{ internalType: "string", name: "filePath", type: "string" }, { internalType: "string", name: "contentType", type: "string" }, { internalType: "uint256", name: "contentKey", type: "uint256" }, { internalType: "bool", name: "complete", type: "bool" }], internalType: "struct FileInfos[]", name: "files", type: "tuple[]" }, { internalType: "contract IStorageBackend", name: "storageBackend", type: "address" }, { internalType: "string", name: "description", type: "string" }, { internalType: "bool", name: "locked", type: "bool" }], internalType: "struct FrontendFilesSet[]", name: "", type: "tuple[]" }], 
    stateMutability: "view", 
    type: "function" 
  },
  { 
    inputs: [{ internalType: "uint256", name: "frontendIndex", type: "uint256" }], 
    name: "getFrontendVersion", 
    outputs: [{ components: [{ components: [{ internalType: "string", name: "filePath", type: "string" }, { internalType: "string", name: "contentType", type: "string" }, { internalType: "uint256", name: "contentKey", type: "uint256" }, { internalType: "bool", name: "complete", type: "bool" }], internalType: "struct FileInfos[]", name: "files", type: "tuple[]" }, { internalType: "contract IStorageBackend", name: "storageBackend", type: "address" }, { internalType: "string", name: "description", type: "string" }, { internalType: "bool", name: "locked", type: "bool" }], internalType: "struct FrontendFilesSet", name: "", type: "tuple" }], 
    stateMutability: "view", 
    type: "function" 
  },
  { 
    inputs: [{ internalType: "uint256", name: "frontendIndex", type: "uint256" }], 
    name: "removeFrontendVersion", 
    outputs: [], 
    stateMutability: "nonpayable", 
    type: "function" 
  },

  { 
    inputs: [], 
    name: "getDefaultFrontendIndex", 
    outputs: [{ internalType: "uint256", name: "frontendIndex", type: "uint256" }], 
    stateMutability: "view", 
    type: "function" 
  }, 
  { 
    inputs: [{ internalType: "uint256", name: "frontendIndex", type: "uint256" }], 
    name: "setDefaultFrontendIndex", 
    outputs: [], 
    stateMutability: "nonpayable", 
    type: "function" 
  },

  {
    inputs: [
      { internalType: "uint256", name: "frontendIndex", type: "uint256" },
      { components: [{ internalType: "string", name: "filePath", type: "string" }, { internalType: "uint256", name: "fileSize", type: "uint256" }, { internalType: "string", name: "contentType", type: "string" }, { internalType: "bytes", name: "data", type: "bytes" }], internalType: "struct IFrontendLibrary.FileUploadInfos[]", name: "fileUploadInfos", type: "tuple[]" }], 
    name: "addFilesToFrontendVersion", 
    outputs: [], 
    stateMutability: "payable", 
    type: "function"
  }, 
  { 
    inputs: [{ internalType: "uint256", name: "frontendIndex", type: "uint256" }, { internalType: "string", name: "filePath", type: "string" }], 
    name: "getFileUploadedSizeInFrontendVersion", 
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }], 
    stateMutability: "view", 
    type: "function" 
  },
  { 
    inputs: [{ internalType: "uint256", name: "frontendIndex", type: "uint256" }, { internalType: "string", name: "filePath", type: "string" }, { internalType: "bytes", name: "data", type: "bytes" }], 
    name: "appendToFileInFrontendVersion", 
    outputs: [], 
    stateMutability: "payable", 
    type: "function" 
  }, 

  { 
    inputs: [{ internalType: "uint256", name: "frontendIndex", type: "uint256" }, { internalType: "string", name: "filePath", type: "string" }, { internalType: "uint256", name: "chunkId", type: "uint256" }], 
    name: "readFileFromFrontendVersion", 
    outputs: [{ internalType: "bytes", name: "data", type: "bytes" }, { internalType: "uint256", name: "nextChunkId", type: "uint256" }], 
    stateMutability: "view", 
    type: "function" 
  },

  { 
    inputs: [{ internalType: "uint256", name: "frontendIndex", type: "uint256" }, { internalType: "string[]", name: "filePaths", type: "string[]" }], 
    name: "removeFilesFromFrontendVersion", 
    outputs: [], 
    stateMutability: "nonpayable", 
    type: "function" 
  },
  { 
    inputs: [{ internalType: "uint256", name: "frontendIndex", type: "uint256" }], 
    name: "removeAllFilesFromFrontendVersion", 
    outputs: [], 
    stateMutability: "nonpayable", 
    type: "function" 
  },

  { 
    inputs: [{ internalType: "uint256", name: "frontendIndex", type: "uint256" }], 
    name: "lockFrontendVersion", 
    outputs: [], 
    stateMutability: "nonpayable", 
    type: "function" 
  },
  { 
    inputs: [], 
    name: "lockFrontendLibrary", 
    outputs: [], 
    stateMutability: "nonpayable", 
    type: "function" 
  }];