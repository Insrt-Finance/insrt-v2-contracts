// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { IGuardsInternal } from "./IGuardsInternal.sol";
import { PerpetualMintStorage as Storage } from "../PerpetualMint/Storage.sol";

/// @title Guards contract
/// @dev contains guard function implementation and setters of related variables
abstract contract GuardsInternal is IGuardsInternal {
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
}
