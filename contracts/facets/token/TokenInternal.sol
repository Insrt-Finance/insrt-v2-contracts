// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { ERC20BaseInternal } from "@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol";

import { ITokenInternal } from "./ITokenInternal.sol";
import { TokenStorage as Storage } from "./Storage.sol";

/// @title $MINT Token contract
/// @dev The internal functionality of $MINT token.
abstract contract TokenInternal is
    ERC20BaseInternal,
    OwnableInternal,
    ITokenInternal
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // used for floating point calculations
    uint256 internal constant SCALE = 10 ** 36;
    // used for fee calculations - not sufficient for floating point calculations
    uint32 internal constant BASIS = 1000000000;

    /// @notice modifier to only allow addresses contained in mintingContracts
    /// to call modified function
    modifier onlyMintingContract() {
        if (!Storage.layout().mintingContracts.contains(msg.sender))
            revert NotMintingContract();
        _;
    }

    /// @notice accrues the tokens available for claiming for an account
    /// @param l TokenStorage Layout struct
    /// @param account address of account
    function _accrueTokens(Storage.Layout storage l, address account) internal {
        // calculate claimable tokens
        uint256 accruedTokens = _scaleDown(
            (l.globalRatio - l.accountOffset[account]) * _balanceOf(account)
        );

        // decrease distribution supply
        l.distributionSupply -= accruedTokens;

        // update account's last ratio
        l.accountOffset[account] = l.globalRatio;

        // update claimable tokens
        l.accruedTokens[account] += accruedTokens;
    }

    /// @notice adds an account to the mintingContracts enumerable set
    /// @param account address of account
    function _addMintingContract(address account) internal {
        uint32 size;
        assembly {
            size := extcodesize(account)
        }

        if (size != 0) {
            Storage.layout().mintingContracts.add(account);
        }

        emit MintingContractAdded(account);
    }

    /// @notice overrides _beforeTokenTransfer hook to enforce non-transferability
    /// @param from sender of tokens
    /// @param to receiver of tokens
    /// @param amount quantity of tokens transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from != address(0) && from != address(this)) {
            if (to != address(0)) {
                revert NonTransferable();
            }
        }
    }

    /// @notice burns an amount of tokens of an account
    /// @dev parameter ordering is reversed to remove clash with ERC20BaseInternal burn(address,uint256)
    /// @param amount amount of tokens to burn
    /// @param account account to burn from
    function _burn(uint256 amount, address account) internal {
        _accrueTokens(Storage.layout(), account);
        _burn(account, amount);
    }

    /// @notice claims all claimable tokens for an account
    /// @param account address of account
    function _claim(address account) internal {
        Storage.Layout storage l = Storage.layout();

        _accrueTokens(l, account);
        _transfer(address(this), account, l.accruedTokens[account]);
        l.accruedTokens[account] = 0;
    }

    /// @notice returns all claimable tokens of a given account
    /// @param account address of account
    /// @return amount amount of claimable tokens
    function _claimableTokens(
        address account
    ) internal view returns (uint256 amount) {
        Storage.Layout storage l = Storage.layout();

        amount =
            _scaleDown(
                (l.globalRatio - l.accountOffset[account]) * _balanceOf(account)
            ) +
            l.accruedTokens[account];
    }

    /// @notice returns the distributionFractionBP value
    /// @return fractionBP value of distributionFractionBP
    function _distributionFractionBP()
        internal
        view
        returns (uint32 fractionBP)
    {
        fractionBP = Storage.layout().distributionFractionBP;
    }

    /// @notice mint an amount of tokens to an account
    /// @dev parameter ordering is reversed to remove clash with ERC20BaseInternal mint(address,uint256)
    /// @param amount amount of tokens to disburse
    /// @param account address of account receive the tokens
    function _mint(uint256 amount, address account) internal {
        Storage.Layout storage l = Storage.layout();

        // calculate amount for distribution
        uint256 distributionAmount = (amount * l.distributionFractionBP) /
            BASIS;

        // decrease amount to mint to account
        amount -= distributionAmount;

        uint256 supplyDelta = _totalSupply() - l.distributionSupply;

        // if the supplyDelta is zero, it means there are no tokens in circulation
        // so the receiving account is the first/only receiver therefore is owed the full
        // distribution amount.
        // if the the supplyDelta is equal to the balance of an account, it means this account
        // is the only which has received or is receiving tokens so the distribution amount
        // should again belong to this sole account.
        // to ensure the full distribution amount is given to an account in this instance,
        // the account offset for said account should not be updated
        if (supplyDelta > 0 && supplyDelta != _balanceOf(account)) {
            // update global ratio
            l.globalRatio += _scaleUp(distributionAmount) / supplyDelta;

            // update accountOffset of account
            l.accountOffset[account] = l.globalRatio;
        } else {
            // update global ratio
            l.globalRatio += _scaleUp(distributionAmount) / amount;
        }

        // increase distribution supply
        l.distributionSupply += distributionAmount;

        // mint tokens to contract and account
        _mint(address(this), distributionAmount);
        _mint(account, amount);
    }

    /// @notice returns all addresses of contracts which are allowed to call mint/burn
    /// @return contracts array of addresses of contracts which are allowed to call mint/burn
    function _mintingContracts()
        internal
        view
        returns (address[] memory contracts)
    {
        contracts = Storage.layout().mintingContracts.toArray();
    }

    /// @notice removes an account from the mintingContracts enumerable set
    /// @param account address of account
    function _removeMintingContract(address account) internal {
        Storage.layout().mintingContracts.remove(account);
        emit MintingContractRemoved(account);
    }

    /// @notice multiplies a value by the scale, to enable floating point calculations
    /// @param value value to be scaled up
    /// @return scaledValue product of value and scale
    function _scaleUp(
        uint256 value
    ) internal pure returns (uint256 scaledValue) {
        scaledValue = value * SCALE;
    }

    /// @notice divides a value by the scale, to rectify a previous scaleUp operation
    /// @param value value to be scaled down
    /// @return scaledValue value divided by scale
    function _scaleDown(
        uint256 value
    ) internal pure returns (uint256 scaledValue) {
        scaledValue = value / SCALE;
    }

    /// @notice sets a new value for distributionFractionBP
    /// @param distributionFractionBP new distributionFractionBP value
    function _setDistributionFractionBP(
        uint32 distributionFractionBP
    ) internal {
        Storage.layout().distributionFractionBP = distributionFractionBP;
        emit DistributionFractionSet(distributionFractionBP);
    }
}
