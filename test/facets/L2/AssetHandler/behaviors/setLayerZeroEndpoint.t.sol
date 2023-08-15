// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { LayerZeroClientBaseStorage } from "@solidstate/layerzero-client/base/LayerZeroClientBaseStorage.sol";

import { L2AssetHandlerTest } from "../AssetHandler.t.sol";

/// @title L2AssetHandler_setLayerZeroEndpoint
/// @dev L2AssetHandler test contract for testing expected setLayerZeroEndpoint behavior.
contract L2AssetHandler_setLayerZeroEndpoint is L2AssetHandlerTest {
    /// @dev Tests setLayerZeroEndpoint functionality.
    function test_setLayerZeroEndpoint() public {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        bytes32 currentLayerZeroEndpointStorageSlot = LayerZeroClientBaseStorage
            .STORAGE_SLOT; // the LayerZeroEndpoint address storage slot

        // load the current LayerZeroEndpoint address from storage
        address currentLayerZeroEndpoint = address(
            uint160( // downcast to match address type
                uint256( // convert bytes32 to uint256
                    vm.load(
                        address(l2AssetHandler),
                        currentLayerZeroEndpointStorageSlot
                    )
                )
            )
        );

        assertEq(currentLayerZeroEndpoint, ARBITRUM_LAYER_ZERO_ENDPOINT);
    }

    /// @dev Tests that setLayerZeroEndpoint reverts when called by a non-owner address.
    function test_setLayerZeroEndpointRevertsWhen_CallerNotOwner() public {
        vm.prank(NON_OWNER_TEST_ADDRESS);
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
    }
}
