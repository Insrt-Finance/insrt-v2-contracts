// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setCollectionReferralFeeBP
/// @dev PerpetualMint test contract for testing expected behavior of the setCollectionReferralFeeBP function
contract PerpetualMint_setCollectionReferralFeeBP is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev collection mint referral fee in basis points to test;
    uint32 COLLECTION_REFERRAL_FEE_BP = baycCollectionReferralFeeBP;

    /// @dev new collection mint referral fee in basis points to test
    uint32 newCollectionReferralFeeBP = 20000000; // 2%

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev tests the setting of a new collection referral fee in basis points
    function testFuzz_setCollectionReferralFeeBP(
        uint32 _newCollectionReferralFeeBP
    ) external {
        assert(
            COLLECTION_REFERRAL_FEE_BP ==
                perpetualMint.collectionReferralFeeBP(COLLECTION)
        );

        // if the new collection referral fee BP is greater than the basis, the function should revert
        if (_newCollectionReferralFeeBP > perpetualMint.BASIS()) {
            vm.expectRevert(IGuardsInternal.BasisExceeded.selector);
        }

        perpetualMint.setCollectionReferralFeeBP(
            COLLECTION,
            _newCollectionReferralFeeBP
        );

        // if the new collection referral fee BP was greater than the basis, the function should have reverted
        // and the collection mint referral fee BP should not have changed
        if (_newCollectionReferralFeeBP > perpetualMint.BASIS()) {
            assert(
                COLLECTION_REFERRAL_FEE_BP ==
                    perpetualMint.collectionReferralFeeBP(COLLECTION)
            );
        } else {
            assert(
                _newCollectionReferralFeeBP ==
                    perpetualMint.collectionReferralFeeBP(COLLECTION)
            );
        }
    }

    /// @dev tests for the CollectionReferralFeeBPSet event emission after a new collection mint referral fee BP is set
    function test_setCollectionReferralFeeBPEmitsCollectionReferralFeeBPSetEvent()
        external
    {
        vm.expectEmit();
        emit CollectionReferralFeeBPSet(COLLECTION, newCollectionReferralFeeBP);

        perpetualMint.setCollectionReferralFeeBP(
            COLLECTION,
            newCollectionReferralFeeBP
        );
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setCollectionReferralFeeBPRevertsWhen_CallerIsNotOwner()
        external
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setCollectionReferralFeeBP(
            COLLECTION,
            newCollectionReferralFeeBP
        );
    }
}
