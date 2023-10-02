#!/usr/bin/env bash
set -e

CHAIN_ID=421613
CONFIGURATION_SCRIPT="05_configurePerpetualMint.s.sol"
RPC_URL=$ARBITRUM_GOERLI_RPC_URL
export COLLECTION_PRICE_TO_MINT_RATIO_BP=1000 # 1e7, 0.0001%
export CONSOLATION_FEE_BP=5000000 # 1e7, 0.5%
export MINT_FEE_BP=5000000 # 1e7, 0.5
export REDEMPTION_FEE_BP=10000000 # 1e7, 1%
export TIER_MULTIPLIERS="1,2,4,8,16" # 1x, 2x, 4x, 8x, 16x
export TIER_RISKS="600000000,250000000,100000000,40000000,10000000" # 60%, 25%, 10%, 4%, 1% (1e7)
export VRF_KEY_HASH="0x83d1b6e3388bed3d76426974512bb0d270e9542a765cd667242ea26c0cc0b730"

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
forge script script/${CONFIGURATION_SCRIPT} --rpc-url $RPC_URL --broadcast
