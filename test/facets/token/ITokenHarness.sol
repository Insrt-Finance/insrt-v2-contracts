// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

/// @title ITokenHarness
/// @dev Interface for TokenHarness contract
interface ITokenHarness {
    /// @notice exposes _accrueTokens functions
    function exposed_accrueTokens(address account) external;
}
