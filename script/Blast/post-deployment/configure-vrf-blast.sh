#!/usr/bin/env bash
set -e

CHAIN_ID=168587773 # TODO: UPDATE WHEN BLAST MAINNET IS LIVE
CONFIGURATION_SCRIPT="02_configureVRFSubscription.s.sol"
RPC_URL=$BLAST_RPC_URL
export ETH_FUND_AMOUNT=20 # 20 ETH

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

# Get current ETH balance in Wei
DEPLOYER_CURRENT_BALANCE_WEI=$(cast balance $DEPLOYER_ADDRESS --rpc-url $RPC_URL)

# Convert ETH balance from Wei to ETH base unit
DEPLOYER_BALANCE_ETH_DEC=$(cast from-wei $DEPLOYER_CURRENT_BALANCE_WEI)

if [ $(echo "$DEPLOYER_CURRENT_BALANCE_WEI < $ETH_FUND_AMOUNT_WEI" | bc -l) -eq 1 ]; then
  echo -e "Error: Deployer ETH balance is $DEPLOYER_BALANCE_ETH_DEC ETH, which is less than the specified ETH amount to fund the Supra VRF Subscription ($ETH_FUND_AMOUNT ETH).\n"
  exit 1
fi

echo -e "Deployer ETH balance is $DEPLOYER_BALANCE_ETH_DEC ETH.\n"

# Create broadcast directories for storing configuration data
mkdir -p ./broadcast/${CONFIGURATION_SCRIPT}/$CHAIN_ID

# Run forge scripts
forge script script/Blast/post-deployment/${CONFIGURATION_SCRIPT} --rpc-url $RPC_URL --broadcast
