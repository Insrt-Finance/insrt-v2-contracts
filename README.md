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

Note: `TOKEN_DISTRIBUTION_FRACTION_BP` is modifiable in `./scripts/configure-token-arb.sh`.

```
make configure-token-arb
```

2. VRF configuration

Note: `LINK_FUND_AMOUNT` is modifiable in `./scripts/configure-vrf-arb.sh`.

```
make configure-vrf-arb
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./scripts/configure-perp-mint-arb.sh`:

- `COLLECTION_PRICE_TO_MINT_RATIO_BP`
- `CONSOLATION_FEE_BP`
- `MINT_FEE_BP`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`

```
make configure-perp-mint-arb
```

### Arbitrum Goerli

1. Token configuration

Note: `TOKEN_DISTRIBUTION_FRACTION_BP` is modifiable in `./scripts/configure-token-arb-goerli.sh`.

```
make configure-token-arb-goerli
```

2. VRF configuration

Note: `LINK_FUND_AMOUNT` is modifiable in `./scripts/configure-vrf-arb-goerli.sh`.

```
make configure-vrf-arb-goerli
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./scripts/configure-perp-mint-arb-goerli.sh`:

- `COLLECTION_PRICE_TO_MINT_RATIO_BP`
- `CONSOLATION_FEE_BP`
- `MINT_FEE_BP`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`

```
make configure-perp-mint-arb-goerli
```

### Localhost

1. Token configuration

Note: `TOKEN_DISTRIBUTION_FRACTION_BP` is modifiable in `./scripts/configure-token-local.sh`.

```
make configure-token-local
```

2. VRF configuration

Note: `LINK_FUND_AMOUNT` is modifiable in `./scripts/configure-vrf-local.sh`.

```
make configure-vrf-local
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./scripts/configure-perp-mint-local.sh`:

- `COLLECTION_PRICE_TO_MINT_RATIO_BP`
- `CONSOLATION_FEE_BP`
- `MINT_FEE_BP`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`

```
make configure-perp-mint-local
```
