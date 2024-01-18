// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { SafeOwnable } from "@solidstate/contracts/access/ownable/SafeOwnable.sol";

import { RequestCommitment } from "./DataTypes.sol";
import { IInsrtVRFCoordinator } from "./IInsrtVRFCoordinator.sol";
import { InsrtVRFCoordinatorInternal } from "./InsrtVRFCoordinatorInternal.sol";

/// @title InsrtVRFCoordinator
/// @dev A simplified version of Chainlink's VRF Coordinator without subscriptions.
contract InsrtVRFCoordinator is
    IInsrtVRFCoordinator,
    InsrtVRFCoordinatorInternal,
    SafeOwnable
{
    constructor() payable InsrtVRFCoordinatorInternal() {
        _setOwner(msg.sender);
    }

    /// @inheritdoc IInsrtVRFCoordinator
    function addConsumer(uint64, address consumer) external onlyOwner {
        _addConsumer(consumer);
    }

    /// @inheritdoc IInsrtVRFCoordinator
    function addFulfiller(address fulfiller) external onlyOwner {
        _addFulfiller(fulfiller);
    }

    /// @inheritdoc IInsrtVRFCoordinator
    function fulfillRandomWords(
        uint256 requestId,
        uint256 randomness,
        RequestCommitment calldata rc
    ) external returns (uint96 payment) {
        payment = _fulfillRandomWords(requestId, randomness, rc);
    }

    /// @inheritdoc IInsrtVRFCoordinator
    function getRequestFulfillmentDelta()
        external
        view
        returns (uint256 requestFulfillmentDelta)
    {
        requestFulfillmentDelta = _getRequestFulfillmentDelta();
    }

    /// @inheritdoc IInsrtVRFCoordinator
    function getSubscription(
        uint64
    )
        external
        pure
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        )
    {
        (balance, reqCount, owner, consumers) = _getSubscription();
    }

    /// @inheritdoc IInsrtVRFCoordinator
    function MAX_NUM_WORDS() external view returns (uint32 maxNumWords) {
        maxNumWords = _MAX_NUM_WORDS();
    }

    /// @inheritdoc IInsrtVRFCoordinator
    function removeConsumer(uint64, address consumer) external onlyOwner {
        _removeConsumer(consumer);
    }

    /// @inheritdoc IInsrtVRFCoordinator
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId) {
        requestId = _requestRandomWords(
            keyHash,
            subId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    /// @inheritdoc IInsrtVRFCoordinator
    function setMaxNumWords(uint32 maxNumWords) external onlyOwner {
        _setMaxNumWords(maxNumWords);
    }
}
