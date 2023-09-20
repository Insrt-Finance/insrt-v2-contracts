// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title Token_claim
/// @dev Token test contract for testing expected claim behavior. Tested on an Arbitrum fork.
contract Token_claim is ArbForkTest, TokenTest {
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

    /// @dev ensures that claim accrues tokens of account that is claiming
    function test_claimAccruesTokensForAccountAndThenSetsAccruedTokensToZero()
        public
    {
        uint256 claimableTokens = DISTRIBUTION_AMOUNT;

        uint256 oldDistributionSupply = token.distributionSupply();
        uint256 globalRatio = token.globalRatio();

        vm.prank(MINTER);
        token.claim();

        uint256 newDistributionSupply = token.distributionSupply();
        uint256 newAccruedTokens = token.accrualData(MINTER).accruedTokens;

        assert(
            oldDistributionSupply - newDistributionSupply >= claimableTokens - 1
        );
        assert(globalRatio == token.accrualData(MINTER).offset);

        assert(newAccruedTokens == 0);
    }

    /// @dev ensures that claim transfers all claimable tokens to account
    function test_claimAccruesTransfersClaimableTokensToAccount() public {
        uint256 claimableTokens = token.claimableTokens(MINTER);

        uint256 oldBalance = token.balanceOf(MINTER);
        vm.prank(MINTER);
        token.claim();

        uint256 newBalance = token.balanceOf(MINTER);

        assert(newBalance - oldBalance == claimableTokens);
    }
}
