// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @dev PerpetualMint_claimAllEarnings
/// @dev PerpetualMint test contract for testing expected behavior of the _claimAllEarnings function
contract PerpetualMint_claimAllEarnings is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant unsuccessfulMintAttempts = 10;

    // array used to hold collections being used to test functionality
    address[] internal collections;

    /// @dev sets up the context for the test cases
    function setUp() public override {
        super.setUp();

        depositBoredApeYachtClubAssetsMock();
        depositParallelAlphaAssetsMock();

        collections.push(BORED_APE_YACHT_CLUB);
        collections.push(PARALLEL_ALPHA);

        // mocks unsuccessful mint attempts as a method to increase collection earnings
        mock_unsuccessfulMintAttempts(
            BORED_APE_YACHT_CLUB,
            unsuccessfulMintAttempts
        );
        mock_unsuccessfulMintAttempts(PARALLEL_ALPHA, unsuccessfulMintAttempts);

        // ensure contract has enough ETH to send to claimer
        vm.deal(address(perpetualMint), 50 ether);
    }

    /// @dev tests that the globalMultiplier, multiplierOffset for the depositor
    /// and depositorEarnings for the depositor are updated upon claiming earnings,
    /// for all collections that depositor had earnings in
    function test_claimAllEarningsUpdatesDepositorEarningsForDepositorForEachCollections()
        public
    {
        uint256[] memory currentEarnings = new uint256[](2);
        uint256[] memory baseMultipliers = new uint256[](2);
        uint256[] memory totalDepositorRisks = new uint256[](2);
        uint256[] memory multiplierOffsets = new uint256[](2);

        uint256 oldDepositorEarnings;
        uint256 expectedEarnings;

        for (uint256 i; i < currentEarnings.length; ++i) {
            currentEarnings[i] = _collectionEarnings(
                address(perpetualMint),
                collections[i]
            );
            baseMultipliers[i] =
                (currentEarnings[i] -
                    _lastCollectionEarnings(
                        address(perpetualMint),
                        collections[i]
                    )) /
                _totalRisk(address(perpetualMint), collections[i]);

            totalDepositorRisks[i] = (
                _totalDepositorRisk(
                    address(perpetualMint),
                    depositorOne,
                    collections[i]
                )
            );

            multiplierOffsets[i] = (
                _multiplierOffset(
                    address(perpetualMint),
                    depositorOne,
                    collections[i]
                )
            );

            oldDepositorEarnings += _depositorEarnings(
                address(perpetualMint),
                depositorOne,
                collections[i]
            );
        }

        uint256 oldDepositorBalance = depositorOne.balance;

        vm.prank(depositorOne);
        perpetualMint.claimAllEarnings();

        for (uint256 i; i < currentEarnings.length; ++i) {
            assert(
                baseMultipliers[i] ==
                    _baseMultiplier(address(perpetualMint), collections[i])
            );

            assert(
                currentEarnings[i] ==
                    _lastCollectionEarnings(
                        address(perpetualMint),
                        collections[i]
                    )
            );

            expectedEarnings +=
                (baseMultipliers[i] - multiplierOffsets[i]) *
                totalDepositorRisks[i];
        }

        assert(
            expectedEarnings + oldDepositorEarnings ==
                depositorOne.balance - oldDepositorBalance
        );
    }

    /// @dev tests that depositorEarnings are set to zero for all collections depositor
    /// had earnings in
    function test_claimEarningsSetsDepositorEarningsToZero() public {
        for (uint256 i; i < collections.length; ++i) {
            perpetualMint.exposed_updateDepositorEarnings(
                depositorOne,
                collections[i]
            );

            assertNotEq(
                0,
                _depositorEarnings(
                    address(perpetualMint),
                    depositorOne,
                    collections[i]
                )
            );
        }

        vm.prank(depositorOne);
        perpetualMint.claimAllEarnings();

        for (uint256 i; i < collections.length; ++i) {
            assertEq(
                0,
                _depositorEarnings(
                    address(perpetualMint),
                    depositorOne,
                    collections[i]
                )
            );
        }
    }

    /// @dev tests that all earnings accrued are sent to the depositor from the
    /// PerpetualMint contract across all collections
    function test_claimEarningsSendsAllAccruedDepositorEarningsToDepositor()
        public
    {
        uint256 totalEarnings;

        for (uint256 i; i < collections.length; ++i) {
            perpetualMint.exposed_updateDepositorEarnings(
                depositorOne,
                collections[i]
            );

            totalEarnings += _depositorEarnings(
                address(perpetualMint),
                depositorOne,
                collections[i]
            );
        }

        uint256 oldContractBalance = address(perpetualMint).balance;
        uint256 oldDepositorBalance = depositorOne.balance;

        vm.prank(depositorOne);
        perpetualMint.claimAllEarnings();

        assertEq(totalEarnings, depositorOne.balance - oldDepositorBalance);
        assertEq(
            totalEarnings,
            oldContractBalance - address(perpetualMint).balance
        );
    }
}
