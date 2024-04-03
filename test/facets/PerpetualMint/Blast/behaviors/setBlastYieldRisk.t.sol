// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest_SupraBlast } from "../Supra/PerpetualMint.t.sol"; // TODO: for now we are using the Supra version of the PerpetualMintTest contract
import { BlastForkTest } from "../../../../BlastForkTest.t.sol";
import { IGuardsInternal } from "../../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setBlastYieldRisk
/// @dev PerpetualMintTest_SupraBlast test contract for testing expected behavior of the setBlastYieldRisk function
contract PerpetualMint_setBlastYieldRisk is
    BlastForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest_SupraBlast
{
    /// @dev new blast yield risk to test
    uint32 newBlastYieldRisk = 20000000; // 2%

    /// @dev tests the setting of a new blast yield risk
    function testFuzz_setBlastYieldRisk(uint32 _newBlastYieldRisk) external {
        assert(TEST_BLAST_YIELD_RISK == perpetualMint.blastYieldRisk());

        // if the new blast yield risk is greater than the basis, the function should revert
        if (_newBlastYieldRisk > perpetualMint.BASIS()) {
            vm.expectRevert(IGuardsInternal.BasisExceeded.selector);
        }

        perpetualMint.setBlastYieldRisk(_newBlastYieldRisk);

        // if the new blast yield risk was greater than the basis, the function should have reverted
        // and the blast yield risk should not have changed
        if (_newBlastYieldRisk > perpetualMint.BASIS()) {
            assert(TEST_BLAST_YIELD_RISK == perpetualMint.blastYieldRisk());
        } else {
            assert(_newBlastYieldRisk == perpetualMint.blastYieldRisk());
        }
    }

    /// @dev tests for the BlastYieldRiskSet event emission after a new blast yield risk is set
    function test_setBlastYieldRiskEmitsBlastYieldRiskSetEvent() external {
        vm.expectEmit();
        emit BlastYieldRiskSet(newBlastYieldRisk);

        perpetualMint.setBlastYieldRisk(newBlastYieldRisk);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setBlastYieldRiskRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setBlastYieldRisk(newBlastYieldRisk);
    }
}
