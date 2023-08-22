// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @dev PerpetualMint_claimEarnings
/// @dev PerpetualMint test contract for testing expected behavior of the _claimEarnings function
contract PerpetualMint_claimEarnings is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant unsuccessfulMintAttempts = 10;

    // declare collection context for the test cases
    // as BORED_APE_YACHT_CLUB collection
    address internal constant COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev sets up the context for the test cases
    function setUp() public override {
        super.setUp();

        depositBoredApeYachtClubAssetsMock();

        // mocks unsuccessful mint attempts as a method to increase collection earnings
        mock_unsuccessfulMintAttempts(COLLECTION, unsuccessfulMintAttempts);

        // ensure contract has enough ETH to send to claimer
        vm.deal(address(perpetualMint), 50 ether);
    }

    /// @dev tests that the globalMultiplier, multiplierOffset for the depositor
    /// and depositorEarnings for the depositor are updated upon claiming earnings
    function test_claimEarningsUpdatesDepositorEarningsForDepositor() public {
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

        uint256 oldDepositorBalance = depositorOne.balance;

        vm.prank(depositorOne);
        perpetualMint.claimEarnings(COLLECTION);

        assert(
            baseMultiplier ==
                _baseMultiplier(address(perpetualMint), COLLECTION)
        );

        assert(
            currentEarnings ==
                _lastCollectionEarnings(address(perpetualMint), COLLECTION)
        );

        if (totalDepositorRisk != 0) {
            assert(
                expectedEarnings + oldDepositorEarnings ==
                    depositorOne.balance - oldDepositorBalance
            );
        }
    }

    /// @dev tests that depositorEarnings are set to zero
    function test_claimEarningsSetsDepositorEarningsToZero() public {
        perpetualMint.exposed_updateDepositorEarnings(depositorOne, COLLECTION);

        assertNotEq(
            0,
            _depositorEarnings(address(perpetualMint), depositorOne, COLLECTION)
        );

        vm.prank(depositorOne);
        perpetualMint.claimEarnings(COLLECTION);

        assertEq(
            0,
            _depositorEarnings(address(perpetualMint), depositorOne, COLLECTION)
        );
    }

    /// @dev tests that all earnings accrued are sent to the depositor from the
    /// PerpetualMint contract
    function test_claimEarningsSendsAllAccruedDepositorEarningsToDepositor()
        public
    {
        perpetualMint.exposed_updateDepositorEarnings(depositorOne, COLLECTION);

        uint256 earnings = _depositorEarnings(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        uint256 oldContractBalance = address(perpetualMint).balance;
        uint256 oldDepositorBalance = depositorOne.balance;

        vm.prank(depositorOne);
        perpetualMint.claimEarnings(COLLECTION);

        assertEq(earnings, depositorOne.balance - oldDepositorBalance);
        assertEq(earnings, oldContractBalance - address(perpetualMint).balance);
    }
}
