// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title Token_beforeTokenTransfer
/// @dev Token test contract for testing expected _beforeTokenTransfer behavior. Tested on an Arbitrum fork.
contract Token_beforeTokenTransfer is ArbForkTest, TokenTest {
    /// @dev sets up the testing environment
    function setUp() public override {
        super.setUp();
    }

    /// @dev ensure that _beforeTokenTransfer allows all transfers to address(0)
    function testFuzz_beforeTokenTransferAllowsAllBurns(address burner) public {
        if (burner != address(0)) {
            vm.prank(MINTER);
            token.mint(burner, MINT_AMOUNT);

            vm.prank(MINTER);
            token.burn(burner, MINT_AMOUNT / 100);
        }
    }

    /// @dev ensure that _beforeTokenTransfer allows all transfers from address(0)
    function testFuzz_beforeTokenTransferAllowsAllMinting(
        address receiver
    ) public {
        if (receiver != address(0)) {
            vm.prank(MINTER);
            token.mint(receiver, MINT_AMOUNT);
        }
    }

    /// @dev ensure that _beforeTokenTransfer allows all transfers from token address
    function test_beforeTokenTransferAllowsAllTransfersFromTokenContract()
        public
    {
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        vm.prank(address(token));
        token.approve(MINTER, MINT_AMOUNT / 10000);
        vm.prank(MINTER);
        token.transferFrom(address(token), address(121), MINT_AMOUNT / 10000);
    }
}
