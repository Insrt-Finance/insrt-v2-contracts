// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setCollectionReferralPercentage
/// @dev PerpetualMint test contract for testing expected behavior of the setCollectionReferralPercentage function
contract PerpetualMint_setCollectionReferralPercentage is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev collection mint referral percentage to test;
    uint32 COLLECTION_REFERRAL_PERCENTAGE = baycCollectionReferralPercentage;

    /// @dev new collection mint referral percentage to test
    uint32 newCollectionReferralPercentage = 20000000; // 2%

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev tests the setting of a new collection referral percentage
    function testFuzz_setCollectionReferralPercentage(
        uint32 _newCollectionReferralPercentage
    ) external {
        assert(
            COLLECTION_REFERRAL_PERCENTAGE ==
                perpetualMint.collectionReferralPercentage(COLLECTION)
        );

        // if the new collection referral percentage is greater than the basis, the function should revert
        if (_newCollectionReferralPercentage > perpetualMint.BASIS()) {
            vm.expectRevert(IGuardsInternal.BasisExceeded.selector);
        }

        perpetualMint.setCollectionReferralPercentage(
            COLLECTION,
            _newCollectionReferralPercentage
        );

        if (_newCollectionReferralPercentage == 0) {
            // if the new collection referral percentage is 0, the collection referral percentage should be set to the default collection referral percentage
            assert(
                perpetualMint.defaultCollectionReferralPercentage() ==
                    perpetualMint.collectionReferralPercentage(COLLECTION)
            );
        } else {
            // if the new collection referral percentage was greater than the basis, the function should have reverted
            // and the collection mint referral percentage should not have changed
            if (_newCollectionReferralPercentage > perpetualMint.BASIS()) {
                assert(
                    COLLECTION_REFERRAL_PERCENTAGE ==
                        perpetualMint.collectionReferralPercentage(COLLECTION)
                );
            } else {
                assert(
                    _newCollectionReferralPercentage ==
                        perpetualMint.collectionReferralPercentage(COLLECTION)
                );
            }
        }
    }

    /// @dev tests for the CollectionReferralPercentageSet event emission after a new collection mint referral percentage is set
    function test_setCollectionReferralPercentageEmitsCollectionReferralPercentageSetEvent()
        external
    {
        vm.expectEmit();
        emit CollectionReferralPercentageSet(
            COLLECTION,
            newCollectionReferralPercentage
        );

        perpetualMint.setCollectionReferralPercentage(
            COLLECTION,
            newCollectionReferralPercentage
        );
    }

    /// @dev tests that setCollectionReferralPercentage updates the referral percentage for a collection when there is no specific referral percentage set (collection referral percentage is the default referral percentage)
    function test_setCollectionReferralPercentageUpdatesPriceFromDefaultPrice()
        external
    {
        perpetualMint.setCollectionReferralPercentage(COLLECTION, 0);

        /// @dev if the new collection referral percentage is 0, the collection referral percentage should be set to the default collection referral percentage
        assert(
            perpetualMint.defaultCollectionReferralPercentage() ==
                perpetualMint.collectionReferralPercentage(COLLECTION)
        );

        perpetualMint.setCollectionReferralPercentage(
            COLLECTION,
            newCollectionReferralPercentage
        );

        assert(
            newCollectionReferralPercentage ==
                perpetualMint.collectionReferralPercentage(COLLECTION)
        );
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setCollectionReferralPercentageRevertsWhen_CallerIsNotOwner()
        external
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setCollectionReferralPercentage(
            COLLECTION,
            newCollectionReferralPercentage
        );
    }
}
