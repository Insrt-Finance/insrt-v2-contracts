// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

interface IPerpetualMint {
    /**
     * @notice thrown when an incorrent amount of ETH is received
     */
    error IncorrectETHReceived();

    /**
     * @notice thrown when attemping to act for a collection which is not whitelisted
     */
    error CollectionNotWhitelisted();

    /**
     * @notice emitted when the outcome of an attempted mint is resolved
     * @param collection address of collection that attempted mint is for
     * @param result success status of mint attempt
     */
    event ERC721MintResolved(address collection, bool result);

    /**
     * @notice emitted when the outcome of an attempted mint is resolved
     * @param collection address of collection that attempted mint is for
     * @param result success status of mint attempt
     */
    event ERC1155MintResolved(address collection, bool result);
}
