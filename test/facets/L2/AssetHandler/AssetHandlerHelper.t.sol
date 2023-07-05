// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { L2AssetHandler } from "../../../../contracts/facets/L2/AssetHandler/AssetHandler.sol";
import { IL2AssetHandler } from "../../../../contracts/facets/L2/AssetHandler/IAssetHandler.sol";
import { IAssetHandler } from "../../../../contracts/interfaces/IAssetHandler.sol";

/// @title L2AssetHandlerHelper
/// @dev Test helper contract for setting up the L2 Asset Handler facet for diamond cutting and testing.
contract L2AssetHandlerHelper {
    L2AssetHandler public l2AssetHandlerImplementation;

    /// @dev Deploys a new instance of L2AssetHandler.
    constructor() {
        l2AssetHandlerImplementation = new L2AssetHandler();
    }

    /// @dev Provides the facet cuts to be used for setting up L2AssetHandler as a facet of the L2PerpetualMint diamond.
    function getFacetCuts()
        public
        view
        returns (ISolidStateDiamond.FacetCut[] memory)
    {
        bytes4[] memory functionSelectors = new bytes4[](5);

        // Map the function selectors to their respective interfaces.
        functionSelectors[0] = IAssetHandler.getLayerZeroEndpoint.selector;
        functionSelectors[1] = IAssetHandler.setLayerZeroEndpoint.selector;
        functionSelectors[2] = IAssetHandler
            .setLayerZeroTrustedRemoteAddress
            .selector;
        functionSelectors[3] = IL2AssetHandler.unstakeERC1155Assets.selector;
        functionSelectors[4] = IL2AssetHandler.unstakeERC721Assets.selector;

        ISolidStateDiamond.FacetCut memory facetCut = IDiamondWritableInternal
            .FacetCut({
                target: address(l2AssetHandlerImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: functionSelectors
            });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](1);
        facetCuts[0] = facetCut;

        return facetCuts;
    }
}
