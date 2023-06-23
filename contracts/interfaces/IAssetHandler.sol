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

    /// @notice Sets the LayerZero chain ID destination.
    /// @dev Only the contract owner can call this function.
    /// @param newDestinationLayerZeroChainId The new LayerZero chain ID where assets will be staked.
    function setLayerZeroChainIdDestination(
        uint16 newDestinationLayerZeroChainId
    ) external;
}
