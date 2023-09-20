// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title Token_accrueTokens
/// @dev Token test contract for testing expected accrueToken behavior. Tested on an Arbitrum fork.
contract Token_accrueTokens is ArbForkTest, TokenTest {
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

    /// @dev ensures that accrueTokens updates the account offset of the account accruing tokens to the globalRatio
    function test_accrueTokensSetsAccountOffsetToGlobalRatio() public {
        uint256 globalRatio = token.globalRatio();

        token.exposed_accrueTokens(MINTER);

        assert(globalRatio == token.accrualData(MINTER).offset);
    }

    /// @dev ensures that accrueTokens increases the accrued tokens of the account accruing tokens
    function test_accrueTokensIncreasesAccruedTokens() public {
        uint256 oldAccruedTokens = token.accrualData(MINTER).accruedTokens;

        token.exposed_accrueTokens(MINTER);

        uint256 newAccruedTokens = token.accrualData(MINTER).accruedTokens;
        assert(newAccruedTokens - oldAccruedTokens >= DISTRIBUTION_AMOUNT - 1);
    }
}
