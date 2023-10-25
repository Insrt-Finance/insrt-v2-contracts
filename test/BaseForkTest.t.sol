// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "forge-std/Test.sol";

/// @title BaseForkTest
/// @dev Base contract for Base forking test cases.
abstract contract BaseForkTest is Test {
    /// @dev Fetches and stores the Base RPC URL from a local .env file using the passed string as a key.
    string internal BASE_RPC_URL = vm.envString("BASE_RPC_URL");

    /// @dev Identifier for the simulated Base fork.
    /// @notice Fork is created, available for selection, and selected by default.
    uint256 internal baseFork = vm.createSelectFork(BASE_RPC_URL);
}
