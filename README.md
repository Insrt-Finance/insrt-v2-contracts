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

#### Arbitrum Sepolia

Requires the following additional environment variables set:

- `ARBITRUM_SEPOLIA_RPC_URL`: Arbitrum Sepolia RPC URL
- `ARBISCAN_API_KEY`: Arbiscan API key for contract verification

```
make deploy-arb-sepolia
```

#### Arbitrum Sepolia w/ the Insrt VRF Coordinator

Requires the following additional environment variables set:

- `ARBITRUM_SEPOLIA_RPC_URL`: Arbitrum Sepolia RPC URL
- `ARBISCAN_API_KEY`: Arbiscan API key for contract verification

```
make deploy-arb-sepolia-custom
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

#### Base Sepolia

Requires the following additional environment variables set:

- `BASE_SEPOLIA_RPC_URL`: Base Sepolia RPC URL
- `BASESCAN_API_KEY`: Basescan API key for contract verification

```
make deploy-base-sepolia
```

#### Localhost (Base Fork)

Requires the following additional environment variables set:

- `BASE_RPC_URL`: Base RPC URL for forking the initial local state

```
make deploy-local-base
```

### Blast

Requires the following additional environment variables set:

- `BLAST_RPC_URL`: Blast RPC URL
- `BLASTCAN_API_KEY`: Blastscan API key for contract verification

```
make deploy-blast
```

#### Blast Sepolia

Requires the following additional environment variables set:

- `BLAST_SEPOLIA_RPC_URL`: Blast Sepolia RPC URL
- `BLASTCAN_API_KEY`: Blastscan API key for contract verification

```
make deploy-blast-sepolia
```

#### Blast Sepolia w/ the Insrt VRF Coordinator

Requires the following additional environment variables set:

- `BLAST_SEPOLIA_RPC_URL`: Blast Sepolia RPC URL
- `BLASTCAN_API_KEY`: Blastscan API key for contract verification

```
make deploy-blast-sepolia-custom
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

- `COLLECTION_CONSOLATION_FEE_BP`
- `DEFAULT_COLLECTION_REFERRAL_FEE_BP`
- `MINT_EARNINGS_BUFFER_BP`
- `MINT_FEE_BP`
- `MINT_FOR_ETH_CONSOLATION_FEE_BP`
- `MINT_TOKEN_CONSOLATION_FEE_BP`
- `MINT_TOKEN_TIER_MULTIPLIERS`
- `MINT_TOKEN_TIER_RISKS`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`
- `VRF_KEY_HASH`

```
make configure-perp-mint-arb
```

#### Arbitrum Sepolia

1. Token configuration

Note: The following environment variables are modifiable in `./script/Arbitrum/post-deployment/configure-token-arb-sepolia.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-arb-sepolia
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/Arbitrum/post-deployment/configure-vrf-arb-sepolia.sh`:

- `LINK_FUND_AMOUNT`
- `LINK_TOKEN`
- `NEW_VRF_OWNER`
- `VRF_SUBSCRIPTION_BALANCE_THRESHOLD`

```
make configure-vrf-arb-sepolia
```

Note: The following environment variables are modifiable in `./script/Arbitrum/post-deployment/configure-vrf-arb-sepolia-custom.sh`:

- `NEW_VRF_OWNER`
- `VRF_FULFILLER`

```
make configure-vrf-arb-sepolia-custom
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/Arbitrum/post-deployment/configure-perp-mint-arb-sepolia.sh`:

- `COLLECTION_CONSOLATION_FEE_BP`
- `DEFAULT_COLLECTION_REFERRAL_FEE_BP`
- `MINT_EARNINGS_BUFFER_BP`
- `MINT_FEE_BP`
- `MINT_FOR_ETH_CONSOLATION_FEE_BP`
- `MINT_TOKEN_CONSOLATION_FEE_BP`
- `MINT_TOKEN_TIER_MULTIPLIERS`
- `MINT_TOKEN_TIER_RISKS`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`
- `VRF_KEY_HASH`

```
make configure-perp-mint-arb-sepolia
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

- `COLLECTION_CONSOLATION_FEE_BP`
- `DEFAULT_COLLECTION_REFERRAL_FEE_BP`
- `MINT_EARNINGS_BUFFER_BP`
- `MINT_FEE_BP`
- `MINT_FOR_ETH_CONSOLATION_FEE_BP`
- `MINT_TOKEN_CONSOLATION_FEE_BP`
- `MINT_TOKEN_TIER_MULTIPLIERS`
- `MINT_TOKEN_TIER_RISKS`
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

- `COLLECTION_CONSOLATION_FEE_BP`
- `DEFAULT_COLLECTION_REFERRAL_FEE_BP`
- `MINT_EARNINGS_BUFFER_BP`
- `MINT_FEE_BP`
- `MINT_FOR_ETH_CONSOLATION_FEE_BP`
- `MINT_TOKEN_CONSOLATION_FEE_BP`
- `MINT_TOKEN_TIER_MULTIPLIERS`
- `MINT_TOKEN_TIER_RISKS`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`

