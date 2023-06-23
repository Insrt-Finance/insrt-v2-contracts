// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "forge-std/Test.sol";

/// @title ForkTest
/// @dev Base contract for forking test cases.
abstract contract ForkTest is Test {
    /// @dev Fetches and stores the Mainnet RPC URL from a local .env file using the passed string as a key.
    string internal MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    /// @dev Fetches and stores the Arbitrum RPC URL from a local .env file using the passed string as a key.
    string internal ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

    /// @dev Identifier for the simulated Mainnet fork.
    uint256 internal mainnetFork = vm.createFork(MAINNET_RPC_URL);

    /// @dev Identifier for the simulated Arbitrum fork.
    uint256 internal arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
}
