#!/usr/bin/env bash
set -e

ARBISCAN_API_KEY=$3
CHAIN_ID=42161
DEPLOYER_KEY=$1
DEPLOYMENT_SCRIPTS=("01_deployToken.s.sol" "02_deployPerpetualMint.s.sol")
RPC_URL=$2
VERIFIER_URL="https://api.arbiscan.io/api"

# Check if ARBISCAN_API_KEY is set
if [[ -z $ARBISCAN_API_KEY ]]; then
  echo -e "Error: ARBISCAN_API_KEY is not set in .env.\n"
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

# Check balance using curl
DEPLOYER_BALANCE_JSON=$(curl -s -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_getBalance\",\"params\":[\"$DEPLOYER_ADDRESS\", \"latest\"]}" $RPC_URL)

DEPLOYER_BALANCE_HEX=$(echo $DEPLOYER_BALANCE_JSON | node -e "let data = ''; process.stdin.on('data', chunk => { data += chunk; }); process.stdin.on('end', () => { let json = JSON.parse(data); console.log(json.result); });")

# Convert hex to decimal
DEPLOYER_BALANCE_DEC=$((16#${DEPLOYER_BALANCE_HEX#*x}))

# Convert from Wei to Ether
DEPLOYER_BALANCE_ETH=$(echo "scale=18; $DEPLOYER_BALANCE_DEC / 1000000000000000000" | bc)
echo -e "Deployer address balance is $DEPLOYER_BALANCE_ETH ETH.\n"

# Run forge scripts
forge script script/${DEPLOYMENT_SCRIPTS[0]} --rpc-url $RPC_URL --verify --broadcast --verifier-url $VERIFIER_URL
forge script script/${DEPLOYMENT_SCRIPTS[1]} --rpc-url $RPC_URL --verify --broadcast --verifier-url $VERIFIER_URL

# Read and output deployed contract data using Node.js
node script/process-deployment.js ./broadcast/${DEPLOYMENT_SCRIPTS[0]}/$CHAIN_ID/run-latest.json
node script/process-deployment.js ./broadcast/${DEPLOYMENT_SCRIPTS[1]}/$CHAIN_ID/run-latest.json

echo -e "\nDeployer Address: $DEPLOYER_ADDRESS\n"
