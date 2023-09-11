// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @dev PerpetualMint_pause
/// @dev PerpetualMint test contract for testing expected behavior of the pause function
contract PerpetualMint_pause is ArbForkTest, PerpetualMintTest {
    /// @dev tests that calling pause sets paused state to true
    function test_pauseSetsPausedStateToTrue() external {
        perpetualMint.pause();

        assert(perpetualMint.paused() == true);
    }

    /// @dev tests that pause will revert if called by non-owner
    function test_pauseRevertsWhen_CalledByNonOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.pause();
    }
}
