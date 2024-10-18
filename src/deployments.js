// Array of deployment smart contract addresses
const deployments = [
  { chainId: 10, address: '0x9fEB198ec07B31A9A34221c1AA53b71E0d38dA58' }, // Optimism mainnet
  { chainId: 17000, address: '0x94FeD796154344A96152d19c841073d9804Bf0b5' }, // Holesky
  // { chainId: 31337, address: '0x8A791620dd6260079BF849Dc5567aDC3F2FdC318' }, // Hardhat
];

// Function to return a deployment by chain id
function getDeploymentAddressByChainId(chainId) {
  return deployments.find(deployment => deployment.chainId === chainId)?.address;
}

export { deployments, getDeploymentAddressByChainId };