// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFCoordinatorV2Mock } from "@chainlink/vrf/mocks/VRFCoordinatorV2Mock.sol";

import { VRFConsumerBaseV2Mock } from "./VRFConsumerBaseV2Mock.sol";

/// @title VRFCoordinatorV2MockPlus
/// @notice A mock for VRFCoordinatorV2 that uses rawFulfillRandomWordsPlus from VRFConsumerBaseV2Mock
/// to make the consumer VRF fulfillment call.
contract VRFCoordinatorV2MockPlus is VRFCoordinatorV2Mock {
    constructor(
        uint96 _baseFee,
        uint96 _gasPriceLink
    ) VRFCoordinatorV2Mock(_baseFee, _gasPriceLink) {}

    /// @notice fulfillRandomWordsWithOverridePlus allows the user to pass in their own random words
    /// and also allows bypassing VRFConsumerBaseV2's deeply nested msg.sender check by using rawFulfillRandomWordsPlus.
    /// Also returns whether the internal call to rawFulfillRandomWordsPlus succeeded.
    /// @param _requestId the request to fulfill
    /// @param _consumer the VRF randomness consumer to send the result to
    /// @param _words user-provided random words
    function fulfillRandomWordsWithOverridePlus(
        uint256 _requestId,
        address _consumer,
        uint256[] memory _words
    ) external returns (bool success) {
        uint256 startGas = gasleft();
        if (s_requests[_requestId].subId == 0) {
            revert("nonexistent request");
        }
        Request memory req = s_requests[_requestId];

        if (_words.length == 0) {
            _words = new uint256[](req.numWords);
            for (uint256 i = 0; i < req.numWords; i++) {
                _words[i] = uint256(keccak256(abi.encode(_requestId, i)));
            }
        } else if (_words.length != req.numWords) {
            revert InvalidRandomWords();
        }

        VRFConsumerBaseV2Mock v;
        bytes memory callReq = abi.encodeWithSelector(
            v.rawFulfillRandomWordsPlus.selector,
            _requestId,
            _words
        );
        (success, ) = _consumer.call{ gas: req.callbackGasLimit }(callReq);

        uint96 payment = uint96(
            BASE_FEE + ((startGas - gasleft()) * GAS_PRICE_LINK)
        );
        if (s_subscriptions[req.subId].balance < payment) {
            revert InsufficientBalance();
        }
        s_subscriptions[req.subId].balance -= payment;
        delete (s_requests[_requestId]);
        emit RandomWordsFulfilled(_requestId, _requestId, payment, success);

        return success;
    }
}
