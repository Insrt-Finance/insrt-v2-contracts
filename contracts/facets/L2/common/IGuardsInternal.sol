// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

/// @title IGuardsInternal
/// @dev interface holding all events and errors related to guards
interface IGuardsInternal {
    /// @dev emitted when a new value for maxActiveTokens is set
    /// @param maxActiveTokens new maxActiveTokens value
    event MaxActiveTokensSet(uint256 maxActiveTokens);

    /// @dev thrown when attempting to increase activeTokens of a collection past the maxActiveTokens amount
    error MaxActiveTokensExceeded();
}
