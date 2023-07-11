// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { PerpetualMintInternal } from "./PerpetualMintInternal.sol";

contract PerpetualMint is PerpetualMintInternal {
    constructor(
        bytes32 keyHash,
        address vrf,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint16 minConfirmations
    )
        PerpetualMintInternal(
            keyHash,
            vrf,
            subscriptionId,
            callbackGasLimit,
            minConfirmations
        )
    {}

    /**
     * @notice Chainlink VRF Coordinator callback
     * @param requestId id of request for random values
     * @param randomWords random values returned from Chainlink VRF coordination
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        _fulfillRandomWords(requestId, randomWords);
    }

    /**
     * @notice attempts a mint for the msg.sender from a collection
     * @param collection address of collection for mint attempt
     */
    function attemptMint(address collection) external {
        _attemptMint(msg.sender, collection);
    }
}
