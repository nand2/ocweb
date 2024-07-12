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
        name: "websiteVersionIndex",
        type: "uint256"
      },
      {
        internalType: "contract IVersionableWebsitePlugin",
        name: "plugin",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "position",
        type: "uint256"
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
        name: "websiteVersionIndex",
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
            components: [
              {
                internalType: "contract IVersionableWebsitePlugin",
                name: "plugin",
                type: "address"
              },
              {
                internalType: "uint96",
                name: "next",
                type: "uint96"
              }
            ],
            internalType: "struct IVersionableWebsite.LinkedListNodePlugin[]",
            name: "pluginNodes",
            type: "tuple[]"
          },
          {
            internalType: "uint96",
            name: "headPluginLinkedList",
            type: "uint96"
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
        name: "websiteVersionIndex",
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
            components: [
              {
                internalType: "contract IVersionableWebsitePlugin",
                name: "plugin",
                type: "address"
              },
              {
                internalType: "uint96",
                name: "next",
                type: "uint96"
              }
            ],
            internalType: "struct IVersionableWebsite.LinkedListNodePlugin[]",
            name: "pluginNodes",
            type: "tuple[]"
          },
          {
            internalType: "uint96",
            name: "headPluginLinkedList",
            type: "uint96"
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
            components: [
              {
                internalType: "contract IVersionableWebsitePlugin",
                name: "plugin",
                type: "address"
              },
              {
                internalType: "uint96",
                name: "next",
                type: "uint96"
              }
            ],
            internalType: "struct IVersionableWebsite.LinkedListNodePlugin[]",
            name: "pluginNodes",
            type: "tuple[]"
          },
          {
            internalType: "uint96",
            name: "headPluginLinkedList",
            type: "uint96"
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
        name: "websiteVersionIndex",
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
        internalType: "uint256",
        name: "frontendIndex",
        type: "uint256"
      },
      {
        internalType: "contract IVersionableWebsitePlugin",
        name: "plugin",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "newPosition",
        type: "uint256"
      }
    ],
    name: "reorderPlugin",
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
        internalType: "string",
        name: "description",
        type: "string"
      },
      {
        internalType: "uint96",
        name: "headPluginLinkedList",
        type: "uint96"
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