// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { AssetType } from "../../contracts/enums/AssetType.sol";
import { PerpetualMintStorage as Storage } from "../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title DepositFacetMock
/// @dev mocks depositing asset into PerpetualMint
contract DepositFacetMock {
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

        if (l.collectionType[collection] == AssetType.ERC721) {
            l.totalRisk[collection] += risk;
            ++l.totalActiveTokens[collection];
            ++l.activeTokens[msg.sender][collection];
            l.totalDepositorRisk[msg.sender][collection] += risk;
            l.tokenRisk[collection][tokenId] = risk;
            l.escrowedERC721Owner[collection][tokenId] = msg.sender;
        } else {
            uint64 addedRisk = risk * uint64(amount);

            l.totalRisk[collection] += addedRisk;
            l.totalActiveTokens[collection] += amount;
            l.totalDepositorRisk[msg.sender][collection] += addedRisk;
            l.tokenRisk[collection][tokenId] += addedRisk;
            l.depositorTokenRisk[msg.sender][collection][tokenId] = risk;
            l.activeERC1155Owners[collection][tokenId].add(msg.sender);
            l.activeERC1155Tokens[msg.sender][collection][tokenId] += amount;
        }

        l.activeTokenIds[collection].add(tokenId);
    }
}
