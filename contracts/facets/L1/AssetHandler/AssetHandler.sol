// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { SolidStateLayerZeroClient } from "@solidstate/layerzero-client/SolidStateLayerZeroClient.sol";

import { IL1AssetHandler } from "./IAssetHandler.sol";
import { AssetType } from "../../../enums/AssetType.sol";
import { IAssetHandler } from "../../../interfaces/IAssetHandler.sol";
import { PayloadEncoder } from "../../../libraries/PayloadEncoder.sol";

/// @title L1AssetHandler
/// @dev Handles NFT assets on mainnet and allows them to be deposited & withdrawn cross-chain via LayerZero.
contract L1AssetHandler is IL1AssetHandler, SolidStateLayerZeroClient {
    /// @notice Deploys a new instance of the L1AssetHandler contract.
    constructor() {
        // Set initial ownership of the contract to the deployer
        _setOwner(msg.sender);
    }

    /// @inheritdoc IL1AssetHandler
    function depositERC1155Assets(
        address owner,
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata risks,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable {
        // Checks that the lengths of the tokenIds, amounts, and risks arrays match
        if (
            tokenIds.length != amounts.length || risks.length != amounts.length
        ) {
            revert ERC1155TokenIdsAmountsAndRisksLengthMismatch();
        }

        IERC1155(collection).safeBatchTransferFrom(
            msg.sender,
            address(this),
            tokenIds,
            amounts,
            ""
        );

        _depositERC1155Assets(
            owner,
            collection,
            layerZeroDestinationChainId,
            risks,
            tokenIds,
            amounts
        );

        emit ERC1155AssetsDeposited(
            owner,
            collection,
            msg.sender,
            risks,
            tokenIds,
            amounts
        );
    }

    /// @inheritdoc IL1AssetHandler
    function depositERC721Assets(
        address owner,
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata risks,
        uint256[] calldata tokenIds
    ) external payable {
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                IERC721(collection).safeTransferFrom(
                    msg.sender,
                    address(this),
                    tokenIds[i],
                    ""
                );
            }
        }

        _depositERC721Assets(
            owner,
            collection,
            layerZeroDestinationChainId,
            risks,
            tokenIds
        );

        emit ERC721AssetsDeposited(
            owner,
            collection,
            msg.sender,
            risks,
            tokenIds
        );
    }

    /// @inheritdoc IL1AssetHandler
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @inheritdoc IL1AssetHandler
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
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

    /// @notice Handles received LayerZero cross-chain messages.
    /// @dev Overridden from the SolidStateLayerZeroClient contract. It processes data payloads based on the asset type and transfers withdrawn NFT assets accordingly.
    /// @param data The cross-chain message data payload. Decoded based on prefix and processed accordingly.
    function _handleLayerZeroMessage(
        uint16,
        bytes calldata,
        uint64,
        bytes calldata data
    ) internal override {
        // Decode the asset type from the payload. If the asset type is not supported, this call will revert.
        AssetType assetType = abi.decode(data, (AssetType));

        if (assetType == AssetType.ERC1155) {
            // Decode the payload to get the sender, the collection, the tokenIds and the amounts for each tokenId
            (
                ,
                address beneficiary,
                address collection,
                address executor,
                uint256[] memory tokenIds,
                uint256[] memory amounts
            ) = abi.decode(
                    data,
                    (AssetType, address, address, address, uint256[], uint256[])
                );

            // Transfer the ERC1155 assets to the sender
            IERC1155(collection).safeBatchTransferFrom(
                address(this),
                beneficiary,
                tokenIds,
                amounts,
                ""
            );

            emit ERC1155AssetsWithdrawn(
                beneficiary,
                collection,
                executor,
                tokenIds,
                amounts
            );
        } else {
            // Decode the payload to get the sender, the collection, and the tokenIds
            (
                ,
                address beneficiary,
                address collection,
                address executor,
                uint256[] memory tokenIds
            ) = abi.decode(
                    data,
                    (AssetType, address, address, address, uint256[])
                );

            // Transfer the ERC721 assets to the beneficiary
            unchecked {
                for (uint256 i = 0; i < tokenIds.length; ++i) {
                    IERC721(collection).safeTransferFrom(
                        address(this),
                        beneficiary,
                        tokenIds[i],
                        ""
                    );
                }
            }

            emit ERC721AssetsWithdrawn(
                beneficiary,
                collection,
                executor,
                tokenIds
            );
        }
    }

    /// @notice Deposits ERC1155 assets cross-chain using LayerZero.
    /// @param owner Address that will be given ownership for the deposited assets on the destination chain.
    /// @param collection Address of the ERC1155 collection.
    /// @param layerZeroDestinationChainId The LayerZero destination chain ID.
    /// @param risks The risk settings for the assets being deposited.
    /// @param tokenIds IDs of the tokens to be deposited.
    /// @param amounts The amounts of the tokens to be deposited.
    function _depositERC1155Assets(
        address owner,
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata risks,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private {
        _lzSend(
            layerZeroDestinationChainId,
            PayloadEncoder.encodeDepositERC1155AssetsPayload(
                owner,
                collection,
                msg.sender,
                risks,
                tokenIds,
                amounts
            ),
            payable(msg.sender),
            address(0),
            "",
            msg.value
        );
    }

    /// @notice Deposits ERC721 assets cross-chain using LayerZero.
    /// @param owner Address that will be given ownership for the deposited assets on the destination chain.
    /// @param collection Address of the ERC721 collection.
    /// @param layerZeroDestinationChainId The LayerZero destination chain ID.
    /// @param risks The risk settings for the assets being deposited.
    /// @param tokenIds IDs of the tokens to be deposited.
    function _depositERC721Assets(
        address owner,
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata risks,
        uint256[] calldata tokenIds
    ) private {
        _lzSend(
            layerZeroDestinationChainId,
            PayloadEncoder.encodeDepositERC721AssetsPayload(
                owner,
                collection,
                msg.sender,
                risks,
                tokenIds
            ),
            payable(msg.sender),
            address(0),
            "",
            msg.value
        );
    }
}
