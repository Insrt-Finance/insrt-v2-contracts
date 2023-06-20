// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// @title IAssetHandler
/// @dev Defines the base interface for the AssetHandler contracts.
interface IAssetHandler {
    /// @notice Thrown when the length of the `tokenIds` array and the `amounts` array are not equal in the `stakeERC1155Assets` & `unstakeERC1155Assets` functions.
    error ERC1155TokenIdsAndAmountsLengthMismatch();

    /// @notice Thrown when a payload asset type is invalid and not supported.
    error InvalidPayloadAssetType();

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

    /// @notice Sets the LayerZero chain ID destination.
    /// @dev Only the contract owner can call this function.
    /// @param newDestinationLayerZeroChainId The new LayerZero chain ID where assets will be staked.
    function setLayerZeroChainIdDestination(
        uint16 newDestinationLayerZeroChainId
    ) external;
}
