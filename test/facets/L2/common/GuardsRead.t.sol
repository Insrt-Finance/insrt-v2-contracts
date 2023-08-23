// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/StdStorage.sol";
import "forge-std/Test.sol";

import { Guards } from "../../../../contracts/facets/L2/common/Guards.sol";

/// @title GuardsRead library
/// @dev read values from GuardsStorage directly
abstract contract GuardsRead is Test {
    using stdStorage for StdStorage;

    uint256 internal constant LAYOUT_SLOT = uint256(Guards.STORAGE_SLOT);

    /// @dev read maxActiveTokens value directly from storage
    /// @param target address of contract to read storage from
    /// @return maxActiveTokens maxActiveTokens value
    function _maxActiveTokens(
        address target
    ) internal view returns (uint256 maxActiveTokens) {
        bytes32 slot = bytes32(LAYOUT_SLOT);

        maxActiveTokens = uint256(vm.load(target, slot));
    }
}
