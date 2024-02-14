// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "forge-std/Test.sol";

/// @title BlastForkTest
/// @dev Base contract for Blast forking test cases.
abstract contract BlastForkTest is Test {
    /// @dev Fetches and stores the Blast RPC URL from a local .env file using the passed string as a key.
    string internal BLAST_RPC_URL = vm.envString("BLAST_RPC_URL");

    /// @dev Identifier for the simulated Blast fork.
    /// @notice Fork is created, available for selection, and selected by default.
    uint256 internal blastFork = vm.createSelectFork(BLAST_RPC_URL);
}
