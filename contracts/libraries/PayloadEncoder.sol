// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// @title PayloadEncoder
/// @dev Utility library for encoding stake and unstake NFT asset payloads.
/// Used to relay cross-chain messages using LayerZero.
library PayloadEncoder {
    /// @dev Prefix for ERC1155-related operations. Used to distinguish ERC1155 operations in payload.
    string private constant ERC1155_PREFIX = "ERC1155";

    /// @dev Prefix for ERC721-related operations. Used to distinguish ERC721 operations in payload.
    string private constant ERC721_PREFIX = "ERC721";

    /// @notice Encodes the payload for staking ERC-1155 assets cross-chain.
    /// @param staker Address of the staker.
    /// @param collection Address of the collection.
    /// @param tokenIds Array of token ids.
    /// @param amounts Array of amounts, corresponding to the token ids.
    /// @return payload The encoded payload.
    /// @dev Uses abi.encodePacked for tighter packing of the payload.
    function encodeStakeERC1155AssetsPayload(
        address staker,
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal pure returns (bytes memory payload) {
        // Pack the parameters into a dynamically-sized byte array
        payload = abi.encodePacked(
            ERC1155_PREFIX,
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
    /// @dev Uses abi.encodePacked for tighter packing of the payload.
    function encodeStakeERC721AssetsPayload(
        address staker,
        address collection,
        uint256[] calldata tokenIds
    ) internal pure returns (bytes memory payload) {
        // Pack the parameters into a dynamically-sized byte array
        payload = abi.encodePacked(ERC721_PREFIX, staker, collection, tokenIds);
    }

    /// @notice Encodes the payload for unstaking ERC-1155 assets cross-chain.
    /// @param staker Address of the staker.
    /// @param collection Address of the collection.
    /// @param tokenIds Array of token ids.
    /// @param amounts Array of amounts, corresponding to the token ids.
    /// @return payload The encoded payload.
    /// @dev Uses abi.encodePacked for tighter packing of the payload.
    function encodeUnstakeERC1155AssetsPayload(
        address staker,
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal pure returns (bytes memory payload) {
        payload = abi.encodePacked(
            ERC1155_PREFIX,
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
    /// @dev Uses abi.encodePacked for tighter packing of the payload.
    function encodeUnstakeERC721AssetsPayload(
        address staker,
        address collection,
        uint256[] calldata tokenIds
    ) internal pure returns (bytes memory payload) {
        payload = abi.encodePacked(ERC721_PREFIX, staker, collection, tokenIds);
    }
}
