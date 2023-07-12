// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

/// @title IPerpetualMintInternal interface
/// @dev contains all errors and events used in the PerpeutlaMint facet contract
interface IPerpetualMintInternal {
    /// @notice thrown when an incorrent amount of ETH is received
    error IncorrectETHReceived();

    /// @notice emitted when the outcome of an attempted mint is resolved
    /// @param collection address of collection that attempted mint is for
    /// @param result success status of mint attempt
    event ERC1155MintResolved(address collection, bool result);

    /// @notice emitted when the outcome of an attempted mint is resolved
    /// @param collection address of collection that attempted mint is for
    /// @param result success status of mint attempt
    event ERC721MintResolved(address collection, bool result);
}
