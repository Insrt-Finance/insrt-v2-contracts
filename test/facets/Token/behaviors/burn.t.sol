// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title Token_burn
/// @dev Token test contract for testing expected burn behavior. Tested on an Arbitrum fork.
contract Token_burn is ArbForkTest, TokenTest {
    uint256 internal constant BURN_AMOUNT = 0.1 ether;

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

    /// @dev ensures that burn accrues tokens of account that is having its tokens burnt
    function test_burnAccruesTokensForAccount() public {
        uint256 globalRatio = token.globalRatio();
        uint256 oldAccruedTokens = token.accrualData(MINTER).accruedTokens;

        vm.prank(MINTER);
        token.burn(MINTER, BURN_AMOUNT);

        uint256 newAccruedTokens = token.accrualData(MINTER).accruedTokens;

        assert(globalRatio == token.accrualData(MINTER).offset);
        assert(newAccruedTokens - oldAccruedTokens >= DISTRIBUTION_AMOUNT - 1);
    }

    /// @dev ensures that burn reduces the total supply and balance of account of the token
    function test_burnReducesSupplyAndBalanceOfAccountOfToken() public {
        uint256 oldSupply = token.totalSupply();
        uint256 oldBalance = token.balanceOf(MINTER);

        vm.prank(MINTER);
        token.burn(MINTER, BURN_AMOUNT);

        uint256 newSupply = token.totalSupply();
        uint256 newBalance = token.balanceOf(MINTER);

        assert(oldSupply - newSupply == BURN_AMOUNT);
        assert(oldBalance - newBalance == BURN_AMOUNT);
    }
}
