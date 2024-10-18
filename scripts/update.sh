#! /bin/bash

set -euo pipefail

# Target chain: If empty, default to "local"
# Can be: local, sepolia, holesky, mainnet, base-sepolia, base, optimism
TARGET_CHAIN=${1:-local}
# Check that target chain is in allowed values
if [ "$TARGET_CHAIN" != "local" ] && [ "$TARGET_CHAIN" != "sepolia" ] && [ "$TARGET_CHAIN" != "holesky" ] && [ "$TARGET_CHAIN" != "mainnet" ] && [ "$TARGET_CHAIN" != "base-sepolia" ] && [ "$TARGET_CHAIN" != "base" ] && [ "$TARGET_CHAIN" != "optimism" ]; then
  echo "Invalid target chain: $TARGET_CHAIN"
  exit 1
fi
# Section. Default to "all"
SECTION=${2:-}
if [ "$SECTION" != "factory-frontend-files" ]; then
  echo "Invalid section: $SECTION"
  exit 1
fi
DOMAIN=ocweb


# Setup cleanup
function cleanup {
  echo "Exiting, cleaning up..."
  # rm -rf dist
}
trap cleanup EXIT

# Go to the root folder
ROOT_FOLDER=$(cd $(dirname $(readlink -f $0)); cd ..; pwd)
cd $ROOT_FOLDER

# Load .env file
# PRIVATE_KEY must be defined
source .env
# Determine the private key and RPC URL to use, and the chain id
PRIVKEY=
RPC_URL=
CHAIN_ID=
if [ "$TARGET_CHAIN" == "local" ]; then
  PRIVKEY=$PRIVATE_KEY_LOCAL
  RPC_URL=http://127.0.0.1:8545
  CHAIN_ID=31337
elif [ "$TARGET_CHAIN" == "sepolia" ]; then
  PRIVKEY=$PRIVATE_KEY_SEPOLIA
  RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
  CHAIN_ID=11155111
elif [ "$TARGET_CHAIN" == "holesky" ]; then
  PRIVKEY=$PRIVATE_KEY_HOLESKY
  RPC_URL=https://ethereum-holesky-rpc.publicnode.com
  CHAIN_ID=17000
elif [ "$TARGET_CHAIN" == "base-sepolia" ]; then
  PRIVKEY=$PRIVATE_KEY_BASE_SEPOLIA
  RPC_URL=https://sepolia.base.org
  CHAIN_ID=84532
elif [ "$TARGET_CHAIN" == "base" ]; then
  PRIVKEY=$PRIVATE_KEY_BASE
  RPC_URL=https://mainnet.base.org
  CHAIN_ID=8453
elif [ "$TARGET_CHAIN" == "optimism" ]; then
  PRIVKEY=$PRIVATE_KEY_OPTIMISM
  RPC_URL=https://mainnet.optimism.io/
  CHAIN_ID=10
else
  echo "Not implemented yet"
  exit 1
fi

# Preparing the etherscan API key
# For etherscan, it is already set in the .env file
# If basescan, copy BASESCAN_API_KEY into it
if [ "$TARGET_CHAIN" == "base-sepolia" ] || [ "$TARGET_CHAIN" == "base" ]; then
  export ETHERSCAN_API_KEY=$BASESCAN_API_KEY
fi
# If optimism, copy OPTIMISTIC_ETHERSCAN_API_KEY into it
if [ "$TARGET_CHAIN" == "optimism" ]; then
  export ETHERSCAN_API_KEY=$OPTIMISTIC_ETHERSCAN_API_KEY
fi

# Preparing options for forge
FORGE_SCRIPT_OPTIONS=
if [ "$TARGET_CHAIN" == "local" ]; then
  # 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
  FORGE_SCRIPT_OPTIONS="--broadcast"
elif [ "$TARGET_CHAIN" == "sepolia" ]; then
  # 0xAafA7E1FBE681de12D41Ef9a5d5206A96963390e
  FORGE_SCRIPT_OPTIONS="--broadcast --verify" #  --legacy --with-gas-price=5000000000
elif [ "$TARGET_CHAIN" == "holesky" ]; then
  # 0xAafA7E1FBE681de12D41Ef9a5d5206A96963390e
  # Weird, sometimes I have "Failed to get EIP-1559 fees" on holesky, need --legacy
  FORGE_SCRIPT_OPTIONS="--broadcast --verify" #  --legacy --with-gas-price=1000000000
elif [ "$TARGET_CHAIN" == "base-sepolia" ]; then
  # 0xAafA7E1FBE681de12D41Ef9a5d5206A96963390e
  FORGE_SCRIPT_OPTIONS="--broadcast --verify"
elif [ "$TARGET_CHAIN" == "base" ]; then
  # 0xAafA7E1FBE681de12D41Ef9a5d5206A96963390e
  FORGE_SCRIPT_OPTIONS="--broadcast --verify --slow"
elif [ "$TARGET_CHAIN" == "optimism" ]; then
  # 0xAafA7E1FBE681de12D41Ef9a5d5206A96963390e
  FORGE_SCRIPT_OPTIONS="--broadcast --verify --slow"
else
  echo "Not implemented yet"
  exit 1
fi

# Non-hardhat chain: Ask for confirmation
if [ "$TARGET_CHAIN" != "local" ]; then
  echo "Please confirm that you want to deploy on $TARGET_CHAIN"
  read -p "Press enter to continue"
fi

# Get the factory address, and the factory frontend address
if [ "$CHAIN_ID" == "10" ] || [ "$CHAIN_ID" == "17000" ]; then
  OCWEBSITE_FACTORY_ADDRESS=$(node . factory-infos ${CHAIN_ID} | grep 'Address:' |  awk '{print $2}')
  OCWEBSITE_FACTORY_FRONTEND_WEB3_ADDRESS=$(node . factory-infos ${CHAIN_ID} | grep 'Website:' | awk '{print $2}')
else
  OCWEBSITE_FACTORY_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "ERC1967Proxy" and .transactionType == "CREATE")][0].contractAddress')
  OCWEBSITE_FACTORY_FRONTEND_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "InjectedVariablesPlugin" and .function == "addVariable(address,uint256,string,string)")][0].arguments[0]')
  OCWEBSITE_FACTORY_FRONTEND_WEB3_ADDRESS="web3://${OCWEBSITE_FACTORY_FRONTEND_ADDRESS}:${CHAIN_ID}"
fi

# Update files in the factory frontend
if [ "$SECTION" == "factory-frontend-files" ]; then
  echo "Updating files on factory frontend $OCWEBSITE_FACTORY_FRONTEND_WEB3_ADDRESS ..."

  # First create a new version
fi