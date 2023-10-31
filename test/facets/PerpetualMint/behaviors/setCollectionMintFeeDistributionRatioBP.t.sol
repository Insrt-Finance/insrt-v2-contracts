// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setCollectionMintFeeDistributionRatioBP
/// @dev PerpetualMint test contract for testing expected behavior of the setCollectionMintFeeDistributionRatioBP function
contract PerpetualMint_setCollectionMintFeeDistributionRatioBP is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new mint fee distribution ratio to test
    uint32 newMintFeeDistributionRatioBP = 5e8; // 50%

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev tests the setting of a new collection mint fee distribution ratio
    function testFuzz_setCollectionMintFeeDistributionRatioBP() external {
        assert(
            perpetualMint.collectionMintFeeDistributionRatioBP(COLLECTION) == 0
        );

        perpetualMint.setCollectionMintFeeDistributionRatioBP(
            COLLECTION,
            newMintFeeDistributionRatioBP
        );

        assert(
            newMintFeeDistributionRatioBP ==
                perpetualMint.collectionMintFeeDistributionRatioBP(COLLECTION)
        );
    }

    /// @dev tests for the CollectionMintFeeRatioUpdated event emission after a new collection mint fee distribution ratio is set
    function test_setCollectionMintFeeDistributionRatioBPEmitsCollectionMintFeeRatioUpdatedEvent()
        external
    {
        vm.expectEmit();
        emit CollectionMintFeeRatioUpdated(
            COLLECTION,
            newMintFeeDistributionRatioBP
        );

        perpetualMint.setCollectionMintFeeDistributionRatioBP(
            COLLECTION,
            newMintFeeDistributionRatioBP
        );
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setCollectionMintFeeDistributionRatioBPRevertsWhen_CallerIsNotOwner()
        external
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setCollectionMintFeeDistributionRatioBP(
            COLLECTION,
            newMintFeeDistributionRatioBP
        );
    }

    /// @dev ensures setCollectionMintFeeDistributionRatioBP reverts when new value is greater than basis
    function test_setCollectionMintFeeDistributionRatioBPRevertsWhen_NewBPValueIsGreaterThanBasis()
        public
    {
        uint32 newCollectionMintFeeDistributionRatioBP = perpetualMint.BASIS() +
            1;

        vm.expectRevert(IGuardsInternal.BasisExceeded.selector);

        perpetualMint.setCollectionMintFeeDistributionRatioBP(
            COLLECTION,
            newCollectionMintFeeDistributionRatioBP
        );
    }
}