```
make configure-perp-mint-base
```

#### Base Sepolia

1. Token configuration

Note: The following environment variables are modifiable in `./script/Base/post-deployment/configure-token-base-sepolia.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-base-sepolia
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/Base/post-deployment/configure-vrf-base-sepolia.sh`:

- `ETH_FUND_AMOUNT`

```
make configure-vrf-base-sepolia
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/Base/post-deployment/configure-perp-mint-base-sepolia.sh`:

- `COLLECTION_CONSOLATION_FEE_BP`
- `DEFAULT_COLLECTION_REFERRAL_FEE_BP`
- `MINT_EARNINGS_BUFFER_BP`
- `MINT_FEE_BP`
- `MINT_FOR_ETH_CONSOLATION_FEE_BP`
- `MINT_TOKEN_CONSOLATION_FEE_BP`
- `MINT_TOKEN_TIER_MULTIPLIERS`
- `MINT_TOKEN_TIER_RISKS`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`

```
make configure-perp-mint-base-sepolia
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

- `COLLECTION_CONSOLATION_FEE_BP`
- `DEFAULT_COLLECTION_REFERRAL_FEE_BP`
- `MINT_EARNINGS_BUFFER_BP`
- `MINT_FEE_BP`
- `MINT_FOR_ETH_CONSOLATION_FEE_BP`
- `MINT_TOKEN_CONSOLATION_FEE_BP`
- `MINT_TOKEN_TIER_MULTIPLIERS`
- `MINT_TOKEN_TIER_RISKS`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`

```
make configure-perp-mint-local-base
```

### Blast

1. Token configuration

Note: The following environment variables are modifiable in `./script/Blast/post-deployment/configure-token-blast.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-blast
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/Blast/post-deployment/configure-vrf-blast.sh`:

- `ETH_FUND_AMOUNT`

```
make configure-vrf-blast
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/Blast/post-deployment/configure-perp-mint-blast.sh`:

- `BLAST_YIELD_RISK`
- `COLLECTION_CONSOLATION_FEE_BP`
- `DEFAULT_COLLECTION_REFERRAL_FEE_BP`
- `MINT_EARNINGS_BUFFER_BP`
- `MINT_FEE_BP`
- `MINT_FOR_ETH_CONSOLATION_FEE_BP`
- `MINT_TOKEN_CONSOLATION_FEE_BP`
- `MINT_TOKEN_TIER_MULTIPLIERS`
- `MINT_TOKEN_TIER_RISKS`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`

```
make configure-perp-mint-blast
```

#### Blast Sepolia

1. Token configuration

Note: The following environment variables are modifiable in `./script/Blast/post-deployment/configure-token-blast-sepolia.sh`:

- `NEW_TOKEN_PROXY_OWNER`
- `TOKEN_DISTRIBUTION_FRACTION_BP`

```
make configure-token-blast-sepolia
```

2. VRF configuration

Note: The following environment variables are modifiable in `./script/Blast/post-deployment/configure-vrf-blast-sepolia.sh`:

- `ETH_FUND_AMOUNT`

```
make configure-vrf-blast-sepolia
```

Note: The following environment variables are modifiable in `./script/Blast/post-deployment/configure-vrf-blast-sepolia-custom.sh`:

- `NEW_VRF_OWNER`
- `VRF_FULFILLER`

```
make configure-vrf-blast-sepolia-custom
```

3. PerpetualMint configuration

Note: The following environment variables are modifiable in `./script/Blast/post-deployment/configure-perp-mint-blast-sepolia.sh`:

- `COLLECTION_CONSOLATION_FEE_BP`
- `DEFAULT_COLLECTION_REFERRAL_FEE_BP`
- `MINT_EARNINGS_BUFFER_BP`
- `MINT_FEE_BP`
- `MINT_FOR_ETH_CONSOLATION_FEE_BP`
- `MINT_TOKEN_CONSOLATION_FEE_BP`
- `MINT_TOKEN_TIER_MULTIPLIERS`
- `MINT_TOKEN_TIER_RISKS`
- `NEW_PERP_MINT_OWNER`
- `REDEMPTION_FEE_BP`
- `TIER_MULTIPLIERS`
- `TIER_RISKS`

```
make configure-perp-mint-blast-sepolia
```

## Upgrading contracts

Note: All upgrades must have the following environment variables set:

- `DEPLOYER_KEY`: Private key of the deployer account

### Arbitrum

Requires the following additional environment variables set:

- `ARBITRUM_RPC_URL`: Arbitrum RPC URL
- `ARBISCAN_API_KEY`: Arbiscan API key for contract verification

