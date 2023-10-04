#!/usr/bin/env bash
set -e

CHAIN_ID=42161
CONFIGURATION_SCRIPT="05_configurePerpetualMint.s.sol"
RPC_URL=$ARBITRUM_RPC_URL
export CONSOLATION_FEE_BP=850000000 # 1e7, 85%
export MINT_FEE_BP=50000000 # 1e7, 5%
export REDEMPTION_FEE_BP=200000000 # 1e7, 20%
export TIER_MULTIPLIERS="200000000,900000000,1600000000,2200000000,30000000000" # 0.2x, 0.9x, 1.6x, 2.2x, 30x (1e9)
export TIER_RISKS="500000000,250000000,150000000,97500000,2500000" # 50%, 25%, 15%, 9.75%, 0.25% (1e7)
export VRF_KEY_HASH="0x68d24f9a037a649944964c2a1ebd0b2918f4a243d2a99701cc22b548cf2daff0"

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
