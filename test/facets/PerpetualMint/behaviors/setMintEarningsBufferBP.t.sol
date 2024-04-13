// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setMintEarningsBufferBP
/// @dev PerpetualMint test contract for testing expected behavior of the setMintEarningsBufferBP function
contract PerpetualMint_setMintEarningsBufferBP is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new mint earnings buffer basis points to test, 20%
    uint32 newMintEarningsBufferBP = 20e7;

    function setUp() public override {
        super.setUp();

        // set mint earnings buffer basis points to 0.5%
        perpetualMint.setMintEarningsBufferBP(TEST_MINT_EARNINGS_BUFFER_BP);
    }

    /// @dev tests the setting of a new mint earnings buffer basis points
    function testFuzz_setMintEarningsBufferBP(
        uint32 _newMintEarningsBufferBP
    ) external {
        // it is assumed we will never set mintEarningsBufferBP to 0
        if (_newMintEarningsBufferBP != 0) {
            assert(
                perpetualMint.mintEarningsBufferBP() ==
                    TEST_MINT_EARNINGS_BUFFER_BP
            );

            // if the new mint earnings buffer BP is greater than the basis, the function should revert
            if (_newMintEarningsBufferBP > perpetualMint.BASIS()) {
                vm.expectRevert(IGuardsInternal.BasisExceeded.selector);
            }

            perpetualMint.setMintEarningsBufferBP(_newMintEarningsBufferBP);

            // if the new mint earnings buffer BP was greater than the basis, the function should have reverted
            // and the mint earnings buffer BP should not have been updated
            if (_newMintEarningsBufferBP > perpetualMint.BASIS()) {
                assert(
                    perpetualMint.mintEarningsBufferBP() ==
                        TEST_MINT_EARNINGS_BUFFER_BP
                );
            } else {
                assert(
                    perpetualMint.mintEarningsBufferBP() ==
                        _newMintEarningsBufferBP
                );
            }
        }
    }

    /// @dev tests for the MintEarningsBufferSet event emission after a new mint earnings buffer is set
    function test_setMintEarningsBufferBPEmitsMintEarningsBufferSetEvent()
        external
    {
        vm.expectEmit();
        emit MintEarningsBufferSet(newMintEarningsBufferBP);

        perpetualMint.setMintEarningsBufferBP(newMintEarningsBufferBP);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setMintEarningsBufferBPRevertsWhen_CallerIsNotOwner()
        external
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setMintEarningsBufferBP(newMintEarningsBufferBP);
    }
}
