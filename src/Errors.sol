// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

/**
 * @title Insrt Contracts Error library for INLP
 */
library Errors { 
    /**
     * @notice thrown when interaction with non-whitelisted collection attempted
     */
    error INLP__OnlyWhitelistedCollections();

    /**
     * @notice thrown when attempting to mint more shards than shardsPerToken value for given collection
     */
    error INLP__ShardsPerTokenExceeded();
}