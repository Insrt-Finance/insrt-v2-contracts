#!/usr/bin/env bash
set -e

CHAIN_ID=421613
CONFIGURATION_SCRIPT="04_configureVRFSubscription.s.sol"
RPC_URL=$ARBITRUM_GOERLI_RPC_URL
export LINK_FUND_AMOUNT=20 # 20 LINK
export LINK_TOKEN="0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28"

# Check if DEPLOYER_KEY is set
if [[ -z $DEPLOYER_KEY ]]; then
  echo -e "Error: DEPLOYER_KEY is not set in .env.\n"
  exit 1
fi

# Get DEPLOYER_ADDRESS
DEPLOYER_ADDRESS=$(cast wallet address $DEPLOYER_KEY)
echo -e "Deployer Address: $DEPLOYER_ADDRESS\n"

# Convert LINK subscription fund amount to "Link-Wei"
LINK_FUND_AMOUNT_WEI=$(cast to-wei $LINK_FUND_AMOUNT)

# Get current LINK balance as bytes32 hex
DEPLOYER_BALANCE_LINK_HEX=$(cast call $LINK_TOKEN "balanceOf(address)" $DEPLOYER_ADDRESS --rpc-url $RPC_URL)

# Convert LINK balance from bytes32 hex to "Link-Wei"
DEPLOYER_BALANCE_LINK_WEI=$(cast to-dec $DEPLOYER_BALANCE_LINK_HEX)

# Convert LINK balance from "Link-Wei" to LINK base unit
DEPLOYER_BALANCE_LINK_DEC=$(cast from-wei $DEPLOYER_BALANCE_LINK_WEI)

if [ $(echo "$DEPLOYER_BALANCE_LINK_WEI < $LINK_FUND_AMOUNT_WEI" | bc -l) -eq 1 ]; then
  echo -e "Error: Deployer LINK balance is $DEPLOYER_BALANCE_LINK_DEC LINK, which is less than the specified LINK amount to fund the Chainlink VRF Subscription ($LINK_FUND_AMOUNT LINK).\n"
  exit 1
fi

echo -e "Deployer LINK balance is $DEPLOYER_BALANCE_LINK_DEC LINK.\n"

# Create broadcast directories for storing configuration data
mkdir -p ./broadcast/${CONFIGURATION_SCRIPT}/$CHAIN_ID

# Run forge scripts
forge script script/${CONFIGURATION_SCRIPT} --rpc-url $RPC_URL --broadcast
