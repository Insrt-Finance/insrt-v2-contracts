// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { SolidStateLayerZeroClient } from "@solidstate/layerzero-client/SolidStateLayerZeroClient.sol";

import { IL2AssetHandler } from "./IAssetHandler.sol";
import { L2AssetHandlerStorage } from "./Storage.sol";
import { PerpetualMintStorage } from "../PerpetualMint/Storage.sol";
import { IAssetHandler } from "../../../interfaces/IAssetHandler.sol";
import { PayloadEncoder } from "../../../libraries/PayloadEncoder.sol";

/// @title L2AssetHandler
/// @dev Handles NFT assets on L2 and allows them to be deposited & withdrawn cross-chain via LayerZero.
contract L2AssetHandler is IL2AssetHandler, SolidStateLayerZeroClient {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice Deploys a new instance of the L2AssetHandler contract.
    constructor() {
        // Set initial ownership of the contract to the deployer
        _setOwner(msg.sender);
    }

    /// @inheritdoc IAssetHandler
    function setLayerZeroEndpoint(
        address layerZeroEndpoint
    ) external onlyOwner {
        _setLayerZeroEndpoint(layerZeroEndpoint);
    }

    /// @inheritdoc IAssetHandler
    function setLayerZeroTrustedRemoteAddress(
        uint16 remoteChainId,
        bytes calldata trustedRemoteAddress
    ) external onlyOwner {
        _setTrustedRemoteAddress(remoteChainId, trustedRemoteAddress);
    }

    /// @inheritdoc IL2AssetHandler
    function withdrawERC1155Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable {
        // Check that the lengths of the tokenIds and amounts arrays match
        if (tokenIds.length != amounts.length) {
            revert ERC1155TokenIdsAndAmountsLengthMismatch();
        }

        PerpetualMintStorage.Layout
            storage perpetualMintStorageLayout = PerpetualMintStorage.layout();

        // For each tokenId, check if deposited amount is less than requested withdraw amount
        // If it is, revert the transaction with a custom error
        // If not, reduce deposited amount by withdraw amount
        for (uint256 i = 0; i < tokenIds.length; i++) {
            L2AssetHandlerStorage.layout().depositedERC1155Assets[msg.sender][
                collection
            ][tokenIds[i]] -= amounts[i];

            perpetualMintStorageLayout.activeERC1155Tokens[msg.sender][
                collection
            ][tokenIds[i]] -= amounts[i];

            uint64 riskToBeDeducted = perpetualMintStorageLayout
                .depositorTokenRisk[collection][msg.sender][tokenIds[i]] *
                uint64(amounts[i]);

            if (
                perpetualMintStorageLayout.activeERC1155Tokens[msg.sender][
                    collection
                ][tokenIds[i]] == 0
            ) {
                perpetualMintStorageLayout
                .activeERC1155Owners[collection][tokenIds[i]].remove(
                        msg.sender
                    );

                if (
                    perpetualMintStorageLayout
                    .activeERC1155Owners[collection][tokenIds[i]].length() == 0
                ) {
                    perpetualMintStorageLayout
                        .activeTokenIds[collection]
                        .remove(tokenIds[i]);
                }

                perpetualMintStorageLayout.depositorTokenRisk[collection][
                    msg.sender
                ][tokenIds[i]] = 0;
            }

            perpetualMintStorageLayout.totalActiveTokens[collection] -= amounts[
                i
            ];

            perpetualMintStorageLayout.totalDepositorRisk[collection][
                msg.sender
            ] -= riskToBeDeducted;

            perpetualMintStorageLayout.totalRisk[
                collection
            ] -= riskToBeDeducted;

            perpetualMintStorageLayout.totalTokenRisk[collection][
                tokenIds[i]
            ] -= riskToBeDeducted;
        }

        if (perpetualMintStorageLayout.totalActiveTokens[collection] == 0) {
            perpetualMintStorageLayout.activeCollections.remove(collection);
        }

        _withdrawERC1155Assets(
            collection,
            layerZeroDestinationChainId,
            tokenIds,
            amounts
        );

        emit ERC1155AssetsWithdrawn(msg.sender, collection, tokenIds, amounts);
    }

    /// @inheritdoc IL2AssetHandler
    function withdrawERC721Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds
    ) external payable {
        L2AssetHandlerStorage.Layout
            storage l2AssetHandlerStorageLayout = L2AssetHandlerStorage
                .layout();

        PerpetualMintStorage.Layout
            storage perpetualMintStorageLayout = PerpetualMintStorage.layout();

        // For each tokenId, check if token is deposited
        // If it's not, revert the transaction with a custom error
        // If it is, remove it from the set of deposited tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (
                l2AssetHandlerStorageLayout.depositedERC721Assets[msg.sender][
                    collection
                ][tokenIds[i]] == false
            ) {
                revert ERC721TokenNotDeposited();
            }

            l2AssetHandlerStorageLayout.depositedERC721Assets[msg.sender][
                collection
            ][tokenIds[i]] = false;

            perpetualMintStorageLayout.activeTokenIds[collection].remove(
                tokenIds[i]
            );

            perpetualMintStorageLayout.activeTokens[msg.sender][collection]--;

            uint64 riskToBeDeducted = perpetualMintStorageLayout
                .depositorTokenRisk[collection][msg.sender][tokenIds[i]];

            perpetualMintStorageLayout.depositorTokenRisk[collection][
                msg.sender
            ][tokenIds[i]] = 0;

            perpetualMintStorageLayout.tokenRisk[collection][
                tokenIds[i]
            ] -= riskToBeDeducted;

            perpetualMintStorageLayout.totalActiveTokens[collection]--;

            perpetualMintStorageLayout.totalDepositorRisk[collection][
                msg.sender
            ] -= riskToBeDeducted;

            perpetualMintStorageLayout.totalRisk[
                collection
            ] -= riskToBeDeducted;
        }

        if (perpetualMintStorageLayout.totalActiveTokens[collection] == 0) {
            perpetualMintStorageLayout.activeCollections.remove(collection);
        }

        _withdrawERC721Assets(
            collection,
            layerZeroDestinationChainId,
            tokenIds
        );

        emit ERC721AssetsWithdrawn(msg.sender, collection, tokenIds);
    }

    /// @notice Handles received LayerZero cross-chain messages.
    /// @dev Overridden from the SolidStateLayerZeroClient contract. It processes data payloads based on the asset type and updates deposited assets accordingly.
    /// @param data The cross-chain message data payload. Decoded based on prefix and processed accordingly.
    function _handleLayerZeroMessage(
        uint16,
        bytes calldata,
        uint64,
        bytes calldata data
    ) internal override {
        // Decode the asset type from the payload. If the asset type is not supported, this call will revert.
        PayloadEncoder.AssetType assetType = abi.decode(
            data,
            (PayloadEncoder.AssetType)
        );

        PerpetualMintStorage.Layout
            storage perpetualMintStorageLayout = PerpetualMintStorage.layout();

        if (assetType == PayloadEncoder.AssetType.ERC1155) {
            // Decode the payload to get the depositor, the collection, the tokenIds and the amounts for each tokenId
            (
                ,
                address depositor,
                address collection,
                uint64[] memory risks,
                uint256[] memory tokenIds,
                uint256[] memory amounts
            ) = abi.decode(
                    data,
                    (
                        PayloadEncoder.AssetType,
                        address,
                        address,
                        uint64[],
                        uint256[],
                        uint256[]
                    )
                );

            // Iterate over each token ID
            for (uint256 i = 0; i < tokenIds.length; i++) {
                // Update the amount of deposited ERC1155 assets for the depositor and the token ID in the collection
                L2AssetHandlerStorage.layout().depositedERC1155Assets[
                    depositor
                ][collection][tokenIds[i]] += amounts[i];

                // Add the depositor to the set of active owners for the token ID in the collection
                perpetualMintStorageLayout
                .activeERC1155Owners[collection][tokenIds[i]].add(depositor);

                // Update the amount of active ERC1155 tokens for the depositor and the token ID in the collection
                perpetualMintStorageLayout.activeERC1155Tokens[depositor][
                    collection
                ][tokenIds[i]] += amounts[i];

                // Add the token ID to the set of active token IDs in the collection
                perpetualMintStorageLayout.activeTokenIds[collection].add(
                    tokenIds[i]
                );

                // Set the risk for the depositor and the token ID in the collection
                perpetualMintStorageLayout.depositorTokenRisk[collection][
                    depositor
                ][tokenIds[i]] = risks[i];

                // Update the total number of active tokens in the collection
                perpetualMintStorageLayout.totalActiveTokens[
                    collection
                ] += amounts[i];

                uint64 totalAddedRisk = risks[i] * uint64(amounts[i]);

                // Update the total risk for the depositor in the collection
                perpetualMintStorageLayout.totalDepositorRisk[collection][
                    depositor
                ] += totalAddedRisk;

                // Update the total risk in the collection
                perpetualMintStorageLayout.totalRisk[
                    collection
                ] += totalAddedRisk;

                // Update the total risk for the token ID in the collection
                perpetualMintStorageLayout.totalTokenRisk[collection][
                    tokenIds[i]
                ] += totalAddedRisk;
            }

            // Add the collection to the set of active collections
            perpetualMintStorageLayout.activeCollections.add(collection);

            emit ERC1155AssetsDeposited(
                depositor,
                collection,
                risks,
                tokenIds,
                amounts
            );
        } else {
            // Decode the payload to get the depositor, the collection, and the tokenIds
            (
                ,
                address depositor,
                address collection,
                uint64[] memory risks,
                uint256[] memory tokenIds
            ) = abi.decode(
                    data,
                    (
                        PayloadEncoder.AssetType,
                        address,
                        address,
                        uint64[],
                        uint256[]
                    )
                );

            // Iterate over each token ID
            for (uint256 i = 0; i < tokenIds.length; i++) {
                // Mark the ERC721 token as deposited by the depositor in the collection
                L2AssetHandlerStorage.layout().depositedERC721Assets[depositor][
                    collection
                ][tokenIds[i]] = true;

                // Add the token ID to the set of active token IDs in the collection
                perpetualMintStorageLayout.activeTokenIds[collection].add(
                    tokenIds[i]
                );

                // Increment the count of active tokens for the depositor in the collection
                perpetualMintStorageLayout.activeTokens[depositor][
                    collection
                ]++;

                // Set the risk for the depositor and the token ID in the collection
                perpetualMintStorageLayout.depositorTokenRisk[collection][
                    depositor
                ][tokenIds[i]] = risks[i];

                // Increase the risk for the token ID in the collection
                perpetualMintStorageLayout.tokenRisk[collection][
                    tokenIds[i]
                ] += risks[i];

                // Increment the total number of active tokens in the collection
                perpetualMintStorageLayout.totalActiveTokens[collection]++;

                // Increase the total risk for the depositor in the collection
                perpetualMintStorageLayout.totalDepositorRisk[collection][
                    depositor
                ] += risks[i];

                // Increase the total risk in the collection
                perpetualMintStorageLayout.totalRisk[collection] += risks[i];
            }

            // Add the collection to the set of active collections
            perpetualMintStorageLayout.activeCollections.add(collection);

            emit ERC721AssetsDeposited(depositor, collection, risks, tokenIds);
        }
    }

    /// @notice Withdraws ERC1155 assets cross-chain using LayerZero.
    /// @param collection Address of the ERC1155 collection.
    /// @param layerZeroDestinationChainId The LayerZero destination chain ID.
    /// @param tokenIds IDs of the tokens to be withdrawn.
    /// @param amounts The amounts of the tokens to be withdrawn.
    function _withdrawERC1155Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private {
        _lzSend(
            layerZeroDestinationChainId,
            PayloadEncoder.encodeWithdrawERC1155AssetsPayload(
                msg.sender,
                collection,
                tokenIds,
                amounts
            ),
            payable(msg.sender),
            address(0),
            "",
            msg.value
        );
    }

    /// @notice Withdraws ERC721 assets cross-chain using LayerZero.
    /// @param collection Address of the ERC721 collection.
    /// @param layerZeroDestinationChainId The LayerZero destination chain ID.
    /// @param tokenIds IDs of the tokens to be withdrawn.
    function _withdrawERC721Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds
    ) private {
        _lzSend(
            layerZeroDestinationChainId,
            PayloadEncoder.encodeWithdrawERC721AssetsPayload(
                msg.sender,
                collection,
                tokenIds
            ),
            payable(msg.sender),
            address(0),
            "",
            msg.value
        );
    }
}
