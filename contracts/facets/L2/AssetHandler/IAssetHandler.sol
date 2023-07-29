// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IAssetHandler } from "../../../interfaces/IAssetHandler.sol";

/// @title IL2AssetHandler
/// @dev Defines interface for the L2AssetHandler contract. Extends IAssetHandler.
interface IL2AssetHandler is IAssetHandler {
    /// @notice Thrown when a user tries to withdraw and claim an ERC1155 token that is not escrowed.
    error ERC1155TokenNotEscrowed();

    /// @notice Thrown when a user tries to withdraw or claim an ERC721 token that is not escrowed (deposited).
    error ERC721TokenNotEscrowed();

    /// @notice Used to claim ERC1155 assets.
    /// @dev Debits specified ERC1155 token claims from the user and withdraws them cross-chain.
    /// @param collection The address of the ERC1155 token contract.
    /// @param layerZeroSourceChainId The destination chain ID.
    /// @param tokenIds An array of token IDs that the user wants to claim and withdraw.
    /// @param amounts An array of amounts for each respective token ID to be claimed and withdrawn.
    function claimERC1155Assets(
        address collection,
        uint16 layerZeroSourceChainId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable;

    /// @notice Used to claim ERC721 assets.
    /// @dev Debits specified ERC721 token claims from the user and withdraws them cross-chain.
    /// @param collection The address of the ERC721 token contract.
    /// @param layerZeroSourceChainId The destination chain ID.
    /// @param tokenIds An array of token IDs that the user wants to claim and withdraw.
    function claimERC721Assets(
        address collection,
        uint16 layerZeroSourceChainId,
        uint256[] calldata tokenIds
    ) external payable;

    /// @notice Used to withdraw ERC1155 assets.
    /// @dev Debits specified ERC1155 tokens from the user and withdraws them cross-chain.
    /// @param collection The address of the ERC1155 token contract.
    /// @param layerZeroDestinationChainId The destination chain ID.
    /// @param tokenIds An array of token IDs that the user wants to withdraw.
    /// @param amounts An array of amounts for each respective token ID to be withdrawn.
    /// @notice The length of `tokenIds` and `amounts` arrays should be the same.
    function withdrawERC1155Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable;

    /// @notice Used to withdraw ERC721 assets.
    /// @dev Debits specified ERC721 tokens from the user and withdraws them cross-chain.
    /// @param collection The address of the ERC721 token contract.
    /// @param layerZeroDestinationChainId The destination chain ID.
    /// @param tokenIds An array of token IDs that the user wants to withdraw.
    /// @notice Note: Each token ID in the array represents a unique asset to be withdrawn.
    function withdrawERC721Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds
    ) external payable;
}
