// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { TokenProxy } from "../../contracts/diamonds/Token/TokenProxy.sol";

/// @title TokenProxyTest
/// @dev Test helper contract for setting up and testing the TokenProxy diamond and its facets.
/// Inherits from Test contract in forge-std library.
abstract contract TokenProxyTest is Test {
    TokenProxy public tokenProxy;

    receive() external payable virtual {}

    /// @notice Setup function to initialize contract state before tests.
    /// @dev Creates a new instance of TokenProxy (diamond contract) and assigns it to tokenProxy.
    /// Function is virtual, so it can be overridden in derived contracts.
    function setUp() public virtual {
        tokenProxy = new TokenProxy(
            "MINT", //name
            "$MINT" // symbol
        );
    }
}
