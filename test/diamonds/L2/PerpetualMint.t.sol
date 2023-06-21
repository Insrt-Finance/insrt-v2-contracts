// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "forge-std/Test.sol";

import { L2PerpetualMint } from "../../../contracts/diamonds/L2/PerpetualMint/PerpetualMint.sol";

/// @title L2PerpetualMintTest
/// @dev Test helper contract for setting up and testing the L2 Perpetual Mint diamond and its facets.
/// Inherits from Test contract in forge-std library.
abstract contract L2PerpetualMintTest is Test {
    L2PerpetualMint public l2PerpetualMintDiamond;

    /// @notice Setup function to initialize contract state before tests.
    /// @dev Creates a new instance of L2PerpetualMint (diamond contract) and assigns it to l2PerpetualMintDiamond.
    /// Function is virtual, so it can be overridden in derived contracts.
    function setUp() public virtual {
        l2PerpetualMintDiamond = new L2PerpetualMint();
    }
}
