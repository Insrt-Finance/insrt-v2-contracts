// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { SolidStateLayerZeroClient } from "@solidstate/layerzero-client/SolidStateLayerZeroClient.sol";

import { IL2AssetHandler } from "./IAssetHandler.sol";
import { L2AssetHandlerStorage as Storage } from "./Storage.sol";
import { IAssetHandler } from "../../../interfaces/IAssetHandler.sol";
import { PayloadEncoder } from "../../../libraries/PayloadEncoder.sol";

/// @title L2AssetHandler
/// @dev Handles NFT assets on L2 and allows them to be deposited & withdrawn cross-chain via LayerZero.
contract L2AssetHandler is IL2AssetHandler, SolidStateLayerZeroClient {
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

        // For each tokenId, check if deposited amount is less than requested withdraw amount
        // If it is, revert the transaction with a custom error
        // If not, reduce deposited amount by withdraw amount
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (
                Storage.layout().depositedERC1155Assets[msg.sender][collection][
                    tokenIds[i]
                ] < amounts[i]
            ) {
                revert ERC1155TokenAmountExceedsDepositedAmount();
            }

            Storage.layout().depositedERC1155Assets[msg.sender][collection][
                tokenIds[i]
            ] -= amounts[i];
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
        // For each tokenId, check if token is deposited
        // If it's not, revert the transaction with a custom error
        // If it is, remove it from the set of deposited tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (
                Storage.layout().depositedERC721Assets[msg.sender][collection][
                    tokenIds[i]
                ] == false
            ) {
                revert ERC721TokenNotDeposited();
            }

            Storage.layout().depositedERC721Assets[msg.sender][collection][
                tokenIds[i]
            ] = false;
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

        if (assetType == PayloadEncoder.AssetType.ERC1155) {
            // Decode the payload to get the depositor, the collection, the tokenIds and the amounts for each tokenId
            (
                ,
                address depositor,
                address collection,
                uint64 risk,
                uint256[] memory tokenIds,
                uint256[] memory amounts
            ) = abi.decode(
                    data,
                    (
                        PayloadEncoder.AssetType,
                        address,
                        address,
                        uint64,
                        uint256[],
                        uint256[]
                    )
                );

            // Update the deposited ERC1155 assets in the contract's storage
            for (uint256 i = 0; i < tokenIds.length; i++) {
                Storage.layout().depositedERC1155Assets[depositor][collection][
                    tokenIds[i]
                ] += amounts[i];
            }

            emit ERC1155AssetsDeposited(
                depositor,
                collection,
                risk,
                tokenIds,
                amounts
            );
        } else {
            // Decode the payload to get the depositor, the collection, and the tokenIds
            (
                ,
                address depositor,
                address collection,
                uint64 risk,
                uint256[] memory tokenIds
            ) = abi.decode(
                    data,
                    (
                        PayloadEncoder.AssetType,
                        address,
                        address,
                        uint64,
                        uint256[]
                    )
                );

            // Update the deposited ERC721 assets in the contract's storage
            for (uint256 i = 0; i < tokenIds.length; i++) {
                Storage.layout().depositedERC721Assets[depositor][collection][
                    tokenIds[i]
                ] = true;
            }

            emit ERC721AssetsDeposited(depositor, collection, risk, tokenIds);
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
