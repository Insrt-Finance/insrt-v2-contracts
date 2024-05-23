#!/usr/bin/env bash
set -e

CALCULATION_SCRIPT="01_calculateMintResult.s.sol"
CHAIN_ID=81457
RPC_URL=$BLAST_RPC_URL
export COLLECTION_ADDRESS=$1
export CORE_BLAST_ADDRESS="0x8113e6335ddf1e6227113b429cd1f57e8e007760"
export NUMBER_OF_MINTS=$2
export RANDOMNESS="$3,$4"
export PRICE_PER_MINT=$5
export PRIZE_VALUE_IN_WEI=$6
export REFERRAL_MINT=$7
export RISK_REWARD_RATIO=$8

# Run forge scripts
forge script script/Blast/${CALCULATION_SCRIPT} --rpc-url $RPC_URL
