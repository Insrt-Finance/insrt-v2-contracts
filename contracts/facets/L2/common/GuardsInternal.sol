// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { IGuardsInternal } from "./IGuardsInternal.sol";
import { PerpetualMintStorage as Storage } from "../PerpetualMint/Storage.sol";

/// @title Guards contract
/// @dev contains guard function implementation and setters of related variables
abstract contract GuardsInternal is IGuardsInternal {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev enforces the maximum active token limit on an amount of tokens
    /// @param l the PerpetualMint storage layout
    /// @param tokens amount to check
    function _enforceMaxActiveTokensLimit(
        Storage.Layout storage l,
        uint256 tokens
    ) internal view {
        if (tokens > l.maxActiveTokensLimit) {
            revert MaxActiveTokensLimitExceeded();
        }
    }

    /// @dev enforces that there are no pending mint requests for a collection
    /// @param l the PerpetualMint storage layout
    /// @param collection address of collection
    function _enforceNoPendingMints(
        Storage.Layout storage l,
        address collection
    ) internal view {
        if (l.pendingRequests[collection].length() != 0) {
            revert PendingRequests();
        }
    }
}
