// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { AggregatorV3Interface } from "@chainlink/interfaces/AggregatorV3Interface.sol";

/// @title IVRFCoordinatorV2
/// @notice Interface for the Chainlink V2 VRF Coordinator
interface IVRFCoordinatorV2 {
    /// @notice Thrown when the subscription balance is insufficient to pay the VRF request fee
    error InsufficientBalance();

    /// @notice Thrown when the consumer contract is not registered with the VRFCoordinatorV2 contract
    error InvalidConsumer(uint64 subId, address consumer);

    /// @notice Thrown when a request is made with more than MAX_NUM_WORDS words
    error NumWordsTooBig(uint32 have, uint32 want);

    /// @notice Computes fee based on the request count
    /// @param reqCount number of requests
    /// @return feePPM fee in LINK PPM
    /// @dev A flat fee is charged per fulfillment in millionths of link
    /// Fee range is [0, 2^32/10^6].
    function getFeeTier(uint64 reqCount) external view returns (uint32 feePPM);

    /// @notice Returns the LINK/ETH price feed contract
    function LINK_ETH_FEED()
        external
        view
        returns (AggregatorV3Interface linkEthFeed);

    /// @notice Returns the maximum number of words that can be requested in a single VRF request
    /// @return maxNumWords the maximum number of words that can be requested in a single VRF request
    function MAX_NUM_WORDS() external view returns (uint32 maxNumWords);
}
