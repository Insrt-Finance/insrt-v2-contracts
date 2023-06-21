// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "forge-std/Test.sol";

import { L1PerpetualMint } from "../../../contracts/diamonds/L1/PerpetualMint/PerpetualMint.sol";

/// @title L1PerpetualMintTest
/// @dev Test helper contract for setting up and testing the L1 Perpetual Mint diamond and its facets.
/// Inherits from Test contract in forge-std library.
abstract contract L1PerpetualMintTest is Test {
    L1PerpetualMint public l1PerpetualMintDiamond;

    /// @notice Setup function to initialize contract state before tests.
    /// @dev Creates a new instance of L1PerpetualMint (diamond contract) and assigns it to l1PerpetualMintDiamond.
    /// Function is virtual, so it can be overridden in derived contracts.
    function setUp() public virtual {
        l1PerpetualMintDiamond = new L1PerpetualMint();
    }
}
