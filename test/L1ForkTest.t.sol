// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "forge-std/Test.sol";

/// @title L1ForkTest
/// @dev Base contract for L1 forking test cases.
abstract contract L1ForkTest is Test {
    /// @dev LayerZero message fee.
    uint256 internal constant LAYER_ZERO_MESSAGE_FEE = 0.002 ether;

    /// @dev Fetches and stores the Mainnet RPC URL from a local .env file using the passed string as a key.
    string internal MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    /// @dev Identifier for the simulated Mainnet fork.
    /// @notice Fork is created, available for selection, and selected by default.
    uint256 internal mainnetFork = vm.createSelectFork(MAINNET_RPC_URL);
}
