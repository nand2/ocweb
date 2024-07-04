export const abi = [
  {
    type: 'function',
    name: 'mintWebsite',
    stateMutability: 'payable',
    inputs: [{ internalType: "contract IStorageBackend", name: "storageBackend", type: "address" }],
    outputs: [],
  },
  { 
    inputs: [], 
    name: "getStorageBackends", 
    outputs: [{ components: [{ internalType: "IStorageBackend", name: "storageBackend", type: "address" }, { internalType: "string", name: "name", type: "string" }], internalType: "struct IStorageBackendWithName[]", name: "", type: "tuple[]" }], 
    stateMutability: "view", 
    type: "function" 
  },
]