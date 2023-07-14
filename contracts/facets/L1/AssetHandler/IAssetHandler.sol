// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IAssetHandler } from "../../../interfaces/IAssetHandler.sol";

/// @title IL1AssetHandler
/// @dev Defines interface for the L1AssetHandler contract. Extends IAssetHandler.
interface IL1AssetHandler is IAssetHandler {
    /// @notice Validates receipt of an ERC1155 batch transfer.
    /// @param operator Executor of transfer.
    /// @param from Sender of tokens.
    /// @param ids Token IDs received.
    /// @param values Quantities of tokens received.
    /// @param data Data payload.
    /// @return bytes4 Function's own selector if transfer is accepted.
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4);

    /// @notice Validates receipt of an ERC721 transfer.
    /// @param operator Executor of transfer.
    /// @param from Sender of tokens.
    /// @param tokenId Token ID received.
    /// @param data Data payload.
    /// @return bytes4 Function's own selector if transfer is accepted.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4);

    /// @notice Used to deposit ERC1155 assets.
    /// @dev Transfers the specified ERC1155 tokens from the user to this contract and deposits them cross-chain.
    /// @param collection The address of the ERC1155 token contract.
    /// @param layerZeroDestinationChainId The LayerZero destination chain ID.
    /// @param risks The risk settings for the assets being deposited..
    /// @param tokenIds An array of token IDs that the user wants to deposit.
    /// @param amounts An array of amounts for each respective token ID to be deposited.
    /// @notice The length of `tokenIds` and `amounts` arrays should be the same.
    function depositERC1155Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint64[] calldata risks,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable;

    /// @notice Used to deposit ERC721 assets.
    /// @dev Transfers the specified ERC721 tokens from the user to this contract and deposits them cross-chain.
    /// @param collection The address of the ERC721 token contract.
    /// @param layerZeroDestinationChainId The LayerZero destination chain ID.
    /// @param risks The risk settings for the assets being deposited..
    /// @param tokenIds An array of token IDs that the user wants to deposit.
    /// @notice Note: Each token ID in the array represents a unique asset to be deposited.
    function depositERC721Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint64[] calldata risks,
        uint256[] calldata tokenIds
    ) external payable;
}
