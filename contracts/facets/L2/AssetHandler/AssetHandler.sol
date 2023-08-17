// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { SolidStateLayerZeroClient } from "@solidstate/layerzero-client/SolidStateLayerZeroClient.sol";

import { IL2AssetHandler } from "./IAssetHandler.sol";
import { PerpetualMintStorage } from "../PerpetualMint/Storage.sol";
import { AssetType } from "../../../enums/AssetType.sol";
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

    /// @inheritdoc IL2AssetHandler
    function claimERC1155Assets(
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

        // Iterate over each tokenId
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // If the sender (claimer) does not have any ERC1155 tokens of the specified ID available to claim, revert the transaction
            if (
                perpetualMintStorageLayout.inactiveERC1155Tokens[msg.sender][
                    collection
                ][tokenIds[i]] == 0
            ) {
                revert ERC1155TokenNotEscrowed();
            }

            // Reduce the count of inactive ERC1155 tokens for the sender (claimer)
            perpetualMintStorageLayout.inactiveERC1155Tokens[msg.sender][
                collection
            ][tokenIds[i]] -= amounts[i];
        }

        _withdrawERC1155Assets(
            msg.sender,
            collection,
            layerZeroDestinationChainId,
            tokenIds,
            amounts
        );

        emit ERC1155AssetsWithdrawn(
            msg.sender,
            collection,
            msg.sender,
            tokenIds,
            amounts
        );
    }

    /// @inheritdoc IL2AssetHandler
    function claimERC721Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds
    ) external payable {
        PerpetualMintStorage.Layout
            storage perpetualMintStorageLayout = PerpetualMintStorage.layout();

        // Iterate over each token ID
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // If the sender (claimer) is not the escrowed owner of the ERC721 token,
            // or the token has not been removed from the active token IDs in the collection, revert the transaction
            if (
                perpetualMintStorageLayout.escrowedERC721Owner[collection][
                    tokenIds[i]
                ] !=
                msg.sender ||
                perpetualMintStorageLayout.activeTokenIds[collection].contains(
                    tokenIds[i]
                )
            ) {
                revert ERC721TokenNotEscrowed();
            }

            // Remove the sender (claimer) from the mapping of escrowed owners for the token ID
            perpetualMintStorageLayout.escrowedERC721Owner[collection][
                tokenIds[i]
            ] = address(0);
        }

        _withdrawERC721Assets(
            msg.sender,
            collection,
            layerZeroDestinationChainId,
            tokenIds
        );

        emit ERC721AssetsWithdrawn(
            msg.sender,
            collection,
            msg.sender,
            tokenIds
        );
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
        address beneficiary,
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

        // Iterate over each token ID
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // Reduce the count of active ERC1155 tokens for the sender (executor)
            perpetualMintStorageLayout.activeERC1155Tokens[msg.sender][
                collection
            ][tokenIds[i]] -= amounts[i];

            // Calculate the risk to be deducted based on the risk for each token and the amount to be withdrawn
            uint256 riskToBeDeducted = perpetualMintStorageLayout
                .depositorTokenRisk[msg.sender][collection][tokenIds[i]] *
                amounts[i];

            // If all tokens of a particular ID owned by the sender are withdrawn
            if (
                perpetualMintStorageLayout.activeERC1155Tokens[msg.sender][
                    collection
                ][tokenIds[i]] == 0
            ) {
                // Remove the sender from the list of active owners of the token ID
                perpetualMintStorageLayout
                .activeERC1155Owners[collection][tokenIds[i]].remove(
                        msg.sender
                    );

                // Reset the risk for the sender and the token ID
                // Currently, for ERC1155 tokens, the risk is the same for all token IDs in a collection
                perpetualMintStorageLayout.depositorTokenRisk[msg.sender][
                    collection
                ][tokenIds[i]] = 0;
            }

            // Reduce the total risk for the token ID in the collection
            perpetualMintStorageLayout.tokenRisk[collection][
                tokenIds[i]
            ] -= riskToBeDeducted;

            // If all tokens of a particular ID are withdrawn, remove the token ID from the list of active token IDs
            if (
                perpetualMintStorageLayout.tokenRisk[collection][tokenIds[i]] ==
                0
            ) {
                perpetualMintStorageLayout.activeTokenIds[collection].remove(
                    tokenIds[i]
                );
            }

            // Reduce the total count of active tokens in the collection
            perpetualMintStorageLayout.totalActiveTokens[collection] -= amounts[
                i
            ];

            // Reduce the total risk for the sender in the collection
            perpetualMintStorageLayout.totalDepositorRisk[msg.sender][
                collection
            ] -= riskToBeDeducted;

            // Reduce the total risk in the collection
            perpetualMintStorageLayout.totalRisk[
                collection
            ] -= riskToBeDeducted;
        }

        // If there are no more active tokens in the collection, remove the collection from the list of active collections
        if (perpetualMintStorageLayout.totalActiveTokens[collection] == 0) {
            perpetualMintStorageLayout.activeCollections.remove(collection);
        }

        _withdrawERC1155Assets(
            beneficiary,
            collection,
            layerZeroDestinationChainId,
            tokenIds,
            amounts
        );

        emit ERC1155AssetsWithdrawn(
            beneficiary,
            collection,
            msg.sender,
            tokenIds,
            amounts
        );
    }

    /// @inheritdoc IL2AssetHandler
    function withdrawERC721Assets(
        address beneficiary,
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds
    ) external payable {
        PerpetualMintStorage.Layout
            storage perpetualMintStorageLayout = PerpetualMintStorage.layout();

        // Iterate over each token ID
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // If the token is not escrowed by the sender, or the token has already
            // been removed from the active token IDs in the collection, revert the transaction.
            // This is to prevent the sender from withdrawing a token that has been idled (must be claimed instead).
            if (
                perpetualMintStorageLayout.escrowedERC721Owner[collection][
                    tokenIds[i]
                ] !=
                msg.sender ||
                !perpetualMintStorageLayout.activeTokenIds[collection].contains(
                    tokenIds[i]
                )
            ) {
                revert ERC721TokenNotEscrowed();
            }

            // Remove the token ID from the active token IDs in the collection
            perpetualMintStorageLayout.activeTokenIds[collection].remove(
                tokenIds[i]
            );

            // Decrement the count of active tokens for the sender in the collection
            --perpetualMintStorageLayout.activeTokens[msg.sender][collection];

            // Calculate the risk to be deducted based on the sender's risk for the token ID in the collection
            uint256 riskToBeDeducted = perpetualMintStorageLayout
                .depositorTokenRisk[msg.sender][collection][tokenIds[i]];

            // Reset the risk for the sender and the token ID in the collection
            perpetualMintStorageLayout.depositorTokenRisk[msg.sender][
                collection
            ][tokenIds[i]] = 0;

            // Reset the token as not escrowed by the sender
            perpetualMintStorageLayout.escrowedERC721Owner[collection][
                tokenIds[i]
            ] = address(0);

            // Reset the token risk for the token ID in the collection
            perpetualMintStorageLayout.tokenRisk[collection][tokenIds[i]] = 0;

            // Decrement the total number of active tokens in the collection
            --perpetualMintStorageLayout.totalActiveTokens[collection];

            // Deduct the risk from the total risk for the sender in the collection
            perpetualMintStorageLayout.totalDepositorRisk[msg.sender][
                collection
            ] -= riskToBeDeducted;

            // Deduct the risk from the total risk in the collection
            perpetualMintStorageLayout.totalRisk[
                collection
            ] -= riskToBeDeducted;
        }

        // If there are no active tokens in the collection, remove it from the active collections
        if (perpetualMintStorageLayout.totalActiveTokens[collection] == 0) {
            perpetualMintStorageLayout.activeCollections.remove(collection);
        }

        _withdrawERC721Assets(
            beneficiary,
            collection,
            layerZeroDestinationChainId,
            tokenIds
        );

        emit ERC721AssetsWithdrawn(
            msg.sender,
            collection,
            beneficiary,
            tokenIds
        );
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
        AssetType assetType = abi.decode(data, (AssetType));

        PerpetualMintStorage.Layout
            storage perpetualMintStorageLayout = PerpetualMintStorage.layout();

        if (assetType == AssetType.ERC1155) {
            // Decode the payload to get the depositor, the collection, the tokenIds and the amounts for each tokenId
            (
                ,
                address depositor,
                address collection,
                uint256[] memory risks,
                uint256[] memory tokenIds,
                uint256[] memory amounts
            ) = abi.decode(
                    data,
                    (
                        AssetType,
                        address,
                        address,
                        uint256[],
                        uint256[],
                        uint256[]
                    )
                );

            // Iterate over each token ID
            for (uint256 i = 0; i < tokenIds.length; ++i) {
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
                // Currently for ERC1155 tokens, the risk is always the same for all token IDs in the collection
                perpetualMintStorageLayout.depositorTokenRisk[depositor][
                    collection
                ][tokenIds[i]] = risks[i];

                uint256 totalAddedRisk = risks[i] * amounts[i];

                // Update the total risk for the token ID in the collection
                perpetualMintStorageLayout.tokenRisk[collection][
                    tokenIds[i]
                ] += totalAddedRisk;

                // Update the total number of active tokens in the collection
                perpetualMintStorageLayout.totalActiveTokens[
                    collection
                ] += amounts[i];

                // Update the total risk for the depositor in the collection
                perpetualMintStorageLayout.totalDepositorRisk[depositor][
                    collection
                ] += totalAddedRisk;

                // Update the total risk in the collection
                perpetualMintStorageLayout.totalRisk[
                    collection
                ] += totalAddedRisk;
            }

            // Add the collection to the set of active collections
            perpetualMintStorageLayout.activeCollections.add(collection);

            // Set the asset type for the collection
            perpetualMintStorageLayout.collectionType[collection] = assetType;

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
                uint256[] memory risks,
                uint256[] memory tokenIds
            ) = abi.decode(
                    data,
                    (AssetType, address, address, uint256[], uint256[])
                );

            // Iterate over each token ID
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                // Add the token ID to the set of active token IDs in the collection
                perpetualMintStorageLayout.activeTokenIds[collection].add(
                    tokenIds[i]
                );

                // Increment the count of active tokens for the depositor in the collection
                ++perpetualMintStorageLayout.activeTokens[depositor][
                    collection
                ];

                // Set the risk for the depositor and the token ID in the collection
                perpetualMintStorageLayout.depositorTokenRisk[depositor][
                    collection
                ][tokenIds[i]] = risks[i];

                // Mark the deposited ERC721 token as escrowed by the depositor in the collection
                perpetualMintStorageLayout.escrowedERC721Owner[collection][
                    tokenIds[i]
                ] = depositor;

                // Set the risk for the token ID in the collection
                perpetualMintStorageLayout.tokenRisk[collection][
                    tokenIds[i]
                ] = risks[i];

                // Increment the total number of active tokens in the collection
                ++perpetualMintStorageLayout.totalActiveTokens[collection];

                // Increase the total risk for the depositor in the collection
                perpetualMintStorageLayout.totalDepositorRisk[depositor][
                    collection
                ] += risks[i];

                // Increase the total risk in the collection
                perpetualMintStorageLayout.totalRisk[collection] += risks[i];
            }

            // Add the collection to the set of active collections
            perpetualMintStorageLayout.activeCollections.add(collection);

            // Set the asset type for the collection
            perpetualMintStorageLayout.collectionType[collection] = assetType;

            emit ERC721AssetsDeposited(depositor, collection, risks, tokenIds);
        }
    }

    /// @notice Withdraws ERC1155 assets cross-chain using LayerZero.
    /// @param beneficiary Address that will receive the deposited assets on the destination chain.
    /// @param collection Address of the ERC1155 collection.
    /// @param layerZeroDestinationChainId The LayerZero destination chain ID.
    /// @param tokenIds IDs of the tokens to be withdrawn.
    /// @param amounts The amounts of the tokens to be withdrawn.
    function _withdrawERC1155Assets(
        address beneficiary,
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private {
        _lzSend(
            layerZeroDestinationChainId,
            PayloadEncoder.encodeWithdrawERC1155AssetsPayload(
                beneficiary,
                collection,
                msg.sender,
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
    /// @param beneficiary Address that will receive the deposited assets on the destination chain.
    /// @param collection Address of the ERC721 collection.
    /// @param layerZeroDestinationChainId The LayerZero destination chain ID.
    /// @param tokenIds IDs of the tokens to be withdrawn.
    function _withdrawERC721Assets(
        address beneficiary,
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds
    ) private {
        _lzSend(
            layerZeroDestinationChainId,
            PayloadEncoder.encodeWithdrawERC721AssetsPayload(
                beneficiary,
                collection,
                msg.sender,
                tokenIds
            ),
            payable(msg.sender),
            address(0),
            "",
            msg.value
        );
    }
}
