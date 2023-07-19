// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { L1AssetHandlerTest } from "../AssetHandler.t.sol";

/// @title L1AssetHandler_onERC1155BatchReceived
/// @dev L1AssetHandler test contract for testing expected onERC1155BatchReceived behavior.
contract L1AssetHandler_onERC1155BatchReceived is L1AssetHandlerTest {
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
}
