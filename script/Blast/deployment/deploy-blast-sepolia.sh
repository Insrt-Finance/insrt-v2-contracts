#!/usr/bin/env bash
set -e

CHAIN_ID=168587773
DEPLOYMENT_SCRIPTS=("01_deployToken.s.sol" "02_deployPerpetualMint.s.sol")
RPC_URL=$BLAST_SEPOLIA_RPC_URL
VERIFIER_URL="https://api.routescan.io/v2/network/testnet/evm/168587773/etherscan"
export CORE_BLAST="0x0000000000000000000000000000000000000000"
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

# Create broadcast directories for storing deployment data
mkdir -p ./broadcast/${DEPLOYMENT_SCRIPTS[0]}/$CHAIN_ID
mkdir -p ./broadcast/${DEPLOYMENT_SCRIPTS[1]}/$CHAIN_ID

# Run first forge script to deploy token, specify custom deployment
forge script script/Blast/deployment/${DEPLOYMENT_SCRIPTS[0]} --chain $CHAIN_ID --rpc-url $RPC_URL --verify --broadcast --verifier-url $VERIFIER_URL

forge create contracts/diamonds/Core/Blast/Core.sol:CoreBlast --constructor-args-path ./broadcast/01_deployToken.s.sol/${CHAIN_ID}/run-latest-token-proxy-info.txt --chain $CHAIN_ID --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --private-key $DEPLOYER_KEY

# Run second forge script to deploy & diamondCut perpetual mint
forge script script/Blast/deployment/${DEPLOYMENT_SCRIPTS[1]} --chain $CHAIN_ID --rpc-url $RPC_URL --verify --broadcast --verifier-url $VERIFIER_URL

# Read and output deployed contract data using Node.js
node script/common/deployment/process-deployment.js ./broadcast/${DEPLOYMENT_SCRIPTS[0]}/$CHAIN_ID/run-latest.json
node script/common/deployment/process-deployment.js ./broadcast/${DEPLOYMENT_SCRIPTS[1]}/$CHAIN_ID/run-latest.json

echo -e "\nDeployer Address: $DEPLOYER_ADDRESS\n"
