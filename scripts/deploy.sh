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
if [ "$SECTION" != "all" ] && [ "$SECTION" != "contracts" ] && [ "$SECTION" != "frontend-factory" ] && [ "$SECTION" != "frontend-website" ]; then
  echo "Invalid section: $SECTION"
  exit 1
fi
# Domain name
DEFAULT_DOMAIN="ocwebsite"
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
  FORGE_SCRIPT_OPTIONS="--broadcast --verify"
elif [ "$TARGET_CHAIN" == "holesky" ]; then
  # 0xAafA7E1FBE681de12D41Ef9a5d5206A96963390e
  FORGE_SCRIPT_OPTIONS="--broadcast --verify"
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

  # # Testnet : get back the domain we sent to OCWebsiteFactory
  # if [ "$TARGET_CHAIN" == "sepolia" ] || [ "$TARGET_CHAIN" == "holesky" ]; then
  #   echo ""
  #   echo "Fetching back domain ..."

  #   OCWEBSITEFACTORY_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "OCWebsiteFactory")][0].contractAddress')
  #   echo $OCWEBSITEFACTORY_ADDRESS
  #   cast send --private-key ${PRIVKEY} --rpc-url ${RPC_URL}  $OCWEBSITEFACTORY_ADDRESS "testnetSendBackDomain()"
  # fi


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

  # Compressing output
  echo ""
  echo "Compressing factory frontend..."
  mkdir -p dist/frontend-factory/assets

  # For each file in frontend-factory/dist (except blogFactoryAddress.json), compress it, and
  # add it to a list to be given to the SSTORE2 or EthStorage contract
  SSTORE2_FILE_ARGS_SIG=""
  ETHSTORAGE_FILE_ARGS=""
  # Exclude blogFactoryAddress.json
  FULL_FILES=$(find frontend-factory/dist -type f | grep -v "contractAddresses.json")
  for FULL_FILE in $FULL_FILES; do
    # Remove the frontend-factory/dist/ prefix
    FILE=$(echo $FULL_FILE | sed "s|frontend-factory/dist/||")
    # If the file starts with "assets/", then remove it from file
    SUBFOLDER=$(echo $FILE | grep -o "assets/" || true)
    if [ ! -z "$SUBFOLDER" ]; then
      FILE=$(echo $FILE | sed "s|assets/||")
    fi
    # Prepare the final compressed file name
    COMPRESSED_FILE_NAME=${DOMAIN}-factory-${TIMESTAMP}-${FILE}.gz
    
    # Compress the file
    gzip -c $FULL_FILE > dist/frontend-factory/${SUBFOLDER}/${COMPRESSED_FILE_NAME}

    # For SSTORE2 (we will ABI-encode it)
    SSTORE2_FILE_ARGS_SIG="${SSTORE2_FILE_ARGS_SIG}(${FILE},${COMPRESSED_FILE_NAME},$(get_file_mime_type $FULL_FILE),${SUBFOLDER:-''}),"
    # For Ethstorage
    ETHSTORAGE_FILE_ARGS="${ETHSTORAGE_FILE_ARGS} ${SUBFOLDER}${FILE}:dist/frontend-factory/${SUBFOLDER}${COMPRESSED_FILE_NAME}"
  done

  # Fetch the address of the OCWebsiteFactory
  OCWEBSITEFACTORY_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "OCWebsiteFactory")][0].contractAddress')
  echo ""
  echo "Detected OCWebsiteFactory: $OCWEBSITEFACTORY_ADDRESS"

  # Fetch the address of the OCWebsiteFactoryFrontend
  OCWEBSITEFACTORY_FRONTEND_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "OCWebsiteFactory" and .function == "setWebsite(address)")][0].arguments[0]')
  echo "Uploading frontend to OCWebsiteFactoryFrontend ($OCWEBSITEFACTORY_FRONTEND_ADDRESS) ..."

  # EthStorage frontend
  if [ "$TARGET_CHAIN" == "mainnet" ] || [ "$TARGET_CHAIN" == "sepolia" ] || [ "$TARGET_CHAIN" == "holesky" ]; then
    echo "  EthStorage mode..."
    node --env-file=.env scripts/upload-ethstorage-frontend.js \
      $TARGET_CHAIN $OCWEBSITEFACTORY_FRONTEND_ADDRESS \
      $ETHSTORAGE_FILE_ARGS
  # SSTORE2 frontend
  else
    echo "  SSTORE2 mode..."

    FILES_BASE_PATH=frontend-factory/dist/
    COMPRESSED_FILES_BASE_PATH=dist/frontend-factory/

    # ABI encode the file arguments
    SSTORE2_FILE_ARGS_SIG="[${SSTORE2_FILE_ARGS_SIG}]"
    FILE_ARGS=$(cast abi-encode "x((string,string,string,string)[])" "${SSTORE2_FILE_ARGS_SIG}")

    IFRONTEND_LIBRARY_CONTRACT_ADDRESS=$OCWEBSITEFACTORY_FRONTEND_ADDRESS \
    ISTORAGE_BACKEND_LIBRARY_CONTRACT_ADDRESS=$OCWEBSITEFACTORY_ADDRESS \
    FILE_ARGS=$FILE_ARGS \
    COMPRESSED_FILES_BASE_PATH=$COMPRESSED_FILES_BASE_PATH \
    TARGET_CHAIN=$TARGET_CHAIN \
    DOMAIN=$DOMAIN \
    forge script UploadSstore2Frontend --private-key ${PRIVKEY} --rpc-url ${RPC_URL}  $FORGE_SCRIPT_OPTIONS
  fi
