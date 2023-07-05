// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { SolidStateLayerZeroClient } from "@solidstate/layerzero-client/SolidStateLayerZeroClient.sol";

import { IL1AssetHandler } from "./IAssetHandler.sol";
import { IAssetHandler } from "../../../interfaces/IAssetHandler.sol";
import { PayloadEncoder } from "../../../libraries/PayloadEncoder.sol";

/// @title L1AssetHandler
/// @dev Handles NFT assets on mainnet and allows them to be staked & unstaked cross-chain via LayerZero.
contract L1AssetHandler is IL1AssetHandler, SolidStateLayerZeroClient {
    /// @notice Deploys a new instance of the L1AssetHandler contract.
    constructor() {
        // Set initial ownership of the contract to the deployer
        _setOwner(msg.sender);
    }

    /// @inheritdoc IAssetHandler
    function getLayerZeroEndpoint()
        external
        view
        returns (address layerZeroEndpoint)
    {
        return _getLayerZeroEndpoint();
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

    /// TODO: add support for risk parameter
    /// @inheritdoc IL1AssetHandler
    function stakeERC1155Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable {
        // Check that the lengths of the tokenIds and amounts arrays match
        if (tokenIds.length != amounts.length) {
            revert ERC1155TokenIdsAndAmountsLengthMismatch();
        }

        IERC1155(collection).safeBatchTransferFrom(
            msg.sender,
            address(this),
            tokenIds,
            amounts,
            ""
        );

        _stakeERC1155Assets(
            collection,
            layerZeroDestinationChainId,
            tokenIds,
            amounts
        );

        emit ERC1155AssetsStaked(msg.sender, collection, tokenIds, amounts);
    }

    /// TODO: add support for risk parameter
    /// @inheritdoc IL1AssetHandler
    function stakeERC721Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds
    ) external payable {
        for (uint i = 0; i < tokenIds.length; i++) {
            IERC721(collection).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ""
            );
        }

        _stakeERC721Assets(collection, layerZeroDestinationChainId, tokenIds);

        emit ERC721AssetsStaked(msg.sender, collection, tokenIds);
    }

    /// @notice Handles received LayerZero cross-chain messages.
    /// @dev Overridden from the SolidStateLayerZeroClient contract. It processes data payloads based on the asset type and transfers unstaked NFT assets accordingly.
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
            // Decode the payload to get the sender, the collection, the tokenIds and the amounts for each tokenId
            (
                ,
                address sender,
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

            // Transfer the ERC1155 assets to the sender
            IERC1155(collection).safeBatchTransferFrom(
                address(this),
                sender,
                tokenIds,
                amounts,
                ""
            );

            emit ERC1155AssetsUnstaked(sender, collection, tokenIds, amounts);
        } else {
            // Decode the payload to get the sender, the collection, and the tokenIds
            (
                ,
                address sender,
                address collection,
                uint256[] memory tokenIds
            ) = abi.decode(
                    data,
                    (PayloadEncoder.AssetType, address, address, uint256[])
                );

            // Transfer the ERC721 assets to the sender
            for (uint i = 0; i < tokenIds.length; i++) {
                IERC721(collection).safeTransferFrom(
                    address(this),
                    sender,
                    tokenIds[i],
                    ""
                );
            }

            emit ERC721AssetsUnstaked(sender, collection, tokenIds);
        }
    }

    /// TODO: add support for risk parameter
    /// @notice Deposits ERC1155 assets cross-chain using LayerZero.
    /// @param collection Address of the ERC1155 collection.
    /// @param layerZeroDestinationChainId The LayerZero destination chain ID.
    /// @param tokenIds IDs of the tokens to be staked.
    /// @param amounts The amounts of the tokens to be staked.
    function _stakeERC1155Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private {
        _lzSend(
            layerZeroDestinationChainId,
            PayloadEncoder.encodeStakeERC1155AssetsPayload(
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

    /// TODO: add support for risk parameter
    /// @notice Deposits ERC721 assets cross-chain using LayerZero.
    /// @param collection Address of the ERC721 collection.
    /// @param layerZeroDestinationChainId The LayerZero destination chain ID.
    /// @param tokenIds IDs of the tokens to be staked.
    function _stakeERC721Assets(
        address collection,
        uint16 layerZeroDestinationChainId,
        uint256[] calldata tokenIds
    ) private {
        _lzSend(
            layerZeroDestinationChainId,
            PayloadEncoder.encodeStakeERC721AssetsPayload(
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
