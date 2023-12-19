#!/usr/bin/env bash
set -e

CHAIN_ID=421614
RPC_URL=$ARBITRUM_SEPOLIA_RPC_URL
UPGRADE_SCRIPT="02_upgradePerpetualMintViewEOA.s.sol"
VERIFIER_URL="https://api-sepolia.arbiscan.io/api"
export CORE_ADDRESS="0x97f936edd3a5841e87ef7284d1440b2136f1cd69"
export VRF_COORDINATOR="0x50d47e4142598E3411aA864e08a44284e471AC6f"

# Check if ARBISCAN_API_KEY is set
if [[ -z $ARBISCAN_API_KEY ]]; then
  echo -e "Error: ARBISCAN_API_KEY is not set in .env.\n"
  exit 1
fi

# Check if ARBITRUM_SEPOLIA_RPC_URL is set
if [[ -z $ARBITRUM_SEPOLIA_RPC_URL ]]; then
  echo -e "Error: ARBITRUM_SEPOLIA_RPC_URL is not set in .env.\n"
  exit 1
fi

# Check if DEPLOYER_KEY is set
if [[ -z $DEPLOYER_KEY ]]; then
  echo -e "Error: DEPLOYER_KEY is not set in .env.\n"
  exit 1
fi

# Get DEPLOYER_ADDRESS
DEPLOYER_ADDRESS=$(cast wallet address $DEPLOYER_KEY)
echo -e "Deployer Address: $DEPLOYER_ADDRESS\n"

# Get ETH balance in Wei
DEPLOYER_BALANCE_DEC=$(cast balance $DEPLOYER_ADDRESS --rpc-url $RPC_URL)

# Convert from Wei to Ether
DEPLOYER_BALANCE_ETH=$(cast from-wei $DEPLOYER_BALANCE_DEC)
echo -e "Deployer address balance is $DEPLOYER_BALANCE_ETH ETH.\n"

# Run forge scripts
forge script script/Arbitrum/upgrade/${UPGRADE_SCRIPT} --rpc-url $RPC_URL --verify --broadcast --verifier-url $VERIFIER_URL

echo -e "\nDeployer Address: $DEPLOYER_ADDRESS\n"
