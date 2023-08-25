// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

/// @title IGuardsInternal
/// @dev interface holding all events and errors related to guards
interface IGuardsInternal {
    /// @dev emitted when a new value for maxActiveTokensLimit is set
    /// @param limit new maxActiveTokensLimit value
    event MaxActiveTokensSet(uint256 limit);

    /// @dev thrown when attempting to increase activeTokens of a collection past the maxActiveTokensLimit amount
    error MaxActiveTokensLimitExceeded();
}
