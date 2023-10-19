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

### Arbitrum Goerli

Requires the following additional environment variables set:

- `ARBITRUM_GOERLI_RPC_URL`: Arbitrum Goerli RPC URL
- `ARBISCAN_API_KEY`: Arbiscan API key for contract verification

```
make deploy-arb-goerli
```

### Localhost

Requires the following additional environment variables set:

- `ARBITRUM_RPC_URL`: Arbitrum RPC URL for forking the initial local state

```
make deploy-local
```

## Post-deployment configuration

### Arbitrum

1. Token configuration

Note: The following environment variables are modifiable in `./script/post-deployment/configure-token-arb.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-arb
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/post-deployment/configure-vrf-arb.sh`:

- `LINK_FUND_AMOUNT`
- `LINK_TOKEN`
- `NEW_VRF_OWNER`
- `VRF_SUBSCRIPTION_BALANCE_THRESHOLD`

```
make configure-vrf-arb
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/post-deployment/configure-perp-mint-arb.sh`:

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

### Arbitrum Goerli

1. Token configuration

Note: The following environment variables are modifiable in `./script/post-deployment/configure-token-arb-goerli.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-arb-goerli
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/post-deployment/configure-vrf-arb-goerli.sh`:

- `LINK_FUND_AMOUNT`
- `LINK_TOKEN`
- `NEW_VRF_OWNER`
- `VRF_SUBSCRIPTION_BALANCE_THRESHOLD`

```
make configure-vrf-arb-goerli
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/post-deployment/configure-perp-mint-arb-goerli.sh`:

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

### Localhost

1. Token configuration

Note: The following environment variables are modifiable in `./script/post-deployment/configure-token-local.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-local
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/post-deployment/configure-vrf-local.sh`:

- `LINK_FUND_AMOUNT`
- `LINK_TOKEN`
- `NEW_VRF_OWNER`
- `VRF_SUBSCRIPTION_BALANCE_THRESHOLD`

```
make configure-vrf-local
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/post-deployment/configure-perp-mint-local.sh`:

- `CONSOLATION_FEE_BP`
- `MINT_FEE_BP`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`
- `VRF_KEY_HASH`

```
make configure-perp-mint-local
```

## Upgrading contracts

### Upgrade PerpetualMint facet

```
make upgrade-perp-mint-arb
```

### Upgrade PerpetualMintView facet

```
make upgrade-perp-mint-view-arb
```

## On-chain calculations

### Calculating mint results

```
make calculate-mint-result <mint-collection-address> <number-of-mint-attempts> <randomness>
```
