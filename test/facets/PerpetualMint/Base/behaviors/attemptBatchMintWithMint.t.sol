// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPausableInternal } from "@solidstate/contracts/security/pausable/IPausableInternal.sol";

import { PerpetualMintTest_Base } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../../Token/Token.t.sol";
import { BaseForkTest } from "../../../../BaseForkTest.t.sol";
import { CoreTest } from "../../../../diamonds/Core.t.sol";
import { TokenProxyTest } from "../../../../diamonds/TokenProxy.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_attemptBatchMintWithMintBase
/// @dev PerpetualMint_Base test contract for testing expected attemptBatchMintWithMint behavior. Tested on a Base fork.
contract PerpetualMint_attemptBatchMintWithMintBase is
    BaseForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest_Base,
    TokenTest
{
    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest_Base, TokenTest) {
        PerpetualMintTest_Base.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        perpetualMint.setConsolationFees(100 ether);

        token.addMintingContract(address(perpetualMint));

        // mint a bunch of tokens to minter
        vm.prank(MINTER);
        token.mint(minter, MINT_AMOUNT * 1e10);
    }

    /// @dev Tests attemptBatchMintWithMint functionality.
    function test_attemptBatchMintWithMint() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintTokenBalance = token.balanceOf(minter);

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            NO_REFERRER,
            TEST_MINT_ATTEMPTS
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
                    expectedMintFee
        );

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            perpetualMint.ethToMintRatio();

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests attemptBatchMintWithMint functionality when a referrer address is passed.
    function test_attemptBatchMintWithMintWithReferrer() external {
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
        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            REFERRER,
            TEST_MINT_ATTEMPTS
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
            perpetualMint.collectionReferralFeeBP(COLLECTION)) /
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
                    expectedMintFee
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

    /// @dev Tests attemptBatchMintWithMint functionality when a collection mint fee distribution ratio is set.
    function test_attemptBatchMintWithMintWithCollectionMintFeeDistributionRatio()
        external
    {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintTokenBalance = token.balanceOf(minter);

        perpetualMint.setCollectionMintFeeDistributionRatioBP(
            COLLECTION,
            TEST_COLLECTION_MINT_FEE_DISTRIBUTION_RATIO_BP
        );

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            NO_REFERRER,
            TEST_MINT_ATTEMPTS
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
                    expectedAdditionalDepositorFee
        );

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            perpetualMint.ethToMintRatio();

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests that attemptBatchMintWithMint functionality reverts when attempting zero mints.
    function test_attemptBatchMintWithMintRevertsWhen_AttemptingZeroMints()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.InvalidNumberOfMints.selector);

        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            NO_REFERRER,
            ZERO_MINT_ATTEMPTS
        );
    }

    /// @dev Tests that attemptBatchMintWithMint functionality reverts when the contract is paused.
    function test_attemptBatchMintWithMintRevertsWhen_PausedStateIsTrue()
        external
    {
        perpetualMint.pause();
        vm.expectRevert(IPausableInternal.Pausable__Paused.selector);

        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            NO_REFERRER,
            TEST_MINT_ATTEMPTS
        );
    }
}
