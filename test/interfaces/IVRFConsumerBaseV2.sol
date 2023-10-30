// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title IVRFConsumerBaseV2
/// @notice Interface for the Chainlink V2 VRF Consumer Base contract
interface IVRFConsumerBaseV2 {
    /// @notice Callback function used by VRFCoordinator when it receives a valid VRF proof.
    /// @dev rawFulfillRandomness then calls fulfillRandomness, after validating the origin of the call.
    /// @param requestId The ID of the VRF request.
    /// @param randomWords Array of random words generated by the VRF.
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external;
}