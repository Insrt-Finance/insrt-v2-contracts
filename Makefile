# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
install:
	@command -v pnpm >/dev/null 2>&1 || npm i -g pnpm
	@echo
	@pnpm i
	@echo
	@forge install
	@echo
update:; forge update

# Build & test
build  :; forge build
.PHONY: test
test:
	forge test
trace   :; forge test -vvv
clean  :; forge clean
snapshot :; forge snapshot
fmt    :; forge fmt
