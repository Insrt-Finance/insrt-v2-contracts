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
        token.mintAirdrop(MINT_AMOUNT);

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

    /// @dev tests disperseTokens updates accruedTokens and offset of account receiving tokens
    function test_disperseTokensUpdatesAccrualDataOfRecipient() external {
        // mint some tokens to first test recipient so they are able to claim something
        vm.prank(MINTER);
        token.mint(testRecipients[0], MINT_AMOUNT);

        uint256 DISTRIBUTION_AMOUNT = (MINT_AMOUNT *
            token.distributionFractionBP()) / token.BASIS();

        uint256 oldGlobalRatio = token.globalRatio();

        token.disperseTokens(testRecipients, testAmounts);

        for (uint256 i; i < testRecipients.length; ++i) {
            assert(
                token.accrualData(testRecipients[i]).offset == oldGlobalRatio
            );
            if (i == 0) {
                assert(
                    token.accrualData(testRecipients[i]).accruedTokens + 1 >=
                        DISTRIBUTION_AMOUNT
                );
            } else {
                assert(
                    token.accrualData(testRecipients[i]).accruedTokens + 1 >= 0
                );
            }
        }
    }

    /// @dev tests disperseTokens decreases aridropSupply by total amount of $MINT distributed
    function test_disperseTokensIncreasesAirdropSupplyByTokensDispersed()
        external
    {
        uint256 airdropAmount;

        for (uint256 i; i < testRecipients.length; ++i) {
            airdropAmount += testAmounts[i];
        }

        uint256 oldAirdropSupply = token.airdropSupply();
        token.disperseTokens(testRecipients, testAmounts);

        uint256 newAirdropSupply = token.airdropSupply();

        assert(oldAirdropSupply - newAirdropSupply == airdropAmount);
    }

    /// @dev tests that disperseTokens reverts when called by non-owner
    function test_disperseTokensRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(TOKEN_NON_OWNER);
        token.disperseTokens(testRecipients, testAmounts);
    }

    /// @dev tests that disperseTokens reverts when token contract does not have enough
    /// balance to send out full amount of dispersed tokens
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
