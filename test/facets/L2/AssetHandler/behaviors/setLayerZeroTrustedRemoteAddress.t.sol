// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { ILayerZeroClientBaseInternal } from "@solidstate/layerzero-client/base/ILayerZeroClientBaseInternal.sol";

import { L2AssetHandlerTest } from "../AssetHandler.t.sol";
import { ILayerZeroClientBaseInternalEvents } from "../../../../interfaces/ILayerZeroClientBaseInternalEvents.sol";

/// @title L2AssetHandler_setLayerZeroTrustedRemoteAddress
/// @dev L2AssetHandler test contract for testing expected setLayerZeroTrustedRemoteAddress behavior.
contract L2AssetHandler_setLayerZeroTrustedRemoteAddress is
    ILayerZeroClientBaseInternalEvents,
    L2AssetHandlerTest
{
    /// @dev Tests setLayerZeroTrustedRemoteAddress functionality.
    function test_setLayerZeroTrustedRemoteAddress() public {
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        bytes memory trustedRemoteAddressInBytes = l2AssetHandler
            .getLayerZeroTrustedRemoteAddress(DESTINATION_LAYER_ZERO_CHAIN_ID);

        assertEq(
            trustedRemoteAddressInBytes,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );
    }

    /// @dev Tests that setLayerZeroTrustedRemoteAddress emits SetTrustedRemote event.
    function test_setLayerZeroTrustedRemoteAddressEmitsSetTrustedRemoteEvent()
        public
    {
        vm.expectEmit();
        emit SetTrustedRemote(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bytes.concat(
                TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES,
                bytes20(address(l2AssetHandler))
            )
        );

        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );
    }

    /// @dev Tests that setLayerZeroTrustedRemoteAddress reverts when called by a non-owner address.
    function test_setLayerZeroTrustedRemoteAddressRevertsWhenCallerNotOwner()
        public
    {
        vm.prank(NON_OWNER_TEST_ADDRESS);
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );
    }

    /// @dev Tests that setLayerZeroTrustedRemoteAddress reverts when passed an empty remote address.
    function test_setLayerZeroTrustedRemoteAddressRevertsWhenPassedAnEmptyRemoteAddress()
        public
    {
        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            ""
        );
    }
}
