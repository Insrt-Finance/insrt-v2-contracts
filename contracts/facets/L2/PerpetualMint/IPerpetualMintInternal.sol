// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { PerpetualMintStorage as Storage } from "./Storage.sol";

/// @title IPerpetualMintInternal interface
/// @dev contains all errors and events used in the PerpeutlaMint facet contract
interface IPerpetualMintInternal {
    /// @notice thrown when attempting to active more tokens than inactve amount
    error AmountToActivateExceedsInactiveTokens();

    /// @notice thrown when attempting to idle more tokens than currently active for a depositor
    /// in an ERC1155 collection
    error AmountToIdleExceedsActiveTokens();

    /// @notice thrown when the arrays of tokenIds and risks have different length when attempting to update
    /// ERC721 or ERC1155 token risks
    error ArrayLengthMismatch();

    /// @notice thrown when attempting to set a value of risk larger than basis
    error BasisExceeded();

    /// @notice thrown when attempting to update risks of  tokens which belong to a different collection
    /// type than that specified in the functional call
    error CollectionTypeMismatch();

    /// @notice thrown when an incorrent amount of ETH is received
    error IncorrectETHReceived();

    /// @notice thrown when a non-owner is attempting to modify token parameters
    error OnlyEscrowedTokenOwner();

    /// @notice thrown when an attempt is made to update token risk to 0
    error TokenRiskMustBeNonZero();

    /// @notice emitted when the outcome of an attempted mint is resolved
    /// @param collection address of collection that attempted mint is for
    /// @param result success status of mint attempt
    event ERC1155MintResolved(address indexed collection, bool result);

    /// @notice emitted when the outcome of an attempted mint is resolved
    /// @param collection address of collection that attempted mint is for
    /// @param result success status of mint attempt
    event ERC721MintResolved(address indexed collection, bool result);

    /// @notice emitted when the mint price of a collection is set
    /// @param collection address of collection
    /// @param price mint price of collection
    event MintPriceSet(address collection, uint256 price);

    /// @notice emitted when the Chainlink VRF config is set
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF
    event VRFConfigSet(Storage.VRFConfig config);
}
