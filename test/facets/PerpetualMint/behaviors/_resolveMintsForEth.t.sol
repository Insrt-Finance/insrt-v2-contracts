// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../Token/Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { CoreTest } from "../../../diamonds/Core/Core.t.sol";
import { TokenProxyTest } from "../../../diamonds/TokenProxy.t.sol";
import { IPerpetualMintInternal, RequestData } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_resolveMintsForEth
/// @dev PerpetualMint test contract for testing expected behavior of the _resolveMintsForEth function
contract PerpetualMint_resolveMintsForEth is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest,
    TokenTest
{
    /// @dev mimics random values sent by Chainlink VRF
    uint256[] randomWords;

    address COLLECTION = ETH_COLLECTION_ADDRESS;

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest, TokenTest) {
        PerpetualMintTest.setUp();
        TokenTest.setUp();

        // set the mint earnings to 300 ETH
        perpetualMint.setMintEarnings(300 ether);

        // set protocol contract balance to 300 ETH
        vm.deal(address(perpetualMint), 300 ether);

        perpetualMint.setMintToken(address(token));

        token.addMintingContract(address(perpetualMint));
    }

    /// @dev tests that _resolveMintsForEth applies mint for ETH multipliers correctly
    function test_resolveMintsForEthAppliesMintForEthMultipliersCorrectly()
        external
    {
        // expected losing mint resolution
        randomWords.push(uint256(uint160(address(msg.sender))));
        // expected lowest tier mint resolution
        randomWords.push(2);

        // assert that the minter currently has no $MINT tokens
        assert(token.balanceOf(minter) == 0);

        perpetualMint.setCollectionMintMultiplier(COLLECTION, 1e10); // 10x multiplier

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEth(
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
            perpetualMint.collectionMintMultiplier(COLLECTION)) *
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

    /// @dev tests that _resolveMintsForEth applies mint adjustment factor correctly when paying a multiple of the set ETH mint price.
    function test_resolveMintsForEthAppliesMintAdjustmentFactorCorrectlyWhenPaidWithMoreThanMintPrice()
        external
    {
        // expected losing mint resolution
        randomWords.push(uint256(uint160(address(msg.sender))));
        // expected lowest tier mint resolution
        randomWords.push(2);

        // assert that the minter currently has no ETH tokens
        assert(token.balanceOf(minter) == 0);

        // pay 10 times the ETH mint price per spin
        MINT_PRICE = perpetualMint.collectionMintPrice(COLLECTION) * 10;

        uint256 scaledPricePerSpin = MINT_PRICE * perpetualMint.SCALE();

        // calculate the mint price adjustment factor & scale back down
        TEST_ADJUSTMENT_FACTOR =
            ((scaledPricePerSpin /
                perpetualMint.collectionMintPrice(COLLECTION)) *
                perpetualMint.BASIS()) /
            perpetualMint.SCALE();

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEth(
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

    /// @dev tests that _resolveMintsForEth applies mint adjustment factor correctly when paying a fraction of the set ETH mint price.
    function test_resolveMintsForEthAppliesMintAdjustmentFactorCorrectlyWhenPaidWithPartialMintPrice()
        external
    {
        // expected losing mint resolution
        randomWords.push(uint256(uint160(address(msg.sender))));
        // expected lowest tier mint resolution
        randomWords.push(2);

        // assert that the minter currently has no ETH tokens
        assert(token.balanceOf(minter) == 0);

        // pay 1/10th of the ETH mint price per spin
        MINT_PRICE = perpetualMint.collectionMintPrice(COLLECTION) / 10;

        uint256 scaledPricePerSpin = MINT_PRICE * perpetualMint.SCALE();

        // calculate the mint price adjustment factor & scale back down
        TEST_ADJUSTMENT_FACTOR =
            ((scaledPricePerSpin /
                perpetualMint.collectionMintPrice(COLLECTION)) *
                perpetualMint.BASIS()) /
            perpetualMint.SCALE();

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEth(
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

    /// @dev tests that _resolveMintsForEth distributes ETH payouts automatically when mint earnings are sufficient
    function test_resolveMintsForEthDistributesEthPayoutsAutomaticallyWhenMintEarningsSufficient()
        external
    {
        // expected winning mint resolutions
        randomWords.push(1);
        randomWords.push(2);
        randomWords.push(3);
        randomWords.push(4);

        uint256 MINT_ATTEMPTS = randomWords.length / 2;

        uint256 tokenIdForCollection = uint256(bytes32(abi.encode(COLLECTION)));

        // assert that the minter currently has no token receipts
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 0);

        uint256 preFulfillmentAccruedtMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preFulfillmentContractBalance = address(perpetualMint).balance;

        uint256 preFulfillmentMinterBalance = address(minter).balance;

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEth(
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

    /// @dev tests that _resolveMintsForEth distributes token receipt to the minter on successful mints when mint earnings are insufficient
    function test_resolveMintsForEthDistributesWinningReceiptsWhenMintEarningsInsufficient()
        external
    {
        // expected winning mint resolutions
        randomWords.push(1);
        randomWords.push(2);
        randomWords.push(3);
        randomWords.push(4);

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
        perpetualMint.exposed_resolveMintsForEth(
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
        // expected winning mint resolutions
        randomWords.push(1);
        randomWords.push(2);
        randomWords.push(3);
        randomWords.push(4);

        uint256 tokenIdForCollection = uint256(bytes32(abi.encode(COLLECTION)));

        // assert that the minter currently has no token receipts
        assert(perpetualMint.balanceOf(minter, tokenIdForCollection) == 0);

        vm.deal(address(perpetualMint), 0.1 ether);

        uint256 preFulfillmentAccruedtMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preFulfillmentContractBalance = address(perpetualMint).balance;

        uint256 preFulfillmentMinterBalance = address(minter).balance;

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEth(
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

    /// @dev tests that the MintResult event is emitted when successfully resolving a mint
    function test_resolveMintsForEthEmitsMintResult() external {
        // expected winning mint resolution
        randomWords.push(1);
        randomWords.push(2);

        vm.expectEmit();
        emit MintResult(
            minter,
            COLLECTION,
            1,
            0,
            1,
            TEST_MINT_FOR_ETH_PRIZE_VALUE
        );

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEth(
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

    /// @dev tests that _resolveMintsForEth reverts when random words are unmatched
    function test_resolveMintsForEthsRevertsWhen_RandomWordsAreUnmatched()
        public
    {
        // unmatched expected winning mint resolution
        randomWords.push(1);

        vm.expectRevert(IPerpetualMintInternal.UnmatchedRandomWords.selector);

        vm.startPrank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEth(
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
        randomWords.push(2);
        randomWords.push(3);

        vm.expectRevert(IPerpetualMintInternal.UnmatchedRandomWords.selector);

        perpetualMint.exposed_resolveMintsForEth(
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

    /// @dev tests that _resolveMintsForEth works with many random values
    function testFuzz_resolveMintsForEth(uint256 value) external {
        randomWords.push(value);
        randomWords.push(value);

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForEth(
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
}
