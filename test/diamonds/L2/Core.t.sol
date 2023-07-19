// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { L2Core } from "../../../contracts/diamonds/L2/Core/Core.sol";

/// @title L2CoreTest
/// @dev Test helper contract for setting up and testing the L2 Core diamond and its facets.
/// Inherits from Test contract in forge-std library.
abstract contract L2CoreTest is Test {
    L2Core public l2CoreDiamond;

    /// @notice Setup function to initialize contract state before tests.
    /// @dev Creates a new instance of L2Core (diamond contract) and assigns it to l2CoreDiamond.
    /// Function is virtual, so it can be overridden in derived contracts.
    function setUp() public virtual {
        l2CoreDiamond = new L2Core();
    }
}
