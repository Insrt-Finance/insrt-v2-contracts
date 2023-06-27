// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IAssetHandler } from "../../../interfaces/IAssetHandler.sol";

/// @title IL2AssetHandler
/// @dev Defines interface for the L2AssetHandler contract. Extends IAssetHandler.
interface IL2AssetHandler is IAssetHandler {
    /// @notice Thrown when a user tries to unstake more ERC1155 tokens than they have staked. May implicitly signal that there are no tokens staked.
    error ERC1155TokenAmountExceedsStakedAmount();

    /// @notice Thrown when a user tries to unstake an ERC721 token that is not staked.
    error ERC721TokenNotStaked();

    /// @notice Used to unstake and withdraw ERC1155 assets.
    /// @dev Debits specified ERC1155 tokens from the user and withdraws them cross-chain.
    /// @param collection The address of the ERC1155 token contract.
    /// @param layerZeroDestinationChainId The destination chain ID.
    /// @param tokenIds An array of token IDs that the user wants to unstake.
    /// @param amounts An array of amounts for each respective token ID to be unstaked.
    /// @notice The length of `tokenIds` and `amounts` arrays should be the same.
    function unstakeERC1155Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable;

    /// @notice Used to unstake and withdraw ERC721 assets.
    /// @dev Debits specified ERC721 tokens from the user and withdraws them cross-chain.
    /// @param collection The address of the ERC721 token contract.
    /// @param layerZeroDestinationChainId The destination chain ID.
    /// @param tokenIds An array of token IDs that the user wants to unstake.
    /// @notice Note: Each token ID in the array represents a unique asset to be unstaked.
    function unstakeERC721Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds
    ) external payable;
}
