// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// @title IAssetHandlerEvents
/// @dev Defines the base interface for AssetHandler contract events.
interface IAssetHandlerEvents {
    /// @notice Emitted when ERC1155 assets are successfully staked.
    /// @param staker The indexed address of the staker.
    /// @param collection The indexed address of the ERC1155 collection.
    /// @param tokenIds Token IDs of the staked ERC1155 assets.
    /// @param amounts Amount of staked ERC1155 assets for each tokenId.
    event ERC1155AssetsStaked(
        address indexed staker,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] amounts
    );

    /// @notice Emitted when ERC1155 assets are successfully unstaked.
    /// @param staker The indexed address of the staker.
    /// @param collection The indexed address of the ERC1155 collection.
    /// @param tokenIds Token IDs of the unstaked ERC1155 assets.
    /// @param amounts Amount of unstaked ERC1155 assets for each tokenId.
    event ERC1155AssetsUnstaked(
        address indexed staker,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] amounts
    );

    /// @notice Emitted when ERC721 assets are successfully staked.
    /// @param staker The indexed address of the staker.
    /// @param collection The indexed address of the ERC721 collection.
    /// @param tokenIds Token IDs of the staked ERC721 assets.
    event ERC721AssetsStaked(
        address indexed staker,
        address indexed collection,
        uint256[] tokenIds
    );

    /// @notice Emitted when ERC721 assets are successfully unstaked.
    /// @param staker The indexed address of the staker.
    /// @param collection The indexed address of the ERC721 collection.
    /// @param tokenIds Token IDs of the unstaked ERC721 assets.
    event ERC721AssetsUnstaked(
        address indexed staker,
        address indexed collection,
        uint256[] tokenIds
    );
}
