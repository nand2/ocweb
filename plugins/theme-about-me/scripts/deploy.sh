#! /bin/bash

set -euo pipefail

# Cd to the folder of the script
cd $(dirname $(readlink -f $0))

# We need private key, RPC URL and chain id
PRIVKEY=${PRIVKEY:-}
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


# Go to the plugin root folder
cd ..
# Go to the admin frontend folder
cd admin

# Build the admin frontend
npm run build

# Create an OCWebsite


# 2 modes
# Deploy new
# Deploy update

# Build vitejs files
# mint ocwebsite (optional)
# Upload files

# Compile and deploy plugin with forge

# Set the site to the plugin
