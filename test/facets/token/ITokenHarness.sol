// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

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

    /// @notice adds a non-contract minting "contract" for ease of testing
    /// @param account address of account
    function mock_addMintingContract(address account) external;

    /// @notice returns account offset  for an account
    /// @param account address of account
    /// @return offset account offset
    function accountOffset(
        address account
    ) external view returns (uint256 offset);

    /// @notice returns accrued tokens of account
    /// @param account address of account
    /// @return amount amount of accrued tokens
    function accruedTokens(
        address account
    ) external view returns (uint256 amount);

    /// @notice returns distribution supply
    /// @return supply distribution supply
    function distributionSupply() external view returns (uint256 supply);

    /// @notice returns global ratio
    /// @return ratio global ratio
    function globalRatio() external view returns (uint256 ratio);
}
