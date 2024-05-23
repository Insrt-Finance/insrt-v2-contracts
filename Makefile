# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env
export


### Install dependencies
install:
	@command -v pnpm >/dev/null 2>&1 || npm i -g pnpm
	@echo
	@pnpm i
	@echo
	@forge install
	@echo
update:; forge update


### Build & test
build  :; forge build
# remove build artifacts and cache directories
clean  :; forge clean
# run built-in formatter
fmt    :; forge fmt
# run prettier formatter on tests and contracts
prettier    :; pnpm prettier --write "contracts/**/*.sol" "test/**/*.sol"
# show contract sizes
size  :; forge build --sizes
 # create a snapshot of each test's gas usage
snapshot :; forge snapshot
test:
	forge test
# show stack traces for failing tests
trace   :; forge test -vvv
# prevent make from looking for a file named test
.PHONY: test


### Anvil process control for local testing & development
start-anvil:
	./script/start-anvil.sh
stop-anvil:
	./script/stop-anvil.sh


### Deployments

#### Arbitrum

deploy-arb:
	@./script/Arbitrum/deployment/deploy-arb.sh

deploy-arb-sepolia:
	@./script/Arbitrum/deployment/deploy-arb-sepolia.sh

deploy-arb-sepolia-custom:
	@./script/Arbitrum/deployment/deploy-arb-sepolia-custom.sh

deploy-local-arb:
	@./script/Arbitrum/deployment/deploy-local.sh

#### Base

deploy-base:
	@./script/Base/deployment/deploy-base.sh

deploy-base-sepolia:
	@./script/Base/deployment/deploy-base-sepolia.sh

deploy-local-base:
	@./script/Base/deployment/deploy-local.sh

#### Blast

deploy-blast:
	@./script/Blast/deployment/deploy-blast.sh

deploy-blast-sepolia:
	@./script/Blast/deployment/deploy-blast-sepolia.sh

deploy-blast-sepolia-custom:
	@./script/Blast/deployment/deploy-blast-sepolia-custom.sh


### Post-deployment configuration

#### Arbitrum

##### 1. Token configuration
configure-token-arb:
	@./script/Arbitrum/post-deployment/configure-token-arb.sh

configure-token-arb-sepolia:
	@./script/Arbitrum/post-deployment/configure-token-arb-sepolia.sh

configure-token-local-arb:
	@./script/common/post-deployment/configure-token-local.sh

##### 2. VRF configuration
configure-vrf-arb:
	@./script/Arbitrum/post-deployment/configure-vrf-arb.sh

configure-vrf-arb-sepolia:
	@./script/Arbitrum/post-deployment/configure-vrf-arb-sepolia.sh

configure-vrf-arb-sepolia-custom:
	@./script/Arbitrum/post-deployment/configure-vrf-arb-sepolia-custom.sh

configure-vrf-local-arb:
	@./script/Arbitrum/post-deployment/configure-vrf-local.sh

##### 3. PerpetualMint configuration
configure-perp-mint-arb:
	@./script/Arbitrum/post-deployment/configure-perp-mint-arb.sh

configure-perp-mint-arb-sepolia:
	@./script/Arbitrum/post-deployment/configure-perp-mint-arb-sepolia.sh

configure-perp-mint-local-arb:
	@./script/Arbitrum/post-deployment/configure-perp-mint-local.sh

#### Base

##### 1. Token configuration
configure-token-base:
	@./script/Base/post-deployment/configure-token-base.sh

configure-token-base-sepolia:
	@./script/Base/post-deployment/configure-token-base-sepolia.sh

configure-token-local-base:
	@./script/common/post-deployment/configure-token-local.sh

##### 2. VRF configuration
configure-vrf-base:
	@./script/Base/post-deployment/configure-vrf-base.sh

configure-vrf-base-sepolia:
	@./script/Base/post-deployment/configure-vrf-base-sepolia.sh

configure-vrf-local-base:
	@./script/Base/post-deployment/configure-vrf-local.sh

