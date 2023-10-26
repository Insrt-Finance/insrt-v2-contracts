#!/usr/bin/env bash
set -e

CHAIN_ID=31337
CONFIGURATION_SCRIPT="01_configureVRFSubscription.s.sol"
export LINK_FUND_AMOUNT=20 # 20 LINK
export LINK_TOKEN="0xf97f4df75117a78c1A5a0DBb814Af92458539FB4"
export NEW_VRF_OWNER="0x0000000000000000000000000000000000000000"
export VRF_SUBSCRIPTION_BALANCE_THRESHOLD=300 # 300 LINK
LOCALHOST="http://localhost:8545"

# Check if DEPLOYER_KEY is set
if [[ -z $DEPLOYER_KEY ]]; then
  echo -e "Error: DEPLOYER_KEY is not set in .env.\n"
  exit 1
fi

# Get DEPLOYER_ADDRESS
DEPLOYER_ADDRESS=$(cast wallet address $DEPLOYER_KEY)
echo -e "Deployer Address: $DEPLOYER_ADDRESS\n"

# Get the storage index of the _balances(address => uint256) mapping for the deployer
DEPLOYER_LINK_BALANCE_STORAGE_INDEX=$(cast index address $DEPLOYER_ADDRESS 51) # mapping _balances(address => uint256) is at storage index 51

# Convert LINK to "Link-Wei"
DEPLOYER_BALANCE_LINK_WEI=$(cast to-wei $LINK_FUND_AMOUNT)

# Convert decimal to bytes32 hex
DEPLOYER_BALANCE_LINK_HEX=$(cast to-uint256 $DEPLOYER_BALANCE_LINK_WEI)

# Set LINK balance using curl
curl -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"anvil_setStorageAt\",\"params\":[\"$LINK_TOKEN\", \"$DEPLOYER_LINK_BALANCE_STORAGE_INDEX\", \"$DEPLOYER_BALANCE_LINK_HEX\"]}" $LOCALHOST  > /dev/null 2>&1

echo -e "Deployer LINK balance set to $LINK_FUND_AMOUNT LINK.\n"

# Create broadcast directories for storing configuration data
mkdir -p ./broadcast/${CONFIGURATION_SCRIPT}/$CHAIN_ID

# Run forge scripts
forge script script/Arbitrum/post-deployment/${CONFIGURATION_SCRIPT} --rpc-url $LOCALHOST --broadcast
