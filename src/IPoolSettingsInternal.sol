// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

interface IPoolSettingsInternal {
    /**
     * @notice emitted when a collection is added to the supported collections of INLP
     * @param collection address of collection
     */
    event CollectionAddition(address collection);

    /**
     * @notice emitted when a collection is removed from the supported collections of INLP
     * @param collection address of collection
     */
    event CollectionRemoval(address collection);

    /**
     * @notice emitted when the ShardID of a collection is set
     * @param collection address of collection
     * @param id value of ID
     */
    event ShardIDSet(address collection, uint256 id);
}
