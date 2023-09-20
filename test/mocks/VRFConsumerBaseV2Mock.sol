// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";

/// @title VRFConsumerBaseV2Mock
/// @notice Mock contract to test VRFConsumerBaseV2
abstract contract VRFConsumerBaseV2Mock is VRFConsumerBaseV2 {
    /// @notice rawFulfillRandomWordsPlus is a workaround to remove the guard in rawFulfillRandomness
    /// that checks the origin of the call. This is necessary to test the contract, due to current foundry limitations.
    /// @dev In production, rawFulfillRandomness is called by the VRFCoordinator once it receives a valid VRF proof.
    /// After validating the origin of the call, rawFulfillRandomness calls fulfillRandomness.
    /// @param requestId The mock request ID to be fulfilled
    /// @param randomWords The generated mock random words to be used to fulfill the request
    function rawFulfillRandomWordsPlus(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        fulfillRandomWords(requestId, randomWords);
    }
}
