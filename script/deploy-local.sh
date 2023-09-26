#!/usr/bin/env bash
set -e

CHAIN_ID=31337
DEPLOYER_KEY=$1
DEPLOYMENT_SCRIPTS=("01_deployToken.s.sol" "02_deployPerpetualMint.s.sol")
LOCALHOST="http://localhost:8545"

# Check if DEPLOYER_KEY is set
if [[ -z $DEPLOYER_KEY ]]; then
  echo -e "Error: DEPLOYER_KEY is not set in .env.\n"
  exit 1
fi

# Get DEPLOYER_ADDRESS
DEPLOYER_ADDRESS=$(cast wallet address $DEPLOYER_KEY)
echo -e "Deployer Address: $DEPLOYER_ADDRESS\n"

# Start anvil and wait for 1 second
make start-anvil
sleep 1

# Set balance using curl
curl -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"anvil_setBalance\",\"params\":[\"$DEPLOYER_ADDRESS\", \"0x056BC75E2D63100000\"]}" $LOCALHOST > /dev/null 2>&1
echo -e "Deployer balance set to 100 ETH.\n"

# Run forge scripts
forge script script/${DEPLOYMENT_SCRIPTS[0]} --rpc-url $LOCALHOST --broadcast
forge script script/${DEPLOYMENT_SCRIPTS[1]} --rpc-url $LOCALHOST --broadcast

# Read and output deployed contract data using Node.js
node script/process-deployment.js ./broadcast/${DEPLOYMENT_SCRIPTS[0]}/$CHAIN_ID/run-latest.json
node script/process-deployment.js ./broadcast/${DEPLOYMENT_SCRIPTS[1]}/$CHAIN_ID/run-latest.json

echo -e "\nDeployer Address: $DEPLOYER_ADDRESS\n"
