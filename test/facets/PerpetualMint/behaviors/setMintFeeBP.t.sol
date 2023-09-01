// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title PerpetualMint_setMintFeeBP
/// @dev PerpetualMint test contract for testing expected behavior of the setMintFeeBP function
contract PerpetualMint_setMintFeeBP is ArbForkTest, PerpetualMintTest {
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

            perpetualMint.setMintFeeBP(_newMintFeeBP);

            assert(_newMintFeeBP == perpetualMint.mintFeeBP());
        }
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setMintFeeBPRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(NON_OWNER);
        perpetualMint.setMintFeeBP(newMintFeeBP);
    }
}
