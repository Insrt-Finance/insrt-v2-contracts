// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// @title IL1AssetHandler
/// @dev Defines methods for the L1AssetHandler contract.
interface IL1AssetHandler {
    /// @notice Thrown when the length of the `tokenIds` array and the `amounts` array are not equal in the `stakeERC1155Assets` function.
    error ERC1155TokenIdsAndAmountsLengthMismatch();

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

    /// @notice Emitted when ERC721 assets are successfully staked.
    /// @param staker The indexed address of the staker.
    /// @param collection The indexed address of the ERC721 collection.
    /// @param tokenIds Token IDs of the staked ERC721 assets.
    event ERC721AssetsStaked(
        address indexed staker,
        address indexed collection,
        uint256[] tokenIds
    );

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

    /// @notice Sets the LayerZero chain ID destination.
    /// @dev Only the contract owner can call this function.
    /// @param newDestinationLayerZeroChainId The new LayerZero chain ID where assets will be staked.
    function setLayerZeroChainIdDestination(
        uint16 newDestinationLayerZeroChainId
    ) external;

    /// @notice Used to stake and deposit ERC1155 assets.
    /// @dev Transfers the specified ERC1155 tokens from the user to this contract and deposits them cross-chain.
    /// @param collection The address of the ERC1155 token contract.
    /// @param tokenIds An array of token IDs that the user wants to stake.
    /// @param amounts An array of amounts for each respective token ID to be staked.
    /// @notice The length of `tokenIds` and `amounts` arrays should be the same.
    function stakeERC1155Assets(
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable;

    /// @notice Used to stake and deposit ERC721 assets.
    /// @dev Transfers the specified ERC721 tokens from the user to this contract and deposits them cross-chain.
    /// @param collection The address of the ERC721 token contract.
    /// @param tokenIds An array of token IDs that the user wants to stake.
    /// @notice Note: Each token ID in the array represents a unique asset to be staked.
    function stakeERC721Assets(
        address collection,
        uint256[] calldata tokenIds
    ) external payable;
}
