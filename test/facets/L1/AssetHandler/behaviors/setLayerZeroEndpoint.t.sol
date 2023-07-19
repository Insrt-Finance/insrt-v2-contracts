// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { LayerZeroClientBaseStorage } from "@solidstate/layerzero-client/base/LayerZeroClientBaseStorage.sol";

import { L1AssetHandlerTest } from "../AssetHandler.t.sol";

/// @title L1AssetHandler_setLayerZeroEndpoint
/// @dev L1AssetHandler test contract for testing expected setLayerZeroEndpoint behavior.
contract L1AssetHandler_setLayerZeroEndpoint is L1AssetHandlerTest {
    /// @dev Tests setLayerZeroEndpoint functionality.
    function test_setLayerZeroEndpoint() public {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);

        bytes32 currentLayerZeroEndpointStorageSlot = LayerZeroClientBaseStorage
            .STORAGE_SLOT; // the LayerZeroEndpoint address storage slot

        // load the current LayerZeroEndpoint address from storage
        address currentLayerZeroEndpoint = address(
            uint160( // downcast to match address type
                uint256( // convert bytes32 to uint256
                    vm.load(
                        address(l1AssetHandler),
                        currentLayerZeroEndpointStorageSlot
                    )
                )
            )
        );

        assertEq(currentLayerZeroEndpoint, MAINNET_LAYER_ZERO_ENDPOINT);
    }

    /// @dev Tests that setLayerZeroEndpoint reverts when called by a non-owner address.
    function test_setLayerZeroEndpointRevertsWhenCallerNotOwner() public {
        vm.prank(NON_OWNER_TEST_ADDRESS);
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
    }
}
