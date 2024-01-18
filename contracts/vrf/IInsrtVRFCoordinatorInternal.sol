// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { RequestCommitment } from "./DataTypes.sol";

/// @title IInsrtVRFCoordinatorInternal
/// @dev Interface containing all errors and events used in the InsrtVRFCoordinator contract
interface IInsrtVRFCoordinatorInternal {
    /// @notice thrown when an incorrect request commitment is provided for fulfillment
    error IncorrectCommitment();

    /// @notice thrown when an invalid consumer is attempting to request random words
    error InvalidConsumer(uint64 subId, address consumer);

    /// @notice thrown when an invalid fulfiller is attempting to fulfill random words
    error InvalidFullfiller();

    /// @notice thrown when the number of words requested is greater than MAX_NUM_WORDS
    /// @param numWordsRequested the number of words requested
    /// @param maxNumWords the maximum number of words allowed
    error NumWordsTooBig(uint32 numWordsRequested, uint32 maxNumWords);

    /// @notice emitted when a request for random words is successfully fulfilled
    /// @param requestId id of fulfilled request
    /// @param outputSeed output seed of fulfilled request
    /// @param payment payment amount for fulfilled request
    /// @param success whether fulfillment was successful
    event RandomWordsFulfilled(
        uint256 indexed requestId,
        uint256 outputSeed,
        uint96 payment,
        bool success
    );

    /// @notice emitted when a request for random words is successfully made
    /// @param keyHash hash of VRF key
    /// @param requestId id of request
    /// @param preSeed pre-seed of request
    /// @param subId subscription id of request
    /// @param minimumRequestConfirmations minimum number of confirmations required for request
    /// @param callbackGasLimit gas limit for callback
    /// @param numWords number of random words requested
    /// @param sender address of request sender
    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 requestId,
        uint256 preSeed,
        uint64 indexed subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address indexed sender
    );
}
