// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @dev DataTypes.sol defines the struct data types used in the InsrtVRFCoordinator contract

/// @dev Represents data specific to a request for random words
struct RequestCommitment {
    /// @dev The block number of the request
    uint64 blockNum;
    /// @dev The subscription ID of the request
    uint64 subId;
    /// @dev The gas limit of the callback
    uint32 callbackGasLimit;
    /// @dev The number of random words requested
    uint32 numWords;
    /// @dev The address of the request sender
    address sender;
}
