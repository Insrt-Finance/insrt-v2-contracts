// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenInternal } from "../../../../contracts/facets/Token/ITokenInternal.sol";

/// @title Token_mintReferral
/// @dev Token test contract for testing expected mintReferral behavior. Tested on an Arbitrum fork.
contract Token_mintReferral is ArbForkTest, TokenTest {
    /// @dev amount of $MINT to mint as a referral reward
    uint256 internal constant REFERRAL_MINT_AMOUNT = 10 ether;

    /// @dev address to mint referral reward to
    address internal constant REFERRER = address(0xdeadbeef);

    /// @dev tests mintReferral successfully mints tokens to token contract
    function test_mintReferral() external {
        vm.prank(MINTER);
        token.mintReferral(REFERRER, REFERRAL_MINT_AMOUNT);

        // assert that the token contract has minted all the referral tokens
        assert(token.balanceOf(REFERRER) == REFERRAL_MINT_AMOUNT);
    }

    /// @dev tests that mintReferral keeps the globalRatio and distributionSupply the same
    function test_mintReferralKeepsGlobalRatioDistributionSupplySame()
        external
    {
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        uint256 oldGlobalRatio = token.globalRatio();
        uint256 oldDistributionSupply = token.distributionSupply();

        vm.prank(MINTER);
        token.mintReferral(REFERRER, REFERRAL_MINT_AMOUNT);

        uint256 newGlobalRatio = token.globalRatio();
        uint256 newDistributionSupply = token.distributionSupply();

        assert(oldGlobalRatio == newGlobalRatio);
        assert(oldDistributionSupply == newDistributionSupply);
    }

    /// @dev tests that mintReferral increases totalSupply by referral mint amount
    function test_mintReferralIncreasesAirdropSupply() external {
        uint256 oldTotalSupply = token.totalSupply();

        vm.prank(MINTER);
        token.mintReferral(REFERRER, REFERRAL_MINT_AMOUNT);

        uint256 newTotalSupply = token.totalSupply();

        assert(newTotalSupply - oldTotalSupply == REFERRAL_MINT_AMOUNT);
    }

    /// @dev tests that mintReferral reverts when called by non-mintingContract
    function test_mintReferralRevertsWhen_CallerIsNotMintingContract()
        external
    {
        vm.expectRevert(ITokenInternal.NotMintingContract.selector);

        vm.prank(TOKEN_NON_OWNER);
        token.mintReferral(REFERRER, REFERRAL_MINT_AMOUNT);
    }
}
