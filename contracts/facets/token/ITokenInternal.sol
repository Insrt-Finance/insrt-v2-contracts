// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

/// @title ITokenMintInternal interface
/// @dev contains all errors and events used in the Token facet contract
interface ITokenInternal {
    /// @dev thrown when attempting to transfer tokens and the from address is neither
    /// the zero-address, nor the contract address, or the to address is not the zero address
    error NonTransferable();
}
