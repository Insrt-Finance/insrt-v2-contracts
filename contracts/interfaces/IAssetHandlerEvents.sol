// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// @title IAssetHandlerEvents
/// @dev Defines the base interface for AssetHandler contract events.
interface IAssetHandlerEvents {
    /// @notice Emitted when ERC1155 assets are successfully deposited.
    /// @param depositor The indexed address of the depositor.
    /// @param collection The indexed address of the ERC1155 collection.
    /// @param risk The risk setting for the deposited assets.
    /// @param tokenIds Token IDs of the deposited ERC1155 assets.
    /// @param amounts Amount of deposited ERC1155 assets for each tokenId.
    event ERC1155AssetsDeposited(
        address indexed depositor,
        address indexed collection,
        uint64 risk,
        uint256[] tokenIds,
        uint256[] amounts
    );

    /// @notice Emitted when ERC1155 assets are successfully withdrawn.
    /// @param depositor The indexed address of the depositor.
    /// @param collection The indexed address of the ERC1155 collection.
    /// @param tokenIds Token IDs of the withdrawn ERC1155 assets.
    /// @param amounts Amount of withdrawn ERC1155 assets for each tokenId.
    event ERC1155AssetsWithdrawn(
        address indexed depositor,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] amounts
    );

    /// @notice Emitted when ERC721 assets are successfully deposited.
    /// @param depositor The indexed address of the depositor.
    /// @param collection The indexed address of the ERC721 collection.
    /// @param risk The risk setting for the deposited assets.
    /// @param tokenIds Token IDs of the deposited ERC721 assets.
    event ERC721AssetsDeposited(
        address indexed depositor,
        address indexed collection,
        uint64 risk,
        uint256[] tokenIds
    );

    /// @notice Emitted when ERC721 assets are successfully withdrawn.
    /// @param depositor The indexed address of the depositor.
    /// @param collection The indexed address of the ERC721 collection.
    /// @param tokenIds Token IDs of the withdrawn ERC721 assets.
    event ERC721AssetsWithdrawn(
        address indexed depositor,
        address indexed collection,
        uint256[] tokenIds
    );
}
