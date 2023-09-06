// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title Token_mint
/// @dev Token test contract for testing expected mint behavior. Tested on an Arbitrum fork.
contract Token_mint is ArbForkTest, TokenTest {
    address internal constant RECEIVER = address(2);

    uint256 internal constant DISTRIBUTION_AMOUNT =
        (MINT_AMOUNT * DISTRIBUTION_FRACTION_BP) / BASIS;

    /// @dev sets up the testing environment
    function setUp() public override {
        super.setUp();
    }

    /// @dev ensures that mint, when there are more than 1 token holders, updates the global ratio based on
    /// the difference in total and distribution supplies
    function test_mintUpdatesGlobalRatioByDistributionAmountOverSupplyDeltaWhenMoreThanOneTokenHolder()
        public
    {
        uint256 globalRatio = token.globalRatio();
        uint256 expectedRatio;
        assert(globalRatio == expectedRatio);

        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        globalRatio = token.globalRatio();

        expectedRatio +=
            (DISTRIBUTION_AMOUNT * SCALE) /
            (MINT_AMOUNT - DISTRIBUTION_AMOUNT);
        assert(globalRatio == expectedRatio);

        expectedRatio +=
            (DISTRIBUTION_AMOUNT * SCALE) /
            (token.totalSupply() - token.distributionSupply());

        vm.prank(MINTER);
        token.mint(RECEIVER, MINT_AMOUNT);

        globalRatio = token.globalRatio();

        assert(globalRatio == expectedRatio);
    }

    /// @dev ensures that mint, when there are more than 1 token holders, updates the offset of the account receiving the
    /// minted tokens
    function test_mintSetsReceiverOffsetToGlobalRatioWhenMoreThanOneTokenHolder()
        public
    {
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        uint256 accountOffset = token.accountOffset(RECEIVER);
        assert(accountOffset == 0);

        vm.prank(MINTER);
        token.mint(RECEIVER, MINT_AMOUNT);

        uint256 globalRatio = token.globalRatio();
        accountOffset = token.accountOffset(RECEIVER);

        assert(globalRatio == accountOffset);
    }

    /// @dev ensures that mint, when there is 1 token holder, updates the global ratio based on
    /// the amount being minted
    function test_mintUpdatesGlobalRatioByDistributionAmountOverMintAmountIfFirstMintOrOnleSingleTokenHolderMinting()
        public
    {
        uint256 globalRatio = token.globalRatio();

        assert(globalRatio == 0);

        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        globalRatio = token.globalRatio();

        assert(
            globalRatio ==
                (DISTRIBUTION_AMOUNT * SCALE) /
                    (MINT_AMOUNT - DISTRIBUTION_AMOUNT)
        );

        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        globalRatio = token.globalRatio();

        assert(
            globalRatio ==
                ((DISTRIBUTION_AMOUNT * SCALE) /
                    (MINT_AMOUNT - DISTRIBUTION_AMOUNT)) *
                    2
        );
    }

    /// @dev ensures that mint increases the distribution supply by the distribution amount
    function test_mintIncreasesDistributionSupplyByDistributionAmount() public {
        uint256 oldDistributionSupply = token.distributionSupply();

        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        uint256 newDistributionSupply = token.distributionSupply();

        assert(
            newDistributionSupply - oldDistributionSupply == DISTRIBUTION_AMOUNT
        );
    }

    /// @dev ensures that mint mints a distributionAmount of tokens to token contract
    function test_mintMintsDistributionAmountOfTokensToTokenContract() public {
        uint256 oldBalance = token.balanceOf(address(token));

        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        uint256 newBalance = token.balanceOf(address(token));

        assert(newBalance - oldBalance == DISTRIBUTION_AMOUNT);
    }

    /// @dev ensures that mint mints a minted amount - distributionAmount of tokens to receiver
    function test_mintMintsAmountMinusDistributionAmountOfTokensToMinter()
        public
    {
        uint256 oldBalance = token.balanceOf(MINTER);

        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        uint256 newBalance = token.balanceOf(MINTER);

        assert(newBalance - oldBalance == MINT_AMOUNT - DISTRIBUTION_AMOUNT);
    }
}
