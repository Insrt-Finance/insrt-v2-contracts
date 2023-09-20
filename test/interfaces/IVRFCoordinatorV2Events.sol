// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title IVRFCoordinatorV2Events
/// @dev Defines the base interface for VRFCoordinatorV2 contract events.
interface IVRFCoordinatorV2Events {
    /// @notice Emitted when a set of random words is successfully requested.
    /// @param keyHash The key hash of the request. Corresponds to a particular oracle job which uses
    /// the key for generating the VRF proof. Different key hashes have different gas price
    /// ceilings, so you can select a specific one to bound your maximum per request cost.
    /// @param requestId A unique identifier of the request. Used to match a request to a response in fulfillRandomWords.
    /// @param preSeed The pre seed generated during the request.
    /// @param subId The ID of the VRF subscription. Must be funded with the minimum
    /// subscription balance required for the selected keyHash.
    /// @param minimumRequestConfirmations The minimum number of blocks the oracle will wait
    /// before responding to the request. The acceptable range is [minimumRequestBlockConfirmations, 200].
    /// @param callbackGasLimit The amount of gas requested to receive in the fulfillRandomWords callback.
    /// Note: gasleft() inside fulfillRandomWords may be slightly less than this amount because of gas used calling the function
    /// (argument decoding etc.). The acceptable range is [0, maxGasLimit].
    /// @param numWords The number of uint256 random values requested to receive in the fulfillRandomWords callback.
    /// Note: these numbers are expanded in a secure way by the VRFCoordinator from a single random value supplied by the oracle.
    /// @param sender The address of the sender of the request.
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
