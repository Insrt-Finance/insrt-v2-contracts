// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPausableInternal } from "@solidstate/contracts/security/pausable/IPausableInternal.sol";

import { PerpetualMintTest_Base } from "../PerpetualMint.t.sol";
import { BaseForkTest } from "../../../../BaseForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_attemptBatchMintForMintWithEthBase
/// @dev PerpetualMint_Base test contract for testing expected attemptBatchMintForMintWithEth behavior. Tested on a Base fork.
contract PerpetualMint_attemptBatchMintForMintWithEthBase is
    BaseForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest_Base
{
    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev for now, mints for $MINT are treated as address(0) collections
    address COLLECTION = address(0);

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

        // get the mint price for $MINT
        MINT_PRICE = perpetualMint.collectionMintPrice(COLLECTION);
    }

    /// @dev Tests attemptBatchMintForMintWithEth functionality when paying the full set $MINT mint price.
    function test_attemptBatchMintForMintWithEthWithFullMintPrice() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(address(perpetualMint).balance == 0);

        assert(MINT_PRICE == perpetualMint.collectionMintPrice(COLLECTION));

        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(NO_REFERRER, TEST_MINT_ATTEMPTS);

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintTokenConsolationFeeBP()) /
                    perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        // asert that depositor earnings have not been updated on mints for $MINT
        assert(postMintAccruedMintEarnings == 0);

        assert(
            address(perpetualMint).balance ==
                postMintAccruedConsolationFees + postMintAccruedProtocolFees
        );
    }

    /// @dev Tests attemptBatchMintForMintWithEth functionality when paying a multiple of the set $MINT mint price.
    function test_attemptBatchMintForMintWithEthWithMoreThanMintPrice()
        external
    {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(address(perpetualMint).balance == 0);

        // pay 10 times the $MINT mint price per spin
        MINT_PRICE = MINT_PRICE * 10;

        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(NO_REFERRER, TEST_MINT_ATTEMPTS);

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintTokenConsolationFeeBP()) /
                    perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        // asert that depositor earnings have not been updated on mints for $MINT
        assert(postMintAccruedMintEarnings == 0);

        assert(
            address(perpetualMint).balance ==
                postMintAccruedConsolationFees + postMintAccruedProtocolFees
        );
    }

    /// @dev Tests attemptBatchMintForMintWithEth functionality when paying a fraction of the set $MINT mint price.
    function test_attemptBatchMintForMintWithEthWithPartialMintPrice()
        external
    {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(address(perpetualMint).balance == 0);

        // pay 1/10th of the $MINT mint price per spin
        MINT_PRICE = MINT_PRICE / 10;

        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(NO_REFERRER, TEST_MINT_ATTEMPTS);

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintTokenConsolationFeeBP()) /
                    perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        // asert that depositor earnings have not been updated on mints for $MINT
        assert(postMintAccruedMintEarnings == 0);

        assert(
            address(perpetualMint).balance ==
                postMintAccruedConsolationFees + postMintAccruedProtocolFees
        );
    }

    /// @dev Tests attemptBatchMintForMintWithEth functionality when a referrer address is passed.
    function test_attemptBatchMintForMintWithEthWithReferrer() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(address(perpetualMint).balance == 0);

        assert(REFERRER.balance == 0);

        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(REFERRER, TEST_MINT_ATTEMPTS);

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintTokenConsolationFeeBP()) /
                    perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintProtocolFee = (MINT_PRICE * TEST_MINT_ATTEMPTS) -
            postMintAccruedConsolationFees;

        uint256 expectedMintReferralFee = (expectedMintProtocolFee *
            perpetualMint.defaultCollectionReferralFeeBP()) /
            perpetualMint.BASIS();

        assert(
            postMintAccruedProtocolFees ==
                expectedMintProtocolFee - expectedMintReferralFee
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        // asert that depositor earnings have not been updated on mints for $MINT
        assert(postMintAccruedMintEarnings == 0);

        assert(
            address(perpetualMint).balance ==
                postMintAccruedConsolationFees + postMintAccruedProtocolFees
        );

        assert(REFERRER.balance == expectedMintReferralFee);
    }

    /// @dev Tests that attemptBatchMintForMintWithEth functionality reverts when attempting to mint with an incorrect msg value amount.
    function test_attemptBatchMintForMintWithEthRevertsWhen_AttemptingToMintWithIncorrectMsgValue()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.IncorrectETHReceived.selector);

        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS + 1
        }(NO_REFERRER, TEST_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMintForMintWithEth functionality reverts when attempting to mint with less than MINIMUM_PRICE_PER_SPIN.
    function test_attemptBatchMintForMintWithEthRevertsWhen_AttemptingToMintWithLessThanMinimumPricePerSpin()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.PricePerSpinTooLow.selector);

        perpetualMint.attemptBatchMintForMintWithEth(
            NO_REFERRER,
            TEST_MINT_ATTEMPTS
        );
    }

    /// @dev Tests that attemptBatchMintForMintWithEth functionality reverts when attempting zero mints.
    function test_attemptBatchMintForMintWithEthRevertsWhen_AttemptingZeroMints()
        external
    {
        vm.expectRevert();

        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(NO_REFERRER, ZERO_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMintForMintWithEth functionality reverts when the contract is paused.
    function test_attemptBatchMintForMintWithEthRevertsWhen_PausedStateIsTrue()
        external
    {
        perpetualMint.pause();
        vm.expectRevert(IPausableInternal.Pausable__Paused.selector);

        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(NO_REFERRER, TEST_MINT_ATTEMPTS);
    }
}
