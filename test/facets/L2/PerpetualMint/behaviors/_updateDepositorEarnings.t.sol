// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetuaMint_updateDepositorEarnings
/// @dev PerpetualMint test contract for testing expected behavior of the updateDepositorEarnings function
contract PerpetualMint_updateDepositorEarnings is
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant unsuccessfulMintAttempts = 1;

    // declare collection context for the test cases
    // as BORED_APE_YACHT_CLUB collection
    address internal constant COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev sets up the context for the test cases
    function setUp() public override {
        super.setUp();

        depositBoredApeYachtClubAssetsMock();

        mockUnsuccessfulCollectionMints(COLLECTION, unsuccessfulMintAttempts);
    }

    /// @dev asserts that _updateBaseMultiplier is called so the baseMultiplier and lastCollectionEarnings
    /// are updated
    function test_updateDepositorEarningsUpdatesBaseMultiplierWhenCollectionRiskIsNonZero()
        public
    {
        uint256 currentEarnings = _collectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 lastEarnings = _lastCollectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 baseMultiplier = (currentEarnings - lastEarnings) /
            _totalRisk(address(perpetualMint), COLLECTION);

        perpetualMint.exposed_updateDepositorEarnings(depositorOne, COLLECTION);

        assert(
            baseMultiplier ==
                _baseMultiplier(address(perpetualMint), COLLECTION)
        );

        assert(
            currentEarnings ==
                _lastCollectionEarnings(address(perpetualMint), COLLECTION)
        );
    }

    /// @dev tests that the earnings of a depositor are increased by the multiplier - multiplierOffset * totalDepositorRisk,
    /// if the totalDepositorRisk is non-zero
    function test_updateDepositorEarningsIncreasesDepositorEarningsWhenCollectionAndDepositorRisksAreNonZero()
        public
    {
        uint256 currentEarnings = _collectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 lastEarnings = _lastCollectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 baseMultiplier = (currentEarnings - lastEarnings) /
            _totalRisk(address(perpetualMint), COLLECTION);

        uint256 oldDepositorEarnings = _depositorEarnings(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );
        uint256 totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );
        uint256 multiplierOffset = _multiplierOffset(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        uint256 expectedEarnings = (baseMultiplier - multiplierOffset) *
            totalDepositorRisk;

        perpetualMint.exposed_updateDepositorEarnings(depositorOne, COLLECTION);

        assert(
            expectedEarnings + oldDepositorEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    depositorOne,
                    COLLECTION
                )
        );
    }

    /// @dev tests that upon updating depositor earnings, the depositors multiplierOffset is set to the baseMultiplier
    function test_updateDepositorEarningsSetsMultiplierOffsetOfDepositorToBaseMultiplierWhenTotalRiskOfCollcetionIsNonZero()
        public
    {
        perpetualMint.exposed_updateDepositorEarnings(depositorOne, COLLECTION);

        assert(
            _multiplierOffset(
                address(perpetualMint),
                depositorOne,
                COLLECTION
            ) == _baseMultiplier(address(perpetualMint), COLLECTION)
        );
    }
}
