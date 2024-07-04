export const abi = [
  {
    inputs: [
      {
        internalType: "contract IStorageBackend",
        name: "firstFrontendVersionStorageBackend",
        type: "address"
      }
    ],
    name: "mintWebsite",
    outputs: [
      {
        internalType: "contract ClonableOCWebsite",
        name: "",
        type: "address"
      }
    ],
    stateMutability: "payable",
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
          }
        ],
        internalType: "struct IStorageBackendLibrary.IStorageBackendWithName[]",
        name: "",
        type: "tuple[]"
      }
    ],
    stateMutability: "view",
    type: "function"
  }];