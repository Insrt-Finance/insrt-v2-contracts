// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPausableInternal } from "@solidstate/contracts/security/pausable/IPausableInternal.sol";

import { PerpetualMintTest_SupraBlast } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../../../Token/Token.t.sol";
import { BlastForkTest } from "../../../../../BlastForkTest.t.sol";
import { CoreTest } from "../../../../../diamonds/Core/Core.t.sol";
import { TokenProxyTest } from "../../../../../diamonds/TokenProxy.t.sol";
import { IPerpetualMintInternal } from "../../../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_attemptBatchMintForMintWithMintSupraBlast
/// @dev PerpetualMint_SupraBlast test contract for testing expected attemptBatchMintForMintWithMint behavior. Tested on a Blast fork.
contract PerpetualMint_attemptBatchMintForMintWithMintSupraBlast is
    BlastForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest_SupraBlast,
    TokenTest
{
    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev for now, mints for $MINT are treated as address(0) collections
    address COLLECTION = address(0);

    // /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest_SupraBlast, TokenTest) {
        PerpetualMintTest_SupraBlast.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        perpetualMint.setConsolationFees(100 ether);

        token.addMintingContract(address(perpetualMint));

        // mint a bunch of tokens to minter
        vm.prank(MINTER);
        token.mint(minter, MINT_AMOUNT * 1e10);

        // get the mint price for $MINT
        MINT_PRICE = perpetualMint.collectionMintPrice(COLLECTION);
    }

    /// @dev Tests attemptBatchMintForMintWithMint functionality when paying the full set $MINT mint price.
    function test_attemptBatchMintForMintWithMintWithFullMintPrice() external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(MINT_PRICE == perpetualMint.collectionMintPrice(COLLECTION));

        uint256 preMintTokenBalance = token.balanceOf(minter);

        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedMintTokenConsolationFee = (expectedEthRequired *
            perpetualMint.mintTokenConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedMintTokenConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        // the difference between the expected ETH required and the $MINT consolation fee is the protocol fee
        uint256 expectedMintFee = expectedEthRequired -
            expectedMintTokenConsolationFee;

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        // asert that depositor earnings have not been updated on mints for $MINT
        assert(postMintAccruedMintEarnings == 0);

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests attemptBatchMintForMintWithMint functionality when paying a multiple of the set $MINT mint price.
    function test_attemptBatchMintForMintWithMintWithMoreThanMintPrice()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintTokenBalance = token.balanceOf(minter);

        // pay 10 times the $MINT mint price per spin
        MINT_PRICE = MINT_PRICE * 10;

        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedMintTokenConsolationFee = (expectedEthRequired *
            perpetualMint.mintTokenConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedMintTokenConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        // the difference between the expected ETH required and the $MINT consolation fee is the protocol fee
        uint256 expectedMintFee = expectedEthRequired -
            expectedMintTokenConsolationFee;

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        // asert that depositor earnings have not been updated on mints for $MINT
        assert(postMintAccruedMintEarnings == 0);

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests attemptBatchMintForMintWithMint functionality when paying a fraction of the set $MINT mint price.
    function test_attemptBatchMintForMintWithMintWithPartialMintPrice()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintTokenBalance = token.balanceOf(minter);

        // pay 1/10th of the $MINT mint price per spin
        MINT_PRICE = MINT_PRICE / 10;

        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedMintTokenConsolationFee = (expectedEthRequired *
            perpetualMint.mintTokenConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedMintTokenConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        // the difference between the expected ETH required and the $MINT consolation fee is the protocol fee
        uint256 expectedMintFee = expectedEthRequired -
            expectedMintTokenConsolationFee;

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        // asert that depositor earnings have not been updated on mints for $MINT
        assert(postMintAccruedMintEarnings == 0);

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests attemptBatchMintForMintWithMint functionality when a referrer address is passed.
    function test_attemptBatchMintForMintWithMintWithReferrer() external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintMinterTokenBalance = token.balanceOf(minter);

        uint256 preMintReferrerTokenBalance = token.balanceOf(REFERRER);

        assert(preMintReferrerTokenBalance == 0);

        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedMintTokenConsolationFee = (expectedEthRequired *
            perpetualMint.mintTokenConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedMintTokenConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        // the difference between the expected ETH required and the $MINT consolation fee is the protocol fee
        uint256 expectedMintFee = expectedEthRequired -
            expectedMintTokenConsolationFee;

        uint256 expectedMintReferralFee = (expectedMintFee *
            perpetualMint.defaultCollectionReferralFeeBP()) /
            perpetualMint.BASIS();

        assert(
            postMintAccruedProtocolFees ==
                expectedMintFee - expectedMintReferralFee
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        // asert that depositor earnings have not been updated on mints for $MINT
        assert(postMintAccruedMintEarnings == 0);

        uint256 postMintMinterTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintMinterTokenBalance ==
                preMintMinterTokenBalance - expectedMintTokenBurned
        );

        uint256 postMintReferrerTokenBalance = token.balanceOf(REFERRER);

        assert(
            postMintReferrerTokenBalance ==
                expectedMintReferralFee * currentEthToMintRatio
        );
    }

    /// @dev Tests that attemptBatchMintForMintWithMint functionality reverts when attempting to mint with an invalid fractional price per mint.
    function test_attemptBatchMintFoeMintWithMintRevertsWhen_AttemptingToMintWithInvalidPricePerMint()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.InvalidPricePerMint.selector);

        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            1 ether + 1, // 1 $MINT + 1 wei (dust)
            TEST_MINT_ATTEMPTS
        );
    }

    /// @dev Tests that attemptBatchMintForMintWithMint functionality reverts when attempting to mint with less than MINIMUM_PRICE_PER_SPIN.
    function test_attemptBatchMintForMintWithMintRevertsWhen_AttemptingToMintForLessThanMinimumPricePerSpin()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.PricePerSpinTooLow.selector);

        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            1 ether - 1, // less than 1 $MINT
            TEST_MINT_ATTEMPTS
        );
    }

    /// @dev Tests that attemptBatchMintForMintWithMint functionality reverts when attempting zero mints.
    function test_attemptBatchMintForMintWithMintRevertsWhen_AttemptingZeroMints()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        vm.expectRevert(IPerpetualMintInternal.InvalidNumberOfMints.selector);

        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            ZERO_MINT_ATTEMPTS
        );
    }

    /// @dev Tests that attemptBatchMintForMintWithMint functionality reverts when the contract is paused.
    function test_attemptBatchMintForMintWithMintRevertsWhen_PausedStateIsTrue()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        perpetualMint.pause();
        vm.expectRevert(IPausableInternal.Pausable__Paused.selector);

        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );
    }
}
