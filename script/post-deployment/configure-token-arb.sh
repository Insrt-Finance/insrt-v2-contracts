#!/usr/bin/env bash
set -e

CHAIN_ID=42161
CONFIGURATION_SCRIPT="01_configureToken.s.sol"
RPC_URL=$ARBITRUM_RPC_URL
export NEW_TOKEN_PROXY_OWNER="0x536935E002b88412aC4e05Eb23a07272e7BdB033"
export TOKEN_DISTRIBUTION_FRACTION_BP=10000000 # 1e7, 1%

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
forge script script/post-deployment/${CONFIGURATION_SCRIPT} --rpc-url $RPC_URL --broadcast
