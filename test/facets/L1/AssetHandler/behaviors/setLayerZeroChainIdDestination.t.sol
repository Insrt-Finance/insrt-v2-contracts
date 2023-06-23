// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { L1AssetHandlerTest } from "../AssetHandler.t.sol";

/// @title L1AssetHandler_setLayerZeroChainIdDestination
/// @dev L1AssetHandler test contract for testing expected setLayerZeroChainIdDestination behavior.
contract L1AssetHandler_setLayerZeroChainIdDestination is L1AssetHandlerTest {
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
