// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { SafeOwnableInternal } from "@solidstate/contracts/access/ownable/SafeOwnableInternal.sol";

import { InsrtChainSpecificUtil } from "./InsrtChainSpecificUtil.sol";
import { RequestCommitment } from "./DataTypes.sol";
import { IInsrtVRFCoordinatorInternal } from "./IInsrtVRFCoordinatorInternal.sol";

/// @title InsrtVRFCoordinatorInternal
/// @dev defines modularly all logic for the InsrtVRFCoordinator contract in internal functions
abstract contract InsrtVRFCoordinatorInternal is IInsrtVRFCoordinatorInternal {
    /// @dev Mapping of consumer address to nonce
    mapping(address consumer => uint64 nonce) private consumers;

    /// @dev Mapping of fulfiller address to boolean
    mapping(address fulfiller => bool) private fulfillers;

    /// @dev Mapping of request ID to request commitment
    mapping(uint256 requestId => bytes32 requestCommitment)
        private requestCommitments;

    /// @dev The number of requests fulfilled
    uint256 private fulfillmentCount;

    /// @dev The number of requests made
    uint256 private requestCount;

    uint32 private MAX_NUM_WORDS = type(uint16).max;

    /// @notice Adds a consumer to a VRF coordinator contract
    /// @param consumer The consumer to add to the coordinator
    function _addConsumer(address consumer) internal {
        if (consumers[consumer] == 0) {
            consumers[consumer] = 1;
        }
    }

    /// @notice Adds a fulfiller to the VRF coordinator contract
    /// @param fulfiller The address of the fulfiller to add
    function _addFulfiller(address fulfiller) internal {
        fulfillers[fulfiller] = true;
    }

    /// @notice Computes the request ID and pre-seed for a random words request
    /// @param keyHash The key hash used for the request
    /// @param sender The address making the request
    /// @param subId The subscription ID for the request
    /// @param nonce The nonce for the request
    /// @return requestId The computed request ID
    /// @return preSeed The computed pre-seed
    function _computeRequestId(
        bytes32 keyHash,
        address sender,
        uint64 subId,
        uint64 nonce
    ) private pure returns (uint256 requestId, uint256 preSeed) {
        preSeed = uint256(keccak256(abi.encode(keyHash, sender, subId, nonce)));

        requestId = uint256(keccak256(abi.encode(keyHash, preSeed)));
    }

    /// @notice Fulfills a request for random words
    /// @param requestId The ID of the request to fulfill
    /// @param randomness The randomness to fulfill the request with
    /// @param rc The request commitment of the request to fulfill
    /// @return payment The payment amount for the fulfilled request
    function _fulfillRandomWords(
        uint256 requestId,
        uint256 randomness,
        RequestCommitment calldata rc
    ) internal returns (uint96 payment) {
        _onlyFulfiller();

        payment = 0;

        uint256[] memory randomWords = new uint256[](rc.numWords);

        for (uint256 i = 0; i < rc.numWords; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // if the request has already been fulfilled, short circuit to retain idempotency
        if (requestCommitments[requestId] == 0) {
            return payment = 1;
        }

        if (
            requestCommitments[requestId] !=
            keccak256(
                abi.encode(
                    requestId,
                    rc.blockNum,
                    rc.subId,
                    rc.callbackGasLimit,
                    rc.numWords,
                    rc.sender
                )
            )
        ) {
            revert IncorrectCommitment();
        }

        delete requestCommitments[requestId];

        VRFConsumerBaseV2 consumer = VRFConsumerBaseV2(rc.sender);

        consumer.rawFulfillRandomWords(requestId, randomWords);

        emit RandomWordsFulfilled(requestId, randomness, payment, true);

        fulfillmentCount++;
    }

    /// @notice Gets the current request fulfillment delta
    /// @return requestFulfillmentDelta The current request fulfillment delta
    function _getRequestFulfillmentDelta()
        internal
        view
        returns (uint256 requestFulfillmentDelta)
    {
        requestFulfillmentDelta = requestCount - fulfillmentCount;
    }

    /// @notice Mocks the Chainlink VRF coordinator's getSubscription function and returns dummy values.
    /// The max uint96 value is returned for the balance, since there is no subscription payment when using
    /// the InsrtVRFCoordinator contract.
    /// @return balance The mocked balance of the subscription
    function _getSubscription()
        internal
        pure
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory _consumers
        )
    {
        balance = type(uint96).max;
        reqCount = 0;
        owner = address(0);
        _consumers = new address[](0);
    }

    function _MAX_NUM_WORDS() internal view returns (uint32 maxNumWords) {
        maxNumWords = MAX_NUM_WORDS;
    }

    /// @notice Reverts if the caller is not a fulfiller
    function _onlyFulfiller() private view {
        if (!fulfillers[msg.sender]) {
            revert InvalidFullfiller();
        }
    }

    /// @notice Removes a consumer from the VRF coordinator contract
    /// @param consumer The consumer to remove from the contract
    function _removeConsumer(address consumer) internal {
        consumers[consumer] = 0;
    }

    /// @notice Requests a set of random words
    /// @param keyHash The hash of the VRF key to use for the request
    /// @param subId The subscription ID to use for the request
    /// @param requestConfirmations The number of confirmations to wait for before fulfilling the request
    /// @param callbackGasLimit The gas limit for the callback
    /// @param numWords The number of random words to request
    /// @return requestId The ID of the request
    function _requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) internal returns (uint256) {
        if (numWords > MAX_NUM_WORDS) {
            revert NumWordsTooBig(numWords, MAX_NUM_WORDS);
        }

        address msgSender = msg.sender;

        uint64 currentNonce = consumers[msgSender];

        if (currentNonce == 0) {
            revert InvalidConsumer(subId, msgSender);
        }

        uint64 nonce = currentNonce + 1;

        (uint256 requestId, uint256 preSeed) = _computeRequestId(
            keyHash,
            msgSender,
            subId,
            nonce
        );

        requestCommitments[requestId] = keccak256(
            abi.encode(
                requestId,
                InsrtChainSpecificUtil._getBlockNumber(),
                subId,
                callbackGasLimit,
                numWords,
                msgSender
            )
        );

        emit RandomWordsRequested(
            keyHash,
            requestId,
            preSeed,
            subId,
            requestConfirmations,
            callbackGasLimit,
            numWords,
            msgSender
        );

        consumers[msgSender] = nonce;

        requestCount++;

        return requestId;
    }

    function _setMaxNumWords(uint32 maxNumWords) internal {
        MAX_NUM_WORDS = maxNumWords;
    }
}
