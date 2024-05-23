// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPausableInternal } from "@solidstate/contracts/security/pausable/IPausableInternal.sol";

import { PerpetualMintTest_Base } from "../PerpetualMint.t.sol";
import { BaseForkTest } from "../../../../BaseForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_attemptBatchMintForEthWithEthBase
/// @dev PerpetualMint_Base test contract for testing expected attemptBatchMintForEthWithEth behavior. Tested on a Base fork.
contract PerpetualMint_attemptBatchMintForEthWithEthBase is
    BaseForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest_Base
{
    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    address COLLECTION = ETH_COLLECTION_ADDRESS;

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

        // get the mint price for ETH
        MINT_PRICE = perpetualMint.collectionMintPrice(COLLECTION);

        // set the mint earnings to 300 ETH
        perpetualMint.setMintEarnings(300 ether);
    }

    /// @dev Tests attemptBatchMintForEthWithEth functionality when paying the full set ETH mint price.
    function test_attemptBatchMintForEthWithEthWithFullMintPrice() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintContractBalance = address(perpetualMint).balance;

        assert(preMintContractBalance == 0);

        assert(MINT_PRICE == perpetualMint.collectionMintPrice(COLLECTION));

        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(
            NO_REFERRER,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintForEthConsolationFeeBP()) /
                    perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintFeeBP()) / perpetualMint.BASIS())
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees -
                    postMintAccruedProtocolFees +
                    preMintAccruedMintEarnings
        );

        uint256 postMintContractBalance = address(perpetualMint).balance;

        assert(
            postMintContractBalance ==
                postMintAccruedConsolationFees +
                    postMintAccruedMintEarnings +
                    postMintAccruedProtocolFees -
                    preMintAccruedMintEarnings // account for the mocked mint earnings during setup
        );
    }

    /// @dev Tests attemptBatchMintForEthWithEth functionality when paying a multiple of the set ETH mint price.
    function test_attemptBatchMintForEthWithEthWithMoreThanMintPrice()
        external
    {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintContractBalance = address(perpetualMint).balance;

        assert(preMintContractBalance == 0);

        // pay 10 times the ETH mint price per spin
        MINT_PRICE = MINT_PRICE * 10;

        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(
            NO_REFERRER,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintForEthConsolationFeeBP()) /
                    perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintFeeBP()) / perpetualMint.BASIS())
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees -
                    postMintAccruedProtocolFees +
                    preMintAccruedMintEarnings
        );

        uint256 postMintContractBalance = address(perpetualMint).balance;

        assert(
            postMintContractBalance ==
                postMintAccruedConsolationFees +
                    postMintAccruedMintEarnings +
                    postMintAccruedProtocolFees -
                    preMintAccruedMintEarnings // account for the mocked mint earnings during setup
        );
    }

    /// @dev Tests attemptBatchMintForEthWithEth functionality when paying a fraction of the set ETH mint price.
    function test_attemptBatchMintForEthWithEthWithPartialMintPrice() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintContractBalance = address(perpetualMint).balance;

        assert(preMintContractBalance == 0);

        // pay 1/4th of the ETH mint price per spin
        MINT_PRICE = MINT_PRICE / 4;

        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(
            NO_REFERRER,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintForEthConsolationFeeBP()) /
                    perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintFeeBP()) / perpetualMint.BASIS())
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees -
                    postMintAccruedProtocolFees +
                    preMintAccruedMintEarnings
        );

        uint256 postMintContractBalance = address(perpetualMint).balance;

        assert(
            postMintContractBalance ==
                postMintAccruedConsolationFees +
                    postMintAccruedMintEarnings +
                    postMintAccruedProtocolFees -
                    preMintAccruedMintEarnings // account for the mocked mint earnings during setup
        );
    }

    /// @dev Tests attemptBatchMintForEthWithEth functionality when a referrer address is passed.
    function test_attemptBatchMintForEthWithEthWithReferrer() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintContractBalance = address(perpetualMint).balance;

        assert(preMintContractBalance == 0);

        assert(REFERRER.balance == 0);

        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(
            REFERRER,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintForEthConsolationFeeBP()) /
                    perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintProtocolFee = ((MINT_PRICE * TEST_MINT_ATTEMPTS) *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        uint256 expectedMintReferralFee = (expectedMintProtocolFee *
            perpetualMint.defaultCollectionReferralFeeBP()) /
            perpetualMint.BASIS();

        assert(
            postMintAccruedProtocolFees ==
                expectedMintProtocolFee - expectedMintReferralFee
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees -
                    postMintAccruedProtocolFees -
                    expectedMintReferralFee +
                    preMintAccruedMintEarnings
        );

        uint256 postMintContractBalance = address(perpetualMint).balance;

        assert(
            postMintContractBalance ==
                postMintAccruedConsolationFees +
                    postMintAccruedMintEarnings +
                    postMintAccruedProtocolFees -
                    preMintAccruedMintEarnings // account for the mocked mint earnings during setup
        );

        assert(REFERRER.balance == expectedMintReferralFee);
    }

    /// @dev Tests attemptBatchMintForWithEth functionality when a collection mint fee distribution ratio is set.
    function test_attemptBatchMintForEthWithEthWithCollectionMintFeeDistributionRatio()
        external
    {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintContractBalance = address(perpetualMint).balance;

        assert(preMintContractBalance == 0);

        perpetualMint.setCollectionMintFeeDistributionRatioBP(
            COLLECTION,
            TEST_COLLECTION_MINT_FEE_DISTRIBUTION_RATIO_BP
        );

        uint256 preCalculatedCollectionConsolationFee = ((MINT_PRICE *
            TEST_MINT_ATTEMPTS) * perpetualMint.collectionConsolationFeeBP()) /
            perpetualMint.BASIS();

        uint256 expectedAdditionalDepositorFee = (preCalculatedCollectionConsolationFee *
                TEST_COLLECTION_MINT_FEE_DISTRIBUTION_RATIO_BP) /
                perpetualMint.BASIS();

        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(
            NO_REFERRER,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preCalculatedCollectionConsolationFee -
                    expectedAdditionalDepositorFee
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintFeeBP()) / perpetualMint.BASIS())
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    preCalculatedCollectionConsolationFee -
                    postMintAccruedProtocolFees +
                    expectedAdditionalDepositorFee +
                    preMintAccruedMintEarnings
        );

        uint256 postMintContractBalance = address(perpetualMint).balance;

        assert(
            postMintContractBalance ==
                postMintAccruedConsolationFees +
                    postMintAccruedMintEarnings +
                    postMintAccruedProtocolFees -
                    preMintAccruedMintEarnings // account for the mocked mint earnings during setup
        );
    }

    /// @dev Tests that attemptBatchMintForEthWithEth functionality reverts when attempting to mint for an ETH prize value that
    /// is more than the buffer adjusted mint earnings.
    function test_attemptBatchMintForEthWithEthRevertsWhen_AttemptingToMintMoreThanBufferAdjustedMintEarnings()
        external
    {
        vm.expectRevert(
            IPerpetualMintInternal.InsufficientMintEarnings.selector
        );

        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(
            NO_REFERRER,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE * 2,
            TEST_RISK_REWARD_RATIO
        );
    }

    /// @dev Tests that attemptBatchMintForEthWithEth functionality reverts when attempting to mint with an incorrect msg value amount.
    function test_attemptBatchMintForEthWithEthRevertsWhen_AttemptingToMintWithIncorrectMsgValue()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.IncorrectETHReceived.selector);

        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS + 1
        }(
            NO_REFERRER,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );
    }

    /// @dev Tests that attemptBatchMintForEthWithEth functionality reverts when attempting to mint with less than MINIMUM_PRICE_PER_SPIN.
    function test_attemptBatchMintForEthWithEthRevertsWhen_AttemptingToMintWithLessThanMinimumPricePerSpin()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.PricePerSpinTooLow.selector);

        perpetualMint.attemptBatchMintForEthWithEth(
            NO_REFERRER,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );
    }

    /// @dev Tests that attemptBatchMintForEthWithEth functionality reverts when attempting zero mints.
    function test_attemptBatchMintForEthWithEthRevertsWhen_AttemptingZeroMints()
        external
    {
        vm.expectRevert();

        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(
            NO_REFERRER,
            ZERO_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );
    }

    /// @dev Tests that attemptBatchMintForEthWithEth functionality reverts when the contract is paused.
    function test_attemptBatchMintForEthWithEthRevertsWhen_PausedStateIsTrue()
        external
    {
        perpetualMint.pause();
        vm.expectRevert(IPausableInternal.Pausable__Paused.selector);

        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(
            NO_REFERRER,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );
    }
}
