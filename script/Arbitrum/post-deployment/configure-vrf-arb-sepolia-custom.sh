#!/usr/bin/env bash
set -e

CHAIN_ID=421614
CONFIGURATION_SCRIPT="01_configureInsrtVRFSubscription.s.sol"
RPC_URL=$ARBITRUM_SEPOLIA_RPC_URL
export NEW_VRF_OWNER="0x0000000000000000000000000000000000000000"
export VRF_FULFILLER="0xE952ba4dC956D8d5402cD3CDE9Eeb7B613bf838C"

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
forge script script/common/post-deployment/${CONFIGURATION_SCRIPT} --rpc-url $RPC_URL --broadcast
