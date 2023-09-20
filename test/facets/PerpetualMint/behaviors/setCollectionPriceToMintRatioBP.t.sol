// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setCollectionPriceToMintRatioBP
/// @dev PerpetualMint test contract for testing expected behavior of the setCollectionPriceToMintRatioBP function
contract PerpetualMint_setCollectionPriceToMintRatioBP is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new collection price to $MINT ratio basis points to test, 0.0001%
    uint32 newCollectionPriceToMintRatioBP = 1000;

    /// @dev tests the setting of a new collection price to $MINT ratio in basis points
    function testFuzz_setCollectionPriceToMintRatioBP(
        uint32 _newCollectionPriceToMintRatioBP
    ) external {
        // it is assumed we will never set collectionPriceToMintRatioBP to 0
        if (_newCollectionPriceToMintRatioBP > 0) {
            assert(perpetualMint.collectionPriceToMintRatioBP() == 0);

            perpetualMint.setCollectionPriceToMintRatioBP(
                _newCollectionPriceToMintRatioBP
            );

            assert(
                perpetualMint.collectionPriceToMintRatioBP() ==
                    _newCollectionPriceToMintRatioBP
            );
        }
    }

    /// @dev tests for the CollectionPriceToMintRatioSet event emission after a new collectionPriceToMintRatioBP is set
    function test_setCollectionPriceToMintRatioBPEmitsCollectionPriceToMintRatioSetEvent()
        external
    {
        vm.expectEmit();
        emit CollectionPriceToMintRatioSet(newCollectionPriceToMintRatioBP);

        perpetualMint.setCollectionPriceToMintRatioBP(
            newCollectionPriceToMintRatioBP
        );
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setCollectionPriceToMintRatioBPRevertsWhen_CallerIsNotOwner()
        external
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setCollectionPriceToMintRatioBP(
            newCollectionPriceToMintRatioBP
        );
    }
}
