// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

interface IPerpetualMint {
    /**
     * @notice attempts a mint for the msg.sender from a collection
     * @param collection address of collection for mint attempt
     */
    function attemptMint(address collection) external;
}
