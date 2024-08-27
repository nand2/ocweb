export const abi = [
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
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
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
        internalType: "struct StaticFrontendPlugin.FileUploadInfos[]",
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
      }
    ],
    name: "addStorageBackend",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
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
    inputs: [
      {
        internalType: "contract IStorageBackend",
        name: "",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "",
        type: "uint256"
      }
    ],
    name: "contentKeysRefCounters",
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
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "fromFrontendIndex",
        type: "uint256"
      },
      {
        internalType: "uint256",
        name: "toFrontendIndex",
        type: "uint256"
      }
    ],
    name: "copyFrontendSettings",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
        type: "uint256"
      },
      {
        internalType: "uint256[]",
        name: "contentKeys",
        type: "uint256[]"
      }
    ],
    name: "filesSizeAndUploadSizes",
    outputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "size",
            type: "uint256"
          },
          {
            internalType: "uint256",
            name: "uploadedSize",
            type: "uint256"
          }
        ],
        internalType: "struct IStorageBackend.Sizes[]",
        name: "",
        type: "tuple[]"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
        type: "uint256"
      }
    ],
    name: "getStaticFrontend",
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
          }
        ],
        internalType: "struct StaticFrontendPlugin.StaticFrontend",
        name: "",
        type: "tuple"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "getStorageBackends",
    outputs: [
      {
        components: [
          {
            internalType: "contract IStorageBackend",
            name: "storageBackend",
            type: "address"
          },
          {
            internalType: "string",
            name: "name",
            type: "string"
          },
          {
            internalType: "string",
            name: "title",
            type: "string"
          },
          {
            internalType: "string",
            name: "version",
            type: "string"
          }
        ],
        internalType: "struct StaticFrontendPlugin.StorageBackendWithInfos[]",
        name: "",
        type: "tuple[]"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "infos",
    outputs: [
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
          },
          {
            internalType: "contract IVersionableWebsitePlugin[]",
            name: "dependencies",
            type: "address[]"
          },
          {
            components: [
              {
                internalType: "string",
                name: "title",
                type: "string"
              },
              {
                internalType: "string",
                name: "url",
                type: "string"
              },
              {
                internalType: "contract IVersionableWebsitePlugin",
                name: "moduleForGlobalAdminPanel",
                type: "address"
              },
              {
                internalType: "enum IVersionableWebsitePlugin.AdminPanelType",
                name: "panelType",
                type: "uint8"
              }
            ],
            internalType: "struct IVersionableWebsitePlugin.AdminPanel[]",
            name: "adminPanels",
            type: "tuple[]"
          }
        ],
        internalType: "struct IVersionableWebsitePlugin.Infos",
        name: "",
        type: "tuple"
      }
    ],
    stateMutability: "view",
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
    inputs: [
      {
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
        type: "uint256"
      },
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
    name: "processWeb3Request",
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
    inputs: [
      {
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
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
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
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
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
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
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
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
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
        type: "uint256"
      },
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
    name: "rewriteWeb3Request",
    outputs: [
      {
        internalType: "bool",
        name: "rewritten",
        type: "bool"
      },
      {
        internalType: "string[]",
        name: "newResource",
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
        name: "newParams",
        type: "tuple[]"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
        type: "uint256"
      },
      {
        internalType: "contract IStorageBackend",
        name: "storageBackend",
        type: "address"
      }
    ],
    name: "setStorageBackend",
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
    name: "storageBackends",
    outputs: [
      {
        internalType: "contract IStorageBackend",
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
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4"
      }
    ],
    name: "supportsInterface",
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
        internalType: "contract IVersionableWebsite",
        name: "",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "",
        type: "uint256"
      }
    ],
    name: "websiteVersionStaticFrontends",
    outputs: [
      {
        internalType: "contract IStorageBackend",
        name: "storageBackend",
        type: "address"
      }
    ],
    stateMutability: "view",
    type: "function"
  }
]