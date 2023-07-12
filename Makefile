# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# Install dependencies
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
clean  :; forge clean # remove build artifacts and cache directories
fmt    :; forge fmt # run built-in formatter
prettier    :; pnpm prettier --write contracts/**/**/**/*.sol
size  :; forge build --sizes # show contract sizes
snapshot :; forge snapshot # create a snapshot of each test's gas usage
test:
	forge test
trace   :; forge test -vvv # show stack traces for failing tests
.PHONY: test # prevent make from looking for a file named test

