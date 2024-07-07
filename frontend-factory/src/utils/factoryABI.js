export const abi = [
  {
    inputs: [
      {
        internalType: "bytes",
        name: "font",
        type: "bytes"
      }
    ],
    stateMutability: "nonpayable",
    type: "constructor"
  },
  {
    inputs: [
      {
        internalType: "contract OCWebsiteFactory",
        name: "_websiteFactory",
        type: "address"
      }
    ],
    name: "setWebsiteFactory",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256"
      }
    ],
    name: "tokenSVG",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "addressStrPart1",
        type: "string"
      },
      {
        internalType: "string",
        name: "addressStrPart2",
        type: "string"
      }
    ],
    name: "tokenSVGByVars",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256"
      }
    ],
    name: "tokenURI",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256"
      }
    ],
    name: "tokenWeb3Address",
    outputs: [
      {
        internalType: "string",
        name: "web3Address",
        type: "string"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "websiteFactory",
    outputs: [
      {
        internalType: "contract OCWebsiteFactory",
        name: "",
        type: "address"
      }
    ],
    stateMutability: "view",
    type: "function"
  }
];