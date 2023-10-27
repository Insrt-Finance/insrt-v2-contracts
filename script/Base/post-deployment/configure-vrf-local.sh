#!/usr/bin/env bash
set -e

CHAIN_ID=31337
CONFIGURATION_SCRIPT="01_configureVRFSubscription.s.sol"
LOCALHOST="http://localhost:8545"
SUPRA_DEPOSIT_CONTRACT=0xAf2eE23d1Ff837A02D4D58c07a97561F5709fCb2
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
DEPLOYER_CURRENT_BALANCE_WEI=$(cast balance $DEPLOYER_ADDRESS)

# Sum ETH_FUND_AMOUNT_WEI and DEPLOYER_CURRENT_BALANCE_WEI to get NEW_DEPLOYER_BALANCE_WEI
NEW_DEPLOYER_BALANCE_WEI=$(bc <<< "$ETH_FUND_AMOUNT_WEI + $DEPLOYER_CURRENT_BALANCE_WEI")

# Convert decimal to bytes32 hex
NEW_DEPLOYER_BALANCE_HEX=$(cast to-uint256 $NEW_DEPLOYER_BALANCE_WEI)

# Set ETH balance using curl
curl -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"anvil_setBalance\",\"params\":[\"$DEPLOYER_ADDRESS\", \"$NEW_DEPLOYER_BALANCE_HEX\"]}" $LOCALHOST  > /dev/null 2>&1

echo -e "Deployer ETH balance set to $(cast from-wei $NEW_DEPLOYER_BALANCE_WEI) ETH.\n"

# Get Supra Deposit Contract Owner
SUPRA_DEPOSIT_CONTRACT_OWNER=$(cast call $SUPRA_DEPOSIT_CONTRACT "owner()(address)" --rpc-url $LOCALHOST)

# Add DEPLOYER_ADDRESS to Supra Deposit Contract whitelist
curl -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_sendUnsignedTransaction\",\"params\":[{\"to\": \"$SUPRA_DEPOSIT_CONTRACT\", \"from\": \"$SUPRA_DEPOSIT_CONTRACT_OWNER\", \"data\": \"0x08b35dd400000000000000000000000062dbcbe89327eb3ffae35130ae5233385ba25b690000000000000000000000000000000000000000000000000000000000000001\"}]}" $LOCALHOST > /dev/null 2>&1

# Create broadcast directories for storing configuration data
mkdir -p ./broadcast/${CONFIGURATION_SCRIPT}/$CHAIN_ID

# Run forge scripts
forge script script/Base/post-deployment/${CONFIGURATION_SCRIPT} --rpc-url $LOCALHOST --broadcast
