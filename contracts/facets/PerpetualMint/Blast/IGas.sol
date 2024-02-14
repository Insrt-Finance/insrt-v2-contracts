// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title IGas
/// @notice Interface for the Blast Gas precompile contract
interface IGas {
    /// @notice Returns the ceiling claim rate in basis points that can be claimed by consuming
    /// ceil gas seconds or more.
    /// @return ceilGasSeconds The ceiling claim rate in basis points
    function ceilGasSeconds() external view returns (uint256 ceilGasSeconds);
}
