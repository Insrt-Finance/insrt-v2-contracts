// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title PerpetualMint_setConsolationFeeBP
/// @dev PerpetualMint test contract for testing expected behavior of the setConsolationFeeBP function
contract PerpetualMint_setConsolationFeeBP is ArbForkTest, PerpetualMintTest {
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

            perpetualMint.setConsolationFeeBP(_newConsolationFeeBP);

            assert(_newConsolationFeeBP == perpetualMint.consolationFeeBP());
        }
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setConsolationFeeBPRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(NON_OWNER);
        perpetualMint.setConsolationFeeBP(newConsolationFeeBP);
    }
}
