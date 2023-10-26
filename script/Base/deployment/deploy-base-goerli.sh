#!/usr/bin/env bash
set -e

CHAIN_ID=84531
DEPLOYMENT_SCRIPTS=("01_deployToken.s.sol" "01_deployPerpetualMint.s.sol")
RPC_URL=$BASE_GOERLI_RPC_URL
VERIFIER_URL="https://api-goerli.basescan.org/api"
export VRF_ROUTER="0xe01754DEB54c4915D65331Fa31ebf9111CacF9C2"

# Check if BASESCAN_API_KEY is set
if [[ -z $BASESCAN_API_KEY ]]; then
  echo -e "Error: BASESCAN_API_KEY is not set in .env.\n"
  exit 1
fi

# Check if BASE_GOERLI_RPC_URL is set
if [[ -z $BASE_GOERLI_RPC_URL ]]; then
  echo -e "Error: BASE_GOERLI_RPC_URL is not set in .env.\n"
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

# Run forge scripts
forge script script/common/deployment/${DEPLOYMENT_SCRIPTS[0]} --rpc-url $RPC_URL --verify --broadcast --verifier-url $VERIFIER_URL
forge script script/Base/deployment/${DEPLOYMENT_SCRIPTS[1]} --rpc-url $RPC_URL --verify --broadcast --verifier-url $VERIFIER_URL

# Read and output deployed contract data using Node.js
node script/common/deployment/process-deployment.js ./broadcast/${DEPLOYMENT_SCRIPTS[0]}/$CHAIN_ID/run-latest.json
node script/common/deployment/process-deployment.js ./broadcast/${DEPLOYMENT_SCRIPTS[1]}/$CHAIN_ID/run-latest.json

echo -e "\nDeployer Address: $DEPLOYER_ADDRESS\n"
