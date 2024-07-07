export const abi = [
  {
    inputs: [
      {
        internalType: "contract IVersionableStaticWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        internalType: "contract IDecentralizedApp",
        name: "proxiedWebsite",
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
    name: "addProxiedWebsite",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "contract IVersionableStaticWebsite",
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
        internalType: "contract IVersionableStaticWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      }
    ],
    name: "getProxiedWebsites",
    outputs: [
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
        internalType: "struct ProxiedWebsitesPlugin.ProxiedWebsite[]",
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
          }
        ],
        internalType: "struct IVersionableStaticWebsitePlugin.Infos",
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
        internalType: "contract IVersionableStaticWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "frontendIndex",
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
        internalType: "contract IVersionableStaticWebsite",
        name: "",
        type: "address"
      },
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
    name: "proxiedWebsites",
    outputs: [
      {
        internalType: "contract IDecentralizedApp",
        name: "website",
        type: "address"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "contract IVersionableStaticWebsite",
        name: "website",
        type: "address"
      },
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
    name: "removeProxiedWebsite",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  }
];