##### 3. PerpetualMint configuration
configure-perp-mint-base:
	@./script/Base/post-deployment/configure-perp-mint-base.sh

configure-perp-mint-base-sepolia:
	@./script/Base/post-deployment/configure-perp-mint-base-sepolia.sh

configure-perp-mint-local-base:
	@./script/Base/post-deployment/configure-perp-mint-local.sh

#### Blast

##### 1. Token configuration
configure-token-blast:
	@./script/Blast/post-deployment/configure-token-blast.sh

configure-token-blast-sepolia:
	@./script/Blast/post-deployment/configure-token-blast-sepolia.sh

##### 2. VRF configuration
configure-vrf-blast:
	@./script/Blast/post-deployment/configure-vrf-blast.sh

configure-vrf-blast-sepolia:
	@./script/Blast/post-deployment/configure-vrf-blast-sepolia.sh

configure-vrf-blast-sepolia-custom:
	@./script/Blast/post-deployment/configure-vrf-blast-sepolia-custom.sh

##### 3. PerpetualMint configuration
configure-perp-mint-blast:
	@./script/Blast/post-deployment/configure-perp-mint-blast.sh

configure-perp-mint-blast-sepolia:
	@./script/Blast/post-deployment/configure-perp-mint-blast-sepolia.sh


### Upgrading contracts

#### Arbitrum

##### Upgrade & Remove PerpetualMint facet
upgrade-remove-perp-mint-arb:
	@./script/Arbitrum/upgrade/upgrade-remove-perp-mint-arb.sh

##### Upgrade & Remove PerpetualMintView facet
upgrade-remove-perp-mint-view-arb:
	@./script/Arbitrum/upgrade/upgrade-remove-perp-mint-view-arb.sh

##### Upgrade & Split PerpetualMint facet
upgrade-split-perp-mint-arb:
	@./script/Arbitrum/upgrade/upgrade-split-perp-mint-arb.sh

##### Upgrade PerpetualMint facet
upgrade-perp-mint-arb:
	@./script/Arbitrum/upgrade/upgrade-perp-mint-arb.sh

##### Upgrade PerpetualMintAdmin facet
upgrade-perp-mint-admin-arb:
	@./script/Arbitrum/upgrade/upgrade-perp-mint-admin-arb.sh

##### Upgrade PerpetualMintView facet
upgrade-perp-mint-view-arb:
	@./script/Arbitrum/upgrade/upgrade-perp-mint-view-arb.sh

##### Upgrade Token facet
upgrade-token-arb:
	@./script/Arbitrum/upgrade/upgrade-token-arb.sh

##### Arbitrum Sepolia

##### Upgrade & Remove PerpetualMint facet
upgrade-remove-perp-mint-arb-sepolia:
	@./script/Arbitrum/upgrade/upgrade-remove-perp-mint-arb-sepolia.sh

##### Upgrade & Remove PerpetualMintView facet
upgrade-remove-perp-mint-view-arb-sepolia:
	@./script/Arbitrum/upgrade/upgrade-remove-perp-mint-view-arb-sepolia.sh

##### Upgrade & Split PerpetualMint facet
upgrade-split-perp-mint-arb-sepolia:
	@./script/Arbitrum/upgrade/upgrade-split-perp-mint-arb-sepolia.sh

##### Upgrade PerpetualMint facet
upgrade-perp-mint-arb-sepolia:
	@./script/Arbitrum/upgrade/upgrade-perp-mint-arb-sepolia.sh

##### Upgrade PerpetualMintAdmin facet
upgrade-perp-mint-admin-arb-sepolia:
	@./script/Arbitrum/upgrade/upgrade-perp-mint-admin-arb-sepolia.sh

##### Upgrade PerpetualMintView facet
upgrade-perp-mint-view-arb-sepolia:
	@./script/Arbitrum/upgrade/upgrade-perp-mint-view-arb-sepolia.sh

##### Upgrade Token facet
upgrade-token-arb-sepolia:
	@./script/Arbitrum/upgrade/upgrade-token-arb-sepolia.sh

