// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

/// @title PayloadEncoder
/// @dev Utility library for encoding deposit and withdraw NFT asset payloads.
/// Used to relay cross-chain messages using LayerZero.
library PayloadEncoder {
    /// @notice Used to distinguish between different types of operations in the payload.
    /// @dev Each type of operation (ERC1155 or ERC721) is represented by an enum value.
    enum AssetType {
        ERC1155,
        ERC721
    }

    /// @notice Encodes the payload for depositing ERC-1155 assets cross-chain.
    /// @param depositor Address of the depositor.
    /// @param collection Address of the collection.
    /// @param risks The risk settings for the assets being deposited.
    /// @param tokenIds Array of token ids.
    /// @param amounts Array of amounts, corresponding to the token ids.
    /// @return payload The encoded payload.
    function encodeDepositERC1155AssetsPayload(
        address depositor,
        address collection,
        uint64[] calldata risks,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal pure returns (bytes memory payload) {
        // Pack the parameters into a dynamically-sized byte array
        payload = abi.encode(
            AssetType.ERC1155,
            depositor,
            collection,
            risks,
            tokenIds,
            amounts
        );
    }

    /// @notice Encodes the payload for depositing ERC-721 assets cross-chain.
    /// @param depositor Address of the depositor.
    /// @param collection Address of the collection.
    /// @param risks The risk settings for the assets being deposited.
    /// @param tokenIds Array of token ids.
    /// @return payload The encoded payload.
    function encodeDepositERC721AssetsPayload(
        address depositor,
        address collection,
        uint64[] calldata risks,
        uint256[] calldata tokenIds
    ) internal pure returns (bytes memory payload) {
        // Pack the parameters into a dynamically-sized byte array
        payload = abi.encode(
            AssetType.ERC721,
            depositor,
            collection,
            risks,
            tokenIds
        );
    }

    /// @notice Encodes the payload for withdrawing ERC-1155 assets cross-chain.
    /// @param depositor Address of the depositor.
    /// @param collection Address of the collection.
    /// @param tokenIds Array of token ids.
    /// @param amounts Array of amounts, corresponding to the token ids.
    /// @return payload The encoded payload.
    function encodeWithdrawERC1155AssetsPayload(
        address depositor,
        address collection,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal pure returns (bytes memory payload) {
        payload = abi.encode(
            AssetType.ERC1155,
            depositor,
            collection,
            tokenIds,
            amounts
        );
    }

    /// @notice Encodes the payload for withdrawing ERC-721 assets cross-chain.
    /// @param depositor Address of the depositor.
    /// @param collection Address of the collection.
    /// @param tokenIds Array of token ids.
    /// @return payload The encoded payload.
    function encodeWithdrawERC721AssetsPayload(
        address depositor,
        address collection,
        uint256[] calldata tokenIds
    ) internal pure returns (bytes memory payload) {
        payload = abi.encode(AssetType.ERC721, depositor, collection, tokenIds);
    }
}
