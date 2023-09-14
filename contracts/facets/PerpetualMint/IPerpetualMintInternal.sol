// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { PerpetualMintStorage as Storage, VRFConfig } from "./Storage.sol";

/// @title IPerpetualMintInternal interface
/// @dev contains all errors and events used in the PerpetualMint facet contract
interface IPerpetualMintInternal {
    /// @notice thrown when attempting to set a value of risk larger than basis
    error BasisExceeded();

    /// @notice thrown when an incorrect amount of ETH is received
    error IncorrectETHReceived();

    /// @notice thrown when there are not enough consolation fees accrued to faciliate
    /// minting with $MINT
    error InsufficientConsolationFees();

    /// @notice thrown when attempting to mint 0 tokens
    error InvalidNumberOfMints();

    /// @dev thrown when attempting to update a collection risk and
    /// there are pending mint requests in a collection
    error PendingRequests();

    /// @notice thrown when fulfilled random words do not match for attempted mints
    error UnmatchedRandomWords();

    /// @notice emitted when the risk for a collection is set
    /// @param collection address of collection
    /// @param risk risk of collection
    event CollectionRiskSet(address collection, uint32 risk);

    /// @notice emitted when the mint price of a collection is set
    /// @param collection address of collection
    /// @param price mint price of collection
    event MintPriceSet(address collection, uint256 price);

    /// @notice emitted when the outcome of an attempted mint is resolved
    /// @param minter address of account attempting the mint
    /// @param collection address of collection that attempted mint is for
    /// @param attempts number of mint attempts
    /// @param totalMintAmount amount of $MINT tokens minted
    /// @param totalReceiptAmount amount of receipts (ERC1155 tokens) minted (successful mint attempts)
    event MintResult(
        address indexed minter,
        address indexed collection,
        uint256 attempts,
        uint256 totalMintAmount,
        uint256 totalReceiptAmount
    );

    /// @notice emitted when the Chainlink VRF config is set
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF
    event VRFConfigSet(VRFConfig config);
}
