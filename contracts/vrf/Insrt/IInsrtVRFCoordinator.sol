// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ISafeOwnable } from "@solidstate/contracts/access/ownable/ISafeOwnable.sol";

import { RequestCommitment } from "./DataTypes.sol";
import { IInsrtVRFCoordinatorInternal } from "./IInsrtVRFCoordinatorInternal.sol";

/// @title IInsrtVRFCoordinator
/// @dev Interface of the InsrtVRFCoordinator contract
interface IInsrtVRFCoordinator is IInsrtVRFCoordinatorInternal, ISafeOwnable {
    /// @notice Adds a consumer to a VRF subscription
    /// @param subId The subscription ID to add the consumer to
    /// @param consumer The consumer to add to the subscription
    function addConsumer(uint64 subId, address consumer) external;

    /// @notice Adds a fulfiller to the VRF coordinator contract
    /// @param fullfiller The address of the fulfiller to add
    function addFulfiller(address fullfiller) external;

    /// @notice Fulfills a request for random words
    /// @param requestId The ID of the request to fulfill
    /// @param randomness The randomness to fulfill the request with
    /// @param rc The request commitment of the request to fulfill
    /// @return payment The payment amount for the fulfilled request
    function fulfillRandomWords(
        uint256 requestId,
        uint256 randomness,
        RequestCommitment calldata rc
    ) external returns (uint96 payment);

    /// @notice Gets the current request fulfillment delta
    /// @return requestFulfillmentDelta The current request fulfillment delta
    function getRequestFulfillmentDelta()
        external
        view
        returns (uint256 requestFulfillmentDelta);

    /// @notice Gets the current subscription data for a VRF subscription
    /// @param subId The subscription ID to get the data for
    /// @return balance The current balance of the subscription
    /// @return reqCount The current number of requests made for the subscription
    /// @return owner The current owner of the subscription
    /// @return consumers The current consumers of the subscription
    function getSubscription(
        uint64 subId
    )
        external
        pure
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        );

    /// @notice Returns the current maximum number of words that can be requested in a single request
    /// @return maxNumWords The current maximum number of words
    function MAX_NUM_WORDS() external view returns (uint32 maxNumWords);

    /// @notice Removes a consumer from a VRF subscription
    /// @param subId The subscription ID to remove the consumer from
    /// @param consumer The consumer to remove from the subscription
    function removeConsumer(uint64 subId, address consumer) external;

    /// @notice Requests a set of random words
    /// @param keyHash The hash of the VRF key to use for the request
    /// @param subId The subscription ID to use for the request
    /// @param requestConfirmations The number of confirmations to wait for before fulfilling the request
    /// @param callbackGasLimit The gas limit for the callback
    /// @param numWords The number of random words to request
    /// @return requestId The ID of the request
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /// @notice Updates the maximum number of words that can be requested in a single request
    /// @param maxNumWords The new maximum number of words
    function setMaxNumWords(uint32 maxNumWords) external;
}
