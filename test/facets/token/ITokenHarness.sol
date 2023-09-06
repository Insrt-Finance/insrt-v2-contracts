// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

/// @title ITokenHarness
/// @dev Interface for TokenHarness contract
interface ITokenHarness {
    /// @notice exposes _accrueTokens functions
    /// @param account address of account
    function exposed_accrueTokens(address account) external;

    /// @notice adds a non-contract minting "contract" for ease of testing
    /// @param account address of account
    function mock_addMintingContract(address account) external;
}
