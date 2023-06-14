// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// @title PayloadEncoder
/// @dev Utility library for encoding stake and unstake NFT asset payloads.
/// Used to relay cross-chain messages using LayerZero.
library PayloadEncoder {
    /// @notice Encodes the payload for staking NFT assets cross-chain.
    /// @param staker Address of the staker.
    /// @param collection Address of the collection.
    /// @param tokenIds Array of token ids.
    /// @param amounts Array of amounts, corresponding to the token ids.
    /// @return payload The encoded payload.
    /// @dev Uses abi.encodePacked for tighter packing of the payload.
    function encodeStakeAssetPayload(
        address staker,
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal pure returns (bytes memory payload) {
        // Pack the parameters into a dynamically-sized byte array
        payload = abi.encodePacked(staker, collection, tokenIds, amounts);
    }

    /// @notice Encodes the payload for unstaking NFT assets cross-chain.
    /// @param staker Address of the staker.
    /// @param collection Address of the collection.
    /// @param tokenIds Array of token ids.
    /// @param amounts Array of amounts, corresponding to the token ids.
    /// @return payload The encoded payload.
    /// @dev Uses abi.encodePacked for tighter packing of the payload.
    function encodeUnstakeAssetPayload(
        address staker,
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal pure returns (bytes memory payload) {
        payload = abi.encodePacked(staker, collection, tokenIds, amounts);
    }
}
