// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setCollectionMintMultiplier
/// @dev PerpetualMint test contract for testing expected behavior of the setCollectionMintMultiplier function
contract PerpetualMint_setCollectionMintMultiplier is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new mint multiplier to test
    uint256 newMintMultiplier = 10e9; // 10x

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev tests the setting of a new collection mint multiplier
    function testFuzz_setCollectionMintMultiplier(
        uint256 _newMintMultiplier
    ) external {
        assert(
            perpetualMint.BASIS() ==
                perpetualMint.collectionMintMultiplier(COLLECTION)
        );

        perpetualMint.setCollectionMintMultiplier(
            COLLECTION,
            _newMintMultiplier
        );

        if (_newMintMultiplier == 0) {
            /// @dev if the new mint multplier is 0, the mint multiplier should be set to the default mint multiplier (BASIS)
            assert(
                perpetualMint.BASIS() ==
                    perpetualMint.collectionMintMultiplier(COLLECTION)
            );
        } else {
            assert(
                _newMintMultiplier ==
                    perpetualMint.collectionMintMultiplier(COLLECTION)
            );
        }
    }

    /// @dev tests for the CollectionMultiplierSet event emission after a new collection mint multiplier is set
    function test_setCollectionMintMultiplierEmitsCollectionMultiplierSetEvent()
        external
    {
        vm.expectEmit();
        emit CollectionMultiplierSet(COLLECTION, newMintMultiplier);

        perpetualMint.setCollectionMintMultiplier(
            COLLECTION,
            newMintMultiplier
        );
    }

    /// @dev tests that setCollectionMintMultiplier updates the mint multiplier for a collection when there is no specific multiplier set (collection mint multiplier is the default multiplier)
    function test_setCollectionMintMultiplierUpdatesMultiplierFromDefaultMultiplier()
        external
    {
        perpetualMint.setCollectionMintMultiplier(COLLECTION, 0);

        /// @dev if the new multiplier is 0, the mint multiplier should be set to the default mint multiplier (BASIS)
        assert(
            perpetualMint.BASIS() ==
                perpetualMint.collectionMintMultiplier(COLLECTION)
        );

        perpetualMint.setCollectionMintMultiplier(
            COLLECTION,
            newMintMultiplier
        );

        assert(
            newMintMultiplier ==
                perpetualMint.collectionMintMultiplier(COLLECTION)
        );
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setCollectionMintMultiplierRevertsWhen_CallerIsNotOwner()
        external
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setCollectionMintMultiplier(
            COLLECTION,
            newMintMultiplier
        );
    }
}
