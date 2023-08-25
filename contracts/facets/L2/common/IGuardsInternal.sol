// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

/// @title IGuardsInternal
/// @dev interface holding all errors related to guards
interface IGuardsInternal {
    /// @dev thrown when attempting to increase activeTokens of a collection past the maxActiveTokensLimit amount
    error MaxActiveTokensLimitExceeded();
}
