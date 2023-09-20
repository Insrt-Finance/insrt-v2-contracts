// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title ITokenHarness
/// @dev Interface for TokenHarness contract
interface ITokenHarness {
    /// @notice exposes _accrueTokens functions
    /// @param account address of account
    function exposed_accrueTokens(address account) external;

    /// @notice exposes _beforeTokenTransfer
    /// @param from sender of tokens
    /// @param to receiver of tokens
    /// @param amount quantity of tokens transferred
    function exposed_beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external;
}
