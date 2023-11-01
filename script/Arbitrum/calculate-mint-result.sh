#!/usr/bin/env bash
set -e

CALCULATION_SCRIPT="01_calculateMintResult.s.sol"
CHAIN_ID=42161
RPC_URL=$ARBITRUM_RPC_URL
export COLLECTION_ADDRESS=$1
export CORE_ADDRESS="0x791b648aa3bd21964417690c635040f40ce974a5"
export NUMBER_OF_MINTS=$2
export RANDOMNESS=$3

# Run forge scripts
forge script script/Arbitrum/${CALCULATION_SCRIPT} --rpc-url $RPC_URL
