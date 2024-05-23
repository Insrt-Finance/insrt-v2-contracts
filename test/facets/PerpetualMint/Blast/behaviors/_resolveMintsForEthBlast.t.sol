// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest_SupraBlast } from "../Supra/PerpetualMint.t.sol"; // TODO: for now we are using the Supra version of the PerpetualMintTest contract
import { TokenTest } from "../../../Token/Token.t.sol";
import { BlastForkTest } from "../../../../BlastForkTest.t.sol";
import { CoreTest } from "../../../../diamonds/Core/Core.t.sol";
import { TokenProxyTest } from "../../../../diamonds/TokenProxy.t.sol";
import { GasMode } from "../../../../../contracts/diamonds/Core/Blast/IBlast.sol";
import { IPerpetualMintInternal, RequestData } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_resolveMintsForEthBlast
/// @dev PerpetualMint test contract for testing expected behavior of the _resolveMintsForEthBlast function
contract PerpetualMint_resolveMintsForEthBlast is
    BlastForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest_SupraBlast,
    TokenTest
{
    /// @dev mimics random values sent by VRF
    uint256[] randomWords;

    /// @dev collection to test
    address COLLECTION = ETH_COLLECTION_ADDRESS;

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest_SupraBlast, TokenTest) {
        PerpetualMintTest_SupraBlast.setUp();
        TokenTest.setUp();

        vm.deal(GAS, 1 ether);
        vm.deal(YIELD, 1 ether);

        // set the mint earnings to 300 ETH
        perpetualMint.setMintEarnings(300 ether);

        // set protocol contract balance to 300 ETH
        vm.deal(address(perpetualMint), 300 ether);

        perpetualMint.setMintToken(address(token));

        token.addMintingContract(address(perpetualMint));

        _activateClaimableGas();
    }

    /// @dev tests that _resolveMintsForEthBlast applies custom risk reward ratios correctly.
    function test_resolveMintsForEthBlastAppliesCustomRiskRewardRatiosCorrectly()
        external
    {
        // expected losing mint resolution
        randomWords.push(uint256(uint160(address(msg.sender))));
        // expected lowest tier mint resolution
        randomWords.push(2);
        // expected no-win yield resolution
        randomWords.push(uint256(uint160(address(msg.sender))));

        uint256 currentEthBalance = address(minter).balance;

        // assert that the minter currently has no $MINT tokens
        assert(token.balanceOf(minter) == 0);

        // set max risk reward ratio
        TEST_RISK_REWARD_RATIO = perpetualMint.BASIS();

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );

        uint256 totalMintedAmount = (((testTiersData.tierMultipliers[0] *
            perpetualMint.ethToMintRatio() *
            perpetualMint.collectionMintPrice(COLLECTION) *
            (perpetualMint.BASIS() - TEST_RISK_REWARD_RATIO)) *
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

        // set a third of the max risk reward ratio
        TEST_RISK_REWARD_RATIO = perpetualMint.BASIS() / 3;

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );

        totalMintedAmount = (((testTiersData.tierMultipliers[0] *
            perpetualMint.ethToMintRatio() *
            perpetualMint.collectionMintPrice(COLLECTION) *
            (perpetualMint.BASIS() - TEST_RISK_REWARD_RATIO)) *
            TEST_ADJUSTMENT_FACTOR) /
            (uint256(perpetualMint.BASIS()) *
                perpetualMint.BASIS() *
                perpetualMint.BASIS()));

        distributionTokenAmount =
            (totalMintedAmount * token.distributionFractionBP()) /
            perpetualMint.BASIS();

        postMintEthBalance = address(minter).balance;

        assert(
            token.balanceOf(minter) ==
                totalMintedAmount - distributionTokenAmount
        );

        assert(postMintEthBalance == currentEthBalance);
    }

    /// @dev tests that _resolveMintsForEthBlast applies mint adjustment factor correctly when paying a multiple of the set ETH mint price.
    function test_resolveMintsForEthBlastAppliesMintAdjustmentFactorCorrectlyWhenPaidWithMoreThanMintPrice()
        external
    {
        // expected losing mint resolution
        randomWords.push(uint256(uint160(address(msg.sender))));
        // expected lowest tier mint resolution
        randomWords.push(2);
        // expected no-win yield resolution
        randomWords.push(uint256(uint160(address(msg.sender))));

        uint256 currentEthBalance = address(minter).balance;

        // assert that the minter currently has no $MINT tokens
        assert(token.balanceOf(minter) == 0);

        // pay 10 times the ETH mint price per spin
        MINT_PRICE = MINT_PRICE * 10;

        uint256 scaledPricePerSpin = MINT_PRICE * perpetualMint.SCALE();

        // calculate the mint price adjustment factor & scale back down
        TEST_ADJUSTMENT_FACTOR =
            ((scaledPricePerSpin /
                perpetualMint.collectionMintPrice(COLLECTION)) *
                perpetualMint.BASIS()) /
            perpetualMint.SCALE();

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );

        uint256 totalMintedAmount = ((testTiersData.tierMultipliers[0] *
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

    /// @dev tests that _resolveMintsForEthBlast applies mint adjustment factor correctly when paying a fraction of the set ETH mint price.
    function test_resolveMintsForEthBlastAppliesMintAdjustmentFactorCorrectlyWhenPaidWithPartialMintPrice()
        external
    {
        // expected losing mint resolution
        randomWords.push(uint256(uint160(address(msg.sender))));
        // expected lowest tier mint resolution
        randomWords.push(2);
        // expected no-win yield resolution
        randomWords.push(uint256(uint160(address(msg.sender))));

        // assert that the minter currently has no $MINT tokens
        assert(token.balanceOf(minter) == 0);

        // pay 1/4th of the ETH mint price per spin
        MINT_PRICE = MINT_PRICE / 4;

        // scale up the price per spin
        uint256 scaledPricePerSpin = MINT_PRICE * perpetualMint.SCALE();

        // calculate the mint price adjustment factor & scale back down
        TEST_ADJUSTMENT_FACTOR =
            ((scaledPricePerSpin /
                perpetualMint.collectionMintPrice(COLLECTION)) *
                perpetualMint.BASIS()) /
            perpetualMint.SCALE();

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );

        uint256 totalMintedAmount = ((testTiersData.tierMultipliers[0] *
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

    /// @dev tests that _resolveMintsForEthBlast distributes ETH payouts automatically when mint earnings are sufficient
    function test_resolveMintsForEthBlastDistributesEthPayoutsAutomaticallyWhenMintEarningsSufficient()
        external
    {
        // expected winning mint resolutions w/ no-win yield resolution
        randomWords.push(1);
        randomWords.push(2);
        randomWords.push(uint256(uint160(address(msg.sender))));
        randomWords.push(4);
        randomWords.push(5);
        randomWords.push(uint256(uint160(address(msg.sender))));

        uint256 MINT_ATTEMPTS = randomWords.length / 3;

        uint256 tokenIdForCollection = uint256(bytes32(abi.encode(COLLECTION)));

        // assert that the minter currently has no token receipts
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 0);

        uint256 preFulfillmentAccruedtMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preFulfillmentContractBalance = address(perpetualMint).balance;

        uint256 preFulfillmentMinterBalance = address(minter).balance;

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );

        // check that the protocol contract balance decreased by the prize value for each mint
        assert(
            address(perpetualMint).balance ==
                preFulfillmentContractBalance -
                    (TEST_MINT_FOR_ETH_PRIZE_VALUE * MINT_ATTEMPTS)
        );

        // check that the minter's ETH balance increased by the prize value for each mint
        assert(
            address(minter).balance ==
                preFulfillmentMinterBalance +
                    (TEST_MINT_FOR_ETH_PRIZE_VALUE * MINT_ATTEMPTS)
        );

        // check that mint earnings decreased by the prize value for each mint
        assert(
            perpetualMint.accruedMintEarnings() ==
                preFulfillmentAccruedtMintEarnings -
                    (TEST_MINT_FOR_ETH_PRIZE_VALUE * MINT_ATTEMPTS)
        );

        // check that minter received no token receipts
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 0);
    }

    /// @dev tests that _resolveMintsForEthBlast distributes token receipt to the minter on successful mints when mint earnings are insufficient
    function test_resolveMintsForEthBlastDistributesWinningReceiptsWhenMintEarningsInsufficient()
        external
    {
        // expected winning mint resolutions w/ no-win yield resolution
        randomWords.push(1);
        randomWords.push(2);
        randomWords.push(uint256(uint160(address(msg.sender))));
        randomWords.push(4);
        randomWords.push(5);
        randomWords.push(uint256(uint160(address(msg.sender))));

        uint256 tokenIdForCollection = uint256(bytes32(abi.encode(COLLECTION)));

        // assert that the minter currently has no token receipts
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 0);

        // set the mint earnings to 0.1 ETH
        perpetualMint.setMintEarnings(0.1 ether);

        uint256 preFulfillmentAccruedtMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preFulfillmentContractBalance = address(perpetualMint).balance;

        uint256 preFulfillmentMinterBalance = address(minter).balance;

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );

        // check that the protocol contract balance is still the same
        assert(address(perpetualMint).balance == preFulfillmentContractBalance);

        // check that the minter's ETH balance is still the same
        assert(address(minter).balance == preFulfillmentMinterBalance);

        // check that mint earnings are still the same
        assert(
            perpetualMint.accruedMintEarnings() ==
                preFulfillmentAccruedtMintEarnings
        );

        // check that minter received a token receipt for each won mint
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 2);
    }

    /// @dev tests that _resolveMintsForEth distributes token receipt to the minter on successful mints when mint earnings are sufficient but payout fails
    function test_resolveMintsForEthDistributesWinningReceiptsWhenMintEarningsSufficientAndPayoutFails()
        external
    {
        // expected winning mint resolutions w/ no-win yield resolution
        randomWords.push(1);
        randomWords.push(2);
        randomWords.push(uint256(uint160(address(msg.sender))));
        randomWords.push(4);
        randomWords.push(5);
        randomWords.push(uint256(uint160(address(msg.sender))));

        uint256 tokenIdForCollection = uint256(bytes32(abi.encode(COLLECTION)));

        // assert that the minter currently has no token receipts
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 0);

        vm.deal(address(perpetualMint), 0.1 ether);

        uint256 preFulfillmentAccruedtMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preFulfillmentContractBalance = address(perpetualMint).balance;

        uint256 preFulfillmentMinterBalance = address(minter).balance;

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );

        // check that the protocol contract balance is still the same
        assert(address(perpetualMint).balance == preFulfillmentContractBalance);

        // check that the minter's ETH balance is still the same
        assert(address(minter).balance == preFulfillmentMinterBalance);

        // check that mint earnings are still the same
        assert(
            perpetualMint.accruedMintEarnings() ==
                preFulfillmentAccruedtMintEarnings
        );

        // check that minter received a token receipt for each won mint
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 2);
    }

    /// @dev tests that _resolveMintsForEthBlast distributes Blast yield to the minter regardless of mint outcome
    function test_resolveMintsForEthBlastDistributesBlastYield() external {
        // expected winning mint resolutions w/ win yield resolution
        randomWords.push(1);
        randomWords.push(2);
        randomWords.push(3);

        uint256 MINT_ATTEMPTS = randomWords.length / 3;

        uint256 tokenIdForCollection = uint256(bytes32(abi.encode(COLLECTION)));

        // assert that the minter currently has no token receipts
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 0);

        uint256 preFulfillmentAccruedtMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preFulfillmentContractBalance = address(perpetualMint).balance;

        uint256 preFulfillmentMinterBalance = address(minter).balance;

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );

        // check that the protocol contract balance decreased by the prize value for each mint
        assert(
            address(perpetualMint).balance ==
                preFulfillmentContractBalance -
                    (TEST_MINT_FOR_ETH_PRIZE_VALUE * MINT_ATTEMPTS)
        );

        uint256 newEthBalance = address(minter).balance;

        // check that the minter's ETH balance increased by at least the prize value for each mint
        assert(
            newEthBalance >=
                preFulfillmentMinterBalance +
                    (TEST_MINT_FOR_ETH_PRIZE_VALUE * MINT_ATTEMPTS)
        );

        // check that mint earnings decreased by the prize value for each mint
        assert(
            perpetualMint.accruedMintEarnings() ==
                preFulfillmentAccruedtMintEarnings -
                    (TEST_MINT_FOR_ETH_PRIZE_VALUE * MINT_ATTEMPTS)
        );

        // check that minter received no token receipts
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 0);

        delete randomWords;

        // expected losing mint resolution w/ win yield resolution
        randomWords.push(uint256(uint160(address(msg.sender))));
        randomWords.push(4);
        randomWords.push(5);

        // refill the claimable Yield balance
        vm.deal(YIELD, 1 ether);

        // refill the claimable Gas balance
        _activateClaimableGas();

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );

        uint256 endingEthBalance = address(minter).balance;

        assert(endingEthBalance > newEthBalance);

        // check that minter still has not received a token receipt
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 0);
    }

    /// @dev tests that _resolveMintsForEthBlast does not distribute Blast yield to the minter if they win the yield bounty and there is no
    /// Blast yield to claim. Also tests that the VRF fulfillment still succeeds.
    function test_resolveMintsForEthBlastDoesNotDistributeBlastYieldIfBountyIsEmpty()
        external
    {
        // expected winning mint resolutions w/ win yield resolution
        randomWords.push(1);
        randomWords.push(2);
        randomWords.push(3);

        uint256 MINT_ATTEMPTS = randomWords.length / 3;

        uint256 tokenIdForCollection = uint256(bytes32(abi.encode(COLLECTION)));

        // assert that the minter currently has no token receipts
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 0);

        uint256 preFulfillmentAccruedtMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preFulfillmentContractBalance = address(perpetualMint).balance;

        uint256 preFulfillmentMinterBalance = address(minter).balance;

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );

        // check that the protocol contract balance decreased by the prize value for each mint
        assert(
            address(perpetualMint).balance ==
                preFulfillmentContractBalance -
                    (TEST_MINT_FOR_ETH_PRIZE_VALUE * MINT_ATTEMPTS)
        );

        uint256 newEthBalance = address(minter).balance;

        // check that the minter's ETH balance increased by at least the prize value for each mint
        assert(
            newEthBalance >=
                preFulfillmentMinterBalance +
                    (TEST_MINT_FOR_ETH_PRIZE_VALUE * MINT_ATTEMPTS)
        );

        // check that mint earnings decreased by the prize value for each mint
        assert(
            perpetualMint.accruedMintEarnings() ==
                preFulfillmentAccruedtMintEarnings -
                    (TEST_MINT_FOR_ETH_PRIZE_VALUE * MINT_ATTEMPTS)
        );

        // check that minter received no token receipts
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 0);

        delete randomWords;

        // expected losing mint resolution w/ win yield resolution
        randomWords.push(uint256(uint160(address(msg.sender))));
        randomWords.push(4);
        randomWords.push(5);

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );

        uint256 endingEthBalance = address(minter).balance;

        assert(endingEthBalance == newEthBalance);

        // check that minter still has not received a token receipt
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 0);
    }

    /// @dev tests that the MintResultBlast event is emitted when successfully resolving a mint
    function test_resolveMintsForEthBlastEmitsMintResultBlast() external {
        // expected winning mint resolution w/ no-win yield resolution
        randomWords.push(1);
        randomWords.push(2);
        randomWords.push(uint256(uint160(address(msg.sender))));

        vm.expectEmit();
        emit MintResultBlast(
            minter,
            COLLECTION,
            1,
            0,
            0,
            1,
            TEST_MINT_FOR_ETH_PRIZE_VALUE
        );

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );
    }

    /// @dev tests that _resolveMintsForEthBlast reverts when random words are unmatched
    function test_resolveMintsForEthBlastRevertsWhen_RandomWordsAreUnmatched()
        public
    {
        // unmatched expected winning mint resolution
        randomWords.push(1);

        vm.expectRevert(IPerpetualMintInternal.UnmatchedRandomWords.selector);

        vm.startPrank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );

        // add additional unmatched extra words to cause unmatched random words revert
        randomWords.push(3);

        vm.expectRevert(IPerpetualMintInternal.UnmatchedRandomWords.selector);

        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
            randomWords
        );
    }

    /// @dev tests that _resolveMintsForEthBlast works with many random values
    function testFuzz_resolveMintsForEthBlast(
        uint256 valueOne,
        uint256 valueTwo,
        uint256 valueThree
    ) external {
        randomWords.push(valueOne);
        randomWords.push(valueTwo);
        randomWords.push(valueThree);

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEthBlast(
            RequestData({
                minter: minter,
                collection: COLLECTION,
                mintEarningsFeePerSpin: TEST_MINT_EARNINGS_FEE_PER_SPIN,
                mintPriceAdjustmentFactor: TEST_ADJUSTMENT_FACTOR,
                prizeValueInWei: TEST_MINT_FOR_ETH_PRIZE_VALUE,
                riskRewardRatio: TEST_RISK_REWARD_RATIO
            }),
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
