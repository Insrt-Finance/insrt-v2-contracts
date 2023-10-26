#!/usr/bin/env bash
set -e

CHAIN_ID=31337
DEPLOYER_BALANCE=100 # 100 ETH
DEPLOYMENT_SCRIPTS=("01_deployToken.s.sol" "01_deployPerpetualMint.s.sol")
export FORK_URL=$BASE_RPC_URL
LOCALHOST="http://localhost:8545"
export VRF_ROUTER="0x73970504Df8290E9A508676a0fbd1B7f4Bcb7f5a"

# Check if BASE_RPC_URL is set
if [[ -z $BASE_RPC_URL ]]; then
  echo -e "Error: BASE_RPC_URL is being used to fork and deploy locally and is not set in .env.\n"
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

# Start anvil and wait for 2 seconds
make start-anvil
sleep 2

# Convert Ether to Wei
DEPLOYER_BALANCE_WEI=$(cast to-wei $DEPLOYER_BALANCE)

# Convert decimal to hex
DEPLOYER_BALANCE_HEX=$(cast to-hex $DEPLOYER_BALANCE_WEI)

# Set balance using curl
curl -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"anvil_setBalance\",\"params\":[\"$DEPLOYER_ADDRESS\", \"$DEPLOYER_BALANCE_HEX\"]}" $LOCALHOST > /dev/null 2>&1

echo -e "Deployer balance set to $DEPLOYER_BALANCE ETH.\n"

# Create broadcast directories for storing deployment data
mkdir -p ./broadcast/${DEPLOYMENT_SCRIPTS[0]}/$CHAIN_ID
mkdir -p ./broadcast/${DEPLOYMENT_SCRIPTS[1]}/$CHAIN_ID

# Run forge scripts
forge script script/common/deployment/${DEPLOYMENT_SCRIPTS[0]} --rpc-url $LOCALHOST --broadcast
forge script script/Base/deployment/${DEPLOYMENT_SCRIPTS[1]} --rpc-url $LOCALHOST --broadcast

# Read and output deployed contract data using Node.js
node script/common/deployment/process-deployment.js ./broadcast/${DEPLOYMENT_SCRIPTS[0]}/$CHAIN_ID/run-latest.json
node script/common/deployment/process-deployment.js ./broadcast/${DEPLOYMENT_SCRIPTS[1]}/$CHAIN_ID/run-latest.json

echo -e "\nDeployer Address: $DEPLOYER_ADDRESS\n"
