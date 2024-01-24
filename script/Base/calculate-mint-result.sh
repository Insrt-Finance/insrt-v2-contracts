#!/usr/bin/env bash
set -e

CALCULATION_SCRIPT="01_calculateMintResult.s.sol"
CHAIN_ID=8453
RPC_URL=$BASE_PRC_URL
export COLLECTION_ADDRESS=$1
export CORE_ADDRESS="0x0000000000000000000000000000000000000000"
export NUMBER_OF_MINTS=$2
export RANDOMNESS="$3,$4"
export PRICE_PER_MINT=$5

# Run forge scripts
forge script script/Supra/${CALCULATION_SCRIPT} --rpc-url $RPC_URL
