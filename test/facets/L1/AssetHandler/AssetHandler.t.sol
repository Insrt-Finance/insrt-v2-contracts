// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { L1AssetHandlerHelper } from "./AssetHandlerHelper.t.sol";
import { L1PerpetualMintTest } from "../../../diamonds/L1/PerpetualMint.t.sol";
import { IL1AssetHandler } from "../../../../contracts/facets/L1/AssetHandler/IAssetHandler.sol";

/// @title L1AssetHandlerTest
/// @dev L1AssetHandler test helper contract. Configures L1AssetHandler as a facet of the L1PerpetualMint diamond.
abstract contract L1AssetHandlerTest is L1PerpetualMintTest {
    IL1AssetHandler public l1AssetHandler;

    /// @dev The LayerZero Ethereum mainnet endpoint address.
    address internal constant MAINNET_LAYER_ZERO_ENDPOINT =
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;

    /// @dev Address used to simulate non-owner access.
    address internal immutable NON_OWNER_TEST_ADDRESS = vm.addr(1);

    /// @dev The LayerZero proprietary chain ID for setting Arbitrum as the destination blockchain.
    uint16 internal constant DESTINATION_LAYER_ZERO_CHAIN_ID = 110;

    /// @dev Sets up L1AssetHandler for testing.
    function setUp() public override {
        super.setUp();

        initL1AssetHandler();

        l1AssetHandler = IL1AssetHandler(address(l1PerpetualMintDiamond));
    }

    /// @dev Initializes L1AssetHandler as a facet by executing a diamond cut on the L1PerpetualMintDiamond.
    function initL1AssetHandler() private {
        L1AssetHandlerHelper l1AssetHandlerHelper = new L1AssetHandlerHelper();

        ISolidStateDiamond.FacetCut[] memory facetCuts = l1AssetHandlerHelper
            .getFacetCuts();

        l1PerpetualMintDiamond.diamondCut(facetCuts, address(0), "");
    }
}
