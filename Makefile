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
deploy-arb:
	@./script/deploy-arb.sh

deploy-arb-goerli:
	@./script/deploy-arb-goerli.sh

deploy-local:
	@./script/deploy-local.sh

### Post-deployment configuration

#### 1. Token configuration
configure-token-arb:
	@./script/configure-token-arb.sh

configure-token-arb-goerli:
	@./script/configure-token-arb-goerli.sh

configure-token-local:
	@./script/configure-token-local.sh

#### 2. VRF configuration
configure-vrf-arb:
	@./script/configure-vrf-arb.sh

configure-vrf-arb-goerli:
	@./script/configure-vrf-arb-goerli.sh

configure-vrf-local:
	@./script/configure-vrf-local.sh

#### 3. PerpetualMint configuration
configure-perp-mint-arb:
	@./script/configure-perp-mint-arb.sh

configure-perp-mint-arb-goerli:
	@./script/configure-perp-mint-arb-goerli.sh

configure-perp-mint-local:
	@./script/configure-perp-mint-local.sh
