// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setVRFSubscriptionBalanceThreshold
/// @dev PerpetualMint test contract for testing expected behavior of the setVRFSubscriptionBalanceThreshold function
contract PerpetualMint_setVRFSubscriptionBalanceThreshold is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new VRF subscription balance threshold to set, 300 LINK, 1e18
    uint96 newVRFSubscriptionBalanceThreshold = 300 ether;

    /// @dev tests the setting of a new collection price to $MINT ratio in basis points
    function testFuzz_setVRFSubscriptionBalanceThreshold(
        uint96 _newVRFSubscriptionBalanceThreshold
    ) external {
        // it is assumed we will never set vrfSubscriptionBalanceThreshold to 0
        if (_newVRFSubscriptionBalanceThreshold > 0) {
            assert(perpetualMint.vrfSubscriptionBalanceThreshold() == 0);

            perpetualMint.setVRFSubscriptionBalanceThreshold(
                _newVRFSubscriptionBalanceThreshold
            );

            assert(
                perpetualMint.vrfSubscriptionBalanceThreshold() ==
                    _newVRFSubscriptionBalanceThreshold
            );
        }
    }

    /// @dev tests for the VRFSubscriptionBalanceThresholdSet event emission after a new vrfSubscriptionBalanceThreshold is set
    function test_setVRFSubscriptionBalanceThresholdEmitsVRFSubscriptionBalanceThresholdSetEvent()
        external
    {
        vm.expectEmit();
        emit VRFSubscriptionBalanceThresholdSet(
            newVRFSubscriptionBalanceThreshold
        );

        perpetualMint.setVRFSubscriptionBalanceThreshold(
            newVRFSubscriptionBalanceThreshold
        );
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setVRFSubscriptionBalanceThresholdRevertsWhen_CallerIsNotOwner()
        external
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setVRFSubscriptionBalanceThreshold(
            newVRFSubscriptionBalanceThreshold
        );
    }
}
