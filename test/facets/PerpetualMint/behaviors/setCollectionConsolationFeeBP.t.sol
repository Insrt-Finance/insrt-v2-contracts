// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setCollectionConsolationFeeBP
/// @dev PerpetualMint test contract for testing expected behavior of the setCollectionConsolationFeeBP function
contract PerpetualMint_setCollectionConsolationFeeBP is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new mint for collection consolation fee basis points to test, 1.0%
    uint32 newCollectionConsolationFeeBP = 10000000;

    function setUp() public override {
        super.setUp();

        // set collection consolation fee basis points to 0.5%
        perpetualMint.setCollectionConsolationFeeBP(
            TEST_COLLECTION_CONSOLATION_FEE_BP
        );
    }

    /// @dev tests the setting of a new collection consolation fee basis points
    function testFuzz_setCollectionConsolationFeeBP(
        uint32 _newCollectionConsolationFeeBP
    ) external {
        // it is assumed we will never set collectionConsolationFeeBP to 0
        if (_newCollectionConsolationFeeBP != 0) {
            assert(
                perpetualMint.collectionConsolationFeeBP() ==
                    TEST_COLLECTION_CONSOLATION_FEE_BP
            );

            // if the new collection consolation fee BP is greater than the basis, the function should revert
            if (_newCollectionConsolationFeeBP > perpetualMint.BASIS()) {
                vm.expectRevert(IGuardsInternal.BasisExceeded.selector);
            }

            perpetualMint.setCollectionConsolationFeeBP(
                _newCollectionConsolationFeeBP
            );

            // if the new collection consolation fee BP was greater than the basis, the function should have reverted
            // and the collection consolation fee BP should not have been updated
            if (_newCollectionConsolationFeeBP > perpetualMint.BASIS()) {
                assert(
                    perpetualMint.collectionConsolationFeeBP() ==
                        TEST_COLLECTION_CONSOLATION_FEE_BP
                );
            } else {
                assert(
                    perpetualMint.collectionConsolationFeeBP() ==
                        _newCollectionConsolationFeeBP
                );
            }
        }
    }

    /// @dev tests for the CollectionConsolationFeeSet event emission after a new collection consolation fee is set
    function test_setCollectionConsolationFeeBPEmitsCollectionConsolationFeeSetEvent()
        external
    {
        vm.expectEmit();
        emit CollectionConsolationFeeSet(newCollectionConsolationFeeBP);

        perpetualMint.setCollectionConsolationFeeBP(
            newCollectionConsolationFeeBP
        );
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setCollectionConsolationFeeBPRevertsWhen_CallerIsNotOwner()
        external
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setCollectionConsolationFeeBP(
            newCollectionConsolationFeeBP
        );
    }
}
