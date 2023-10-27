#!/usr/bin/env bash
set -e

CHAIN_ID=42161
CONFIGURATION_SCRIPT="02_configurePerpetualMint.s.sol"
RPC_URL=$ARBITRUM_RPC_URL
export CONSOLATION_FEE_BP=850000000 # 1e7, 85%
export MINT_FEE_BP=50000000 # 1e7, 5%
export NEW_PERP_MINT_OWNER="0x536935E002b88412aC4e05Eb23a07272e7BdB033"
export REDEMPTION_FEE_BP=50000000 # 1e7, 5%
export TIER_MULTIPLIERS="200000000,350000000,950000000,1750000000,10000000000" # 0.2x, 0.35x, .95x, 1.75x, 10x (1e9)
export TIER_RISKS="500000000,330000000,125000000,40000000,5000000" # 50%, 33%, 12.5%, 4%, 0.5% (1e7)
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
forge script script/Arbitrum/post-deployment/${CONFIGURATION_SCRIPT} --rpc-url $RPC_URL --broadcast
