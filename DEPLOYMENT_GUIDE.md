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

### Arbitrum Goerli Deployments

- `ARBITRUM_GOERLI_RPC_URL`: Arbitrum Goerli RPC URL
- `ARBISCAN_API_KEY`: Arbiscan API key for contract verification

### Localhost Deployments

- `ARBITRUM_RPC_URL`: Arbitrum RPC URL for forking the initial local state

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
2. **Arbitrum Goerli (Testnet)**
3. **Localhost**

---

## Deployment Steps

Here is how to deploy on each of these networks.

### Bash Environment Variables

These are set in each of the deployment bash scripts.

Double-check that they are correct before running the deployment script.

```bash
export VRF_COORDINATOR="0x..." # Address of the Chainlink VRF Coordinator
```

### Hardcoded Metadata

The following metadata is set on deployment in the Solidity deployment scripts:

### [./script/deployment/01_deployToken.s.sol](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/deployment/01_deployToken.s.sol)

- `name`: Name of the mint consolation token
- `symbol`: Symbol of the mint consolation token

#### [./script/deployment/02_deployPerpetualMint.s.sol](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/deployment/02_deployPerpetualMint.s.sol)

- `receiptName`: Name of the receipt token received when winning mints
- `receiptSymbol`: Symbol of the receipt token received when winning mints

### Deploying on Arbitrum

```bash
make deploy-arb
```

### Deploying on Arbitrum Goerli (Testnet)

```bash
make deploy-arb-goerli
```

### Deploying Locally (on a Fork)

```bash
make deploy-local
```

---

## Post-Deployment Configuration

We provide post-deployment configuration scripts for the following networks:

1. **Arbitrum**
2. **Arbitrum Goerli (Testnet)**
3. **Localhost**

### Bash Environment Variables

These are set in each of the post-deployment configuration bash scripts.

Double-check that they are correct before running the script.

#### [./script/post-deployment/configure-token-\*.sh](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/post-deployment/configure-token-arb.sh)

NOTE: For reference, currently the `BASIS` being used by `PerpetualMint` & `Token` is `1e9`.

```bash
export NEW_TOKEN_PROXY_OWNER="0x..." # Address to set as the new TokenProxy owner

# Determines the token emissions rate per mint
export TOKEN_DISTRIBUTION_FRACTION_BP=<1e7 percentage number> # Example: 1e7 = 1%
```

#### [./script/post-deployment/configure-vrf-\*.sh](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/post-deployment/configure-vrf-arb.sh)

```bash
export LINK_FUND_AMOUNT=<base LINK unit amount> # Example: 1 = 1 LINK, can be 0 to fund subscription later

export LINK_TOKEN="0x..." # Address of the LINK token

export NEW_VRF_OWNER="0x..." # Address to set and request as the new VRF subscription owner

export VRF_SUBSCRIPTION_BALANCE_THRESHOLD=<base LINK unit amount> # Example: 1 = 1 LINK
```

#### [./script/post-deployment/configure-perp-mint-\*.sh](https://github.com/Insrt-Finance/insrt-v2-contracts/blob/v0.1.0-alpha/script/post-deployment/configure-perp-mint-arb.sh)

```bash
# Mint fee for funding $MINT
export CONSOLATION_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

# Protocol mint fee
export MINT_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

export NEW_PERP_MINT_OWNER="0x..." # Address to set as the new Core/PerpetualMint owner

export REDEMPTION_FEE_BP=<1e7 percentage number> # Example: 1e7 = 1%

export TIER_MULTIPLIERS=<1e9 number array aligned with TIER_RISKS> # Example: 1e9,2e9,4e9,8e9,16e9 = 1x, 2x, 4x, 8x, 16x

export TIER_RISKS=<1e7 number array aligned with TIER_MULTIPLIERS> # Example: 60e7,25e7,10e7,4e7,1e7 = 60%, 25%, 10%, 4%, 1%

export VRF_KEY_HASH="0x..." # Bytes32 gas lane key hash for the Chainlink VRF Coordinator
```

### Step 1: Token Configuration

#### Arbitrum

```bash
make configure-token-arb
```

### Arbitrum Goerli (Testnet)

```bash
make configure-token-arb-goerli
```

### Locally (on a Fork)

```bash
make configure-token-local
```

### Step 2: VRF Configuration

#### Arbitrum

```bash
make configure-vrf-arb
```

### Arbitrum Goerli (Testnet)

```bash
make configure-vrf-arb-goerli
```

### Locally (on a Fork)

```bash
make configure-vrf-local
```

### Step 3: PerpetualMint Configuration

NOTE: Once this step is complete, the protocol is activated.

#### Arbitrum

```bash
make configure-perp-mint-arb
```

### Arbitrum Goerli (Testnet)

```bash
make configure-perp-mint-arb-goerli
```

### Locally (on a Fork)

```bash
make configure-perp-mint-local
```

---
