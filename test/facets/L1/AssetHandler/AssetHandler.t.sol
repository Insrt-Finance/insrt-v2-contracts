// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { L1AssetHandlerHelper } from "./AssetHandlerHelper.t.sol";
import { L1PerpetualMintTest } from "../../../diamonds/L1/PerpetualMint.t.sol";
import { IL1AssetHandler } from "../../../../contracts/facets/L1/AssetHandler/IAssetHandler.sol";

/// @title L1AssetHandlerTest
/// @dev L1AssetHandler test contract. Configures and tests L1AssetHandler as a facet of the L1PerpetualMint diamond.
contract L1AssetHandlerTest is L1PerpetualMintTest {
    IL1AssetHandler public l1AssetHandler;

    /// @dev Address used to simulate non-owner access.
    address internal immutable NON_OWNER_TEST_ADDRESS = vm.addr(1);

    /// @dev Test LayerZero chain ID used to test contract functionality.
    uint16 private constant TEST_LAYER_ZERO_CHAIN_ID_DESTINATION = 666;

    // The slot in contract storage where L1AssetHandler data is stored as Layout struct.
    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.L1AssetHandler");

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

    /// @dev Tests onERC1155BatchReceived functionality.
    function test_onERC1155BatchReceived() public {
        assertEq(
            l1AssetHandler.onERC1155BatchReceived(
                address(0),
                address(0),
                new uint256[](0),
                new uint256[](0),
                ""
            ),
            l1AssetHandler.onERC1155BatchReceived.selector
        );
    }

    /// @dev Tests onERC721Received functioniality.
    function test_onERC721Received() public {
        assertEq(
            l1AssetHandler.onERC721Received(address(0), address(0), 0, ""),
            l1AssetHandler.onERC721Received.selector
        );
    }

    /// @dev Tests setLayerZeroChainIdDestination functionality.
    function test_setLayerZeroChainIdDestination() public {
        l1AssetHandler.setLayerZeroChainIdDestination(
            TEST_LAYER_ZERO_CHAIN_ID_DESTINATION
        );

        // Calculate the storage slot of DESTINATION_LAYER_ZERO_CHAIN_ID
        bytes32 storageSlotOfNewChainIdDestination = bytes32(
            uint256(STORAGE_SLOT) + 0
        );

        // Retrieve the value from storage
        uint16 newChainIdDestinationValueInStorage = uint16(
            uint256(
                vm.load(
                    address(l1AssetHandler),
                    storageSlotOfNewChainIdDestination
                )
            )
        );

        assertEq(
            TEST_LAYER_ZERO_CHAIN_ID_DESTINATION,
            newChainIdDestinationValueInStorage
        );
    }

    /// @dev Tests that setLayerZeroChainIdDestination reverts when called by a non-owner address.
    function test_setLayerZeroChainIdDestinationRevertsWhenCallerNotOwner()
        public
    {
        vm.prank(NON_OWNER_TEST_ADDRESS);
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        l1AssetHandler.setLayerZeroChainIdDestination(
            TEST_LAYER_ZERO_CHAIN_ID_DESTINATION
        );
    }
}
