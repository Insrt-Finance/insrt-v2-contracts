#!/usr/bin/env bash
set -e

CHAIN_ID=81457
RPC_URL=$BLAST_RPC_URL
UPGRADE_SCRIPT="01_upgradeAndRemovePerpetualMintSupraBlast.s.sol"
VERIFIER_URL="https://api.blastscan.io/api"
export CHAIN="blast"
export CORE_BLAST_ADDRESS="0x8113E6335ddf1E6227113B429CD1F57e8E007760"
export GNOSIS_SAFE="0xA5200F89aDB961B9D6d92DA2D0D45Ba9a0976F90"
export PRIVATE_KEY=$DEPLOYER_KEY
export VRF_ROUTER="0x82A515c2BEC5C4be8aBBbF0D2F59C19A4547709c"
export WALLET_TYPE="local"

# Check if BLASTSCAN_API_KEY is set
if [[ -z $BLASTSCAN_API_KEY ]]; then
  echo -e "Error: BLASTSCAN_API_KEY is not set in .env.\n"
  exit 1
fi

# Check if BLAST_RPC_URL is set
if [[ -z $BLAST_RPC_URL ]]; then
  echo -e "Error: BLAST_RPC_URL is not set in .env.\n"
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
forge script script/Blast/upgrade/${UPGRADE_SCRIPT} --rpc-url $RPC_URL --verify --broadcast --verifier-url $VERIFIER_URL --ffi --sender $DEPLOYER_ADDRESS --legacy

echo -e "\nDeployer Address: $DEPLOYER_ADDRESS\n"
