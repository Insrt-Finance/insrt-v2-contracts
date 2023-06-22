// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { L2AssetHandlerHelper } from "./AssetHandlerHelper.t.sol";
import { L2PerpetualMintTest } from "../../../diamonds/L2/PerpetualMint.t.sol";
import { IL2AssetHandler } from "../../../../contracts/facets/L2/AssetHandler/IAssetHandler.sol";

/// @title L2AssetHandlerTest
/// @dev L2AssetHandler test contract. Configures and tests L2AssetHandler as a facet of the L2PerpetualMint diamond.
contract L2AssetHandlerTest is L2PerpetualMintTest {
    IL2AssetHandler public l2AssetHandler;

    /// @dev Address used to simulate non-owner access.
    address internal immutable NON_OWNER_TEST_ADDRESS = vm.addr(1);

    /// @dev Test LayerZero chain ID used to test contract functionality.
    uint16 private constant TEST_LAYER_ZERO_CHAIN_ID_DESTINATION = 666;

    // The slot in contract storage where L2AssetHandler data is stored as Layout struct.
    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.L2AssetHandler");

    /// @dev Sets up L2AssetHandler for testing.
    function setUp() public override {
        super.setUp();

        initL2AssetHandler();

        l2AssetHandler = IL2AssetHandler(address(l2PerpetualMintDiamond));
    }

    /// @dev Initializes L2AssetHandler as a facet by executing a diamond cut on the L2PerpetualMintDiamond.
    function initL2AssetHandler() private {
        L2AssetHandlerHelper l2AssetHandlerHelper = new L2AssetHandlerHelper();

        ISolidStateDiamond.FacetCut[] memory facetCuts = l2AssetHandlerHelper
            .getFacetCuts();

        l2PerpetualMintDiamond.diamondCut(facetCuts, address(0), "");
    }

    /// @dev Tests setLayerZeroChainIdDestination functionality.
    function test_setLayerZeroChainIdDestination() public {
        l2AssetHandler.setLayerZeroChainIdDestination(
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
                    address(l2AssetHandler),
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

        l2AssetHandler.setLayerZeroChainIdDestination(
            TEST_LAYER_ZERO_CHAIN_ID_DESTINATION
        );
    }
}