fi


# # Section frontend-website: Upload the blog frontend
# if [ "$SECTION" == "all" ] || [ "$SECTION" == "frontend-website" ]; then

#   # Build blog
#   echo "Building blog frontend..."
#   npm run build-blog

#   # Compressing output
#   echo ""
#   echo "Compressing blog frontend..."
#   mkdir -p dist/frontend-website/assets

#   # For each file in frontend-website/dist (except blogAddress.json), compress it, and
#   # add it to a list to be given to the SSTORE2 or EthStorage contract
#   SSTORE2_FILE_ARGS_SIG=""
#   ETHSTORAGE_FILE_ARGS=""
#   for FULL_FILE in $(find frontend-website/dist -type f | grep -v "blogAddress.json"); do
#     # Remove the frontend-website/dist/ prefix
#     FILE=$(echo $FULL_FILE | sed "s|frontend-website/dist/||")
#     # If the file starts with "assets/", then remove it from file
#     SUBFOLDER=$(echo $FILE | grep -o "assets/" || true)
#     if [ ! -z "$SUBFOLDER" ]; then
#       FILE=$(echo $FILE | sed "s|assets/||")
#     fi
#     # Prepare the final compressed file name
#     COMPRESSED_FILE_NAME=${DOMAIN}-blog-${TIMESTAMP}-${FILE}.gz
    
#     # Compress the file
#     gzip -c $FULL_FILE > dist/frontend-website/${SUBFOLDER}/${COMPRESSED_FILE_NAME}

#     # For SSTORE2 (we will ABI-encode it)
#     SSTORE2_FILE_ARGS_SIG="${SSTORE2_FILE_ARGS_SIG}(${FILE},${COMPRESSED_FILE_NAME},$(get_file_mime_type $FULL_FILE),${SUBFOLDER:-''}),"
#     # For Ethstorage
#     ETHSTORAGE_FILE_ARGS="${ETHSTORAGE_FILE_ARGS} ${SUBFOLDER}${FILE}:dist/frontend-website/${SUBFOLDER}${COMPRESSED_FILE_NAME}"
#   done

#   # Fetch the address of the OCWebsiteFrontendLibrary
#   OCWEBSITEFRONTEND_LIBRARY_ADDRESS=$(cat contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "OCWebsiteFrontendLibrary")][0].contractAddress')
#   # Do the uploading
#   echo ""
#   echo "Uploading frontend to OCWebsiteFrontendLibrary ($OCWEBSITEFRONTEND_LIBRARY_ADDRESS) ..."


#   # EthStorage frontend
#   if [ "$TARGET_CHAIN" == "mainnet" ] || [ "$TARGET_CHAIN" == "sepolia" ] || [ "$TARGET_CHAIN" == "holesky" ]; then
#     echo "  EthStorage mode..."
#     node --env-file=.env scripts/upload-ethstorage-frontend.js \
#       $TARGET_CHAIN $OCWEBSITEFRONTEND_LIBRARY_ADDRESS \
#       $ETHSTORAGE_FILE_ARGS
#   # SSTORE2 frontend
#   else
#     echo "  SSTORE2 mode..."

#     FILES_BASE_PATH=frontend-website/dist/
#     COMPRESSED_FILES_BASE_PATH=dist/frontend-website/

#     # ABI encode the file arguments
#     SSTORE2_FILE_ARGS_SIG="[${SSTORE2_FILE_ARGS_SIG}]"
#     FILE_ARGS=$(cast abi-encode "x((string,string,string,string)[])" "${SSTORE2_FILE_ARGS_SIG}")

#     IFRONTEND_LIBRARY_CONTRACT_ADDRESS=$OCWEBSITEFRONTEND_LIBRARY_ADDRESS \
#     FILE_ARGS=$FILE_ARGS \
#     COMPRESSED_FILES_BASE_PATH=$COMPRESSED_FILES_BASE_PATH \
#     TARGET_CHAIN=$TARGET_CHAIN \
#     DOMAIN=$DOMAIN \
#     forge script UploadSstore2Frontend --private-key ${PRIVKEY} --rpc-url ${RPC_URL}  $FORGE_SCRIPT_OPTIONS
#   fi
# fi