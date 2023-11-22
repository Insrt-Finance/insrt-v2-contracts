# insrt-v2-contracts

Insrt V2 Solidity Smart Contracts

## Prerequisites

- [Foundry](https://getfoundry.sh/)
- [NodeJS](https://nodejs.org/en/)
  - \>= v18.16.0

## Local development

### Install dependencies

```
make install
```

### Update dependencies

```
make update
```

### Compilation

```
make build
```

### Testing

```
make test
```

### `anvil` process control

#### Start `anvil` (in background)

```
make start-anvil
```

#### Stop `anvil`

```
make stop-anvil
```

## Deployment

Note: All deployments must have the following environment variables set:

- `DEPLOYER_KEY`: Private key of the deployer account

### Arbitrum

Requires the following additional environment variables set:

- `ARBITRUM_RPC_URL`: Arbitrum RPC URL
- `ARBISCAN_API_KEY`: Arbiscan API key for contract verification

```
make deploy-arb
```

#### Arbitrum Goerli

Requires the following additional environment variables set:

- `ARBITRUM_GOERLI_RPC_URL`: Arbitrum Goerli RPC URL
- `ARBISCAN_API_KEY`: Arbiscan API key for contract verification

```
make deploy-arb-goerli
```

#### Localhost (Arbitrum Fork)

Requires the following additional environment variables set:

- `ARBITRUM_RPC_URL`: Arbitrum RPC URL for forking the initial local state

```
make deploy-local-arb
```

### Base

Requires the following additional environment variables set:

- `BASE_RPC_URL`: Base RPC URL
- `BASESCAN_API_KEY`: Basescan API key for contract verification

```
make deploy-base
```

#### Base Goerli

Requires the following additional environment variables set:

- `BASE_GOERLI_RPC_URL`: Base Goerli RPC URL
- `BASESCAN_API_KEY`: Basescan API key for contract verification

```
make deploy-base-goerli
```

#### Localhost (Base Fork)

Requires the following additional environment variables set:

- `BASE_RPC_URL`: Base RPC URL for forking the initial local state

```
make deploy-local-base
```

## Post-deployment configuration

### Arbitrum

1. Token configuration

Note: The following environment variables are modifiable in `./script/Arbitrum/post-deployment/configure-token-arb.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-arb
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/Arbitrum/post-deployment/configure-vrf-arb.sh`:

- `LINK_FUND_AMOUNT`
- `LINK_TOKEN`
- `NEW_VRF_OWNER`
- `VRF_SUBSCRIPTION_BALANCE_THRESHOLD`

```
make configure-vrf-arb
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/Arbitrum/post-deployment/configure-perp-mint-arb.sh`:

- `CONSOLATION_FEE_BP`
- `MINT_FEE_BP`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`
- `VRF_KEY_HASH`

```
make configure-perp-mint-arb
```

#### Arbitrum Goerli

1. Token configuration

Note: The following environment variables are modifiable in `./script/Arbitrum/post-deployment/configure-token-arb-goerli.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-arb-goerli
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/Arbitrum/post-deployment/configure-vrf-arb-goerli.sh`:

- `LINK_FUND_AMOUNT`
- `LINK_TOKEN`
- `NEW_VRF_OWNER`
- `VRF_SUBSCRIPTION_BALANCE_THRESHOLD`

```
make configure-vrf-arb-goerli
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/Arbitrum/post-deployment/configure-perp-mint-arb-goerli.sh`:

- `CONSOLATION_FEE_BP`
- `MINT_FEE_BP`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`
- `VRF_KEY_HASH`

```
make configure-perp-mint-arb-goerli
```

#### Localhost (Arbitrum Fork)

1. Token configuration

Note: The following environment variables are modifiable in `./script/common/post-deployment/configure-token-local.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-local-arb
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/Arbitrum/post-deployment/configure-vrf-local.sh`:

- `LINK_FUND_AMOUNT`
- `LINK_TOKEN`
- `NEW_VRF_OWNER`
- `VRF_SUBSCRIPTION_BALANCE_THRESHOLD`

```
make configure-vrf-local-arb
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/Arbitrum/post-deployment/configure-perp-mint-local.sh`:

- `CONSOLATION_FEE_BP`
- `MINT_FEE_BP`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`
- `VRF_KEY_HASH`

```
make configure-perp-mint-local-arb
```

### Base

1. Token configuration

Note: The following environment variables are modifiable in `./script/Base/post-deployment/configure-token-base.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-base
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/Base/post-deployment/configure-vrf-base.sh`:

- `ETH_FUND_AMOUNT`

```
make configure-vrf-base
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/Base/post-deployment/configure-perp-mint-base.sh`:

- `CONSOLATION_FEE_BP`
- `MINT_FEE_BP`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`

```
make configure-perp-mint-base
```

#### Base Goerli

1. Token configuration

Note: The following environment variables are modifiable in `./script/Base/post-deployment/configure-token-base-goerli.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-base-goerli
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/Base/post-deployment/configure-vrf-base-goerli.sh`:

- `ETH_FUND_AMOUNT`

```
make configure-vrf-base-goerli
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/Base/post-deployment/configure-perp-mint-base-goerli.sh`:

- `CONSOLATION_FEE_BP`
- `MINT_FEE_BP`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`

```
make configure-perp-mint-base-goerli
```

#### Localhost (Base Fork)

1. Token configuration

Note: The following environment variables are modifiable in `./script/common/post-deployment/configure-token-local.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-local-base
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/Base/post-deployment/configure-vrf-local.sh`:

- `ETH_FUND_AMOUNT`

```
make configure-vrf-local-base
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/Base/post-deployment/configure-perp-mint-local.sh`:

- `CONSOLATION_FEE_BP`
- `MINT_FEE_BP`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`

```
make configure-perp-mint-local-base
```

## Upgrading contracts

Note: All upgrades must have the following environment variables set:

- `DEPLOYER_KEY`: Private key of the deployer account

### Arbitrum

Requires the following additional environment variables set:

- `ARBITRUM_RPC_URL`: Arbitrum RPC URL
- `ARBISCAN_API_KEY`: Arbiscan API key for contract verification

#### Upgrade PerpetualMint facet

```
make upgrade-perp-mint-arb
```

#### Upgrade PerpetualMintView facet

```
make upgrade-perp-mint-view-arb
```

#### Upgrade Token facet

```
make upgrade-token-arb
```

#### Arbitrum Goerli

Requires the following additional environment variables set:

- `ARBITRUM_GOERLI_RPC_URL`: Arbitrum Goerli RPC URL
- `ARBISCAN_API_KEY`: Arbiscan API key for contract verification

##### Upgrade PerpetualMint facet

```
make upgrade-perp-mint-arb-goerli
```

##### Upgrade PerpetualMintView facet

```
make upgrade-perp-mint-view-arb-goerli
```

## On-chain calculations

### Arbitrum

Requires the following additional environment variables set:

- `ARBITRUM_RPC_URL`: Arbitrum RPC URL

#### Calculating mint results

```
make calculate-mint-result-arb <mint-collection-address> <number-of-mint-attempts> <randomness>
```

### Base

Requires the following additional environment variables set:

- `BASE_RPC_URL`: Base RPC URL

#### Calculating mint results

```
make calculate-mint-result-base <mint-collection-address> <number-of-mint-attempts> <randomness_signature_index_1> <randomness_signature_index_2>
```
