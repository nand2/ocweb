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
# Section. Default to "all"
SECTION=${2:-all}
if [ "$SECTION" != "all" ] && [ "$SECTION" != "contracts" ] && [ "$SECTION" != "frontend-factory" ] && [ "$SECTION" != "plugin-theme-about-me" ] && [ "$SECTION" != "example-ocwebsite" ]; then
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

  # Upload the factory frontend
  PRIVATE_KEY=$PRIVKEY \
  WEB3_ADDRESS=web3://$OCWEBSITEFACTORY_FRONTEND_ADDRESS:${CHAIN_ID} \
  node . --rpc $RPC_URL --skip-tx-validation upload frontend-factory/dist/* / --exclude 'frontend-factory/dist/variables.json'
fi


# Section plugin-theme-about-me: Setup the ThemeAboutMePlugin
if [ "$SECTION" == "all" ] || [ "$SECTION" == "plugin-theme-about-me" ]; then

  # Checking if the plugin is present in an adjacent folder
  # Compute the plugin root folder
  EXPECTED_PLUGIN_LOCATION=$ROOT_FOLDER/../ocweb-theme-about-me
  echo "Checking the plugin-theme-about-me folder at $EXPECTED_PLUGIN_LOCATION ..."
  if [ ! -d "$EXPECTED_PLUGIN_LOCATION" ]; then
    echo "The plugin-theme-about-me folder is missing"
    exit 1
  fi
  PLUGIN_ROOT=$(cd $EXPECTED_PLUGIN_LOCATION && pwd)
  echo "Plugin root folder: $PLUGIN_ROOT"

  # Fetch the address of the OCWebsiteFactory
  OCWEBSITE_FACTORY_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "OCWebsiteFactory" and .transactionType == "CREATE")][0].contractAddress')
  echo "OCWebsiteFactory: $OCWEBSITE_FACTORY_ADDRESS"

  # Fetch the address of the static frontend plugin
  STATIC_FRONTEND_PLUGIN_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "StaticFrontendPlugin" and .transactionType == "CREATE")][0].contractAddress')
  echo "StaticFrontendPlugin: $STATIC_FRONTEND_PLUGIN_ADDRESS"

  # Fetch the address of the OCWebAdminPlugin
  OCWEB_ADMIN_PLUGIN_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "OCWebAdminPlugin" and .transactionType == "CREATE")][0].contractAddress')
  echo "OCWebAdminPlugin: $OCWEB_ADMIN_PLUGIN_ADDRESS"

  # Deploying the plugin
  cd $PLUGIN_ROOT
  echo "Deploying the plugin..."
  exec 5>&1
  OUTPUT="$(
    PRIVATE_KEY=$PRIVKEY \
    RPC_URL=$RPC_URL \
    CHAIN_ID=$CHAIN_ID \
    OCWEBSITE_FACTORY_ADDRESS=$OCWEBSITE_FACTORY_ADDRESS \
    STATIC_FRONTEND_PLUGIN_ADDRESS=$STATIC_FRONTEND_PLUGIN_ADDRESS \
    OCWEB_ADMIN_PLUGIN_ADDRESS=$OCWEB_ADMIN_PLUGIN_ADDRESS \
    ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY \
    ./scripts/deploy.sh | tee >(cat - >&5))"
  
  # Extract the address of the deployed plugin
  PLUGIN_THEME_ABOUT_ME_ADDRESS=$(echo "$OUTPUT" | grep -oP 'Deployed to: \K0x\w+')
  echo "Plugin Theme About Me address: $PLUGIN_THEME_ABOUT_ME_ADDRESS"

  # Add the plugin to the OCWebsiteFactory library, and as a default plugin
  echo "Adding the plugin to the OCWebsiteFactory library..."
  cast send $OCWEBSITE_FACTORY_ADDRESS "addWebsitePlugin(address,bool)()" $PLUGIN_THEME_ABOUT_ME_ADDRESS true --private-key ${PRIVKEY} --rpc-url ${RPC_URL}
fi

# Make a example OCWebsite, and add it as a variable to the factory
if [ "$SECTION" == "all" ] || [ "$SECTION" == "example-ocwebsite" ]; then
  cd $ROOT_FOLDER

  # Fetch the address of the OCWebsiteFactory
  OCWEBSITE_FACTORY_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "OCWebsiteFactory" and .transactionType == "CREATE")][0].contractAddress')
  echo "OCWebsiteFactory: $OCWEBSITE_FACTORY_ADDRESS"

  exec 5>&1
  OUTPUT="$(PRIVATE_KEY=$PRIVKEY \
    node . --rpc $RPC_URL --skip-tx-validation mint --factory-address $OCWEBSITE_FACTORY_ADDRESS $CHAIN_ID example | tee >(cat - >&5))"

  # Get the address of the OCWebsite
  OCWEBSITE_ADDRESS=$(echo "$OUTPUT" | grep -oP 'New OCWebsite smart contract: \K0x\w+')

  # Fetch the address of the injectedVariables plugin
  INJECTED_VARIABLES_PLUGIN_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "InjectedVariablesPlugin" and .transactionType == "CREATE")][0].contractAddress')

  # Fetch the address of the OCWebsiteFactoryFrontend
  OCWEBSITE_FACTORY_FRONTEND_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "OCWebsiteFactory" and .function == "setWebsite(address)")][0].arguments[0]')
  echo "OCWebsiteFactoryFrontend: $OCWEBSITE_FACTORY_FRONTEND_ADDRESS"

  # Add the OCWebsite address as a variable to the factory
  echo "Adding the example OCWebsite to the factory as a variable..."
  cast send $INJECTED_VARIABLES_PLUGIN_ADDRESS "addVariable(address,uint,string,string)" $OCWEBSITE_FACTORY_FRONTEND_ADDRESS 0 ocwebsite-example "${OCWEBSITE_ADDRESS}:${CHAIN_ID}" --private-key ${PRIVKEY} --rpc-url ${RPC_URL}
fi