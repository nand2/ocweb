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
SECTION=${2:-all}
if [ "$SECTION" != "all" ] && [ "$SECTION" != "contracts" ] && [ "$SECTION" != "frontend-factory" ] && [ "$SECTION" != "plugin-theme-about-me" ] && [ "$SECTION" != "example-ocwebsite" ] && [ "$SECTION" != "plugin-visualizevalue-mint" ]; then
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
elif [ "$TARGET_CHAIN" == "mainnet" ]; then
  PRIVKEY=$PRIVATE_KEY_MAINNET
  RPC_URL=https://ethereum-rpc.publicnode.com
  CHAIN_ID=1
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
elif [ "$TARGET_CHAIN" == "mainnet" ]; then
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
  LOG_CONTRACTS_WEB3_ADDRESSES=$(echo "$OUTPUT" | grep "web3://")
  echo "$LOG_CONTRACTS_WEB3_ADDRESSES"
  LOG_OCWEBSITEFACTORY_ADDRESS=$(echo "$OUTPUT" | grep "OCWebsiteFactory: ")

fi


# Section frontend-factory: Upload the factory frontend
if [ "$SECTION" == "all" ] || [ "$SECTION" == "frontend-factory" ]; then

  # Build factory
  echo "Building factory frontend..."
  npm run build-factory

  # Fetch the address of the OCWebsiteFactoryFrontend
  OCWEBSITEFACTORY_FRONTEND_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "InjectedVariablesPlugin" and .function == "addVariable(address,uint256,string,string)")][0].arguments[0]')
  echo "Uploading frontend to OCWebsiteFactoryFrontend ($OCWEBSITEFACTORY_FRONTEND_ADDRESS) ..."

  # Upload the factory frontend
  OCWEB_UPLOAD_ARGS=
  if [ "$TARGET_CHAIN" == "local" ]; then
    OCWEB_UPLOAD_ARGS="--skip-tx-validation"
  fi
  PRIVATE_KEY=$PRIVKEY \
  WEB3_ADDRESS=web3://$OCWEBSITEFACTORY_FRONTEND_ADDRESS:${CHAIN_ID} \
  node . --rpc $RPC_URL $OCWEB_UPLOAD_ARGS upload frontend-factory/dist/* / --exclude 'frontend-factory/dist/variables.json'
fi


# Process all plugins to build
if [ "$SECTION" == "all" ]; then
  # Fetch the address of the OCWebsiteFactory
  OCWEBSITE_FACTORY_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "ERC1967Proxy" and .transactionType == "CREATE")][0].contractAddress')
  echo "OCWebsiteFactory: $OCWEBSITE_FACTORY_ADDRESS"

  # Fetch the address of the static frontend plugin
  STATIC_FRONTEND_PLUGIN_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "StaticFrontendPlugin" and .transactionType == "CREATE")][0].contractAddress')
  echo "StaticFrontendPlugin: $STATIC_FRONTEND_PLUGIN_ADDRESS"

  # Fetch the address of the OCWebAdminPlugin
  OCWEB_ADMIN_PLUGIN_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "OCWebAdminPlugin" and .transactionType == "CREATE")][0].contractAddress')
  if [ "$OCWEB_ADMIN_PLUGIN_ADDRESS" == "null" ]; then
    OCWEB_ADMIN_PLUGIN_ADDRESS="0x0000000000000000000000000000000000000000"
  fi
  echo "OCWebAdminPlugin: $OCWEB_ADMIN_PLUGIN_ADDRESS"

  # OCWEB_PLUGINS_BUILD is a string containing a list of plugins to build, in the format
  # "plugin-folder:add-to-factory-library-bool:add-to-default-plugins-bool", separated by a whitespace
  # Explode OCWEB_PLUGINS_BUILD into an array
  IFS=' ' read -r -a OCWEB_PLUGINS_BUILD <<<"$OCWEB_PLUGINS_BUILD"
  for PLUGIN_BUILD in "${OCWEB_PLUGINS_BUILD[@]}"; do
    PLUGIN_FOLDER=$(echo $PLUGIN_BUILD | cut -d: -f1)
    ADD_TO_FACTORY_LIBRARY=$(echo $PLUGIN_BUILD | cut -d: -f2)
    ADD_TO_DEFAULT_PLUGINS=$(echo $PLUGIN_BUILD | cut -d: -f3)
    # Check if the plugin folder exists
    EXPECTED_PLUGIN_LOCATION=$ROOT_FOLDER/../$PLUGIN_FOLDER
    if [ ! -d "$EXPECTED_PLUGIN_LOCATION" ]; then
      echo "The plugin $PLUGIN_FOLDER folder is missing, skipping..."
    else
      PLUGIN_ROOT=$(cd $EXPECTED_PLUGIN_LOCATION && pwd)
      echo "Plugin root folder: $PLUGIN_ROOT"

      # Deploying the plugin
      cd $PLUGIN_ROOT
      echo "Deploying the plugin $PLUGIN_FOLDER..."
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
      PLUGIN_ADDRESS=$(echo "$OUTPUT" | grep -oP 'Deployed to: \K0x\w+')
      echo "Plugin $PLUGIN_FOLDER address: $PLUGIN_ADDRESS"

      # Add the plugin to the OCWebsiteFactory library, and as a default plugin
      if [ "$ADD_TO_FACTORY_LIBRARY" == "true" ]; then
        echo "Adding the plugin to the OCWebsiteFactory library..."
        cast send $OCWEBSITE_FACTORY_ADDRESS "addWebsitePlugin(address,bool)()" $PLUGIN_ADDRESS $ADD_TO_DEFAULT_PLUGINS --private-key ${PRIVKEY} --rpc-url ${RPC_URL}
      fi
    fi
  done
fi


# Make a example OCWebsite, and add it as a variable to the factory
if [ "$SECTION" == "all" ] || [ "$SECTION" == "example-ocwebsite" ]; then
  cd $ROOT_FOLDER

  # Fetch the address of the OCWebsiteFactory
  OCWEBSITE_FACTORY_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "ERC1967Proxy" and .transactionType == "CREATE")][0].contractAddress')
  echo "OCWebsiteFactory: $OCWEBSITE_FACTORY_ADDRESS"

  exec 5>&1
  OUTPUT="$(PRIVATE_KEY=$PRIVKEY \
    node . --rpc $RPC_URL --skip-tx-validation mint --factory-address $OCWEBSITE_FACTORY_ADDRESS $CHAIN_ID example | tee >(cat - >&5))"

  # Get the address of the OCWebsite
  OCWEBSITE_ADDRESS=$(echo "$OUTPUT" | grep -oP 'New OCWebsite smart contract: \K0x\w+')
  # Get the OCWebsite token id
  OCWEBSITE_TOKEN_ID=2 # $(echo "$OUTPUT" | grep -oP 'Token ID: \K\d+')

  # Fetch the address of the injectedVariables plugin
  INJECTED_VARIABLES_PLUGIN_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "InjectedVariablesPlugin" and .transactionType == "CREATE")][0].contractAddress')

  # Fetch the address of the OCWebsiteFactoryFrontend
  OCWEBSITE_FACTORY_FRONTEND_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "InjectedVariablesPlugin" and .function == "addVariable(address,uint256,string,string)")][0].arguments[0]')
  echo "OCWebsiteFactoryFrontend: $OCWEBSITE_FACTORY_FRONTEND_ADDRESS"

  # Add the OCWebsite address as a variable to the factory
  echo "Adding the example OCWebsite to the factory as a variable..."
  cast send $INJECTED_VARIABLES_PLUGIN_ADDRESS "addVariable(address,uint,string,string)" $OCWEBSITE_FACTORY_FRONTEND_ADDRESS 0 ocwebsite-example "${OCWEBSITE_TOKEN_ID}:${CHAIN_ID}" --private-key ${PRIVKEY} --rpc-url ${RPC_URL}
fi


# Final logging : Display the web3:// address of the factory
if [ "$SECTION" == "all" ] || [ "$SECTION" == "contracts" ]; then
  echo ""
  echo "$LOG_OCWEBSITEFACTORY_ADDRESS"
  echo "$LOG_CONTRACTS_WEB3_ADDRESSES"
fi