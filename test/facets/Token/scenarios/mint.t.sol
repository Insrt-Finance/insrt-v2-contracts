// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// TODO: add scenario where distributionFractionBP changes
/// @title Token_mint
/// @dev Token test contract for testing expected mint behavior. Tested on an Arbitrum fork.
contract Token_mint is ArbForkTest, TokenTest {
    address internal constant RECEIVER_ONE = address(1001);
    address internal constant RECEIVER_TWO = address(1002);

    /// @dev sets up the testing environment
    function setUp() public override {
        super.setUp();
    }

    /// @dev ensures that throughout a series of actions the $MINT tokens are distributed correctly
    /// amongst the participants of the system
    /// the sequence of actions is:
    /// - MINTER mints
    /// - RECEIVER_ONE mints
    /// - RECEIVER_TWO mints
    /// - MINTER claims
    /// - RECEIVER_ONE mints
    /// - MINTER burns
    /// - RECEIVER_TWO mints
    /// each of the actions listed above affect token accruals and future distributions so
    /// after each action, the division of the distributed tokens is checked
    function test_accountingOfAccruedTokensWithMultipleReceiversAcrossMultipleActions()
        public
    {
        // mint for MINTER
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        // since only one holder (MINTER), all of the MINT_AMOUNT should belong to them
        // ± 1 error range due to rounding
        assert(
            MINT_AMOUNT + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        assert(
            MINT_AMOUNT - 1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // mint for RECEIVER_ONE
        vm.prank(MINTER);
        token.mint(RECEIVER_ONE, MINT_AMOUNT);

        // second holder (RECEIVER_ONE) should be entitled to the minted amount minus whatever
        // amount is kept for distribution
        assert(
            MINT_AMOUNT - DISTRIBUTION_AMOUNT ==
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );

        // first holder (MINTER) is entitled to the full amount of RECEIVE_ONE's distributionAmount, so should have
        // their own MINT_AMOUNT + DISTRIBUTION_AMOUNT
        // ± 1 error range due to rounding
        assert(
            MINT_AMOUNT + DISTRIBUTION_AMOUNT + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );
        assert(
            MINT_AMOUNT + DISTRIBUTION_AMOUNT - 1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // mint for RECEIVER_TWO
        vm.prank(MINTER);
        token.mint(RECEIVER_TWO, MINT_AMOUNT);

        // third holder (RECEIVER_TWO) is entitled to the minted amount minus whatever
        // amount is kept for distribution
        assert(
            MINT_AMOUNT - DISTRIBUTION_AMOUNT ==
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );

        // second holder (RECEIVER_ONE) is entitled to 1/2 of the DISTRIBUTION_AMOUNT contributed by RECEIVE_TWO since
        // they own 1/2 of the total supply - distirbution supply
        // ± 1 error range due to rounding
        assert(
            MINT_AMOUNT - (DISTRIBUTION_AMOUNT / 2) + 1 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );
        assert(
            MINT_AMOUNT - (DISTRIBUTION_AMOUNT / 2) - 1 <=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );

        // first holder (MINTER) is entitled to 1/2 of the DISTRIBUTION_AMOUNT contributed by RECEIVE_TWO since
        // they own 1/2 of the total supply - distirbution supply, as well as what they were entitled previously
        // ± 1 error range due to rounding
        assert(
            MINT_AMOUNT + ((DISTRIBUTION_AMOUNT * 3) / 2) + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );
        assert(
            MINT_AMOUNT + ((DISTRIBUTION_AMOUNT * 3) / 2) - 1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // claim for MINTER
        vm.prank(MINTER);
        token.claim();

        // after MINTER has claimed, the amount they are owed from the distribution supply, which is
        // (DISTRIBUTION_AMOUNT * 3 / 2) should be transferred to them
        assert(
            MINT_AMOUNT + ((DISTRIBUTION_AMOUNT * 3) / 2) + 1 >=
                token.balanceOf(MINTER)
        );
        assert(
            MINT_AMOUNT + ((DISTRIBUTION_AMOUNT * 3) / 2) - 1 <=
                token.balanceOf(MINTER)
        );

        // mint second time for RECEIVER_ONE
        vm.prank(MINTER);
        token.mint(RECEIVER_ONE, MINT_AMOUNT);

        // receiver one is not entitled to any portion of their newly contributed distributionAmount,
        // so their token claims should remain the same, whilst their balance should increase by MINT_AMOUNT - DISTRIBUTION_AMOUNT
        // ± 1 error range due to rounding
        assert(
            2 * MINT_AMOUNT - ((DISTRIBUTION_AMOUNT * 3) / 2) + 1 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );
        assert(
            2 * MINT_AMOUNT - ((DISTRIBUTION_AMOUNT * 3) / 2) - 1 <=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );

        // MINTER has MINT_AMOUNT + 3 / 2 * DISTRIBUTION_AMOUNT of tokens after the claim, whilst
        // RECEIVER_TWO has MINT_AMOUNT - DISTRIBUTION_AMOUNT of tokens
        // it follows that MINTER is entitled to ( MINT_AMOUNT + 3 / 2 * DISTRIBUTION_AMOUNT) / (2 * MINT_AMOUNT + DISTRIBUTION_AMOUNT / 2)
        // of the new distributionAmount contributed by RECEIVER_ONE
        // ± 1 error range due to rounding
        uint256 minterShareOfFourthMint = ((MINT_AMOUNT +
            (DISTRIBUTION_AMOUNT * 3) /
            2) * DISTRIBUTION_AMOUNT) /
            (2 * MINT_AMOUNT + DISTRIBUTION_AMOUNT / 2);

        assert(
            MINT_AMOUNT +
                ((DISTRIBUTION_AMOUNT * 3) / 2) +
                minterShareOfFourthMint +
                1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );
        assert(
            MINT_AMOUNT +
                ((DISTRIBUTION_AMOUNT * 3) / 2) +
                minterShareOfFourthMint -
                1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // RECEIVER_TWO has MINT_AMOUNT - DISTRIBUTION_AMOUNT of their mint
        // it follows that RECEIVER_TWO is entitled to ((MINT_AMOUNT - DISTRIBUTION_AMOUNT) * DISTRIBUTION_AMOUNT) / (2 * MINT_AMOUNT + DISTRIBUTION_AMOUNT / 2)
        // of the new distributionAmount contributed by RECEIVER_ONE
        // ± 1 error range due to rounding
        assert(
            MINT_AMOUNT - minterShareOfFourthMint + 1 >=
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );
        assert(
            MINT_AMOUNT - minterShareOfFourthMint - 1 <=
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );

        // burn balance of MINTER tokens
        vm.startPrank(MINTER); //refresh Foundry memory
        token.burn(MINTER, token.balanceOf(MINTER));

        // MINTER should only be entitled to minterShareOfFourthMint since all of their balance
        // was burnt
        assert(
            minterShareOfFourthMint + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        assert(
            minterShareOfFourthMint - 1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // mint to RECEIVER_TWO
        token.mint(RECEIVER_TWO, MINT_AMOUNT);

        // since MINTER burned all of their tokens, they should only be entitled to their previously
        // unclaimed tokens, which is minterShareOfFourthMint
        // ± 1 error range due to rounding
        assert(
            minterShareOfFourthMint + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        assert(
            minterShareOfFourthMint - 1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // since RECEIVER_TWO is not entitled to any of the DISTRIBUTION_AMOUNT contributed by them,
        // RECEIVER_ONE is entitled to all of it
        // RECEIVER_ONE has minted twice, so they have received (MINT_AMOUNT - DISTRIBUTION_AMOUNT) * 2
        // and were entitled to claim DISTRIBUTION_AMOUNT / 2 from the first mint of RECEIVER_TWO
        // therefore the overall balance of RECEIVER_ONE should be
        // 2 * MINT_AMOUNT - 1/2 DISTRIBUTION_AMOUNT
        //  ± 3 error range due to rounding
        assert(
            2 * MINT_AMOUNT - (DISTRIBUTION_AMOUNT / 2) + 3 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );
        assert(
            2 * MINT_AMOUNT - (DISTRIBUTION_AMOUNT / 2) - 3 <=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );
    }

    /// @dev ensures that when a single user is the holder of all the tokens, they are entitled to the entire
    /// distribution of tokens
    /// this situation can occur either when a minter is minting for the first time or when all other token
    /// holders have burnt their tokens and a single user is left
    /// the sequence of actions is:
    /// - MINTER mints
    /// - MINTER mints
    /// - RECEIVER_ONE mints
    /// - RECEIVER_ONE claims
    /// - RECEIVER_ONE burns
    /// - MINTER mints
    /// - RECEIVER_ONE mints
    /// - RECEIVER_ONE claims
    /// - RECEIVER_ONE burns
    /// - MINTER mints
    /// each of the actions listed above affect token accruals and future distributions so
    /// after each action, the division of the distributed tokens is checked
    function test_trackingOfClaimableTokensWithSingleUser() public {
        // mint for MINTER
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        // since only one holder (MINTER), all of the MINT_AMOUNT should belong to them
        // ± 1 error range due to rounding
        assert(
            MINT_AMOUNT + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        assert(
            MINT_AMOUNT - 1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // mint for MINTER
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        // since only one holder (MINTER), all of the MINT_AMOUNT should belong to them
        // ± 2 error range due to rounding
        assert(
            2 * MINT_AMOUNT + 2 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        assert(
            2 * MINT_AMOUNT - 2 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // mint for RECEIVER_ONE
        vm.prank(MINTER);
        token.mint(RECEIVER_ONE, MINT_AMOUNT);

        // claim for RECEIVER_ONE
        vm.prank(RECEIVER_ONE);
        token.claim();

        // burn all RECEIVER_ONE tokens
        vm.startPrank(MINTER);
        token.burn(RECEIVER_ONE, token.balanceOf(RECEIVER_ONE));

        // mint for MINTER
        vm.startPrank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        // MINTER has done 3 mints which should solely belong to them, and is also entitled
        // to DISTRIBUTION_AMOUNT from the RECEIVER_ONE mint
        // ± 3 error range due to rounding
        assert(
            3 * MINT_AMOUNT + DISTRIBUTION_AMOUNT + 3 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        assert(
            3 * MINT_AMOUNT + DISTRIBUTION_AMOUNT - 3 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // mint for RECEIVER_ONE
        token.mint(RECEIVER_ONE, MINT_AMOUNT);

        // claim for RECEIVER_ONE
        vm.startPrank(RECEIVER_ONE);
        token.claim();

        // burn all RECEIVER_ONE tokens
        vm.startPrank(MINTER);
        token.burn(RECEIVER_ONE, token.balanceOf(RECEIVER_ONE));

        // mint for MINTER
        token.mint(MINTER, MINT_AMOUNT);

        // MINTER has done 4 mints which should solely belong to them, and is also entitled
        // to 2 * DISTRIBUTION_AMOUNT from the RECEIVER_ONE mint
        // ± 3 error range due to rounding
        assert(
            4 * MINT_AMOUNT + 2 * DISTRIBUTION_AMOUNT + 3 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        assert(
            4 * MINT_AMOUNT + DISTRIBUTION_AMOUNT - 3 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );
    }
}
