// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setConsolationFeeBP
/// @dev PerpetualMint test contract for testing expected behavior of the setConsolationFeeBP function
contract PerpetualMint_setConsolationFeeBP is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new consolation fee basis points to test, 1.0%
    uint32 newConsolationFeeBP = 10000000;

    function setUp() public override {
        super.setUp();

        // set consolation fee basis points to 0.5%
        perpetualMint.setConsolationFeeBP(TEST_CONSOLATION_FEE_BP);
    }

    /// @dev tests the setting of a new mint fee basis points
    function testFuzz_setConsolationFeeBP(
        uint32 _newConsolationFeeBP
    ) external {
        // it is assumed we will never set consolationFeeBP to 0
        if (_newConsolationFeeBP != 0) {
            assert(perpetualMint.consolationFeeBP() == TEST_CONSOLATION_FEE_BP);

            // if the new consolation fee BP is greater than the basis, the function should revert
            if (_newConsolationFeeBP > perpetualMint.BASIS()) {
                vm.expectRevert(IGuardsInternal.BasisExceeded.selector);
            }

            perpetualMint.setConsolationFeeBP(_newConsolationFeeBP);

            // if the new consolation fee BP was greater than the basis, the function should have reverted
            // and the consolation fee BP should not have been updated
            if (_newConsolationFeeBP > perpetualMint.BASIS()) {
                assert(
                    perpetualMint.consolationFeeBP() == TEST_CONSOLATION_FEE_BP
                );
            } else {
                assert(
                    perpetualMint.consolationFeeBP() == _newConsolationFeeBP
                );
            }
        }
    }

    /// @dev tests for the ConsolationFeeSet event emission after a new consolation fee is set
    function test_setConsolationFeeBPEmitsConsolationFeeSetEvent() external {
        vm.expectEmit();
        emit ConsolationFeeSet(newConsolationFeeBP);

        perpetualMint.setConsolationFeeBP(newConsolationFeeBP);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setConsolationFeeBPRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setConsolationFeeBP(newConsolationFeeBP);
    }
}
