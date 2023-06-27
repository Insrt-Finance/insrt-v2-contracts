// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { L2AssetHandlerTest } from "../AssetHandler.t.sol";

/// @title L2AssetHandler_setLayerZeroEndpoint
/// @dev L2AssetHandler test contract for testing expected setLayerZeroEndpoint behavior.
contract L2AssetHandler_setLayerZeroEndpoint is L2AssetHandlerTest {
    /// @dev Tests setLayerZeroEndpoint functionality.
    function test_setLayerZeroEndpoint() public {
        l2AssetHandler.setLayerZeroEndpoint(TEST_LAYER_ZERO_ENDPOINT);

        address currentLayerZeroEndpoint = l2AssetHandler
            .getLayerZeroEndpoint();

        assertEq(currentLayerZeroEndpoint, TEST_LAYER_ZERO_ENDPOINT);
    }

    /// @dev Tests that setLayerZeroEndpoint reverts when called by a non-owner address.
    function test_setLayerZeroEndpointRevertsWhenCallerNotOwner() public {
        vm.prank(NON_OWNER_TEST_ADDRESS);
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        l2AssetHandler.setLayerZeroEndpoint(TEST_LAYER_ZERO_ENDPOINT);
    }
}
