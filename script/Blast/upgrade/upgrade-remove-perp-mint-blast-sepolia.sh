#!/usr/bin/env bash
set -e

CHAIN_ID=168587773
RPC_URL=$BLAST_SEPOLIA_RPC_URL
UPGRADE_SCRIPT="01_upgradeAndRemovePerpetualMintSupraBlastEOA.s.sol"
VERIFIER_URL="https://api-sepolia.blastscan.io/api"
export CORE_BLAST_ADDRESS="0x13B78374e752Ca7D6a41DeE2d2f36ceed47499cd"
export VRF_ROUTER="0x2c9e897Ed7d4B1a917046c0d5B0770FE6094A181"

# Check if BLASTSCAN_API_KEY is set
if [[ -z $BLASTSCAN_API_KEY ]]; then
  echo -e "Error: BLASTSCAN_API_KEY is not set in .env.\n"
  exit 1
fi

# Check if BLAST_SEPOLIA_RPC_URL is set
if [[ -z $BLAST_SEPOLIA_RPC_URL ]]; then
  echo -e "Error: BLAST_SEPOLIA_RPC_URL is not set in .env.\n"
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
forge script script/Blast/upgrade/${UPGRADE_SCRIPT} --rpc-url $RPC_URL --verify --broadcast --verifier-url $VERIFIER_URL

echo -e "\nDeployer Address: $DEPLOYER_ADDRESS\n"
