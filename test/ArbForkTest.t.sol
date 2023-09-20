// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "forge-std/Test.sol";

/// @title ArbForkTest
/// @dev Base contract for Arbitrum forking test cases.
abstract contract ArbForkTest is Test {
    /// @dev Fetches and stores the Arbitrum RPC URL from a local .env file using the passed string as a key.
    string internal ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

    /// @dev Identifier for the simulated Arbitrum fork.
    /// @notice Fork is created, available for selection, and selected by default.
    uint256 internal arbitrumFork = vm.createSelectFork(ARBITRUM_RPC_URL);
}
