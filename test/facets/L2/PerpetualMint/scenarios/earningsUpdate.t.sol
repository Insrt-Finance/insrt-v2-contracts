// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { AssetType } from "../../../../../contracts/enums/AssetType.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title PerpetualMint_EarningsScenario
/// @dev PerpetualMint Scenario testing contract to ensure tracking of earnings works in
/// production scenarios
contract PerpetualMint_EarningsScenario is L2ForkTest, PerpetualMintTest {
    // additional depositors
    address internal constant depositorThree = address(3);
    address internal constant depositorFour = address(4);

    // collection to be used this test suite
    address internal constant COLLECTION = BORED_APE_YACHT_CLUB;

    // additional token Ids used of Bored Ape Yacht Club collection
    uint256 BORED_APE_YACHT_CLUB_TOKEN_ID_THREE = 103;
    uint256 BORED_APE_YACHT_CLUB_TOKEN_ID_FOUR = 104;

    // risks of depositors upon deposit
    uint256 depositorOneRisk = 100;
    uint256 depositorTwoRisk = 50;
    uint256 depositorThreeRisk = 100;
    uint256 depositorFourRisk = 50;

    // risks of depositors upon update actions
    uint256 secondDepositorOneRisk = 150;
    uint256 secondDepositorTwoRisk = 50;
    uint256 secondDepositorThreeRisk = 75;
    uint256 secondDepositorFourRisk = 200;

    // tokenId arrays for each depositor
    uint256[] depositorOneTokenIds;
    uint256[] depositorTwoTokenIds;
    uint256[] depositorThreeTokenIds;
    uint256[] depositorFourTokenIds;

    // risk arrays for each depositor
    uint256[] depositorOneRisks;
    uint256[] depositorTwoRisks;
    uint256[] depositorThreeRisks;
    uint256[] depositorFourRisks;

    // dummy array for amounts parameter
    uint256[] DUMMY_AMOUNTS;

    // counter to track amount of unsuccessful mints
    uint256 unsuccessfulMints;

    function setUp() public override {
        super.setUp();

        // add depositor tokenIds to depositor tokenId arrays
        depositorOneTokenIds.push(BORED_APE_YACHT_CLUB_TOKEN_ID_ONE);
        depositorTwoTokenIds.push(BORED_APE_YACHT_CLUB_TOKEN_ID_TWO);
        depositorThreeTokenIds.push(BORED_APE_YACHT_CLUB_TOKEN_ID_THREE);
        depositorFourTokenIds.push(BORED_APE_YACHT_CLUB_TOKEN_ID_FOUR);

        // add depositor risks to depositor risk arrays
        depositorOneRisks.push(depositorOneRisk);
        depositorTwoRisks.push(depositorTwoRisk);
        depositorThreeRisks.push(depositorThreeRisk);
        depositorFourRisks.push(depositorFourRisk);

        // make DUMMY_AMOUNTS non-empty
        DUMMY_AMOUNTS.push(1);

        // mock a deposit for depositorOne
        mock_deposit(
            depositorOne,
            COLLECTION,
            depositorOne,
            depositorOneTokenIds,
            depositorOneRisks,
            DUMMY_AMOUNTS
        );

        // mock a deposit for depositorTwo
        mock_deposit(
            depositorTwo,
            COLLECTION,
            depositorTwo,
            depositorTwoTokenIds,
            depositorTwoRisks,
            DUMMY_AMOUNTS
        );

        // mock a deposit for depositorThree
        mock_deposit(
            depositorThree,
            COLLECTION,
            depositorThree,
            depositorThreeTokenIds,
            depositorThreeRisks,
            DUMMY_AMOUNTS
        );
    }

    /// @dev tests that depositor earnings are updated correctly in the following scenario:
    /// - three depositors deposit into the protocol and accrue some earnings
    /// - one of the depositors update their risk
    /// - more earnings are accrued
    /// - another depositor updates their risk
    /// - a new depositor enters the protocol
    /// - some more earnings are accrued
    /// - the new depositor updates their risk
    function test_scenario() public {
        // mock some earnings accrual for the COLLECTION via unsuccessful mints
        mock_unsuccessfulMintAttempts(COLLECTION, 10);

        // increment unsuccessful mint amount
        unsuccessfulMints += 10;

        // set new depositorThree risk
        depositorThreeRisks[0] = secondDepositorThreeRisk;

        // update depositor earnings via updateERC721TokenRisks
        // and set new risk for depositorThreeTokenIds
        vm.prank(depositorThree);
        perpetualMint.updateERC721TokenRisks(
            COLLECTION,
            depositorThreeTokenIds,
            depositorThreeRisks
        );

        // store earnings up until now
        uint256 firstTotalEarnings = _totalEarnings();

        // use explicit values to calculate expected earnings:
        // - totalEarnings is just the amount of unsuccessfulMints * MINT_PRICE
        // - pertinent total risk is simply the risks set by the depositors on deposit
        // - depositorThreeRisk is the risk which would be used to calculate all the earnings
        // of depositor three until the update
        uint256 expectedEarnings = (depositorThreeRisk * firstTotalEarnings) /
            (depositorOneRisk + depositorTwoRisk + depositorThreeRisk);

        // check earnings is correctly accounted for
        assertEq(
            expectedEarnings,
            _depositorEarnings(
                address(perpetualMint),
                depositorThree,
                COLLECTION
            )
        );

        // mock some earnings accrual for the COLLECTION via unsuccessful mints
        mock_unsuccessfulMintAttempts(COLLECTION, 5);

        // increment unsuccessful mint amount
        unsuccessfulMints += 5;

        // set new depositorOne risk
        depositorOneRisks[0] = secondDepositorOneRisk;

        // update depositor earnings via updateERC721TokenRisks
        // and set new risk for depositorThreeTokenIds
        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(
            COLLECTION,
            depositorOneTokenIds,
            depositorOneRisks
        );

        // two distinct earnings need to be calculated:
        // 1. the earnings prior to depositorThree risk update
        // 2. the earnings after depositorThree risk update
        // since this affects depositorOne share of earnings

        // use explicit values to calculate expected earnings
        // 1. earnings prior to depositorThreeRisk update
        // - firstTotalEarnings is the earnings earned up to depositorThree risk update
        // - depositorOneRisk is the risk depositorOne had up to depositorThree risk update
        // - the total risk up until the depositorThree risk update is just the sum of the
        // risks of the depositors  upon deposit
        uint256 firstEarnings = (depositorOneRisk * firstTotalEarnings) /
            (depositorOneRisk + depositorTwoRisk + depositorThreeRisk);

        // store earnings up until now
        uint256 secondTotalEarnings = _totalEarnings();

        // use explicit values to calculate expected earnings
        // 2. earnings after  depositorThreeRisk update
        // - totalEarnings during the period is the difference of second and first total earnings
        // - depositorOneRisk is the risk depositorOne had up to depositorThree risk update
        // - the total risk after the depositorThree risk update is just the sum of the
        // risks of depositorOne and depositorTwo upon deposit, plus the updated depositorThree risk
        uint256 secondEarnings = (depositorOneRisk *
            (secondTotalEarnings - firstTotalEarnings)) /
            (depositorOneRisk + depositorTwoRisk + secondDepositorThreeRisk);

        expectedEarnings = firstEarnings + secondEarnings;

        // check earnings is correctly accounted for
        assertEq(
            expectedEarnings,
            _depositorEarnings(address(perpetualMint), depositorOne, COLLECTION)
        );

        // depositorFour will deposit so their earnings must be updated prior to the
        // deposit
        perpetualMint.exposed_updateDepositorEarnings(
            depositorFour,
            COLLECTION
        );

        // mock a deposit for depositorFour
        mock_deposit(
            depositorFour,
            COLLECTION,
            depositorFour,
            depositorFourTokenIds,
            depositorFourRisks,
            DUMMY_AMOUNTS
        );

        // check earnings for depositorFour are 0
        assertEq(
            0,
            _depositorEarnings(
                address(perpetualMint),
                depositorFour,
                COLLECTION
            )
        );

        // mock some earnings accrual for the COLLECTION via unsuccessful mints
        mock_unsuccessfulMintAttempts(COLLECTION, 1);

        // increment unsuccessful mint amount
        unsuccessfulMints += 1;

        // set new depositorFour risk
        depositorFourRisks[0] = secondDepositorFourRisk;

        // update depositor earnings via updateERC721TokenRisks
        // and set new risk for depositorFourTokenIds
        vm.prank(depositorFour);
        perpetualMint.updateERC721TokenRisks(
            COLLECTION,
            depositorFourTokenIds,
            depositorFourRisks
        );

        // store earnings up until now
        uint256 thirdTotalEarnings = _totalEarnings();

        // use explicit values to calculate expectedEarnings:
        // - total earnings in the period is the difference between the previous total earnings
        // and the current ones
        // - the total risk is the updated risks of depostirOne and depositorThree, the old risk of
        // depositorFour and the deposit risk of depositorTwo
        // - depositorFourRisk is the pertinent risk for this period
        expectedEarnings =
            (depositorFourRisk * (thirdTotalEarnings - secondTotalEarnings)) /
            (secondDepositorOneRisk +
                depositorTwoRisk +
                secondDepositorThreeRisk +
                depositorFourRisk);

        // there is some inaccuracy (< 20 wei) from rounding errors, so check that
        // resulting earnings are within +-50 wei of expectedEarnings
        assert(
            expectedEarnings + 50 wei >
                _depositorEarnings(
                    address(perpetualMint),
                    depositorFour,
                    COLLECTION
                ) ||
                expectedEarnings - 50 wei <
                _depositorEarnings(
                    address(perpetualMint),
                    depositorFour,
                    COLLECTION
                )
        );

        // update the earnings of all depositors
        perpetualMint.exposed_updateDepositorEarnings(depositorOne, COLLECTION);
        perpetualMint.exposed_updateDepositorEarnings(depositorTwo, COLLECTION);
        perpetualMint.exposed_updateDepositorEarnings(
            depositorThree,
            COLLECTION
        );

        // calculate total earnings of depositors
        // comes in three periods:
        // 1 - time until depositorTwo risk update
        // 2 - time until depositorOne risk update
        // 3 - time until depositorFour risk update (1 unsuccessful mint in between deposit + risk update)

        // depositorOne total earnings calculations
        // thirdEarings should be the updated depositorOneRisk for the time between the last earnings
        // and the more recent updateDepositorEarnings of depositorOne
        // - totalEarnings is the difference between the thirdTotalEarnings and secondTotalEarnings
        // - totalRisk is the sum of the updated depositorOne and depositorThree risks, and the deposit
        // risks of depositorFour and depositorTwo
        uint256 thirdEarnings = (secondDepositorOneRisk *
            (thirdTotalEarnings - secondTotalEarnings)) /
            (secondDepositorOneRisk +
                depositorTwoRisk +
                secondDepositorThreeRisk +
                depositorFourRisk);

        // the expected earnings are the sum of the first, second and third earnings
        expectedEarnings = firstEarnings + secondEarnings + thirdEarnings;

        // there is some inaccuracy (< 20 wei) from rounding errors, so check that
        // resulting earnings are within +-50 wei of expectedEarnings
        assert(
            expectedEarnings + 50 wei >
                _depositorEarnings(
                    address(perpetualMint),
                    depositorOne,
                    COLLECTION
                ) ||
                expectedEarnings - 50 wei <
                _depositorEarnings(
                    address(perpetualMint),
                    depositorOne,
                    COLLECTION
                )
        );

        // calculate depositorTwo earnings

        // the first earnings are the earnings up until depositorThree updated their risk
        // the second earnings are the earnings up until depositorOne updated their risk
        // the third earnings are the earnings up until depositorFour updated their risk (there were no more
        // earnings after this update)
        firstEarnings =
            (depositorTwoRisk * firstTotalEarnings) /
            (depositorOneRisk + depositorTwoRisk + depositorThreeRisk);
        secondEarnings =
            (depositorTwoRisk * (secondTotalEarnings - firstTotalEarnings)) /
            (depositorOneRisk + depositorTwoRisk + secondDepositorThreeRisk);
        thirdEarnings =
            (depositorTwoRisk * (thirdTotalEarnings - secondTotalEarnings)) /
            (secondDepositorOneRisk +
                depositorTwoRisk +
                secondDepositorThreeRisk +
                depositorFourRisk);

        expectedEarnings = firstEarnings + secondEarnings + thirdEarnings;

        // there is some inaccuracy (< 20 wei) from rounding errors, so check that
        // resulting earnings are within +-50 wei of expectedEarnings
        assert(
            expectedEarnings + 50 wei >
                _depositorEarnings(
                    address(perpetualMint),
                    depositorTwo,
                    COLLECTION
                ) ||
                expectedEarnings - 50 wei <
                _depositorEarnings(
                    address(perpetualMint),
                    depositorTwo,
                    COLLECTION
                )
        );

        // calculate depositor three earnings

        // the first earnings are the earnings up until depositorThree updated their risk
        // the second earnings are the earnings up until depositorOne updated their risk
        // the third earnings are the earnings up until depositorFour updated their risk (there were no more
        // earnings after this update)
        firstEarnings =
            (depositorThreeRisk * firstTotalEarnings) /
            (depositorOneRisk + depositorTwoRisk + depositorThreeRisk);
        secondEarnings =
            (secondDepositorThreeRisk *
                (secondTotalEarnings - firstTotalEarnings)) /
            (depositorOneRisk + depositorTwoRisk + secondDepositorThreeRisk);
        thirdEarnings =
            (secondDepositorThreeRisk *
                (thirdTotalEarnings - secondTotalEarnings)) /
            (secondDepositorOneRisk +
                depositorTwoRisk +
                secondDepositorThreeRisk +
                depositorFourRisk);

        expectedEarnings = firstEarnings + secondEarnings + thirdEarnings;

        // there is some inaccuracy (< 20 wei) from rounding errors, so check that
        // resulting earnings are within +-50 wei of expectedEarnings
        assert(
            expectedEarnings + 50 wei >
                _depositorEarnings(
                    address(perpetualMint),
                    depositorThree,
                    COLLECTION
                ) ||
                expectedEarnings - 50 wei <
                _depositorEarnings(
                    address(perpetualMint),
                    depositorThree,
                    COLLECTION
                )
        );
    }

    /// @notice calculates the total earnings from unsuccessful mints
    function _totalEarnings() internal view returns (uint256 earnings) {
        earnings = unsuccessfulMints * MINT_PRICE;
    }
}
