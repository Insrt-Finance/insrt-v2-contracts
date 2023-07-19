// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { L1AssetHandler } from "../../contracts/facets/L1/AssetHandler/AssetHandler.sol";

/// @title L1AssetHandlerMock
/// @dev Mock contract for L1AssetHandler test cases.
contract L1AssetHandlerMock is L1AssetHandler {
    /// @notice Mock function wrapper to call _handleLayerZeroMessage.
    /// @dev Allows for testing of _handleLayerZeroMessage behavior.
    /// All values except for data can be dummy values.
    /// @param sourceChainId LayerZero chain ID of the message source.
    /// @param path The encoded LayerZero trusted remote path.
    /// @param nonce The ordered message nonce.
    /// @param data The cross-chain message data payload. Decoded based on prefix and processed accordingly.
    function mock_HandleLayerZeroMessage(
        uint16 sourceChainId,
        bytes calldata path,
        uint64 nonce,
        bytes calldata data
    ) external {
        _handleLayerZeroMessage(sourceChainId, path, nonce, data);
    }
}
