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

        uint256 userBalance = token.balanceOf(MINTER);
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        globalRatio = token.globalRatio();

        expectedRatio +=
            (DISTRIBUTION_AMOUNT * SCALE) /
            (MINT_AMOUNT - DISTRIBUTION_AMOUNT - userBalance);

        assert(globalRatio == expectedRatio);

        userBalance = token.balanceOf(RECEIVER);

        expectedRatio +=
            (DISTRIBUTION_AMOUNT * SCALE) /
            (token.totalSupply() - token.distributionSupply() - userBalance);

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

        uint256 accountOffset = token.accrualData(RECEIVER).offset;
        assert(accountOffset == 0);

        vm.prank(MINTER);
        token.mint(RECEIVER, MINT_AMOUNT);

        uint256 globalRatio = token.globalRatio();
        accountOffset = token.accrualData(RECEIVER).offset;

        assert(globalRatio == accountOffset);
    }

    /// @dev ensures that mint, when there are more than 1 token holders, updates the accruedTokens of the account receiving the
    /// minted tokens
    function test_mintIncreasesAccountAccruedTokensWhenMoreThanOneTokenHolder()
        public
    {
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        vm.prank(MINTER);
        token.mint(RECEIVER, MINT_AMOUNT);

        uint256 oldAccruedTokens = token.accrualData(MINTER).accruedTokens;

        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        uint256 newAccruedTokens = token.accrualData(MINTER).accruedTokens;
        uint256 expectedAccruedTokens = 2 * DISTRIBUTION_AMOUNT;

        assert(
            newAccruedTokens - oldAccruedTokens + 1 >= expectedAccruedTokens
        );
        assert(
            newAccruedTokens - oldAccruedTokens - 1 <= expectedAccruedTokens
        );
    }

    /// @dev ensures that mint, when the only token holder is the first minter, updates
    /// the global ratio based on the amount being minted
    function test_mintUpdatesGlobalRatioByDistributionRatioIfOnlyFirstMinterMinting()
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

    /// @dev ensures mint, when the only token holder is the first minter, sets the account offset of the minter to
    /// the globalRatio minus the distributionRatio
    function test_mintUpdatesAccountOffsetToGlobalRatioMinusDistributionRatioIfOnlyFirstMinterMinting()
        public
    {
        uint256 globalRatio = token.globalRatio();
        uint256 distributionRatio = (SCALE * DISTRIBUTION_AMOUNT) /
            (MINT_AMOUNT - DISTRIBUTION_AMOUNT);

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
            token.accrualData(MINTER).offset == globalRatio - distributionRatio
        );
    }

    /// @dev ensures mint, when there is a single token holder who is _not_ the first mint,
    /// increases accrued tokens of the account minting
    function test_mintIncreasesAccruedTokensOfAccountByDistributionAmountAndPreviousAccrualsWhenOnlySingleTokenHolder()
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
        token.mint(RECEIVER, MINT_AMOUNT);

        // at this point RECEIVER is entitled to DISTRIBUTION_AMOUNT of tokens
        // since they are the only other token holder
        vm.startPrank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        token.mint(RECEIVER, MINT_AMOUNT);

        // remove all of MINTER's tokens
        token.claim();

        token.burn(MINTER, token.balanceOf(MINTER));

        token.mint(RECEIVER, MINT_AMOUNT);

        // RECEIVER is now entitled to 2 * DISTRIBUTION_AMOUNT of tokens
        // since they are entitled to the full DISTRIBUTION_AMOUNT they
        // contributed
        assert(
            2 * DISTRIBUTION_AMOUNT + 1 >=
                token.accrualData(RECEIVER).accruedTokens
        );
        assert(
            2 * DISTRIBUTION_AMOUNT - 1 <=
                token.accrualData(RECEIVER).accruedTokens
        );
    }

    /// @dev ensures mint, when there is a single token holder who is _not_ the first mint,
    /// increases globalRatio by the distributionRatio
    function test_mintIncreasesGlobalRatioByDistributionRatioWhenOnlySingleTokenHolder()
        public
    {
        uint256 globalRatio = token.globalRatio();
        uint256 distributionRatio = (DISTRIBUTION_AMOUNT * SCALE) /
            (MINT_AMOUNT - DISTRIBUTION_AMOUNT);

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
        token.mint(RECEIVER, MINT_AMOUNT);

        // at this point RECEIVER is entitled to DISTRIBUTION_AMOUNT of tokens
        // since they are the only other token holder
        vm.startPrank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        token.mint(RECEIVER, MINT_AMOUNT);

        // remove all of MINTER's tokens
        token.claim();

        token.burn(MINTER, token.balanceOf(MINTER));

        uint256 oldGlobalRatio = token.globalRatio();

        token.mint(RECEIVER, MINT_AMOUNT);

        uint256 newGlobalRatio = token.globalRatio();

        assert(newGlobalRatio - oldGlobalRatio == distributionRatio);
    }

    /// @dev ensures mint, when there is a single token holder who is _not_ the first mint,
    /// sets accountOffset of minter to globalRatio
    function test_mintUpdatesAccountOffsetOfToGlobalRatioWhenOnlySingleTokenHolder()
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
        token.mint(RECEIVER, MINT_AMOUNT);

        // at this point RECEIVER is entitled to DISTRIBUTION_AMOUNT of tokens
        // since they are the only other token holder
        vm.startPrank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        token.mint(RECEIVER, MINT_AMOUNT);

        // remove all of MINTER's tokens
        token.claim();

        token.burn(MINTER, token.balanceOf(MINTER));

        token.mint(RECEIVER, MINT_AMOUNT);

        assert(token.accrualData(RECEIVER).offset == token.globalRatio());
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
