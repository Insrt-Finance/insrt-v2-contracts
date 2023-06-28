// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "@solidstate/contracts/interfaces/IERC1155.sol";
import "@solidstate/contracts/interfaces/IERC721.sol";

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { L1AssetHandlerHelper } from "./AssetHandlerHelper.t.sol";
import { L1PerpetualMintTest } from "../../../diamonds/L1/PerpetualMint.t.sol";
import { IL1AssetHandler } from "../../../../contracts/facets/L1/AssetHandler/IAssetHandler.sol";
import { IAssetHandlerEvents } from "../../../../contracts/interfaces/IAssetHandlerEvents.sol";

/// @title L1AssetHandlerTest
/// @dev L1AssetHandler test helper contract. Configures L1AssetHandler as a facet of the L1PerpetualMint diamond.
abstract contract L1AssetHandlerTest is
    IAssetHandlerEvents,
    L1PerpetualMintTest
{
    IERC1155 public bongBears;
    IERC721 public boredApeYachtClub;
    IL1AssetHandler public l1AssetHandler;

    /// @dev Ethereum mainnet Bong Bears contract address.
    address internal constant BONG_BEARS =
        0x495f947276749Ce646f68AC8c248420045cb7b5e;

    /// @dev Ethereum mainnet Bored Ape Yacht Club contract address.
    address internal constant BORED_APE_YACHT_CLUB =
        0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

    /// @dev The LayerZero Ethereum mainnet endpoint address.
    address internal constant MAINNET_LAYER_ZERO_ENDPOINT =
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;

    /// @dev Address used to simulate non-owner access.
    address internal immutable NON_OWNER_TEST_ADDRESS = vm.addr(1);

    /// @dev The LayerZero proprietary chain ID for setting Arbitrum as the destination blockchain.
    uint16 internal constant DESTINATION_LAYER_ZERO_CHAIN_ID = 110;

    uint256[] internal boredApeYachtClubTokenIds = new uint256[](1);

    uint256[] internal bongBearTokenIds = new uint256[](1);

    uint256[] internal bongBearTokenAmounts = new uint256[](1);

    /// @dev Sets up L1AssetHandler for testing.
    function setUp() public override {
        super.setUp();

        initL1AssetHandler();

        bongBears = IERC1155(BONG_BEARS);

        bongBearTokenIds[
            0
        ] = 66075445032688988859229341194671037535804503065310441849644897861040871571457;
        bongBearTokenAmounts[0] = 1;

        boredApeYachtClub = IERC721(BORED_APE_YACHT_CLUB);

        boredApeYachtClubTokenIds[0] = 0;

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
