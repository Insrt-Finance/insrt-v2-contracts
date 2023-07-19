// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { L1Core } from "../../../contracts/diamonds/L1/Core/Core.sol";

/// @title L1CoreTest
/// @dev Test helper contract for setting up and testing the L1 Core diamond and its facets.
/// Inherits from Test contract in forge-std library.
abstract contract L1CoreTest is Test {
    L1Core public l1CoreDiamond;

    /// @notice Setup function to initialize contract state before tests.
    /// @dev Creates a new instance of L1Core (diamond contract) and assigns it to l1CoreDiamond.
    /// Function is virtual, so it can be overridden in derived contracts.
    function setUp() public virtual {
        l1CoreDiamond = new L1Core();
    }
}
