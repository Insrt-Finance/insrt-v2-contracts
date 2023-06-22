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
    L2AssetHandler public L2AssetHandlerImplementation;

    /// @dev The LayerZero Arbitrum endpoint address.
    address private constant ARBITRUM_LAYER_ZERO_ENDPOINT =
        0x3c2269811836af69497E5F486A85D7316753cf62;
    /// @dev The LayerZero proprietary chain ID for setting Ethereum as the destination blockchain.
    uint16 private constant DESTINATION_LAYER_ZERO_CHAIN_ID = 101;

    /// @dev Deploys a new instance of L2AssetHandler.
    constructor() {
        L2AssetHandlerImplementation = new L2AssetHandler(
            ARBITRUM_LAYER_ZERO_ENDPOINT,
            DESTINATION_LAYER_ZERO_CHAIN_ID
        );
    }

    /// @dev Provides the facet cuts to be used for setting up L2AssetHandler as a facet of the L2PerpetualMint diamond.
    function getFacetCuts()
        public
        view
        returns (ISolidStateDiamond.FacetCut[] memory)
    {
        bytes4[] memory functionSelectors = new bytes4[](3);

        // Map the function selectors to their respective interfaces.
        functionSelectors[0] = IAssetHandler
            .setLayerZeroChainIdDestination
            .selector;
        functionSelectors[1] = IL2AssetHandler.unstakeERC1155Assets.selector;
        functionSelectors[2] = IL2AssetHandler.unstakeERC721Assets.selector;

        ISolidStateDiamond.FacetCut memory facetCut = IDiamondWritableInternal
            .FacetCut({
                target: address(L2AssetHandlerImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: functionSelectors
            });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](1);
        facetCuts[0] = facetCut;

        return facetCuts;
    }
}
