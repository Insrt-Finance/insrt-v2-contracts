// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

/// @title ITokenMint interface
/// @dev contains all external functions for Token facet
interface IToken {
    /// @notice adds an account to the mintingContracts enumerable set
    /// @param account address of account
    function addMintingContract(address account) external;

    /// @notice burns an amount of tokens of an account
    /// @param amount amount of tokens to burn
    /// @param account account to burn from
    function burn(uint256 amount, address account) external;

    /// @notice claims all claimable tokens for the msg.sender
    function claim() external;

    /// @notice disburses (mints) an amount of tokens to an account
    /// @param account address of account receive the tokens
    /// @param amount amount of tokens to disburse
    function disburse(address account, uint256 amount) external;

    /// @notice removes an account from the mintingContracts enumerable set
    /// @param account address of account
    function removeMintingContract(address account) external;

    /// @notice sets a new value for distributionFractionBP
    /// @param distributionFractionBP new distributionFractionBP value
    function setDistributionFractionBP(uint32 distributionFractionBP) external;
}
