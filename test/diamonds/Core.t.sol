// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { Core } from "../../contracts/diamonds/Core/Core.sol";

/// @title CoreTest
/// @dev Test helper contract for setting up and testing the Core diamond and its facets.
/// Inherits from Test contract in forge-std library.
abstract contract CoreTest is Test {
    Core public coreDiamond;

    receive() external payable virtual {}

    /// @notice Setup function to initialize contract state before tests.
    /// @dev Creates a new instance of Core (diamond contract) and assigns it to CoreDiamond.
    /// Function is virtual, so it can be overridden in derived contracts.
    function setUp() public virtual {
        coreDiamond = new Core();
    }
}
