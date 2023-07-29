// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

/// @notice Used to distinguish between different types of collections supported by the protocol.
/// @dev Each type of supported asset is represented by an enum value.
/// The order of the enum values is important and should only be appended to over time.
/// Enums can be thought of as uint8 data types, with the maximum number of enum members being 256 (0-255).
enum AssetType {
    ERC1155,
    ERC721
}
