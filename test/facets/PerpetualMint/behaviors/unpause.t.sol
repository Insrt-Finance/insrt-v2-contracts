// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @dev PerpetualMint_unpause
/// @dev PerpetualMint test contract for testing expected behavior of the unpause function
contract PerpetualMint_unpause is ArbForkTest, PerpetualMintTest {
    /// @dev tests that calling unpause sets paused state to false
    function test_unpauseSetsunpausedStateToTrue() external {
        assert(perpetualMint.paused() == false);

        perpetualMint.pause();

        assert(perpetualMint.paused() == true);

        perpetualMint.unpause();

        assert(perpetualMint.paused() == false);
    }

    /// @dev tests that unpause will revert if called by non-owner
    function test_unpauseRevertsWhen_CalledByNonOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.unpause();
    }
}
