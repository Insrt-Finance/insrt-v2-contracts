// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { L2AssetHandler } from "../../contracts/facets/L2/AssetHandler/AssetHandler.sol";
import { IL2AssetHandlerMock } from "../interfaces/IL2AssetHandlerMock.sol";

/// @title L2AssetHandlerMock
/// @dev Mock contract for L2AssetHandler test cases.
contract L2AssetHandlerMock is IL2AssetHandlerMock, L2AssetHandler, Test {
    /// @dev Dummy trusted remote test path.
    bytes internal TEST_PATH =
        bytes.concat(bytes20(vm.addr(1234)), bytes20(vm.addr(5678)));

    /// @dev Dummy test nonce value.
    uint64 internal constant TEST_NONCE = 0;

    /// @inheritdoc IL2AssetHandlerMock
    function mock_HandleLayerZeroMessage(
        uint16 sourceChainId,
        bytes calldata path,
        uint64 nonce,
        bytes calldata data
    ) external {
        _handleLayerZeroMessage(sourceChainId, path, nonce, data);
    }
}
