export const abi = [
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
        internalType: "uint256",
        name: "index",
        type: "uint256"
      }
    ],
    name: "isComplete",
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
        name: "owner",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "index",
        type: "uint256"
      }
    ],
    name: "uploadedSize",
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
    name: "size",
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
    inputs: [{internalType:"address", name:"owner", type:"address"}, { internalType: "uint256[]", name: "", type: "uint256[]" }], 
    name: "areComplete", 
    outputs: [{ internalType: "bool[]", name: "", type: "bool[]" }], 
    stateMutability: "view", 
    type: "function" 
  },
  { 
    inputs: [{internalType:"address", name:"owner", type:"address"}, { internalType: "uint256[]", name: "", type: "uint256[]" }], 
    name: "uploadedSizes", 
    outputs: [{ internalType: "uint256[]", name: "", type: "uint256[]" }], 
    stateMutability: "view", 
    type: "function" 
  },
  { 
    inputs: [{internalType:"address", name:"owner", type:"address"}, { internalType: "uint256[]", name: "", type: "uint256[]" }], 
    name: "sizes", 
    outputs: [{ internalType: "uint256[]", name: "", type: "uint256[]" }], 
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
  }
];