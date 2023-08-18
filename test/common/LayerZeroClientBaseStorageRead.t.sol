// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { LayerZeroClientBaseStorage } from "@solidstate/layerzero-client/base/LayerZeroClientBaseStorage.sol";

import "forge-std/Test.sol";

/// @title LayerZeroClientBaseStorageRead
/// @dev Helper test contract for reading from LayerZeroClientBaseStorage.
abstract contract LayerZeroClientBaseStorageRead is Test {
    /// @dev Returns the layerZeroEndpoint address for a given target address.
    /// @param target The target address to read the layerZeroEndpoint address from.
    /// @return layerZeroEndpoint The layerZeroEndpoint address for the given target address.
    function _layerZeroEndpoint(
        address target
    ) internal view returns (address layerZeroEndpoint) {
        // the layer zero endpoint address storage slot
        bytes32 layerZeroEndpointStorageSlot = LayerZeroClientBaseStorage
            .STORAGE_SLOT;

        // load the layerZeroEndpoint address from storage
        layerZeroEndpoint = address(
            uint160( // downcast to match address type
                uint256(vm.load(target, layerZeroEndpointStorageSlot)) // convert bytes32 to uint256
            )
        );
    }

    /// @dev Returns the trusted remote address for a given target address and destination chain ID.
    /// @param target The target address to read the trusted remote address from.
    /// @param destinationChainId The destination chain ID to read the trusted remote address from.
    /// @return trustedRemote The trusted remote address for the given target address and destination chain ID.
    function _trustedRemotes(
        address target,
        uint16 destinationChainId
    ) internal view returns (bytes memory trustedRemote) {
        // the trusted remote address records are stored in a mapping, so we need to compute the storage slot
        bytes32 trustedRemoteStorageSlot = keccak256(
            abi.encode(
                destinationChainId, // the LayerZero destination chain ID
                uint256(LayerZeroClientBaseStorage.STORAGE_SLOT) + 1 // the trustedRemotes storage slot
            )
        );

        // load the trusted remote address in bytes from storage
        trustedRemote = abi.encode(vm.load(target, trustedRemoteStorageSlot));
    }
}
