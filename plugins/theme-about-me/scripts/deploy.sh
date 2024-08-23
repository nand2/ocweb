#! /bin/bash

set -euo pipefail

# We need private key, RPC URL and chain id
PRIVKEY=${PRIVKEY:-}
OCWEBSITE_FACTORY_ADDRESS=${OCWEBSITE_FACTORY_ADDRESS:-}
RPC_URL=${RPC_URL:-}
CHAIN_ID=${CHAIN_ID:-}
if [ -z "$PRIVKEY" ]; then
  echo "PRIVKEY env var is not set"
  exit 1
fi
if [ -z "$RPC_URL" ]; then
  echo "RPC_URL env var is not set"
  exit 1
fi
if [ -z "$CHAIN_ID" ]; then
  echo "CHAIN_ID env var is not set"
  exit 1
fi
if [ -z "$OCWEBSITE_FACTORY_ADDRESS" ]; then
  echo "OCWEBSITE_FACTORY_ADDRESS env var is not set"
  exit 1
fi

# Compute the plugin root folder (which is the parent folder of this script)
PLUGIN_ROOT=$(cd $(dirname $(readlink -f $0)) && cd .. && pwd)


#
# Create an OCWebsite
#

exec 5>&1
OUTPUT="$(PRIVATE_KEY=$PRIVKEY \
  ocweb --rpc $RPC_URL --skip-tx-validation mint --factory-address $OCWEBSITE_FACTORY_ADDRESS $CHAIN_ID about-me-them3 | tee >(cat - >&5))"

# Get the address of the OCWebsite
OCWEBSITE_ADDRESS=$(echo "$OUTPUT" | grep -oP 'New OCWebsite smart contract: \K0x\w+')


#
# Build and upload the admin frontend
#

# Go to the admin frontend folder
cd $PLUGIN_ROOT/admin

# Build the admin frontend
npm run build

# Upload the admin frontend
PRIVATE_KEY=$PRIVKEY \
WEB3_ADDRESS=web3://$OCWEBSITE_ADDRESS:$CHAIN_ID \
ocweb --rpc $RPC_URL --skip-tx-validation upload dist/* /admin/


#
# Build and upload the frontend
#

# Go to the frontend folder
cd $PLUGIN_ROOT/frontend

# Build the frontend
npm run build

# Upload the frontend
PRIVATE_KEY=$PRIVKEY \
WEB3_ADDRESS=web3://$OCWEBSITE_ADDRESS:$CHAIN_ID \
ocweb --rpc $RPC_URL --skip-tx-validation upload dist/* /frontend/ --exclude 'dist/pages/*' --exclude 'dist/themes/about-me/*'



# 2 modes
# Deploy new
# Deploy update

# Build vitejs files
# mint ocwebsite (optional)
# Upload files

# Compile and deploy plugin with forge

# Set the site to the plugin
