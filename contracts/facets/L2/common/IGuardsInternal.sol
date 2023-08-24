// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

interface IGuardsInternal {
    /// @dev emitted when a new value for maxActiveTokens is set
    /// @param maxActiveTokens new maxActiveTokens value
    event MaxActiveTokensSet(uint256 maxActiveTokens);

    /// @dev thrown when attempting to increase activeTokens of a collectino past the maxActiveTokens amount
    error MaxActiveTokensExceeded();
}
