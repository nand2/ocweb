export const abi = [
  {
    inputs: [],
    name: "MAX_CHUNK_SIZE",
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
        name: "index",
        type: "uint256"
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes"
      }
    ],
    name: "append",
    outputs: [
      {
        internalType: "uint256",
        name: "fundsUsed",
        type: "uint256"
      }
    ],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes"
      },
      {
        internalType: "uint256",
        name: "fileSize",
        type: "uint256"
      }
    ],
    name: "create",
    outputs: [
      {
        internalType: "uint256",
        name: "index",
        type: "uint256"
      },
      {
        internalType: "uint256",
        name: "fundsUsed",
        type: "uint256"
      }
    ],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "index",
        type: "uint256"
      }
    ],
    name: "getFileStruct",
    outputs: [
      {
        components: [
          {
            internalType: "address[]",
            name: "chunks",
            type: "address[]"
          },
          {
            internalType: "uint256",
            name: "size",
            type: "uint256"
          },
          {
            internalType: "bool",
            name: "deleted",
            type: "bool"
          }
        ],
        internalType: "struct StorageBackendSSTORE2.File",
        name: "",
        type: "tuple"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "getReadChainId",
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
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string"
      }
    ],
    stateMutability: "pure",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "index",
        type: "uint256"
      },
      {
        internalType: "uint256",
        name: "startingChunkId",
        type: "uint256"
      }
    ],
    name: "read",
    outputs: [
      {
        internalType: "bytes",
        name: "result",
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
        name: "index",
        type: "uint256"
      }
    ],
    name: "remove",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address"
      },
      {
        internalType: "uint256[]",
        name: "indexes",
        type: "uint256[]"
      }
    ],
    name: "sizeAndUploadSizes",
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
  }
];