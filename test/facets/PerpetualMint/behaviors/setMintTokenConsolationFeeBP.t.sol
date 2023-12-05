// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setMintTokenConsolationFeeBP
/// @dev PerpetualMint test contract for testing expected behavior of the setMintTokenConsolationFeeBP function
contract PerpetualMint_setMintTokenConsolationFeeBP is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new mint for $MINT consolation fee basis points to test, 1.0%
    uint32 newMintTokenConsolationFeeBP = 10000000;

    function setUp() public override {
        super.setUp();

        // set $MINT consolation fee basis points to 0.5%
        perpetualMint.setMintTokenConsolationFeeBP(
            TEST_MINT_TOKEN_CONSOLATION_FEE_BP
        );
    }

    /// @dev tests the setting of a new $MINT consolation fee basis points
    function testFuzz_setMintTokenConsolationFeeBP(
        uint32 _newMintTokenConsolationFeeBP
    ) external {
        // it is assumed we will never set mintTokenConsolationFeeBP to 0
        if (_newMintTokenConsolationFeeBP != 0) {
            assert(
                perpetualMint.mintTokenConsolationFeeBP() ==
                    TEST_MINT_TOKEN_CONSOLATION_FEE_BP
            );

            // if the new $MINT consolation fee BP is greater than the basis, the function should revert
            if (_newMintTokenConsolationFeeBP > perpetualMint.BASIS()) {
                vm.expectRevert(IGuardsInternal.BasisExceeded.selector);
            }

            perpetualMint.setMintTokenConsolationFeeBP(
                _newMintTokenConsolationFeeBP
            );

            // if the new $MINT consolation fee BP was greater than the basis, the function should have reverted
            // and the $MINT consolation fee BP should not have been updated
            if (_newMintTokenConsolationFeeBP > perpetualMint.BASIS()) {
                assert(
                    perpetualMint.mintTokenConsolationFeeBP() ==
                        TEST_MINT_TOKEN_CONSOLATION_FEE_BP
                );
            } else {
                assert(
                    perpetualMint.mintTokenConsolationFeeBP() ==
                        _newMintTokenConsolationFeeBP
                );
            }
        }
    }

    /// @dev tests for the MintTokenConsolationFeeSet event emission after a new $MINT consolation fee is set
    function test_setMintTokenConsolationFeeBPEmitsMintTokenConsolationFeeSetEvent()
        external
    {
        vm.expectEmit();
        emit MintTokenConsolationFeeSet(newMintTokenConsolationFeeBP);

        perpetualMint.setMintTokenConsolationFeeBP(
            newMintTokenConsolationFeeBP
        );
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setMintTokenConsolationFeeBPRevertsWhen_CallerIsNotOwner()
        external
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setMintTokenConsolationFeeBP(
            newMintTokenConsolationFeeBP
        );
    }
}
