// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IERC1155Receiver } from "@solidstate/contracts/interfaces/IERC1155Receiver.sol";
import { IERC721Receiver } from "@solidstate/contracts/interfaces/IERC721Receiver.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { PerpetualMintStorage as Storage } from "../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title DepositFacetMock
/// @dev mocks depositing asset into PerpetualMint
contract DepositFacetMock is IERC721Receiver, IERC1155Receiver {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor() {}

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
    ) external {
        Storage.Layout storage l = Storage.layout();

        if (l.collectionType[collection]) {
            IERC721(collection).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId
            );

            l.totalRisk[collection] += risk;
            ++l.totalActiveTokens[collection];
            ++l.activeTokens[msg.sender][collection];
            l.totalDepositorRisk[msg.sender][collection] += risk;
            l.tokenRisk[collection][tokenId] = risk;
            l.escrowedERC721Owner[collection][tokenId] = msg.sender;
        } else {
            IERC1155(collection).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                amount,
                "0x"
            );

            uint64 addedRisk = risk * uint64(amount);

            l.totalRisk[collection] += addedRisk;
            l.totalActiveTokens[collection] += amount;
            l.totalDepositorRisk[msg.sender][collection] += addedRisk;
            l.tokenRisk[collection][tokenId] += addedRisk;
            l.escrowedERC1155Owners[collection][tokenId].add(msg.sender);
            l.depositorTokenRisk[msg.sender][collection][tokenId] = risk;
            l.activeERC1155Owners[collection][tokenId].add(msg.sender);
            l.activeERC1155Tokens[msg.sender][collection][tokenId] += amount;
            l.totalActiveTokenIdTokens[collection][tokenId] += amount;
        }

        l.activeTokenIds[collection].add(tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }
}
