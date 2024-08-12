#! /bin/bash

set -euo pipefail

# Target chain: If empty, default to "local"
# Can be: local, sepolia, holesky, mainnet, base-sepolia, base
TARGET_CHAIN=${1:-local}
# Check that target chain is in allowed values
if [ "$TARGET_CHAIN" != "local" ] && [ "$TARGET_CHAIN" != "sepolia" ] && [ "$TARGET_CHAIN" != "holesky" ] && [ "$TARGET_CHAIN" != "mainnet" ] && [ "$TARGET_CHAIN" != "base-sepolia" ] && [ "$TARGET_CHAIN" != "base" ]; then
  echo "Invalid target chain: $TARGET_CHAIN"
  exit 1
fi
# Section: Can be "all", "contracts", "frontend-factory", "frontend-website". Default to "all"
# Will not work for local chain, as SSTORE2 frontends is used on local chain
SECTION=${2:-all}
# Check that section is in allowed values
if [ "$SECTION" != "all" ] && [ "$SECTION" != "contracts" ] && [ "$SECTION" != "frontend-factory" ] && [ "$SECTION" != "frontend-welcome" ]; then
  echo "Invalid section: $SECTION"
  exit 1
fi
# Domain name
DEFAULT_DOMAIN="ocweb"
DOMAIN=${3:-$DEFAULT_DOMAIN}


# Setup cleanup
function cleanup {
  echo "Exiting, cleaning up..."
  # rm -rf dist
}
trap cleanup EXIT

# Go to the root folder
cd $(dirname $(readlink -f $0))
cd ..

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


# Timestamp
TIMESTAMP=$(date +%s)

# Function to get the mime type of a file
function get_file_mime_type {
  # If file ends with .css, return text/css (the file command returns text/plain sometimes...
  if [[ $1 == *.css ]]; then
    echo "text/css"
    return
  fi
  # If file ends with .js, return application/javascript (the file command returns application/octet-stream sometimes...
  if [[ $1 == *.js ]]; then
    echo "text/javascript"
    return
  fi
  # Use the file command to get the mime type
  file --brief --mime-type $1
}


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
else
  echo "Not implemented yet"
  exit 1
fi



# Section contracts: Deploy the contracts
if [ "$SECTION" == "all" ] || [ "$SECTION" == "contracts" ]; then

  # Launch the OCWebsiteFactoryScript forge script
  echo ""
  echo "Deploying... "

  # Local target chain: Kill and restart anvil
  if [ "$TARGET_CHAIN" == "local" ]; then
    killall anvil || true
    anvil --gas-limit 500000000 1>/tmp/anvil.log &
    # Loop: wait until anvil is ready
    while ! grep -q "Listening on 127.0.0.1:8545" /tmp/anvil.log; do
      sleep 0.2
    done
  fi


  # Execute the forge script, copy the output for later processing
  exec 5>&1
  OUTPUT="$(TARGET_CHAIN=$TARGET_CHAIN \
    DOMAIN=$DOMAIN \
    forge script OCWebsiteFactoryScript --private-key ${PRIVKEY} --rpc-url ${RPC_URL}  $FORGE_SCRIPT_OPTIONS | tee >(cat - >&5))"


  # Write again at the end the web3:// address
  # echo ""
  # echo "ENS:"
  # echo "$OUTPUT" | grep "ENS registry:"
  echo ""
  echo "Web3 addresses:"
  echo "$OUTPUT" | grep "web3://"

fi


#
# Do the frontend uploads
#

# Section frontend-factory: Upload the factory frontend
if [ "$SECTION" == "all" ] || [ "$SECTION" == "frontend-factory" ]; then

  # Build factory
  echo "Building factory frontend..."
  npm run build-factory

  # Fetch the address of the OCWebsiteFactoryFrontend
  OCWEBSITEFACTORY_FRONTEND_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "OCWebsiteFactory" and .function == "setWebsite(address)")][0].arguments[0]')
  echo "Uploading frontend to OCWebsiteFactoryFrontend ($OCWEBSITEFACTORY_FRONTEND_ADDRESS) ..."

  # Upload the welcome frontend
  PRIVATE_KEY=$PRIVKEY \
  WEB3_ADDRESS=web3://$OCWEBSITEFACTORY_FRONTEND_ADDRESS:${CHAIN_ID} \
  node . --rpc $RPC_URL --skip-tx-validation upload frontend-factory/dist/* / --exclude 'variables.json'
fi


# Section frontend-welcome: Upload the welcome frontend
if [ "$SECTION" == "all" ] || [ "$SECTION" == "frontend-welcome" ]; then

  # Build welcome
  echo "Building welcome frontend..."
  npm run build-welcome

  # Fetch the address of the WelcomeHomepagePlugin frontend
  WELCOMEHOMEPAGEPLUGIN_FRONTEND_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "WelcomeHomepagePlugin" and .transactionType == "CREATE")][0].arguments[0]')
  echo "Uploading frontend to WelcomeHomepagePlugin frontend ($WELCOMEHOMEPAGEPLUGIN_FRONTEND_ADDRESS) ..."

  # Upload the welcome frontend
  PRIVATE_KEY=$PRIVKEY \
  WEB3_ADDRESS=web3://$WELCOMEHOMEPAGEPLUGIN_FRONTEND_ADDRESS:${CHAIN_ID} \
  node . --rpc $RPC_URL --skip-tx-validation upload frontend-welcome/dist/* / --exclude 'variables.json'
fi

