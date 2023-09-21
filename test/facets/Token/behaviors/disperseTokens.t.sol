// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { IERC20BaseInternal } from "@solidstate/contracts/token/ERC20/base/IERC20BaseInternal.sol";

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title Token_disperseTokens
/// @dev Token test contract for testing expected disperseTokens behavior. Tested on an Arbitrum fork.
contract Token_disperseTokens is ArbForkTest, TokenTest {
    /// @dev test number of recipients
    uint8 internal constant testNumberOfRecipients = 5;

    uint256[] internal testAmounts;

    address[] internal testRecipients;

    /// @dev sets up the testing environment
    function setUp() public override {
        super.setUp();

        // mimic tokens being minted as part of an airdrop
        vm.prank(MINTER);
        token.mint(address(token), MINT_AMOUNT);

        // set up test amounts and recipients
        for (uint8 i = 0; i < testNumberOfRecipients; ++i) {
            testAmounts.push(MINT_AMOUNT / testNumberOfRecipients);

            testRecipients.push(address(uint160(i + 1)));
        }
    }

    /// @dev tests disperseTokens successfully disperses tokens to recipients
    function test_disperseTokens() external {
        token.disperseTokens(testRecipients, testAmounts);

        for (uint8 i = 0; i < testNumberOfRecipients; ++i) {
            // assert that the recipients received the correct amount of tokens
            assert(token.balanceOf(testRecipients[i]) == testAmounts[i]);
        }

        // assert that the token contract has distributed all minted tokens
        assert(token.balanceOf(address(token)) == 0);
    }

    function test_disperseTokensRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(TOKEN_NON_OWNER);
        token.disperseTokens(testRecipients, testAmounts);
    }

    function test_disperseTokensRevertsWhen_ContractBalanceIsInsufficient()
        external
    {
        // push an additional recipient and amount to testAmounts and testRecipients
        testAmounts.push(MINT_AMOUNT / testNumberOfRecipients);

        testRecipients.push(address(1234));

        vm.expectRevert(
            IERC20BaseInternal.ERC20Base__TransferExceedsBalance.selector
        );

        token.disperseTokens(testRecipients, testAmounts);
    }
}
