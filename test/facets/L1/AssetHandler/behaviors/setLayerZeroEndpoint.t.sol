// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { L1AssetHandlerTest } from "../AssetHandler.t.sol";

/// @title L1AssetHandler_setLayerZeroEndpoint
/// @dev L1AssetHandler test contract for testing expected setLayerZeroEndpoint behavior.
contract L1AssetHandler_setLayerZeroEndpoint is L1AssetHandlerTest {
    /// @dev Tests setLayerZeroEndpoint functionality.
    function test_setLayerZeroEndpoint() public {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);

        address currentLayerZeroEndpoint = l1AssetHandler
            .getLayerZeroEndpoint();

        assertEq(currentLayerZeroEndpoint, MAINNET_LAYER_ZERO_ENDPOINT);
    }

    /// @dev Tests that setLayerZeroEndpoint reverts when called by a non-owner address.
    function test_setLayerZeroEndpointRevertsWhenCallerNotOwner() public {
        vm.prank(NON_OWNER_TEST_ADDRESS);
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
    }
}
