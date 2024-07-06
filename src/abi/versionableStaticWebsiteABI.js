export const abi = [
  {
    inputs: [],
    stateMutability: "nonpayable",
    type: "constructor"
  },
  {
    inputs: [],
    name: "AlreadyInitialized",
    type: "error"
  },
  {
    inputs: [],
    name: "ArraysLengthMismatch",
    type: "error"
  },
  {
    inputs: [],
    name: "ContractAddressNameAlreadyUsed",
    type: "error"
  },
  {
    inputs: [],
    name: "ContractAddressNameReserved",
    type: "error"
  },
  {
    inputs: [],
    name: "FileAlreadyExistsAsDirectory",
    type: "error"
  },
  {
    inputs: [],
    name: "FileAlreadyExistsAtNewLocation",
    type: "error"
  },
  {
    inputs: [],
    name: "FileNotFound",
    type: "error"
  },
  {
    inputs: [],
    name: "FrontendIndexOutOfBounds",
    type: "error"
  },
  {
    inputs: [],
    name: "FrontendLibraryLocked",
    type: "error"
  },
  {
    inputs: [],
    name: "FrontendVersionIsAlreadyLocked",
    type: "error"
  },
  {
    inputs: [],
    name: "FrontendVersionLocked",
    type: "error"
  },
  {
    inputs: [],
    name: "IndexOutOfBounds",
    type: "error"
  },
  {
    inputs: [],
    name: "InvalidNewOwner",
    type: "error"
  },
  {
    inputs: [],
    name: "Unauthorized",
    type: "error"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        components: [
          {
            internalType: "string",
            name: "filePath",
            type: "string"
          },
          {
            internalType: "uint256",
            name: "fileSize",
            type: "uint256"
          },
          {
            internalType: "string",
            name: "contentType",
            type: "string"
          },
          {
            internalType: "enum CompressionAlgorithm",
            name: "compressionAlgorithm",
            type: "uint8"
          },
          {
            internalType: "bytes",
            name: "data",
            type: "bytes"
          }
        ],
        internalType: "struct IFrontendLibrary.FileUploadInfos[]",
        name: "fileUploadInfos",
        type: "tuple[]"
      }
    ],
    name: "addFilesToFrontendVersion",
    outputs: [],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "contract IStorageBackend",
        name: "storageBackend",
        type: "address"
      },
      {
        internalType: "string",
        name: "_description",
        type: "string"
      },
      {
        internalType: "int256",
        name: "settingsCopiedFromFrontendVersionIndex",
        type: "int256"
      }
    ],
    name: "addFrontendVersion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        internalType: "string",
        name: "key",
        type: "string"
      },
      {
        internalType: "string",
        name: "value",
        type: "string"
      }
    ],
    name: "addInjectedVariableToFrontend",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        internalType: "contract IDecentralizedApp",
        name: "website",
        type: "address"
      },
      {
        internalType: "string[]",
        name: "localPrefix",
        type: "string[]"
      },
      {
        internalType: "string[]",
        name: "remotePrefix",
        type: "string[]"
      }
    ],
    name: "addProxiedWebsiteToFrontend",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        internalType: "string",
        name: "filePath",
        type: "string"
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes"
      }
    ],
    name: "appendToFileInFrontendVersion",
    outputs: [],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [],
    name: "defaultFrontendIndex",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        internalType: "bool",
        name: "enable",
        type: "bool"
      }
    ],
    name: "enableViewerForFrontendVersion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [],
    name: "frontendLibraryLocked",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "frontendVersionViewerImplementation",
    outputs: [
      {
        internalType: "contract ClonableFrontendVersionViewer",
        name: "",
        type: "address"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256"
      }
    ],
    name: "frontendVersions",
    outputs: [
      {
        internalType: "contract IStorageBackend",
        name: "storageBackend",
        type: "address"
      },
      {
        internalType: "string",
        name: "description",
        type: "string"
      },
      {
        internalType: "contract IDecentralizedApp",
        name: "viewer",
        type: "address"
      },
      {
        internalType: "bool",
        name: "isViewable",
        type: "bool"
      },
      {
        internalType: "bool",
        name: "locked",
        type: "bool"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "getDefaultFrontendIndex",
    outputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      }
    ],
    name: "getFrontendVersion",
    outputs: [
      {
        components: [
          {
            components: [
              {
                internalType: "string",
                name: "filePath",
                type: "string"
              },
              {
                internalType: "string",
                name: "contentType",
                type: "string"
              },
              {
                internalType: "enum CompressionAlgorithm",
                name: "compressionAlgorithm",
                type: "uint8"
              },
              {
                internalType: "uint256",
                name: "contentKey",
                type: "uint256"
              }
            ],
            internalType: "struct PartialFileInfos[]",
            name: "files",
            type: "tuple[]"
          },
          {
            internalType: "contract IStorageBackend",
            name: "storageBackend",
            type: "address"
          },
          {
            internalType: "string",
            name: "description",
            type: "string"
          },
          {
            components: [
              {
                internalType: "string",
                name: "key",
                type: "string"
              },
              {
                internalType: "string",
                name: "value",
                type: "string"
              }
            ],
            internalType: "struct KeyValueVariable[]",
            name: "injectedVariables",
            type: "tuple[]"
          },
          {
            components: [
              {
                internalType: "contract IDecentralizedApp",
                name: "website",
                type: "address"
              },
              {
                internalType: "string[]",
                name: "localPrefix",
                type: "string[]"
              },
              {
                internalType: "string[]",
                name: "remotePrefix",
                type: "string[]"
              }
            ],
            internalType: "struct ProxiedWebsite[]",
            name: "proxiedWebsites",
            type: "tuple[]"
          },
          {
            internalType: "contract IDecentralizedApp",
            name: "viewer",
            type: "address"
          },
          {
            internalType: "bool",
            name: "isViewable",
            type: "bool"
          },
          {
            internalType: "bool",
            name: "locked",
            type: "bool"
          }
        ],
        internalType: "struct FrontendFilesSet",
        name: "",
        type: "tuple"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "startIndex",
        type: "uint256"
      },
      {
        internalType: "uint256",
        name: "count",
        type: "uint256"
      }
    ],
    name: "getFrontendVersions",
    outputs: [
      {
        components: [
          {
            components: [
              {
                internalType: "string",
                name: "filePath",
                type: "string"
              },
              {
                internalType: "string",
                name: "contentType",
                type: "string"
              },
              {
                internalType: "enum CompressionAlgorithm",
                name: "compressionAlgorithm",
                type: "uint8"
              },
              {
                internalType: "uint256",
                name: "contentKey",
                type: "uint256"
              }
            ],
            internalType: "struct PartialFileInfos[]",
            name: "files",
            type: "tuple[]"
          },
          {
            internalType: "contract IStorageBackend",
            name: "storageBackend",
            type: "address"
          },
          {
            internalType: "string",
            name: "description",
            type: "string"
          },
          {
            components: [
              {
                internalType: "string",
                name: "key",
                type: "string"
              },
              {
                internalType: "string",
                name: "value",
                type: "string"
              }
            ],
            internalType: "struct KeyValueVariable[]",
            name: "injectedVariables",
            type: "tuple[]"
          },
          {
            components: [
              {
                internalType: "contract IDecentralizedApp",
                name: "website",
                type: "address"
              },
              {
                internalType: "string[]",
                name: "localPrefix",
                type: "string[]"
              },
              {
                internalType: "string[]",
                name: "remotePrefix",
                type: "string[]"
              }
            ],
            internalType: "struct ProxiedWebsite[]",
            name: "proxiedWebsites",
            type: "tuple[]"
          },
          {
            internalType: "contract IDecentralizedApp",
            name: "viewer",
            type: "address"
          },
          {
            internalType: "bool",
            name: "isViewable",
            type: "bool"
          },
          {
            internalType: "bool",
            name: "locked",
            type: "bool"
          }
        ],
        internalType: "struct FrontendFilesSet[]",
        name: "",
        type: "tuple[]"
      },
      {
        internalType: "uint256",
        name: "totalCount",
        type: "uint256"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "getLiveFrontendVersion",
    outputs: [
      {
        components: [
          {
            components: [
              {
                internalType: "string",
                name: "filePath",
                type: "string"
              },
              {
                internalType: "string",
                name: "contentType",
                type: "string"
              },
              {
                internalType: "enum CompressionAlgorithm",
                name: "compressionAlgorithm",
                type: "uint8"
              },
              {
                internalType: "uint256",
                name: "contentKey",
                type: "uint256"
              }
            ],
            internalType: "struct PartialFileInfos[]",
            name: "files",
            type: "tuple[]"
          },
          {
            internalType: "contract IStorageBackend",
            name: "storageBackend",
            type: "address"
          },
          {
            internalType: "string",
            name: "description",
            type: "string"
          },
          {
            components: [
              {
                internalType: "string",
                name: "key",
                type: "string"
              },
              {
                internalType: "string",
                name: "value",
                type: "string"
              }
            ],
            internalType: "struct KeyValueVariable[]",
            name: "injectedVariables",
            type: "tuple[]"
          },
          {
            components: [
              {
                internalType: "contract IDecentralizedApp",
                name: "website",
                type: "address"
              },
              {
                internalType: "string[]",
                name: "localPrefix",
                type: "string[]"
              },
              {
                internalType: "string[]",
                name: "remotePrefix",
                type: "string[]"
              }
            ],
            internalType: "struct ProxiedWebsite[]",
            name: "proxiedWebsites",
            type: "tuple[]"
          },
          {
            internalType: "contract IDecentralizedApp",
            name: "viewer",
            type: "address"
          },
          {
            internalType: "bool",
            name: "isViewable",
            type: "bool"
          },
          {
            internalType: "bool",
            name: "locked",
            type: "bool"
          }
        ],
        internalType: "struct FrontendFilesSet",
        name: "frontendVersion",
        type: "tuple"
      },
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_owner",
        type: "address"
      },
      {
        internalType: "address",
        name: "_ownershipController",
        type: "address"
      },
      {
        internalType: "contract ClonableFrontendVersionViewer",
        name: "_frontendViewerImplementation",
        type: "address"
      },
      {
        internalType: "contract IStorageBackend",
        name: "firstFrontendVersionStorageBackend",
        type: "address"
      }
    ],
    name: "initialize",
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
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      }
    ],
    name: "lockFrontendVersion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [],
    name: "owner",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "ownershipController",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        internalType: "string",
        name: "filePath",
        type: "string"
      },
      {
        internalType: "uint256",
        name: "chunkId",
        type: "uint256"
      }
    ],
    name: "readFileFromFrontendVersion",
    outputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes"
      },
      {
        internalType: "uint256",
        name: "nextChunkId",
        type: "uint256"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      }
    ],
    name: "removeAllFilesFromFrontendVersion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        internalType: "string[]",
        name: "filePaths",
        type: "string[]"
      }
    ],
    name: "removeFilesFromFrontendVersion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        internalType: "uint256",
        name: "index",
        type: "uint256"
      }
    ],
    name: "removeInjectedVariableFromFrontend",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        internalType: "uint256",
        name: "index",
        type: "uint256"
      }
    ],
    name: "removeProxiedWebsiteFromFrontend",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        internalType: "string[]",
        name: "oldFilePaths",
        type: "string[]"
      },
      {
        internalType: "string[]",
        name: "newFilePaths",
        type: "string[]"
      }
    ],
    name: "renameFilesInFrontendVersion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        internalType: "string",
        name: "newDescription",
        type: "string"
      }
    ],
    name: "renameFrontendVersion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "string[]",
        name: "resource",
        type: "string[]"
      },
      {
        components: [
          {
            internalType: "string",
            name: "key",
            type: "string"
          },
          {
            internalType: "string",
            name: "value",
            type: "string"
          }
        ],
        internalType: "struct KeyValue[]",
        name: "params",
        type: "tuple[]"
      }
    ],
    name: "request",
    outputs: [
      {
        internalType: "uint256",
        name: "statusCode",
        type: "uint256"
      },
      {
        internalType: "string",
        name: "body",
        type: "string"
      },
      {
        components: [
          {
            internalType: "string",
            name: "key",
            type: "string"
          },
          {
            internalType: "string",
            name: "value",
            type: "string"
          }
        ],
        internalType: "struct KeyValue[]",
        name: "headers",
        type: "tuple[]"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "resolveMode",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32"
      }
    ],
    stateMutability: "pure",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      }
    ],
    name: "setDefaultFrontendIndex",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_newOwner",
        type: "address"
      }
    ],
    name: "transferOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  }
];