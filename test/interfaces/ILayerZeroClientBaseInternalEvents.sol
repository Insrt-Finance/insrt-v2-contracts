// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// @title ILayerZeroClientBaseInternalEvents
/// @dev Defines the base interface for LayerZeroClientBaseInternal contract events.
interface ILayerZeroClientBaseInternalEvents {
    /// @notice Emitted when a message is successfully sent to a LayerZero remote trusted address on a remote chain.
    /// @param destinationChainId LayerZero destination chain ID.
    /// @param payload The cross-chain message data payload.
    /// @param refundAddress The address to refund the surplus native gas message fee to.
    /// @param zroPaymentAddress The address of the ZRO token holder who would pay for the transaction. Currently unused.
    /// @param adapterParams Adapter parameters for custom functionality.
    /// @param nativeFee The native gas message fee.
    event MessageSent(
        uint16 destinationChainId,
        bytes payload,
        address refundAddress,
        address zroPaymentAddress,
        bytes adapterParams,
        uint256 nativeFee
    );

    /// @notice Emitted when trusted remote address is successfully set for a given LayerZero chain ID.
    /// @param remoteChainId LayerZero remote chain ID.
    /// @param path Trusted remote address encoded as bytes.
    event SetTrustedRemote(uint16 remoteChainId, bytes path);
}
