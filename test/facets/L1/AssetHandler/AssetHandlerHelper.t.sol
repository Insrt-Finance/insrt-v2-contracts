// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { L1AssetHandler } from "../../../../contracts/facets/L1/AssetHandler/AssetHandler.sol";
import { IL1AssetHandler } from "../../../../contracts/facets/L1/AssetHandler/IAssetHandler.sol";
import { IAssetHandler } from "../../../../contracts/interfaces/IAssetHandler.sol";

/// @title L1AssetHandlerHelper
/// @dev Test helper contract for setting up the L1 Asset Handler facet for diamond cutting and testing.
contract L1AssetHandlerHelper {
    L1AssetHandler public l1AssetHandlerImplementation;

    /// @dev The LayerZero proprietary chain ID for setting Arbitrum as the destination blockchain.
    uint16 private constant DESTINATION_LAYER_ZERO_CHAIN_ID = 110;

    /// @dev Deploys a new instance of L1AssetHandler.
    constructor() {
        l1AssetHandlerImplementation = new L1AssetHandler();
    }

    /// @dev Provides the facet cuts to be used for setting up L1AssetHandler as a facet of the L1PerpetualMint diamond.
    function getFacetCuts()
        public
        view
        returns (ISolidStateDiamond.FacetCut[] memory)
    {
        bytes4[] memory functionSelectors = new bytes4[](7);

        // Map the function selectors to their respective interfaces.
        functionSelectors[0] = IAssetHandler.getLayerZeroEndpoint.selector;
        functionSelectors[1] = IL1AssetHandler.onERC1155BatchReceived.selector;
        functionSelectors[2] = IL1AssetHandler.onERC721Received.selector;
        functionSelectors[3] = IAssetHandler.setLayerZeroEndpoint.selector;
        functionSelectors[4] = IAssetHandler
            .setLayerZeroTrustedRemoteAddress
            .selector;
        functionSelectors[5] = IL1AssetHandler.stakeERC1155Assets.selector;
        functionSelectors[6] = IL1AssetHandler.stakeERC721Assets.selector;

        ISolidStateDiamond.FacetCut memory facetCut = IDiamondWritableInternal
            .FacetCut({
                target: address(l1AssetHandlerImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: functionSelectors
            });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](1);
        facetCuts[0] = facetCut;

        return facetCuts;
    }
}
