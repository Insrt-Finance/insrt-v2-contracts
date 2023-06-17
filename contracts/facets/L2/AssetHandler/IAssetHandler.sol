// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// @title IL2AssetHandler
/// @dev Defines methods for the L2AssetHandler contract.
interface IL2AssetHandler {
    /// @notice Thrown when a user tries to unstake more ERC1155 tokens than they have staked. May implicitly signal that there are no tokens staked.
    error ERC1155TokenAmountExceedsStakedAmount();

    /// @notice Thrown when the length of the `tokenIds` array and the `amounts` array are not equal in the `unstakeERC1155Assets` function.
    error ERC1155TokenIdsAndAmountsLengthMismatch();

    /// @notice Thrown when a user tries to unstake an ERC721 token that is not staked.
    error ERC721TokenNotStaked();

    /// @notice Thrown when a payload prefix is invalid and not supported.
    error InvalidPayloadPrefix();

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
    /// @param newDestinationLayerZeroChainId The new LayerZero chain ID where assets will be unstaked.
    function setLayerZeroChainIdDestination(
        uint16 newDestinationLayerZeroChainId
    ) external;

    /// @notice Used to unstake and withdraw ERC1155 assets.
    /// @dev Debits specified ERC1155 tokens from the user and withdraws them cross-chain.
    /// @param collection The address of the ERC1155 token contract.
    /// @param tokenIds An array of token IDs that the user wants to unstake.
    /// @param amounts An array of amounts for each respective token ID to be unstaked.
    /// @notice The length of `tokenIds` and `amounts` arrays should be the same.
    function unstakeERC1155Assets(
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable;

    /// @notice Used to unstake and withdraw ERC721 assets.
    /// @dev Debits specified ERC721 tokens from the user and withdraws them cross-chain.
    /// @param collection The address of the ERC721 token contract.
    /// @param tokenIds An array of token IDs that the user wants to unstake.
    /// @notice Note: Each token ID in the array represents a unique asset to be unstaked.
    function unstakeERC721Assets(
        address collection,
        uint256[] calldata tokenIds
    ) external payable;
}
