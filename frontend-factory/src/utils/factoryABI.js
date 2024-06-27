export const abi = [
  {
    type: 'function',
    name: 'mintWebsite',
    stateMutability: 'payable',
    inputs: [{ internalType: "contract IStorageBackend", name: "storageBackend", type: "address" }],
    outputs: [],
  },
]