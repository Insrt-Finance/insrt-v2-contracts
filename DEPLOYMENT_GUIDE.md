# Insrt V2 Deployment Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Environment Variables](#environment-variables)
4. [Local Development](#local-development)
5. [Deployment Overview](#deployment-overview)
6. [Deployment Steps](#deployment-steps)
7. [Post-Deployment Configuration](#post-deployment-configuration)

---

## Introduction

This guide outlines the steps to deploy & configure the Insrt V2 protocol.

---

## Prerequisites

- **Foundry**: Make sure Foundry is installed. [Installation guide](https://getfoundry.sh/).
- **NodeJS**: Required version \>= v18.16.0. [Download NodeJS](https://nodejs.org/en/).

---

## Environment Variables

### Common to All Deployments

- `DEPLOYER_KEY`: Private key of the deployer account

### Arbitrum Deployments

- `ARBITRUM_RPC_URL`: Arbitrum RPC URL
- `ARBISCAN_API_KEY`: Arbiscan API key for contract verification

### Arbitrum Sepolia Deployments

- `ARBITRUM_SEPOLIA_RPC_URL`: Arbitrum Sepolia RPC URL
- `ARBISCAN_API_KEY`: Arbiscan API key for contract verification

### Base Deployments

- `BASE_RPC_URL`: Base RPC URL
- `BASESCAN_API_KEY`: Basescan API key for contract verification

### Base Goerli Deployments

- `BASE_GOERLI_RPC_URL`: Base Goerli RPC URL
- `BASESCAN_API_KEY`: Basescan API key for contract verification

### Localhost Deployments (Arbitrum Fork)

- `ARBITRUM_RPC_URL`: Arbitrum RPC URL for forking the initial local state

### Localhost Deployments (Base Fork)

- `BASE_RPC_URL`: Base RPC URL for forking the initial local state

---

## Local Development

### Step 1: Install Dependencies

```bash
make install
```

### Step 2: Compilation

```bash
make build
```

### Step 3: Testing

```bash
make test
```

---

## Deployment Overview

We provide deployment scripts for the following networks:

1. **Arbitrum**
2. **Arbitrum Sepolia (Testnet)**
3. **Base**
4. **Base Goerli (Testnet)**
5. **Localhost (Arbitrum Fork)**
6. **Localhost (Base Fork)**

---

## Deployment Steps

Here is how to deploy on each of these networks.

### Bash Environment Variables

These are set in each of the deployment bash scripts.

Double-check that they are correct before running the deployment script.

#### Arbitrum

```bash
export VRF_COORDINATOR="0x..." # Address of the Chainlink VRF Coordinator
```

#### Base

```bash
export VRF_ROUTER="0x..." # Address of the Supra VRF Router
```

### Hardcoded Metadata

The following metadata is set on deployment in the Solidity deployment scripts:

### [./script/common/deployment/01_deployToken.s.sol](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/common/deployment/01_deployToken.s.sol)

- `name`: Name of the mint consolation token
- `symbol`: Symbol of the mint consolation token

#### [./script/Arbitrum/deployment/01_deployPerpetualMint.s.sol](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/Arbitrum/deployment/01_deployPerpetualMint.s.sol)

- `receiptName`: Name of the receipt token received when winning mints
- `receiptSymbol`: Symbol of the receipt token received when winning mints

#### [./script/Base/deployment/01_deployPerpetualMint.s.sol](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/Base/deployment/01_deployPerpetualMint.s.sol)

- `receiptName`: Name of the receipt token received when winning mints
- `receiptSymbol`: Symbol of the receipt token received when winning mints

### Deploying on Arbitrum

```bash
make deploy-arb
```

### Deploying on Arbitrum Sepolia (Testnet)

```bash
make deploy-arb-sepolia
```

### Deploying on Base

```bash
make deploy-base
```

### Deploying on Base Goerli (Testnet)

```bash
make deploy-base-goerli
```

### Deploying Locally (on an Arbitrum Fork)

```bash
make deploy-local-arb
```

### Deploying Locally (on a Base Fork)

```bash
make deploy-local-base
```

---

## Post-Deployment Configuration

We provide post-deployment configuration scripts for the following networks:

1. **Arbitrum**
2. **Arbitrum Sepolia (Testnet)**
3. **Base**
4. **Base Goerli (Testnet)**
5. **Localhost (Arbitrum Fork)**
6. **Localhost (Base Fork)**

### Bash Environment Variables

These are set in each of the post-deployment configuration bash scripts.

Double-check that they are correct before running the script.

#### [./script/Arbitrum/post-deployment/configure-token-\*.sh](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/Arbitrum/post-deployment/configure-token-arb.sh)

NOTE: For reference, currently the `BASIS` being used by `PerpetualMint` & `Token` is `1e9`.

```bash
export NEW_TOKEN_PROXY_OWNER="0x..." # Address to set as the new TokenProxy owner

# Determines the token emissions rate per mint
export TOKEN_DISTRIBUTION_FRACTION_BP=<1e7 percentage number> # Example: 1e7 = 1%
```

#### [./script/Arbitrum/post-deployment/configure-vrf-\*.sh](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/Arbitrum/post-deployment/configure-vrf-arb.sh)

```bash
export LINK_FUND_AMOUNT=<base LINK unit amount> # Example: 1 = 1 LINK, can be 0 to fund subscription later

export LINK_TOKEN="0x..." # Address of the LINK token

export NEW_VRF_OWNER="0x..." # Address to set and request as the new VRF subscription owner

export VRF_SUBSCRIPTION_BALANCE_THRESHOLD=<base LINK unit amount> # Example: 1 = 1 LINK
```

#### [./script/Arbitrum/post-deployment/configure-perp-mint-\*.sh](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/Arbitrum/post-deployment/configure-perp-mint-arb.sh)

```bash
# Mint for collection consolation fee used for funding $MINT
export COLLECTION_CONSOLATION_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

# Default collection mint referral fee in basis points
export DEFAULT_COLLECTION_REFERRAL_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

# Protocol mint fee
export MINT_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

# Mint for $MINT consolation fee used for funding $MINT
export MINT_TOKEN_CONSOLATION_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

export MINT_TOKEN_TIER_MULTIPLIERS=<1e9 number array aligned with MINT_TOKEN_TIER_RISKS> # Example: 1e9,2e9,4e9,8e9,16e9 = 1x, 2x, 4x, 8x, 16x

export MINT_TOKEN_TIER_RISKS=<1e7 number array aligned with MINT_TOKEN_TIER_MULTIPLIERS> # Example: 60e7,25e7,10e7,4e7,1e7 = 60%, 25%, 10%, 4%, 1%

export NEW_PERP_MINT_OWNER="0x..." # Address to set as the new Core/PerpetualMint owner

export REDEMPTION_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

export TIER_MULTIPLIERS=<1e9 number array aligned with TIER_RISKS> # Example: 1e9,2e9,4e9,8e9,16e9 = 1x, 2x, 4x, 8x, 16x

export TIER_RISKS=<1e7 number array aligned with TIER_MULTIPLIERS> # Example: 60e7,25e7,10e7,4e7,1e7 = 60%, 25%, 10%, 4%, 1%

export VRF_KEY_HASH="0x..." # Bytes32 gas lane key hash for the Chainlink VRF Coordinator
```

#### [./script/Base/post-deployment/configure-token-\*.sh](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/Base/post-deployment/configure-token-base.sh)

NOTE: For reference, currently the `BASIS` being used by `PerpetualMint` & `Token` is `1e9`.

```bash
export NEW_TOKEN_PROXY_OWNER="0x..." # Address to set as the new TokenProxy owner

# Determines the token emissions rate per mint
export TOKEN_DISTRIBUTION_FRACTION_BP=<1e7 percentage number> # Example: 1e7 = 1%
```

#### [./script/Base/post-deployment/configure-vrf-\*.sh](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/Base/post-deployment/configure-vrf-base.sh)

```bash
export ETH_FUND_AMOUNT=<base ETH unit amount> # Example: 1 = 1 ETH, can be 0 to fund subscription later
```

#### [./script/Base/post-deployment/configure-perp-mint-\*.sh](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/Base/post-deployment/configure-perp-mint-base.sh)

```bash
# Mint for collection consolation fee used for funding $MINT
export COLLECTION_CONSOLATION_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

# Default collection mint referral fee in basis points
export DEFAULT_COLLECTION_REFERRAL_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

# Protocol mint fee
export MINT_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

# Mint for $MINT consolation fee used for funding $MINT
export MINT_TOKEN_CONSOLATION_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

export MINT_TOKEN_TIER_MULTIPLIERS=<1e9 number array aligned with MINT_TOKEN_TIER_RISKS> # Example: 1e9,2e9,4e9,8e9,16e9 = 1x, 2x, 4x, 8x, 16x

export MINT_TOKEN_TIER_RISKS=<1e7 number array aligned with MINT_TOKEN_TIER_MULTIPLIERS> # Example: 60e7,25e7,10e7,4e7,1e7 = 60%, 25%, 10%, 4%, 1%

export NEW_PERP_MINT_OWNER="0x..." # Address to set as the new Core/PerpetualMint owner

export REDEMPTION_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

export TIER_MULTIPLIERS=<1e9 number array aligned with TIER_RISKS> # Example: 1e9,2e9,4e9,8e9,16e9 = 1x, 2x, 4x, 8x, 16x

export TIER_RISKS=<1e7 number array aligned with TIER_MULTIPLIERS> # Example: 60e7,25e7,10e7,4e7,1e7 = 60%, 25%, 10%, 4%, 1%
```

### Step 1: Token Configuration

### Arbitrum

```bash
make configure-token-arb
```

#### Arbitrum Sepolia (Testnet)

```bash
make configure-token-arb-sepolia
```

#### Locally (on an Arbitrum Fork)

```bash
make configure-token-local-arb
```

### Base

```bash
make configure-token-base
```

#### Base Goerli (Testnet)

```bash
make configure-token-base-goerli
```

#### Locally (on a Base Fork)

```bash
make configure-token-local-base
```

### Step 2: VRF Configuration

### Arbitrum

```bash
make configure-vrf-arb
```

#### Arbitrum Sepolia (Testnet)

```bash
make configure-vrf-arb-sepolia
```

#### Locally (on an Arbitrum Fork)

```bash
make configure-vrf-local-arb
```

### Base

```bash
make configure-vrf-base
```

#### Base Goerli (Testnet)

```bash
make configure-vrf-base-goerli
```

#### Locally (on a Base Fork)

```bash
make configure-vrf-local-base
```

### Step 3: PerpetualMint Configuration

NOTE: Once this step is complete, the protocol is activated.

### Arbitrum

```bash
make configure-perp-mint-arb
```

#### Arbitrum Sepolia (Testnet)

```bash
make configure-perp-mint-arb-sepolia
```

#### Locally (on an Arbitrum Fork)

```bash
make configure-perp-mint-local-arb
```

### Base

```bash
make configure-perp-mint-base
```

#### Base Goerli (Testnet)

```bash
make configure-perp-mint-base-goerli
```

#### Locally (on a Base Fork)

```bash
make configure-perp-mint-local-base
```

---
