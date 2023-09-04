// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

/// @title ITokenMintInternal interface
/// @dev contains all errors and events used in the Token facet contract
interface ITokenInternal {
    /// @dev thrown when attempting to transfer tokens and the from address is neither
    /// the zero-address, nor the contract address, or the to address is not the zero address
    error NonTransferable();

    /// @dev thrown when an addrss not contained in mintingContracts attempts to mint or burn
    /// tokens
    error NotMintingContract();

    /// @dev emitted when a new distributionFractionBP value is set
    /// @param distributionFractionBP the new distributionFractionBP value
    event DistributionFractionSet(uint32 distributionFractionBP);
}
