// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

/**
 * @title Insrt Contracts Error library for INLP
 */
library Errors {
    /**
     * @notice thrown when calling a function only allowed to be called by the protocol owner
     */
    error INLP__NotProtocolOwner();

    /**
     * @notice thrown when calling a function only allowed to be called by executor
     */
    error INLP__NotExecutor();

    /**
     * @notice thrown when interaction with non-whitelisted collection attempted
     */
    error INLP__OnlyWhitelistedCollections();

    /**
     * @notice thrown when attempting to mint more shards than shardsPerToken value for given collection
     */
    error INLP__ShardsPerTokenExceeded();

    /**
     * @notice thrown when attempting to claim more shards than amount of unclaimed shards
     */
    error INLP__InsufficientUnclaimedShards();

    /**
     * @notice thrown when attempting to claim shards with incorrect ETH value sent
     */
    error INLP__IncorrectETHReceived();

    /**
     * @notice thrown when attempting to set a shard ID which is already occupied by another collection
     */
    error INLP__ShardIDOccupied();
}
