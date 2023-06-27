// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IAssetHandlerEvents } from "./IAssetHandlerEvents.sol";

/// @title IAssetHandler
/// @dev Defines the base interface for the AssetHandler contracts.
interface IAssetHandler is IAssetHandlerEvents {
    /// @notice Thrown when the length of the `tokenIds` array and the `amounts` array are not equal in the `stakeERC1155Assets` & `unstakeERC1155Assets` functions.
    error ERC1155TokenIdsAndAmountsLengthMismatch();

    /// @notice Thrown when a payload asset type is invalid and not supported.
    error InvalidPayloadAssetType();

    /// @notice Returns the current LayerZero endpoint address for this contract.
    /// @return layerZeroEndpoint Address of the LayerZero endpoint.
    function getLayerZeroEndpoint()
        external
        view
        returns (address layerZeroEndpoint);

    /// @notice Returns the LayerZero trusted remote address for a given LayerZero chain ID.
    /// @param remoteChainId LayerZero remote chain ID.
    /// @return trustedRemoteAddress Trusted remote address encoded as bytes.
    function getLayerZeroTrustedRemoteAddress(
        uint16 remoteChainId
    ) external view returns (bytes memory trustedRemoteAddress);

    /// @notice Sets the LayerZero endpoint address for this contract.
    /// @dev Only the contract owner can call this function.
    /// @param layerZeroEndpoint Address of the LayerZero endpoint.
    function setLayerZeroEndpoint(address layerZeroEndpoint) external;

    /// @notice Sets the LayerZero trusted remote address for a given LayerZero chain ID.
    /// @dev Only the contract owner can call this function.
    /// @param remoteChainId LayerZero remote chain ID.
    /// @param trustedRemoteAddress Trusted remote address encoded as bytes.
    function setLayerZeroTrustedRemoteAddress(
        uint16 remoteChainId,
        bytes calldata trustedRemoteAddress
    ) external;
}
