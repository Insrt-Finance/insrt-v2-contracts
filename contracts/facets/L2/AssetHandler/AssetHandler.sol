// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

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

    /// @inheritdoc IL2AssetHandler
    function claimERC1155Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        ERC1155Claim[] calldata claims
    ) external payable {
        PerpetualMintStorage.Layout
            storage perpetualMintStorageLayout = PerpetualMintStorage.layout();

        uint256[] memory amounts;
        uint256[] memory tokenIds;

        // Iterate over each claim
        for (uint256 i = 0; i < claims.length; ++i) {
            // If the sender (claimer) is not the escrowed claimant of the ERC1155 token, revert the transaction
            if (
                !perpetualMintStorageLayout
                .escrowedERC1155Owners[collection][claims[i].tokenId].contains(
                        msg.sender
                    )
            ) {
                revert ERC1155TokenNotEscrowed();
            }

            // Reduce the original owners' (depositors') claimable balance of the ERC1155 token
            perpetualMintStorageLayout.claimableERC1155Tokens[collection][
                claims[i].originalOwner
            ][claims[i].tokenId] -= claims[i].amount;

            // Reduce the senders' (claimants') claimable balance of the ERC1155 token
            perpetualMintStorageLayout.inactiveERC1155Tokens[msg.sender][
                collection
            ][claims[i].tokenId] -= claims[i].amount;

            // Reduce the original owners' (depositors') deposit balance of the ERC1155 token
            L2AssetHandlerStorage.layout().erc1155Deposits[
                claims[i].originalOwner
            ][collection][claims[i].tokenId] -= claims[i].amount;

            // If the claimant has no more ERC1155 tokens of a particular ID available to claim,
            // remove them from the list of escrowed claimants for the token ID
            if (
                perpetualMintStorageLayout.inactiveERC1155Tokens[msg.sender][
                    collection
                ][claims[i].tokenId] == 0
            ) {
                perpetualMintStorageLayout
                .escrowedERC1155Owners[collection][claims[i].tokenId].remove(
                        msg.sender
                    );
            }

            amounts[i] = claims[i].amount;
            tokenIds[i] = claims[i].tokenId;
        }

        _withdrawERC1155Assets(
            collection,
            layerZeroDestinationChainId,
            tokenIds,
            amounts
        );

        emit ERC1155AssetsClaimed(msg.sender, collection, claims);
    }

    /// @inheritdoc IL2AssetHandler
    function claimERC721Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        ERC721Claim[] calldata claims
    ) external payable {
        PerpetualMintStorage.Layout
            storage perpetualMintStorageLayout = PerpetualMintStorage.layout();

        uint256[] memory tokenIds;

        // Iterate over each claim
        for (uint256 i = 0; i < claims.length; ++i) {
            // If the sender (claimer) is not the escrowed claimant of the ERC721 token, revert the transaction
            if (
                perpetualMintStorageLayout.escrowedERC721Owner[collection][
                    claims[i].tokenId
                ] != msg.sender
            ) {
                revert ERC721TokenNotEscrowed();
            }

            // Reset the original owners' (depositors') deposit balance of the ERC721 token
            L2AssetHandlerStorage.layout().erc721Deposits[
                claims[i].originalOwner
            ][collection][claims[i].tokenId] = false;

            // Remove the sender (claimer) from the mapping of escrowed claimants for the token ID
            perpetualMintStorageLayout.escrowedERC721Owner[collection][
                claims[i].tokenId
            ] = address(0);

            tokenIds[i] = claims[i].tokenId;
        }

        _withdrawERC721Assets(
            collection,
            layerZeroDestinationChainId,
            tokenIds
        );

        emit ERC721AssetsClaimed(msg.sender, collection, claims);
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

        // Iterate over each token ID
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // Reduce the number of the deposited ERC1155 assets for the sender (depositor)
            L2AssetHandlerStorage.layout().erc1155Deposits[msg.sender][
                collection
            ][tokenIds[i]] -= amounts[i];

            // Reduce the count of active ERC1155 tokens for the sender (depositor)
            perpetualMintStorageLayout.activeERC1155Tokens[msg.sender][
                collection
            ][tokenIds[i]] -= amounts[i];

            // Calculate the risk to be deducted based on the risk for each token and the amount to be withdrawn
            uint64 riskToBeDeducted = perpetualMintStorageLayout
                .depositorTokenRisk[msg.sender][collection][tokenIds[i]] *
                uint64(amounts[i]);

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

                // If there are no more active owners for the token ID, remove the token ID from the list of active token IDs
                if (
                    perpetualMintStorageLayout
                    .activeERC1155Owners[collection][tokenIds[i]].length() == 0
                ) {
                    perpetualMintStorageLayout
                        .activeTokenIds[collection]
                        .remove(tokenIds[i]);
                }

                // Reset the risk for the sender and the token ID
                perpetualMintStorageLayout.depositorTokenRisk[msg.sender][
                    collection
                ][tokenIds[i]] = 0;
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

            // Reduce the total risk for the token ID in the collection
            perpetualMintStorageLayout.tokenRisk[collection][
                tokenIds[i]
            ] -= riskToBeDeducted;
        }

        // If there are no more active tokens in the collection, remove the collection from the list of active collections
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

        // Iterate over each token ID
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // If the token is not deposited by the sender, revert the transaction
            if (
                l2AssetHandlerStorageLayout.erc721Deposits[msg.sender][
                    collection
                ][tokenIds[i]] == false
            ) {
                revert ERC721TokenNotDeposited();
            }

            // Reset the token as not deposited by the sender
            l2AssetHandlerStorageLayout.erc721Deposits[msg.sender][collection][
                tokenIds[i]
            ] = false;

            // Remove the token ID from the active token IDs in the collection
            perpetualMintStorageLayout.activeTokenIds[collection].remove(
                tokenIds[i]
            );

            // Decrement the count of active tokens for the sender in the collection
            --perpetualMintStorageLayout.activeTokens[msg.sender][collection];

            // Calculate the risk to be deducted based on the sender's risk for the token ID in the collection
            uint64 riskToBeDeducted = perpetualMintStorageLayout
                .depositorTokenRisk[msg.sender][collection][tokenIds[i]];

            // Reset the risk for the sender and the token ID in the collection
            perpetualMintStorageLayout.depositorTokenRisk[msg.sender][
                collection
            ][tokenIds[i]] = 0;

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
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                // Update the amount of deposited ERC1155 assets for the depositor and the token ID in the collection
                L2AssetHandlerStorage.layout().erc1155Deposits[depositor][
                    collection
                ][tokenIds[i]] += amounts[i];

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
                perpetualMintStorageLayout.depositorTokenRisk[depositor][
                    collection
                ][tokenIds[i]] = risks[i];

                // Update the total number of active tokens in the collection
                perpetualMintStorageLayout.totalActiveTokens[
                    collection
                ] += amounts[i];

                uint64 totalAddedRisk = risks[i] * uint64(amounts[i]);

                // Update the total risk for the depositor in the collection
                perpetualMintStorageLayout.totalDepositorRisk[depositor][
                    collection
                ] += totalAddedRisk;

                // Update the total risk in the collection
                perpetualMintStorageLayout.totalRisk[
                    collection
                ] += totalAddedRisk;

                // Update the total risk for the token ID in the collection
                perpetualMintStorageLayout.tokenRisk[collection][
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
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                // Mark the ERC721 token as deposited by the depositor in the collection
                L2AssetHandlerStorage.layout().erc721Deposits[depositor][
                    collection
                ][tokenIds[i]] = true;

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
        uint256[] memory tokenIds,
        uint256[] memory amounts
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
        uint256[] memory tokenIds
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
