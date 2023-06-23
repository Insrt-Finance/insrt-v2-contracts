// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { L1AssetHandlerTest } from "../AssetHandler.t.sol";

/// @title L1AssetHandler_onERC721Received
/// @dev L1AssetHandler test contract for testing expected onERC721Received behavior.
contract L1AssetHandler_onERC721Received is L1AssetHandlerTest {
    /// @dev Tests onERC721Received functioniality.
    function test_onERC721Received() public {
        assertEq(
            l1AssetHandler.onERC721Received(address(0), address(0), 0, ""),
            l1AssetHandler.onERC721Received.selector
        );
    }
}
