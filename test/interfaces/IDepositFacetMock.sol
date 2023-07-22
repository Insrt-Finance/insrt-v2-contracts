// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { IERC721Receiver } from "@solidstate/contracts/interfaces/IERC721Receiver.sol";
import { IERC1155Receiver } from "@solidstate/contracts/interfaces/IERC1155Receiver.sol";

/// @title IDepositFacetMock
/// @dev interface for DepositFaceMock
interface IDepositFacetMock is IERC721Receiver, IERC1155Receiver {
    /// @notice deposit an ERC721/1155 asset into PerpetualMint
    /// @param collection address of collection
    /// @param tokenId id of token to deposit
    /// @param amount amount of tokens to deposit
    /// @param risk risk to set for deposited assets
    function depositAsset(
        address collection,
        uint256 tokenId,
        uint64 amount,
        uint64 risk
    ) external;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4);

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4);
}
