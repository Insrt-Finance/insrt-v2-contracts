// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { SolidStateLayerZeroClient } from "@solidstate/layerzero-client/SolidStateLayerZeroClient.sol";

import { IL2AssetHandler } from "./IAssetHandler.sol";
import { L2AssetHandlerStorage as Storage } from "./Storage.sol";
import { IAssetHandler } from "../../../interfaces/IAssetHandler.sol";
import { PayloadEncoder } from "../../../libraries/PayloadEncoder.sol";

/// @title L2AssetHandler
/// @dev Handles NFT assets on L2 and allows them to be staked & unstaked cross-chain via LayerZero.
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
    function unstakeERC1155Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable {
        // Check that the lengths of the tokenIds and amounts arrays match
        if (tokenIds.length != amounts.length) {
            revert ERC1155TokenIdsAndAmountsLengthMismatch();
        }

        // For each tokenId, check if staked amount is less than requested unstake amount
        // If it is, revert the transaction with a custom error
        // If not, reduce staked amount by unstake amount
        for (uint i = 0; i < tokenIds.length; i++) {
            if (
                Storage.layout().stakedERC1155Assets[msg.sender][collection][
                    tokenIds[i]
                ] < amounts[i]
            ) {
                revert ERC1155TokenAmountExceedsStakedAmount();
            }

            Storage.layout().stakedERC1155Assets[msg.sender][collection][
                tokenIds[i]
            ] -= amounts[i];
        }

        _unstakeERC1155Assets(
            collection,
            layerZeroDestinationChainId,
            tokenIds,
            amounts
        );

        emit ERC1155AssetsUnstaked(msg.sender, collection, tokenIds, amounts);
    }

    /// @inheritdoc IL2AssetHandler
    function unstakeERC721Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds
    ) external payable {
        // For each tokenId, check if token is staked
        // If it's not, revert the transaction with a custom error
        // If it is, remove it from the set of staked tokens
        for (uint i = 0; i < tokenIds.length; i++) {
            if (
                Storage.layout().stakedERC721Assets[msg.sender][collection][
                    tokenIds[i]
                ] == false
            ) {
                revert ERC721TokenNotStaked();
            }

            Storage.layout().stakedERC721Assets[msg.sender][collection][
                tokenIds[i]
            ] = false;
        }

        _unstakeERC721Assets(collection, layerZeroDestinationChainId, tokenIds);

        emit ERC721AssetsUnstaked(msg.sender, collection, tokenIds);
    }

    /// @notice Handles received LayerZero cross-chain messages.
    /// @dev Overridden from the SolidStateLayerZeroClient contract. It processes data payloads based on the asset type and updates staked assets accordingly.
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
            // Decode the payload to get the staker, the collection, the tokenIds and the amounts for each tokenId
            (
                ,
                address staker,
                address collection,
                uint256[] memory tokenIds,
                uint256[] memory amounts
            ) = abi.decode(
                    data,
                    (
                        PayloadEncoder.AssetType,
                        address,
                        address,
                        uint256[],
                        uint256[]
                    )
                );

            // Update the staked ERC1155 assets in the contract's storage
            for (uint i = 0; i < tokenIds.length; i++) {
                Storage.layout().stakedERC1155Assets[staker][collection][
                    tokenIds[i]
                ] += amounts[i];
            }

            emit ERC1155AssetsStaked(staker, collection, tokenIds, amounts);
        } else {
            // Decode the payload to get the staker, the collection, and the tokenIds
            (
                ,
                address staker,
                address collection,
                uint256[] memory tokenIds
            ) = abi.decode(
                    data,
                    (PayloadEncoder.AssetType, address, address, uint256[])
                );

            // Update the staked ERC721 assets in the contract's storage
            for (uint i = 0; i < tokenIds.length; i++) {
                Storage.layout().stakedERC721Assets[staker][collection][
                    tokenIds[i]
                ] = true;
            }

            emit ERC721AssetsStaked(staker, collection, tokenIds);
        }
    }

    /// @notice Withdraws ERC1155 assets cross-chain using LayerZero.
    /// @param collection Address of the ERC1155 collection.
    /// @param layerZeroDestinationChainId The LayerZero destination chain ID.
    /// @param tokenIds IDs of the tokens to be unstaked.
    /// @param amounts The amounts of the tokens to be unstaked.
    function _unstakeERC1155Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private {
        _lzSend(
            layerZeroDestinationChainId,
            PayloadEncoder.encodeUnstakeERC1155AssetsPayload(
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
    /// @param tokenIds IDs of the tokens to be unstaked.
    function _unstakeERC721Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds
    ) private {
        _lzSend(
            layerZeroDestinationChainId,
            PayloadEncoder.encodeUnstakeERC721AssetsPayload(
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
