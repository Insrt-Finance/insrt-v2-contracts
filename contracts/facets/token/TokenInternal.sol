// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { ERC20BaseInternal } from "@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol";

import { TokenStorage as Storage } from "./Storage.sol";

/// @title $MINT Token contract
/// @dev The internal functionality of $MINT token.
contract TokenInternal is ERC20BaseInternal {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint32 internal constant BASIS = 1000000000;

    /// @notice disburses (mints) an amount of tokens to an account
    /// @param account address of account receive the tokens
    /// @param amount amount of tokens to disburse
    function _disburse(address account, uint256 amount) internal {
        Storage.Layout storage l = Storage.layout();

        // calculate amount for distribution
        uint256 distributionAmount = (amount * l.distributionFraction) / BASIS;

        // decrease amount to mint to account
        amount -= distributionAmount;

        uint256 supplyDelta = _totalSupply() - l.distributionSupply;

        // update global ratio
        if (supplyDelta > 0) {
            l.globalRatio += distributionAmount / supplyDelta;

            // update lastRatio of account
            l.lastRatio[account] = l.globalRatio;
        } else {
            l.globalRatio += distributionAmount / amount;
        }

        // increase distribution supply
        l.distributionSupply += distributionAmount;

        // mint tokens to contract and account
        _mint(address(this), distributionAmount);
        _mint(account, amount);
    }

    /// @notice claims all claimable tokens for an account
    /// @param account address of account
    function _claim(address account) internal {
        Storage.Layout storage l = Storage.layout();

        // calculate claimable tokens
        uint256 claimableTokens = (l.globalRatio - l.lastRatio[account]) *
            _balanceOf(account);

        // decrease distribution supply
        l.distributionSupply -= claimableTokens;

        // update account's last ratio
        l.lastRatio[account] = l.globalRatio;

        _transfer(address(this), account, claimableTokens);
    }

    /// @notice burns an amount of tokens of an account
    /// @param amount amount of tokens to burn
    /// @param account account to burn from
    function _burn(uint256 amount, address account) internal {
        _claim(account);
        _burn(account, amount);
    }
}
