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
    inputs: [],
    name: "UnsupportedStorageBackendInterface",
    type: "error"
  },
  {
    inputs: [],
    name: "VERSION",
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
    name: "addFiles",
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
        internalType: "contract IVersionableWebsitePlugin",
        name: "plugin",
        type: "address"
      }
    ],
    name: "addPlugin",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "_description",
        type: "string"
      },
      {
        internalType: "uint256",
        name: "copyPluginsFromWebsiteVersionIndex",
        type: "uint256"
      }
    ],
    name: "addWebsiteVersion",
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
    name: "appendToFile",
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
    name: "websiteVersionViewerImplementation",
    outputs: [
      {
        internalType: "contract ClonableWebsiteVersionViewer",
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
    name: "websiteVersions",
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
        internalType: "bool",
        name: "locked",
        type: "bool"
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
    name: "websiteVersionsViewer",
    outputs: [
      {
        internalType: "contract IDecentralizedApp",
        name: "viewer",
        type: "address"
      },
      {
        internalType: "bool",
        name: "isViewable",
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
    inputs: [],
    name: "getFrontendLibrary",
    outputs: [
      {
        internalType: "contract IFrontendLibrary",
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
    inputs: [],
    name: "getFrontendVersionCount",
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
    name: "getFrontendVersionsViewer",
    outputs: [
      {
        components: [
          {
            internalType: "contract IDecentralizedApp",
            name: "viewer",
            type: "address"
          },
          {
            internalType: "bool",
            name: "isViewable",
            type: "bool"
          }
        ],
        internalType: "struct IVersionableWebsite.FrontendVersionViewer[]",
        name: "",
        type: "tuple[]"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "getLiveWebsiteVersion",
    outputs: [
      {
        components: [
          {
            internalType: "string",
            name: "description",
            type: "string"
          },
          {
            internalType: "contract IVersionableWebsitePlugin[]",
            name: "plugins",
            type: "address[]"
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
        internalType: "struct IVersionableWebsite.WebsiteVersion",
        name: "websiteVersion",
        type: "tuple"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
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
    name: "getPlugins",
    outputs: [
      {
        components: [
          {
            internalType: "contract IVersionableWebsitePlugin",
            name: "plugin",
            type: "address"
          },
          {
            components: [
              {
                internalType: "string",
                name: "name",
                type: "string"
              },
              {
                internalType: "string",
                name: "version",
                type: "string"
              },
              {
                internalType: "string",
                name: "title",
                type: "string"
              },
              {
                internalType: "string",
                name: "subTitle",
                type: "string"
              },
              {
                internalType: "string",
                name: "author",
                type: "string"
              },
              {
                internalType: "string",
                name: "homepage",
                type: "string"
              }
            ],
            internalType: "struct IVersionableWebsitePlugin.Infos",
            name: "infos",
            type: "tuple"
          }
        ],
        internalType: "struct IVersionableWebsite.IVersionableWebsitePluginWithInfos[]",
        name: "pluginWithInfos",
        type: "tuple[]"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "getSupportedPluginInterfaces",
    outputs: [
      {
        internalType: "bytes4[]",
        name: "",
        type: "bytes4[]"
      }
    ],
    stateMutability: "pure",
    type: "function"
  },
  {
    inputs: [],
    name: "getSupportedStorageBackendInterfaces",
    outputs: [
      {
        internalType: "bytes4[]",
        name: "",
        type: "bytes4[]"
      }
    ],
    stateMutability: "pure",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
        type: "uint256"
      }
    ],
    name: "getWebsiteVersion",
    outputs: [
      {
        components: [
          {
            internalType: "string",
            name: "description",
            type: "string"
          },
          {
            internalType: "contract IVersionableWebsitePlugin[]",
            name: "plugins",
            type: "address[]"
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
        internalType: "struct IVersionableWebsite.WebsiteVersion",
        name: "",
        type: "tuple"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "getWebsiteVersionCount",
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
        name: "startIndex",
        type: "uint256"
      },
      {
        internalType: "uint256",
        name: "count",
        type: "uint256"
      }
    ],
    name: "getWebsiteVersions",
    outputs: [
      {
        components: [
          {
            internalType: "string",
            name: "description",
            type: "string"
          },
          {
            internalType: "contract IVersionableWebsitePlugin[]",
            name: "plugins",
            type: "address[]"
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
        internalType: "struct IVersionableWebsite.WebsiteVersion[]",
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
        internalType: "contract ClonableWebsiteVersionViewer",
        name: "_frontendViewerImplementation",
        type: "address"
      },
      {
        internalType: "contract IStorageBackend",
        name: "firstFrontendVersionStorageBackend",
        type: "address"
      },
      {
        internalType: "contract IVersionableWebsitePlugin[]",
        name: "_plugins",
        type: "address[]"
      }
    ],
    name: "initialize",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [],
    name: "isLocked",
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
    name: "liveWebsiteVersionIndex",
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
    inputs: [],
    name: "lock",
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
    inputs: [
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
        type: "uint256"
      }
    ],
    name: "lockWebsiteVersion",
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
        name: "",
        type: "uint256"
      },
      {
        internalType: "uint256",
        name: "",
        type: "uint256"
      }
    ],
    name: "plugins",
    outputs: [
      {
        internalType: "contract IVersionableWebsitePlugin",
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
    name: "readFile",
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
    name: "removeAllFiles",
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
    name: "removeFiles",
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
        internalType: "address",
        name: "plugin",
        type: "address"
      }
    ],
    name: "removePlugin",
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
    name: "renameFiles",
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
        internalType: "uint256",
        name: "websiteVersionIndex",
        type: "uint256"
      },
      {
        internalType: "string",
        name: "newDescription",
        type: "string"
      }
    ],
    name: "renameWebsiteVersion",
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
        internalType: "uint256",
        name: "index",
        type: "uint256"
      }
    ],
    name: "setLiveWebsiteVersionIndex",
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
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256"
      }
    ],
    name: "websiteVersions",
    outputs: [
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
  }
]