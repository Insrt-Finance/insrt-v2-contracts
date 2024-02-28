#!/usr/bin/env bash
set -e

CHAIN_ID=81457 # TODO: UPDATE WHEN BLAST MAINNET IS LIVE
CONFIGURATION_SCRIPT="01_configureToken.s.sol"
RPC_URL=$BLAST_RPC_URL
export NEW_TOKEN_PROXY_OWNER="0x0000000000000000000000000000000000000000"
export TOKEN_DISTRIBUTION_FRACTION_BP=100000000 # 1e7, 10%

# Check if DEPLOYER_KEY is set
if [[ -z $DEPLOYER_KEY ]]; then
  echo -e "Error: DEPLOYER_KEY is not set in .env.\n"
  exit 1
fi

# Get DEPLOYER_ADDRESS
DEPLOYER_ADDRESS=$(cast wallet address $DEPLOYER_KEY)
echo -e "Deployer Address: $DEPLOYER_ADDRESS\n"

# Create broadcast directories for storing configuration data
mkdir -p ./broadcast/${CONFIGURATION_SCRIPT}/$CHAIN_ID

# Run forge scripts
forge script script/Blast/post-deployment/${CONFIGURATION_SCRIPT} --rpc-url $RPC_URL --broadcast
