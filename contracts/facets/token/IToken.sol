// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { IERC20 } from "@solidstate/contracts/interfaces/IERC20.sol";
import { AccrualData } from "./types/DataTypes.sol";

/// @title ITokenMint interface
/// @dev contains all external functions for Token facet
interface IToken is IERC20 {
    /// @notice returns AccrualData struct pertaining to account, which contains Token accrual
    /// information
    /// @param account address of account
    /// @return data AccrualData of account
    function accrualData(
        address account
    ) external view returns (AccrualData memory data);

    /// @notice adds an account to the mintingContracts enumerable set
    /// @param account address of account
    function addMintingContract(address account) external;

    /// @notice burns an amount of tokens of an account
    /// @param account account to burn from
    /// @param amount amount of tokens to burn
    function burn(address account, uint256 amount) external;

    /// @notice claims all claimable tokens for the msg.sender
    function claim() external;

    /// @notice returns all claimable tokens of a given account
    /// @param account address of account
    /// @return amount amount of claimable tokens
    function claimableTokens(
        address account
    ) external view returns (uint256 amount);

    /// @notice returns the distributionFractionBP value
    /// @return fractionBP value of distributionFractionBP
    function distributionFractionBP() external view returns (uint32 fractionBP);

    /// @notice returns the distribution supply value
    /// @return supply distribution supply value
    function distributionSupply() external view returns (uint256 supply);

    /// @notice returns the global ratio value
    /// @return ratio global ratio value
    function globalRatio() external view returns (uint256 ratio);

    /// @notice disburses (mints) an amount of tokens to an account
    /// @param account address of account receive the tokens
    /// @param amount amount of tokens to disburse
    function mint(address account, uint256 amount) external;

    /// @notice returns all addresses of contracts which are allowed to call mint/burn
    /// @return contracts array of addresses of contracts which are allowed to call mint/burn
    function mintingContracts()
        external
        view
        returns (address[] memory contracts);

    /// @notice removes an account from the mintingContracts enumerable set
    /// @param account address of account
    function removeMintingContract(address account) external;

    /// @notice sets a new value for distributionFractionBP
    /// @param distributionFractionBP new distributionFractionBP value
    function setDistributionFractionBP(uint32 distributionFractionBP) external;
}
