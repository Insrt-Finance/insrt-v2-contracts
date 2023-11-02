#!/usr/bin/env bash
set -e

CHAIN_ID=8453
CONFIGURATION_SCRIPT="01_configureVRFSubscription.s.sol"
RPC_URL=$BASE_RPC_URL
export CHAIN="base"
export GNOSIS_SAFE="0x0000000000000000000000000000000000000000"
export ETH_FUND_AMOUNT=20 # 20 ETH
export PRIVATE_KEY=$DEPLOYER_KEY
export WALLET_TYPE="local"

# Check if DEPLOYER_KEY is set
if [[ -z $DEPLOYER_KEY ]]; then
  echo -e "Error: DEPLOYER_KEY is not set in .env.\n"
  exit 1
fi

# Get DEPLOYER_ADDRESS
DEPLOYER_ADDRESS=$(cast wallet address $DEPLOYER_KEY)
echo -e "Deployer Address: $DEPLOYER_ADDRESS\n"

# Convert ETH_FUND_AMOUNT to Wei
ETH_FUND_AMOUNT_WEI=$(cast to-wei $ETH_FUND_AMOUNT)

# Get current Gnosis Safe ETH balance in Wei
GNOSIS_SAFE_CURRENT_BALANCE_WEI=$(cast balance $GNOSIS_SAFE)

# Convert ETH balance from Wei to ETH base unit
GNOSIS_SAFE_BALANCE_ETH_DEC=$(cast from-wei $GNOSIS_SAFE_CURRENT_BALANCE_WEI)

if [ $(echo "$GNOSIS_SAFE_CURRENT_BALANCE_WEI < $ETH_FUND_AMOUNT_WEI" | bc -l) -eq 1 ]; then
  echo -e "Error: Gnosis Safe ETH balance is $GNOSIS_SAFE_BALANCE_ETH_DEC ETH, which is less than the specified ETH amount to fund the Supra VRF Subscription ($ETH_FUND_AMOUNT ETH).\n"
  exit 1
fi

echo -e "Gnosis Safe ETH balance is $GNOSIS_SAFE_BALANCE_ETH_DEC ETH.\n"

# Create broadcast directories for storing configuration data
mkdir -p ./broadcast/${CONFIGURATION_SCRIPT}/$CHAIN_ID

# Run forge scripts
forge script script/Base/post-deployment/${CONFIGURATION_SCRIPT} --rpc-url $RPC_URL --broadcast --ffi --sender $DEPLOYER_ADDRESS