##### Upgrade & Remove PerpetualMint facet

```
make upgrade-remove-perp-mint-arb
```

##### Upgrade & Remove PerpetualMintView facet

```
make upgrade-remove-perp-mint-view-arb
```

##### Upgrade & Split PerpetualMint facet

```
make upgrade-split-perp-mint-arb
```

#### Upgrade PerpetualMint facet

```
make upgrade-perp-mint-arb
```

#### Upgrade PerpetualMintAdmin facet

```
make upgrade-perp-mint-admin-arb
```

#### Upgrade PerpetualMintView facet

```
make upgrade-perp-mint-view-arb
```

#### Upgrade Token facet

```
make upgrade-token-arb
```

#### Arbitrum Sepolia

Requires the following additional environment variables set:

- `ARBITRUM_SEPOLIA_RPC_URL`: Arbitrum Sepolia RPC URL
- `ARBISCAN_API_KEY`: Arbiscan API key for contract verification

##### Upgrade & Remove PerpetualMint facet

```
make upgrade-remove-perp-mint-arb-sepolia
```

##### Upgrade & Remove PerpetualMintView facet

```
make upgrade-remove-perp-mint-view-arb-sepolia
```

##### Upgrade & Split PerpetualMint facet

```
make upgrade-split-perp-mint-arb-sepolia
```

##### Upgrade PerpetualMint facet

```
make upgrade-perp-mint-arb-sepolia
```

#### Upgrade PerpetualMintAdmin facet

```
make upgrade-perp-mint-admin-arb-sepolia
```

##### Upgrade PerpetualMintView facet

```
make upgrade-perp-mint-view-arb-sepolia
```

#### Upgrade Token facet

```
make upgrade-token-arb-sepolia
```

### Blast

Requires the following additional environment variables set:

- `BLAST_RPC_URL`: Blast RPC URL
- `BLASTSCAN_API_KEY`: Blastscan API key for contract verification

##### Upgrade & Remove PerpetualMint & PerpetualMintSupraBlast facet

```
make upgrade-remove-perp-mint-blast
```

##### Upgrade & Remove PerpetualMintView & PerpetualMintViewSupraBlast facet

```
make upgrade-remove-perp-mint-view-blast
```

##### Upgrade & Split PerpetualMintSupraBlast facet

```
make upgrade-split-perp-mint-blast
```

#### Upgrade PerpetualMintAdmin & PerpetualMintAdminBlast facet

```
make upgrade-perp-mint-admin-blast
```

#### Upgrade PerpetualMint & PerpetualMintSupraBlast facet

```
make upgrade-perp-mint-blast
```

#### Upgrade PerpetualMintView & PerpetualMintViewSupraBlast facet

```
make upgrade-perp-mint-view-blast
```

#### Blast Sepolia

Requires the following additional environment variables set:

- `BLAST_SEPOLIA_RPC_URL`: Blast Sepolia RPC URL
- `BLASTSCAN_API_KEY`: Blastscan API key for contract verification

##### Upgrade & Remove PerpetualMint & PerpetualMintSupraBlast facet

```
make upgrade-remove-perp-mint-blast-sepolia
```

##### Upgrade & Remove PerpetualMintView & PerpetualMintViewSupraBlast facet

```
make upgrade-remove-perp-mint-view-blast-sepolia
```

##### Upgrade & Split PerpetualMintSupraBlast facet

```
make upgrade-split-perp-mint-blast-sepolia
```

#### Upgrade PerpetualMintAdmin & PerpetualMintAdminBlast facet

```
make upgrade-perp-mint-admin-blast-sepolia
```

#### Upgrade PerpetualMintView & PerpetualMintViewSupraBlast facet

```
make upgrade-perp-mint-view-blast-sepolia
```

## On-chain calculations

### Arbitrum

Requires the following additional environment variables set:

- `ARBITRUM_RPC_URL`: Arbitrum RPC URL

#### Calculating mint results

```
make calculate-mint-result-arb <mint-collection-address> <number-of-mint-attempts> <randomness> <price-per-mint> <prize-value>
```

### Base

Requires the following additional environment variables set:

- `BASE_RPC_URL`: Base RPC URL

#### Calculating mint results

```
make calculate-mint-result-base <mint-collection-address> <number-of-mint-attempts> <randomness_signature-index-1> <randomness-signature-index-2> <price-per-mint> <prize-value>
```

### Blast

Requires the following additional environment variables set:

- `BLAST_RPC_URL`: Blast RPC URL

#### Calculating mint results

```
make calculate-mint-result-blast <mint-collection-address> <number-of-mint-attempts> <randomness-signature-index-1> <randomness-signature-index-2> <price-per-mint> <prize-value> <referral-mint> <risk-reward_ratio>
```
