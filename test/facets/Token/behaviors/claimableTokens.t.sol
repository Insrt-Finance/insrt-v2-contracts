// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title Token_claimableTokens
/// @dev Token test contract for testing expected claimableTokens behavior. Tested on an Arbitrum fork.
contract Token_claimableTokens is ArbForkTest, TokenTest {
    uint256 internal constant DISTRIBUTION_AMOUNT =
        (MINT_AMOUNT * DISTRIBUTION_FRACTION_BP) / BASIS;

    /// @dev sets up the testing environment
    function setUp() public override {
        super.setUp();

        // mints token to minter
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        assert(token.balanceOf(MINTER) == MINT_AMOUNT - DISTRIBUTION_AMOUNT);

        assert(token.distributionSupply() == DISTRIBUTION_AMOUNT);

        assert(token.accrualData(MINTER).offset == 0);

        assert(
            token.globalRatio() ==
                (SCALE * DISTRIBUTION_AMOUNT) /
                    (MINT_AMOUNT - DISTRIBUTION_AMOUNT)
        );
    }

    /// @dev ensures that claimableTokens returns sum of accrued tokens and tokens which have
    /// yet to be accrued
    function test_claimableTokensReturnsSumOfAccruedTokensAndTokensYetToBeAccrued()
        public
        view
    {
        uint256 expectedClaimableTokens = DISTRIBUTION_AMOUNT;

        uint256 actualClaimableTokens = token.claimableTokens(MINTER);

        assert(actualClaimableTokens <= expectedClaimableTokens - 1);
    }
}
