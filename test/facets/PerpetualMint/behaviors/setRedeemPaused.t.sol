// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setRedeemPaused
/// @dev PerpetualMint test contract for testing expected behavior of the setRedeemPaused function
contract PerpetualMint_setRedeemPaused is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev tests that redeemPaused is updated after setRedeemPaused call
    function test_setRedeemPausedUpdatesStatusOfRedeemPaused() external {
        assert(perpetualMint.redeemPaused() == false);

        perpetualMint.setRedeemPaused(true);

        assert(perpetualMint.redeemPaused() == true);
    }

    /// @dev tests for the RedeemPausedSet event emission after a new status is set for redeemPaused
    function test_setRedeemPausedEmitsRedeemPausedSetEvent() external {
        vm.expectEmit();
        emit RedeemPausedSet(true);

        perpetualMint.setRedeemPaused(true);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setRedeemPausedRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setRedeemPaused(true);
    }
}