#### Blast

##### Remove failed VRF fulfillments using RemoveFailedVRFFulfillments facet
remove-failed-vrf-fulfillments-blast:
	@./script/Blast/upgrade/remove-failed-vrf-fulfillments-blast.sh

##### Upgrade PerpetualMintAdmin + PerpetualMintAdminBlast facet
upgrade-perp-mint-admin-blast:
	@./script/Blast/upgrade/upgrade-perp-mint-admin-blast.sh

##### Upgrade & Remove PerpetualMint & PerpetualMintSupraBlast facet
upgrade-remove-perp-mint-blast:
	@./script/Blast/upgrade/upgrade-remove-perp-mint-blast.sh

##### Upgrade & Remove PerpetualMintView & PerpetualMintViewSupraBlast facet
upgrade-remove-perp-mint-view-blast:
	@./script/Blast/upgrade/upgrade-remove-perp-mint-view-blast.sh

##### Upgrade PerpetualMint + PerpetualMintSupraBlast facet
upgrade-perp-mint-blast:
	@./script/Blast/upgrade/upgrade-perp-mint-blast.sh

##### Upgrade PerpetualMintView + PerpetualMintViewSupraBlast facet
upgrade-perp-mint-view-blast:
	@./script/Blast/upgrade/upgrade-perp-mint-view-blast.sh

##### Upgrade + Split PerpetualMintSupraBlast facet
upgrade-split-perp-mint-blast:
	@./script/Blast/upgrade/upgrade-split-perp-mint-blast.sh

##### Blast Sepolia

##### Configure Blast Points Operator using ConfigurePointsOperator facet
configure-blast-points-operator-blast-sepolia:
	@./script/Blast/upgrade/configure-points-operator-blast-sepolia.sh

##### Upgrade & Remove PerpetualMint & PerpetualMintSupraBlast facet
upgrade-remove-perp-mint-blast-sepolia:
	@./script/Blast/upgrade/upgrade-remove-perp-mint-blast-sepolia.sh

##### Upgrade & Remove PerpetualMintView & PerpetualMintViewSupraBlast facet
upgrade-remove-perp-mint-view-blast-sepolia:
	@./script/Blast/upgrade/upgrade-remove-perp-mint-view-blast-sepolia.sh

##### Upgrade PerpetualMint + PerpetualMintSupraBlast facet
upgrade-perp-mint-blast-sepolia:
	@./script/Blast/upgrade/upgrade-perp-mint-blast-sepolia.sh

##### Upgrade PerpetualMintAdmin + PerpetualMintAdminBlast facet
upgrade-perp-mint-admin-blast-sepolia:
	@./script/Blast/upgrade/upgrade-perp-mint-admin-blast-sepolia.sh

##### Upgrade PerpetualMintView + PerpetualMintViewSupraBlast facet
upgrade-perp-mint-view-blast-sepolia:
	@./script/Blast/upgrade/upgrade-perp-mint-view-blast-sepolia.sh

##### Upgrade & Split PerpetualMintSupraBlast facet
upgrade-split-perp-mint-blast-sepolia:
	@./script/Blast/upgrade/upgrade-split-perp-mint-blast-sepolia.sh


### Calculations

#### Arbitrum

##### Calculate mint results
calculate-mint-result-arb:
	@./script/Arbitrum/calculate-mint-result.sh $(filter-out $@,$(MAKECMDGOALS))

#### Base

##### Calculate mint results
calculate-mint-result-base:
	@./script/Base/calculate-mint-result.sh $(filter-out $@,$(MAKECMDGOALS))

%:      # Do nothing to silence "No rule to make target" error when calculating mint results
	@:

#### Blast

##### Calculate mint results
calculate-mint-result-blast:
	@./script/Blast/calculate-mint-result.sh $(filter-out $@,$(MAKECMDGOALS))

%:      # Do nothing to silence "No rule to make target" error when calculating mint results
	@:
