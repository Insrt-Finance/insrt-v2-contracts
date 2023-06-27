// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// @title ILayerZeroClientBaseInternalEvents
/// @dev Defines the base interface for LayerZeroClientBaseInternal contract events.
interface ILayerZeroClientBaseInternalEvents {
    /// @notice Emitted when trusted remote address is successfully set for a given LayerZero chain ID.
    /// @param remoteChainId LayerZero remote chain ID.
    /// @param path Trusted remote address encoded as bytes.
    event SetTrustedRemote(uint16 remoteChainId, bytes path);
}
