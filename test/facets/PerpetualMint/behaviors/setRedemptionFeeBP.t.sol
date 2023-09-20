// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setRedemptionFeeBP
/// @dev PerpetualMint test contract for testing expected behavior of the setRedemptionFeeBP function
contract PerpetualMint_setRedemptionFeeBP is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev redemption fee basis points to test, 1.0%
    uint32 redemptionFeeBP = 10000000;

    function setUp() public override {
        super.setUp();
    }

    /// @dev tests the setting of a redemption fee basis points
    function testFuzz_setRedemptionFeeBP(uint32 _redemptionFeeBP) external {
        // it is assumed we will never set redemptionFeeBP to 0
        if (_redemptionFeeBP != 0) {
            assert(perpetualMint.redemptionFeeBP() == 0);

            // if the new redemption fee BP is greater than the basis, the function should revert
            if (_redemptionFeeBP > perpetualMint.BASIS()) {
                vm.expectRevert(IGuardsInternal.BasisExceeded.selector);
            }

            perpetualMint.setRedemptionFeeBP(_redemptionFeeBP);

            // if the new redemption fee BP was greater than the basis, the function should have reverted
            // and the redemption fee BP should not have been updated
            if (_redemptionFeeBP > perpetualMint.BASIS()) {
                assert(perpetualMint.redemptionFeeBP() == 0);
            } else {
                assert(perpetualMint.redemptionFeeBP() == _redemptionFeeBP);
            }
        }
    }

    /// @dev tests for the RedemptionFeeSet event emission after a new RedemptionFeeBP is set
    function test_setRedemptionFeeBPEmitsRedemptionFeeSetEvent() external {
        vm.expectEmit();
        emit RedemptionFeeSet(redemptionFeeBP);

        perpetualMint.setRedemptionFeeBP(redemptionFeeBP);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setRedemptionFeeBPRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setRedemptionFeeBP(redemptionFeeBP);
    }
}
