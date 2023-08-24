// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { IGuardsInternal } from "./IGuardsInternal.sol";
import { PerpetualMintStorage as Storage } from "../PerpetualMint/Storage.sol";

/// @title Guards contract
/// @dev contains guard function implementation
abstract contract GuardsInternal is IGuardsInternal {
    /// @dev enforces the maximum active token limit on an amount of tokens
    /// @param l the PerpetualMint storage layout
    /// @param tokens amount to check
    function _enforceMaxActiveTokens(
        Storage.Layout storage l,
        uint256 tokens
    ) internal view {
        if (tokens > l.maxActiveTokens) {
            revert MaxActiveTokensExceeded();
        }
    }

    /// @dev sets a new value for maxActiveTokens
    /// @param l the PerpetualMint storage layout
    /// @param maxActiveTokens new maxActiveTokens value
    function _setMaxActiveTokens(
        Storage.Layout storage l,
        uint256 maxActiveTokens
    ) internal {
        l.maxActiveTokens = maxActiveTokens;
        emit MaxActiveTokensSet(maxActiveTokens);
    }
}
