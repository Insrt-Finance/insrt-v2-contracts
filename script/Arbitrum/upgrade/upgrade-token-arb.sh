#!/usr/bin/env bash
set -e

CHAIN_ID=42161
RPC_URL=$ARBITRUM_RPC_URL
UPGRADE_SCRIPT="01_upgradeToken.s.sol"
VERIFIER_URL="https://api.arbiscan.io/api"
export CHAIN="arbitrum_one"
export TOKEN_PROXY_ADDRESS="0xEf97C7394F71851880A7868D21df3A9dF24FAfC7"
export GNOSIS_SAFE="0x536935E002b88412aC4e05Eb23a07272e7BdB033"
export PRIVATE_KEY=$DEPLOYER_KEY
export WALLET_TYPE="local"

# Check if ARBISCAN_API_KEY is set
if [[ -z $ARBISCAN_API_KEY ]]; then
  echo -e "Error: ARBISCAN_API_KEY is not set in .env.\n"
  exit 1
fi

# Check if ARBITRUM_RPC_URL is set
if [[ -z $ARBITRUM_RPC_URL ]]; then
  echo -e "Error: ARBITRUM_RPC_URL is not set in .env.\n"
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
forge script script/Arbitrum/upgrade/${UPGRADE_SCRIPT} --rpc-url $RPC_URL --verify --broadcast --verifier-url $VERIFIER_URL --ffi --sender $DEPLOYER_ADDRESS --legacy

echo -e "\nDeployer Address: $DEPLOYER_ADDRESS\n"
