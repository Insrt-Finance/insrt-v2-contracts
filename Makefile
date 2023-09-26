# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

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

# Anvil process control for local testing & development
start-anvil:
	./script/start-anvil.sh
stop-anvil:
	./script/stop-anvil.sh


# Deployments
deploy-arb:
	@./script/deploy-arb.sh $(DEPLOYER_KEY) $(ARBITRUM_RPC_URL) ${ARBISCAN_API_KEY}

deploy-arb-goerli:
	@./script/deploy-arb-goerli.sh $(DEPLOYER_KEY) $(ARBITRUM_GOERLI_RPC_URL) ${ARBISCAN_API_KEY}

deploy-local:
	@./script/deploy-local.sh $(DEPLOYER_KEY)
