// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

/// @dev DataTypes.sol defines the Token struct data types used in the TokenStorage layout

/// @dev represents data related to $MINT token accruals of a given account
struct AccountData {
    /// @dev last ratio an account had when one of their actions led to a change in the
    /// reservedSupply
    uint256 accountOffset;
    /// @dev amount of tokens accrued as a result of distribution to token holders
    uint256 accruedTokens;
}
