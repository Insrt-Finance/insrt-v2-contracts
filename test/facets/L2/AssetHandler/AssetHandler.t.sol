// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { L2AssetHandlerHelper } from "./AssetHandlerHelper.t.sol";
import { L2PerpetualMintTest } from "../../../diamonds/L2/PerpetualMint.t.sol";
import { IL2AssetHandler } from "../../../../contracts/facets/L2/AssetHandler/IAssetHandler.sol";

/// @title L2AssetHandlerTest
/// @dev L2AssetHandler test helper contract. Configures L2AssetHandler as a facet of the L2PerpetualMint diamond.
abstract contract L2AssetHandlerTest is L2PerpetualMintTest {
    IL2AssetHandler public l2AssetHandler;

    /// @dev The LayerZero Arbitrum endpoint address.
    address internal constant ARBITRUM_LAYER_ZERO_ENDPOINT =
        0x3c2269811836af69497E5F486A85D7316753cf62;

    /// @dev Ethereum mainnet Bong Bears contract address.
    address internal constant BONG_BEARS =
        0x495f947276749Ce646f68AC8c248420045cb7b5e;

    /// @dev Ethereum mainnet Bored Ape Yacht Club contract address.
    address internal constant BORED_APE_YACHT_CLUB =
        0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

    /// @dev Address used to simulate non-owner access.
    address internal immutable NON_OWNER_TEST_ADDRESS = vm.addr(1);

    /// @dev The LayerZero proprietary chain ID for setting Ethereum as the destination blockchain.
    uint16 internal constant DESTINATION_LAYER_ZERO_CHAIN_ID = 101;

    uint256[] internal boredApeYachtClubTokenIds = new uint256[](1);

    uint256[] internal bongBearTokenIds = new uint256[](1);

    uint256[] internal bongBearTokenAmounts = new uint256[](1);

    /// @dev Sets up L2AssetHandler for testing.
    function setUp() public override {
        super.setUp();

        initL2AssetHandler();

        bongBearTokenIds[
            0
        ] = 66075445032688988859229341194671037535804503065310441849644897861040871571457;
        bongBearTokenAmounts[0] = 1;

        boredApeYachtClubTokenIds[0] = 1;

        l2AssetHandler = IL2AssetHandler(address(l2PerpetualMintDiamond));
    }

    /// @dev Initializes L2AssetHandler as a facet by executing a diamond cut on the L2PerpetualMintDiamond.
    function initL2AssetHandler() private {
        L2AssetHandlerHelper l2AssetHandlerHelper = new L2AssetHandlerHelper();

        ISolidStateDiamond.FacetCut[] memory facetCuts = l2AssetHandlerHelper
            .getFacetCuts();

        l2PerpetualMintDiamond.diamondCut(facetCuts, address(0), "");
    }
}
