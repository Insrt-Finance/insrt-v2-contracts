// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setCollectionRisk
/// @dev PerpetualMint test contract for testing expected behavior of the setCollectionRisk function
contract PerpetualMint_setCollectionRisk is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev collection risk to test;
    uint32 COLLECTION_RISK = baycCollectionRisk;

    /// @dev new collection risk to test
    uint32 newCollectionRisk = 20000000; // 2%

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev tests the setting of a new collection risk
    function testFuzz_setCollectionRisk(uint32 _newCollectionRisk) external {
        assert(COLLECTION_RISK == perpetualMint.collectionRisk(COLLECTION));

        // if the new collection risk is greater than the basis, the function should revert
        if (_newCollectionRisk > perpetualMint.BASIS()) {
            vm.expectRevert(IGuardsInternal.BasisExceeded.selector);
        }

        perpetualMint.setCollectionRisk(COLLECTION, _newCollectionRisk);

        if (_newCollectionRisk == 0) {
            // if the new collection risk is 0, the collection risk should be set to the default collection risk
            assert(
                perpetualMint.defaultCollectionRisk() ==
                    perpetualMint.collectionRisk(COLLECTION)
            );
        } else {
            // if the new collection risk was greater than the basis, the function should have reverted
            // and the collection risk should not have changed
            if (_newCollectionRisk > perpetualMint.BASIS()) {
                assert(
                    COLLECTION_RISK == perpetualMint.collectionRisk(COLLECTION)
                );
            } else {
                assert(
                    _newCollectionRisk ==
                        perpetualMint.collectionRisk(COLLECTION)
                );
            }
        }
    }

    /// @dev tests for the CollectionRiskSet event emission after a new collection risk is set
    function test_setCollectionRiskEmitsCollectionRiskSetEvent() external {
        vm.expectEmit();
        emit CollectionRiskSet(COLLECTION, newCollectionRisk);

        perpetualMint.setCollectionRisk(COLLECTION, newCollectionRisk);
    }

    /// @dev tests that setCollectionRisk updates the risk for a collection when there is no specific risk set (collection risk is the default risk)
    function test_setCollectionRiskUpdatesPriceFromDefaultPrice() external {
        perpetualMint.setCollectionRisk(COLLECTION, 0);

        /// @dev if the new collection risk is 0, the collection risk should be set to the default collection risk
        assert(
            perpetualMint.defaultCollectionRisk() ==
                perpetualMint.collectionRisk(COLLECTION)
        );

        perpetualMint.setCollectionRisk(COLLECTION, newCollectionRisk);

        assert(newCollectionRisk == perpetualMint.collectionRisk(COLLECTION));
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setCollectionRiskRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setCollectionRisk(COLLECTION, newCollectionRisk);
    }
}
