// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

/// @title L2ForkTest
/// @dev Base contract for L2 forking test cases.
abstract contract L2ForkTest is Test {
    /// @dev Fetches and stores the Arbitrum RPC URL from a local .env file using the passed string as a key.
    string internal ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

    /// @dev Identifier for the simulated Arbitrum fork.
    /// @notice Fork is created, available for selection, and selected by default.
    uint256 internal arbitrumFork = vm.createSelectFork(ARBITRUM_RPC_URL);
}
