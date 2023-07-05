// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { ILayerZeroClientBaseInternal } from "@solidstate/layerzero-client/base/ILayerZeroClientBaseInternal.sol";
import { LayerZeroClientBaseStorage } from "@solidstate/layerzero-client/base/LayerZeroClientBaseStorage.sol";

import { L1AssetHandlerTest } from "../AssetHandler.t.sol";
import { ILayerZeroClientBaseInternalEvents } from "../../../../interfaces/ILayerZeroClientBaseInternalEvents.sol";

/// @title L1AssetHandler_setLayerZeroTrustedRemoteAddress
/// @dev L1AssetHandler test contract for testing expected setLayerZeroTrustedRemoteAddress behavior.
contract L1AssetHandler_setLayerZeroTrustedRemoteAddress is
    ILayerZeroClientBaseInternalEvents,
    L1AssetHandlerTest
{
    /// @dev Tests setLayerZeroTrustedRemoteAddress functionality.
    function test_setLayerZeroTrustedRemoteAddress() public {
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        // trusted remote address records are stored in a mapping, so we need to compute the storage slot
        bytes32 trustedRemoteAddressInBytesStorageSlot = keccak256(
            abi.encode(
                DESTINATION_LAYER_ZERO_CHAIN_ID, // the LayerZero destination chain ID
                uint256(LayerZeroClientBaseStorage.STORAGE_SLOT) + 1 // the trustedRemotes storage slot
            )
        );

        // load the trusted remote address in bytes from storage
        bytes memory trustedRemoteAddressInBytes = abi.encode(
            vm.load(
                address(l1AssetHandler),
                trustedRemoteAddressInBytesStorageSlot
            )
        );

        assertEq(
            bytes20(trustedRemoteAddressInBytes), // convert to bytes20 to remove padding
            bytes20(TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES)
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
                bytes20(address(l1AssetHandler))
            )
        );

        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
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

        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
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

        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            ""
        );
    }
}
