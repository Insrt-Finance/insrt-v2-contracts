// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { SolidStateLayerZeroClient } from "@solidstate/layerzero-client/SolidStateLayerZeroClient.sol";

import { IL1AssetHandler } from "./IAssetHandler.sol";
import { L1AssetHandlerStorage as Storage } from "./Storage.sol";
import { IAssetHandler } from "../../../interfaces/IAssetHandler.sol";
import { PayloadEncoder } from "../../../libraries/PayloadEncoder.sol";

/// @title L1AssetHandler
/// @dev Handles NFT assets on mainnet and allows them to be staked & unstaked cross-chain via LayerZero.
contract L1AssetHandler is IL1AssetHandler, SolidStateLayerZeroClient {
    /// @notice Deploys a new instance of the L1AssetHandler contract.
    /// @param layerZeroEndpoint Address of the LayerZero endpoint.
    /// @param destinationLayerZeroChainId LayerZero chain ID used to determine the chain where assets will be staked.
    constructor(address layerZeroEndpoint, uint16 destinationLayerZeroChainId) {
        Storage
            .layout()
            .DESTINATION_LAYER_ZERO_CHAIN_ID = destinationLayerZeroChainId;

        // Set the LayerZero endpoint address for this contract
        _setLayerZeroEndpoint(layerZeroEndpoint);

        // Set initial ownership of the contract to the deployer
        _setOwner(msg.sender);
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
    function setLayerZeroChainIdDestination(
        uint16 newDestinationLayerZeroChainId
    ) external onlyOwner {
        Storage
            .layout()
            .DESTINATION_LAYER_ZERO_CHAIN_ID = newDestinationLayerZeroChainId;
    }

    /// TODO: add support for risk parameter
    /// @inheritdoc IL1AssetHandler
    function stakeERC1155Assets(
        address collection,
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

        _stakeERC1155Assets(collection, tokenIds, amounts);

        emit ERC1155AssetsStaked(msg.sender, collection, tokenIds, amounts);
    }

    /// TODO: add support for risk parameter
    /// @inheritdoc IL1AssetHandler
    function stakeERC721Assets(
        address collection,
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

        _stakeERC721Assets(collection, tokenIds);

        emit ERC721AssetsStaked(msg.sender, collection, tokenIds);
    }

    /// @notice Handles received LayerZero cross-chain messages.
    /// @dev Overridden from the SolidStateLayerZeroClient contract. It processes data payloads based on the prefix and transfers unstaked NFT assets accordingly.
    /// @param data The cross-chain message data payload. Decoded based on profix and processed accordingly.
    function _handleLayerZeroMessage(
        uint16,
        bytes calldata,
        uint64,
        bytes calldata data
    ) internal override {
        // Decode the prefix from the payload
        PayloadEncoder.Prefix prefix = abi.decode(
            data,
            (PayloadEncoder.Prefix)
        );

        if (prefix == PayloadEncoder.Prefix.ERC1155) {
            // Decode the payload to get the sender, the collection, the tokenIds and the amounts for each tokenId
            (
                address sender,
                address collection,
                uint256[] memory tokenIds,
                uint256[] memory amounts
            ) = abi.decode(data, (address, address, uint256[], uint256[]));

            // Transfer the ERC1155 assets to the sender
            IERC1155(collection).safeBatchTransferFrom(
                address(this),
                sender,
                tokenIds,
                amounts,
                ""
            );

            emit ERC1155AssetsUnstaked(sender, collection, tokenIds, amounts);
        } else if (prefix == PayloadEncoder.Prefix.ERC721) {
            // Decode the payload to get the sender, the collection, and the tokenIds
            (
                address sender,
                address collection,
                uint256[] memory tokenIds
            ) = abi.decode(data, (address, address, uint256[]));

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
        } else {
            revert InvalidPayloadPrefix();
        }
    }

    /// TODO: add support for risk parameter
    /// @notice Deposits ERC1155 assets cross-chain using LayerZero.
    /// @param collection Address of the ERC1155 collection.
    /// @param tokenIds IDs of the tokens to be staked.
    /// @param amounts The amounts of the tokens to be staked.
    function _stakeERC1155Assets(
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private {
        _lzSend(
            Storage.layout().DESTINATION_LAYER_ZERO_CHAIN_ID,
            PayloadEncoder.encodeStakeERC1155AssetsPayload(
                msg.sender,
                collection,
                tokenIds,
                amounts
            ),
            payable(msg.sender),
            address(0),
            "0x",
            msg.value
        );
    }

    /// TODO: add support for risk parameter
    /// @notice Deposits ERC721 assets cross-chain using LayerZero.
    /// @param collection Address of the ERC721 collection.
    /// @param tokenIds IDs of the tokens to be staked.
    function _stakeERC721Assets(
        address collection,
        uint256[] calldata tokenIds
    ) private {
        _lzSend(
            Storage.layout().DESTINATION_LAYER_ZERO_CHAIN_ID,
            PayloadEncoder.encodeStakeERC721AssetsPayload(
                msg.sender,
                collection,
                tokenIds
            ),
            payable(msg.sender),
            address(0),
            "0x",
            msg.value
        );
    }
}
