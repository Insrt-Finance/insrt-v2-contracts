// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPausableInternal } from "@solidstate/contracts/security/pausable/IPausableInternal.sol";

import { PerpetualMintTest_Base } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../../Token/Token.t.sol";
import { BaseForkTest } from "../../../../BaseForkTest.t.sol";
import { CoreTest } from "../../../../diamonds/Core/Core.t.sol";
import { TokenProxyTest } from "../../../../diamonds/TokenProxy.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_attemptBatchMintForEthWithMintBase
/// @dev PerpetualMint_Base test contract for testing expected attemptBatchMintForEthWithMint behavior. Tested on a Base fork.
contract PerpetualMint_attemptBatchMintForEthWithMintBase is
    BaseForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest_Base,
    TokenTest
{
    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev collection to test
    address COLLECTION = ETH_COLLECTION_ADDRESS;

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest_Base, TokenTest) {
        PerpetualMintTest_Base.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        // get the mint price for ETH
        MINT_PRICE = perpetualMint.collectionMintPrice(COLLECTION);

        perpetualMint.setConsolationFees(100 ether);

        // set the mint earnings to 300 ETH
        perpetualMint.setMintEarnings(300 ether);

        token.addMintingContract(address(perpetualMint));

        // mint a bunch of tokens to minter
        vm.prank(MINTER);
        token.mint(minter, MINT_AMOUNT * 1e10);
    }

    /// @dev Tests attemptBatchMintForEthWithMint functionality when paying the full set ETH mint price.
    function test_attemptBatchMintForEthWithMintWithFullMintPrice() external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(MINT_PRICE == perpetualMint.collectionMintPrice(COLLECTION));

        uint256 preMintTokenBalance = token.balanceOf(minter);

        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedCollectionConsolationFee = (expectedEthRequired *
            perpetualMint.collectionConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedCollectionConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintFee = (expectedEthRequired *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                expectedEthRequired -
                    expectedCollectionConsolationFee -
                    expectedMintFee +
                    preMintAccruedMintEarnings // account for the mocked mint earnings during setup
        );

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests attemptBatchMintForEthWithMint functionality when paying a multiple of the set ETH mint price.
    function test_attemptBatchMintForEthWithMintWithMoreThanMintPrice()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(MINT_PRICE == perpetualMint.collectionMintPrice(COLLECTION));

        uint256 preMintTokenBalance = token.balanceOf(minter);

        // pay 10 times the ETH mint price per spin
        MINT_PRICE = MINT_PRICE * 10;

        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedCollectionConsolationFee = (expectedEthRequired *
            perpetualMint.collectionConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedCollectionConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintFee = (expectedEthRequired *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                expectedEthRequired -
                    expectedCollectionConsolationFee -
                    expectedMintFee +
                    preMintAccruedMintEarnings // account for the mocked mint earnings during setup
        );

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests attemptBatchMintForEthWithMint functionality when paying a fraction of the set ETH mint price.
    function test_attemptBatchMintForEthWithMintWithPartialMintPrice()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintTokenBalance = token.balanceOf(minter);

        // pay 1/4th of the ETH mint price per spin
        MINT_PRICE = MINT_PRICE / 4;

        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedCollectionConsolationFee = (expectedEthRequired *
            perpetualMint.collectionConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedCollectionConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintFee = (expectedEthRequired *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                expectedEthRequired -
                    expectedCollectionConsolationFee -
                    expectedMintFee +
                    preMintAccruedMintEarnings // account for the mocked mint earnings during setup
        );

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests attemptBatchMintForEthWithMint functionality when a referrer address is passed.
    function test_attemptBatchMintForEthWithMintWithReferrer() external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintMinterTokenBalance = token.balanceOf(minter);

        uint256 preMintReferrerTokenBalance = token.balanceOf(REFERRER);

        assert(preMintReferrerTokenBalance == 0);

        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithMint(
            REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedCollectionConsolationFee = (expectedEthRequired *
            perpetualMint.collectionConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedCollectionConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintFee = (expectedEthRequired *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        uint256 expectedMintReferralFee = (expectedMintFee *
            perpetualMint.defaultCollectionReferralFeeBP()) /
            perpetualMint.BASIS();

        assert(
            postMintAccruedProtocolFees ==
                expectedMintFee - expectedMintReferralFee
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                expectedEthRequired -
                    expectedCollectionConsolationFee -
                    expectedMintFee +
                    preMintAccruedMintEarnings // account for the mocked mint earnings during setup
        );

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

    /// @dev Tests attemptBatchMintForEthWithMint functionality when a collection mint fee distribution ratio is set.
    function test_attemptBatchMintForEthWithMintWithCollectionMintFeeDistributionRatio()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintTokenBalance = token.balanceOf(minter);

        perpetualMint.setCollectionMintFeeDistributionRatioBP(
            COLLECTION,
            TEST_COLLECTION_MINT_FEE_DISTRIBUTION_RATIO_BP
        );

        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedCollectionConsolationFee = (expectedEthRequired *
            perpetualMint.collectionConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 expectedAdditionalDepositorFee = (expectedCollectionConsolationFee *
                TEST_COLLECTION_MINT_FEE_DISTRIBUTION_RATIO_BP) /
                perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired -
                        expectedCollectionConsolationFee +
                        expectedAdditionalDepositorFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintFee = (expectedEthRequired *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                expectedEthRequired -
                    expectedCollectionConsolationFee -
                    expectedMintFee +
                    expectedAdditionalDepositorFee +
                    preMintAccruedMintEarnings // account for the mocked mint earnings during setup
        );

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests that attemptBatchMintForEthWithMint functionality reverts when attempting to mint for an ETH prize value that
    /// is more than the buffer adjusted mint earnings.
    function test_attemptBatchMintForEthWithMintRevertsWhen_AttemptingToMintMoreThanBufferAdjustedMintEarnings()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        vm.expectRevert(
            IPerpetualMintInternal.InsufficientMintEarnings.selector
        );

        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE * 2,
            TEST_RISK_REWARD_RATIO
        );
    }

    /// @dev Tests that attemptBatchMintForEthWithMint functionality reverts when attempting to mint with an invalid fractional price per mint.
    function test_attemptBatchMintForEthWithMintRevertsWhen_AttemptingToMintWithInvalidPricePerMint()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.InvalidPricePerMint.selector);

        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            2_500 ether + 1, // 2,500 $MINT + 1 wei (dust)
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );
    }

    /// @dev Tests that attemptBatchMintForEthWithMint functionality reverts when attempting to mint with less than MINIMUM_PRICE_PER_SPIN.
    function test_attemptBatchMintForEthWithMintRevertsWhen_AttemptingToMintForLessThanMinimumPricePerSpin()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.PricePerSpinTooLow.selector);

        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            1 ether - 1, // less than 1 $MINT
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );
    }

    /// @dev Tests that attemptBatchMintForEthWithMint functionality reverts when attempting zero mints.
    function test_attemptBatchMintForEthWithMintRevertsWhen_AttemptingZeroMints()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        vm.expectRevert(IPerpetualMintInternal.InvalidNumberOfMints.selector);

        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            ZERO_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );
    }

    /// @dev Tests that attemptBatchMintForEthWithMint functionality reverts when the contract is paused.
    function test_attemptBatchMintForEthWithMintRevertsWhen_PausedStateIsTrue()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        perpetualMint.pause();
        vm.expectRevert(IPausableInternal.Pausable__Paused.selector);

        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );
    }
}
