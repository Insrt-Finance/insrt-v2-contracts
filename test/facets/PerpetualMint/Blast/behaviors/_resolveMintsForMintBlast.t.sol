// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest_SupraBlast } from "../Supra/PerpetualMint.t.sol"; // TODO: for now we are using the Supra version of the PerpetualMintTest contract
import { TokenTest } from "../../../Token/Token.t.sol";
import { BlastForkTest } from "../../../../BlastForkTest.t.sol";
import { CoreTest } from "../../../../diamonds/Core/Core.t.sol";
import { TokenProxyTest } from "../../../../diamonds/TokenProxy.t.sol";
import { GasMode } from "../../../../../contracts/diamonds/Core/Blast/IBlast.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_resolveMintsForMintBlast
/// @dev PerpetualMint test contract for testing expected behavior of the _resolveMintsForMintBlast function
contract PerpetualMint_resolveMintsForMintBlast is
    BlastForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest_SupraBlast,
    TokenTest
{
    /// @dev mimics random values sent by VRF
    uint256[] randomWords;

    /// @dev for now, mints for $MINT are treated as address(0) collections
    address COLLECTION = address(0);

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest_SupraBlast, TokenTest) {
        PerpetualMintTest_SupraBlast.setUp();
        TokenTest.setUp();

        vm.deal(GAS, 1 ether);
        vm.deal(YIELD, 1 ether);

        perpetualMint.setMintToken(address(token));

        token.addMintingContract(address(perpetualMint));

        _activateClaimableGas();
    }

    /// @dev tests that _resolveMintsForMintBlast applies mint adjustment factor correctly when paying a multiple of the set $MINT mint price.
    function test_resolveMintsForMintBlastAppliesMintAdjustmentFactorCorrectlyWhenPaidWithMoreThanMintPrice()
        external
    {
        // expected lowest tier mint resolution
        randomWords.push(2);
        // expected no-win yield resolution
        randomWords.push(uint256(uint160(address(msg.sender))));

        uint256 currentEthBalance = address(minter).balance;

        // assert that the minter currently has no $MINT tokens
        assert(token.balanceOf(minter) == 0);

        // pay 10 times the $MINT mint price per spin
        MINT_PRICE = perpetualMint.collectionMintPrice(COLLECTION) * 10;

        uint256 scaledPricePerSpin = MINT_PRICE * perpetualMint.SCALE();

        // calculate the mint price adjustment factor & scale back down
        TEST_ADJUSTMENT_FACTOR =
            ((scaledPricePerSpin /
                perpetualMint.collectionMintPrice(COLLECTION)) *
                perpetualMint.BASIS()) /
            perpetualMint.SCALE();

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMintBlast(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );

        uint256 totalMintedAmount = ((testMintTokenTiersData.tierMultipliers[
            0
        ] *
            perpetualMint.ethToMintRatio() *
            perpetualMint.collectionMintPrice(COLLECTION) *
            perpetualMint.collectionMintMultiplier(COLLECTION) *
            TEST_ADJUSTMENT_FACTOR) /
            (uint256(perpetualMint.BASIS()) *
                perpetualMint.BASIS() *
                perpetualMint.BASIS()));

        uint256 distributionTokenAmount = (totalMintedAmount *
            token.distributionFractionBP()) / perpetualMint.BASIS();

        uint256 postMintEthBalance = address(minter).balance;

        assert(
            token.balanceOf(minter) ==
                totalMintedAmount - distributionTokenAmount
        );

        assert(postMintEthBalance == currentEthBalance);
    }

    /// @dev tests that _resolveMintsForMintBlast applies mint adjustment factor correctly when paying a fraction of the set $MINT mint price.
    function test_resolveMintsForMintBlastAppliesMintAdjustmentFactorCorrectlyWhenPaidWithPartialMintPrice()
        external
    {
        // expected lowest tier mint resolution
        randomWords.push(2);
        // expected no-win yield resolution
        randomWords.push(uint256(uint160(address(msg.sender))));

        // assert that the minter currently has no $MINT tokens
        assert(token.balanceOf(minter) == 0);

        // pay 1/4th of the $MINT mint price per spin
        MINT_PRICE = perpetualMint.collectionMintPrice(COLLECTION) / 4;

        uint256 scaledPricePerSpin = MINT_PRICE * perpetualMint.SCALE();

        // calculate the mint price adjustment factor & scale back down
        TEST_ADJUSTMENT_FACTOR =
            ((scaledPricePerSpin /
                perpetualMint.collectionMintPrice(COLLECTION)) *
                perpetualMint.BASIS()) /
            perpetualMint.SCALE();

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMintBlast(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );

        uint256 totalMintedAmount = ((testMintTokenTiersData.tierMultipliers[
            0
        ] *
            perpetualMint.ethToMintRatio() *
            perpetualMint.collectionMintPrice(COLLECTION) *
            perpetualMint.collectionMintMultiplier(COLLECTION) *
            TEST_ADJUSTMENT_FACTOR) /
            (uint256(perpetualMint.BASIS()) *
                perpetualMint.BASIS() *
                perpetualMint.BASIS()));

        uint256 distributionTokenAmount = (totalMintedAmount *
            token.distributionFractionBP()) / perpetualMint.BASIS();

        assert(
            token.balanceOf(minter) ==
                totalMintedAmount - distributionTokenAmount
        );
    }

    /// @dev tests that _resolveMintsForMintBlast applies mint for $MINT multipliers correctly
    function test_resolveMintsForMintBlastAppliesMintForMintMultipliersCorrectly()
        external
    {
        // expected lowest tier mint resolution
        randomWords.push(2);
        // expected no-win yield resolution
        randomWords.push(uint256(uint160(address(msg.sender))));

        // assert that the minter currently has no $MINT tokens
        assert(token.balanceOf(minter) == 0);

        perpetualMint.setCollectionMintMultiplier(COLLECTION, 1e10); // 10x multiplier

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMintBlast(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );

        uint256 totalMintedAmount = ((testMintTokenTiersData.tierMultipliers[
            0
        ] *
            perpetualMint.ethToMintRatio() *
            perpetualMint.collectionMintPrice(COLLECTION) *
            perpetualMint.collectionMintMultiplier(COLLECTION) *
            TEST_ADJUSTMENT_FACTOR) /
            (uint256(perpetualMint.BASIS()) *
                perpetualMint.BASIS() *
                perpetualMint.BASIS()));

        uint256 distributionTokenAmount = (totalMintedAmount *
            token.distributionFractionBP()) / perpetualMint.BASIS();

        assert(
            token.balanceOf(minter) ==
                totalMintedAmount - distributionTokenAmount
        );
    }

    /// @dev tests that _resolveMintsForMintBlast distributes Blast yield to the minter regardless of mint outcome
    function test_resolveMintsForMintBlastDistributesBlastYield() external {
        // expected win yield resolution
        randomWords.push(1);
        randomWords.push(2);

        uint256 startingEthBalance = address(minter).balance;

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMintBlast(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );

        uint256 newEthBalance = address(minter).balance;

        assert(newEthBalance > startingEthBalance);

        delete randomWords;

        // expected win yield resolution
        randomWords.push(4);
        randomWords.push(5);

        // refill the claimable Yield balance
        vm.deal(YIELD, 1 ether);

        // refill the claimable Gas balance
        _activateClaimableGas();

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMintBlast(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );

        uint256 endingEthBalance = address(minter).balance;

        assert(endingEthBalance > newEthBalance);
    }

    /// @dev tests that _resolveMintsForMintBlast does not distribute Blast yield to the minter if they win the yield bounty and there is no
    /// Blast yield to claim. Also tests that the VRF fulfillment still succeeds.
    function test_resolveMintsForMintBlastDoesNotDistributeBlastYieldIfBountyIsEmpty()
        external
    {
        // expected mint resolutions w/ win yield resolution
        randomWords.push(1);
        randomWords.push(2);

        uint256 startingEthBalance = address(minter).balance;

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMintBlast(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );

        uint256 newEthBalance = address(minter).balance;

        assert(newEthBalance > startingEthBalance);

        delete randomWords;

        // expected mint resolution w/ win yield resolution
        randomWords.push(4);
        randomWords.push(5);

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMintBlast(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );

        uint256 endingEthBalance = address(minter).balance;

        assert(endingEthBalance == newEthBalance);
    }

    /// @dev tests that the MintResultBlast event is emitted when successfully resolving a mint
    function test_resolveMintsForMintBlastEmitsMintResultBlast() external {
        // expected no-win yield resolution
        randomWords.push(2);
        randomWords.push(uint256(uint160(address(msg.sender))));

        uint256 totalMintedAmount = ((testMintTokenTiersData.tierMultipliers[
            0
        ] *
            perpetualMint.ethToMintRatio() *
            perpetualMint.collectionMintPrice(COLLECTION) *
            perpetualMint.collectionMintMultiplier(COLLECTION) *
            TEST_ADJUSTMENT_FACTOR) /
            (uint256(perpetualMint.BASIS()) *
                perpetualMint.BASIS() *
                perpetualMint.BASIS()));

        vm.expectEmit();
        emit MintResultBlast(minter, COLLECTION, 1, 0, totalMintedAmount, 0, 0);

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMintBlast(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );
    }

    /// @dev tests that _resolveMintsForMintBlast reverts when random words are unmatched
    function test_resolveMintsForMintBlastRevertsWhen_RandomWordsAreUnmatched()
        public
    {
        // unmatched expected winning mint resolution
        randomWords.push(1);

        vm.expectRevert(IPerpetualMintInternal.UnmatchedRandomWords.selector);

        vm.startPrank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMintBlast(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );

        // add additional unmatched extra words to cause unmatched random words revert
        randomWords.push(3);
        randomWords.push(4);

        vm.expectRevert(IPerpetualMintInternal.UnmatchedRandomWords.selector);

        perpetualMint.exposed_resolveMintsForMintBlast(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );
    }

    /// @dev tests that _resolveMintsForMintBlast works with many random values
    function testFuzz_resolveMintsForMintBlast(
        uint256 valueOne,
        uint256 valueTwo
    ) external {
        randomWords.push(valueOne);
        randomWords.push(valueTwo);

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMintBlast(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );
    }

    function _activateClaimableGas() private {
        // grab the PerpetualMint gas params storage slot
        bytes32 gasParamsStorageSlot = keccak256(
            abi.encodePacked(address(perpetualMint), "parameters")
        );

        uint256 updatedTimestamp = block.timestamp;

        bytes32 packedParams = ((bytes32(uint256(GasMode.CLAIMABLE)) <<
            ((12 + 15 + 4) * 8)) | // Shift mode to the most significant byte
            (bytes32(uint256(1 ether)) << ((15 + 4) * 8)) | // Shift etherBalance to start after 1 byte of mode
            (bytes32(uint256(1 ether)) << (4 * 8)) | // Shift etherSeconds to start after mode and etherBalance
            bytes32(updatedTimestamp)); // Keep updatedTimestamp in the least significant bytes

        vm.store(GAS, gasParamsStorageSlot, packedParams);
    }
}
