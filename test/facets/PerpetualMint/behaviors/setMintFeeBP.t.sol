// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setMintFeeBP
/// @dev PerpetualMint test contract for testing expected behavior of the setMintFeeBP function
contract PerpetualMint_setMintFeeBP is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new mint fee basis points to test, 1.0%
    uint32 newMintFeeBP = 10000000;

    function setUp() public override {
        super.setUp();

        // set mint fee basis points to 0.5%
        perpetualMint.setMintFeeBP(TEST_MINT_FEE_BP);
    }

    /// @dev tests the setting of a new mint fee basis points
    function testFuzz_setMintFeeBP(uint32 _newMintFeeBP) external {
        // it is assumed we will never set mintFeeBP to 0
        if (_newMintFeeBP != 0) {
            assert(perpetualMint.mintFeeBP() == TEST_MINT_FEE_BP);

            // if the new mint fee BP is greater than the basis, the function should revert
            if (_newMintFeeBP > perpetualMint.BASIS()) {
                vm.expectRevert(IGuardsInternal.BasisExceeded.selector);
            }

            perpetualMint.setMintFeeBP(_newMintFeeBP);

            // if the new mint fee BP was greater than the basis, the function should have reverted
            // and the mint fee BP should not have been updated
            if (_newMintFeeBP > perpetualMint.BASIS()) {
                assert(perpetualMint.mintFeeBP() == TEST_MINT_FEE_BP);
            } else {
                assert(perpetualMint.mintFeeBP() == _newMintFeeBP);
            }
        }
    }

    /// @dev tests for the MintFeeSet event emission after a new MintFeeBP is set
    function test_setMintFeeBPEmitsMintFeeSetEvent() external {
        vm.expectEmit();
        emit MintFeeSet(newMintFeeBP);

        perpetualMint.setMintFeeBP(newMintFeeBP);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setMintFeeBPRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setMintFeeBP(newMintFeeBP);
    }
}
