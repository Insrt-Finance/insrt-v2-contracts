// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// @title PayloadEncoder
/// @dev Utility library for encoding stake and unstake NFT asset payloads.
/// Used to relay cross-chain messages using LayerZero.
library PayloadEncoder {
    /// @notice Used to distinguish between different types of operations in the payload.
    /// @dev Each type of operation (ERC1155 or ERC721) is represented by an enum value.
    enum AssetType {
        ERC1155,
        ERC721
    }

    /// @notice Encodes the payload for staking ERC-1155 assets cross-chain.
    /// @param staker Address of the staker.
    /// @param collection Address of the collection.
    /// @param tokenIds Array of token ids.
    /// @param amounts Array of amounts, corresponding to the token ids.
    /// @return payload The encoded payload.
    function encodeStakeERC1155AssetsPayload(
        address staker,
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal pure returns (bytes memory payload) {
        // Pack the parameters into a dynamically-sized byte array
        payload = abi.encode(
            AssetType.ERC1155,
            staker,
            collection,
            tokenIds,
            amounts
        );
    }

    /// @notice Encodes the payload for staking ERC-721 assets cross-chain.
    /// @param staker Address of the staker.
    /// @param collection Address of the collection.
    /// @param tokenIds Array of token ids.
    /// @return payload The encoded payload.
    function encodeStakeERC721AssetsPayload(
        address staker,
        address collection,
        uint256[] calldata tokenIds
    ) internal pure returns (bytes memory payload) {
        // Pack the parameters into a dynamically-sized byte array
        payload = abi.encode(AssetType.ERC721, staker, collection, tokenIds);
    }

    /// @notice Encodes the payload for unstaking ERC-1155 assets cross-chain.
    /// @param staker Address of the staker.
    /// @param collection Address of the collection.
    /// @param tokenIds Array of token ids.
    /// @param amounts Array of amounts, corresponding to the token ids.
    /// @return payload The encoded payload.
    function encodeUnstakeERC1155AssetsPayload(
        address staker,
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal pure returns (bytes memory payload) {
        payload = abi.encode(
            AssetType.ERC1155,
            staker,
            collection,
            tokenIds,
            amounts
        );
    }

    /// @notice Encodes the payload for unstaking ERC-721 assets cross-chain.
    /// @param staker Address of the staker.
    /// @param collection Address of the collection.
    /// @param tokenIds Array of token ids.
    /// @return payload The encoded payload.
    function encodeUnstakeERC721AssetsPayload(
        address staker,
        address collection,
        uint256[] calldata tokenIds
    ) internal pure returns (bytes memory payload) {
        payload = abi.encode(AssetType.ERC721, staker, collection, tokenIds);
    }
}
