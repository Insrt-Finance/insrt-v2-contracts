// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setDefaultCollectionReferralFeeBP
/// @dev PerpetualMint test contract for testing expected behavior of the setDefaultCollectionReferralFeeBP function
contract PerpetualMint_setDefaultCollectionReferralFeeBP is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new default collection mint referral fee in basis points to test
    uint32 newCollectionReferralFeeBP = 20000000; // 2%

    /// @dev tests the setting of a new default collection referral fee in basis points
    function testFuzz_setDefaultCollectionReferralFeeBP(
        uint32 _newDefaultCollectionReferralFeeBP
    ) external {
        uint32 currentDefaultCollectionReferralFeeBP = perpetualMint
            .defaultCollectionReferralFeeBP();

        // if the new default collection referral fee BP is greater than the basis, the function should revert
        if (_newDefaultCollectionReferralFeeBP > perpetualMint.BASIS()) {
            vm.expectRevert(IGuardsInternal.BasisExceeded.selector);
        }

        perpetualMint.setDefaultCollectionReferralFeeBP(
            _newDefaultCollectionReferralFeeBP
        );

        // if the new default collection referral fee BP was greater than the basis, the function should have reverted
        // and the default collection mint referral fee BP should not have changed
        if (_newDefaultCollectionReferralFeeBP > perpetualMint.BASIS()) {
            assert(
                currentDefaultCollectionReferralFeeBP ==
                    perpetualMint.defaultCollectionReferralFeeBP()
            );
        } else {
            assert(
                _newDefaultCollectionReferralFeeBP ==
                    perpetualMint.defaultCollectionReferralFeeBP()
            );
        }
    }

    /// @dev tests for the DefaultCollectionReferralFeeBPSet event emission after a new default collection mint referral fee BP is set
    function test_setDefaultCollectionReferralFeeBPEmitsDefaultCollectionReferralFeeBPSetEvent()
        external
    {
        vm.expectEmit();
        emit DefaultCollectionReferralFeeBPSet(newCollectionReferralFeeBP);

        perpetualMint.setDefaultCollectionReferralFeeBP(
            newCollectionReferralFeeBP
        );
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setDefaultCollectionReferralFeeBPRevertsWhen_CallerIsNotOwner()
        external
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setDefaultCollectionReferralFeeBP(
            newCollectionReferralFeeBP
        );
    }
}
