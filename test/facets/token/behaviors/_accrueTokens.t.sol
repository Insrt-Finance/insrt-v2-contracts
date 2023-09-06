// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title Token_accrueTokens
/// @dev Token test contract for testing expected accrueToken behavior. Tested on an Arbitrum fork.
contract Token_accrueTokens is ArbForkTest, TokenTest {
    uint256 internal constant DISTRIBUTION_AMOUNT =
        (MINT_AMOUNT * DISTRIBUTION_FRACTION_BP) / BASIS;

    /// @dev sets up the testing environment
    function setUp() public override {
        super.setUp();

        // mint stoken to minter
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        assert(token.balanceOf(MINTER) == MINT_AMOUNT - DISTRIBUTION_AMOUNT);

        assert(token.distributionSupply() == DISTRIBUTION_AMOUNT);

        assert(token.accountOffset(MINTER) == 0);

        assert(
            token.globalRatio() ==
                (SCALE * DISTRIBUTION_AMOUNT) /
                    (MINT_AMOUNT - DISTRIBUTION_AMOUNT)
        );
    }

    /// @dev ensures that accrueTokens decreases the distribution supply by the accrued token amount
    function test_accrueTokensDecreasesDistributionSupply() public {
        uint256 claimableTokens = DISTRIBUTION_AMOUNT;

        uint256 oldDistributionSupply = token.distributionSupply();

        token.exposed_accrueTokens(MINTER);

        uint256 newDistributionSupply = token.distributionSupply();

        assert(
            oldDistributionSupply - newDistributionSupply >= claimableTokens - 1
        );
    }

    /// @dev ensures that accrueTokens updates the account offset of the account accruing tokens to the globalRatio
    function test_accrueTokensSetsAccountOffsetToGlobalRatio() public {
        uint256 globalRatio = token.globalRatio();

        token.exposed_accrueTokens(MINTER);

        assert(globalRatio == token.accountOffset(MINTER));
    }

    /// @dev ensures that accrueTokens increases the accrued tokens of the account accruing tokens
    function test_accrueTokensIncreasesAccruedTokens() public {
        uint256 oldAccruedTokens = token.accruedTokens(MINTER);

        token.exposed_accrueTokens(MINTER);

        uint256 newAccruedTokens = token.accruedTokens(MINTER);
        assert(newAccruedTokens - oldAccruedTokens <= DISTRIBUTION_AMOUNT - 1);
    }
}
