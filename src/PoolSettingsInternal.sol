// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {EnumerableSet} from "@solidstate-solidity/data/EnumerableSet.sol";
import {ERC1155MetadataInternal} from "@solidstate-solidity/token/ERC1155/metadata/ERC1155MetadataInternal.sol";

import {AccessControl} from "./AccessControl.sol";
import {Errors} from "./Errors.sol";
import {IPoolSettingsInternal} from "./IPoolSettingsInternal.sol";
import {PoolStorage} from "./PoolStorage.sol";

abstract contract PoolSettingsInternal is IPoolSettingsInternal, ERC1155MetadataInternal, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice sets the token URI for a shard of a given collection
     * @param collection address of underlying collection
     * @param shardURI token URI
     */
    function _setShardURI(address collection, string memory shardURI) internal {
        _setTokenURI(PoolStorage.layout().collectionShardId[collection], shardURI);
    }

    /**
     * @notice adds a collection to the underlying collections set of INLP
     * @param collection address of collection to add
     */
    function _addCollection(address collection) internal {
        PoolStorage.layout().whitelistedCollections.add(collection);
        emit CollectionAddition(collection);
    }

    /**
     * @notice removes a collection from the underlying collections set of INLP
     * @param collection address of collection to remove
     */
    function _removeCollection(address collection) internal {
        PoolStorage.layout().whitelistedCollections.remove(collection);
        emit CollectionRemoval(collection);
    }

    /**
     * @notice sets the shard ID for a given underlying collection
     * @param collection address of underlying collection
     * @param id id to be set
     */
    function _setShardId(address collection, uint256 id) internal {
        PoolStorage.Layout storage l = PoolStorage.layout();

        if (l.occupiedShardIds.contains(id)) {
            revert Errors.INLP__ShardIDOccupied();
        }

        l.collectionShardId[collection] = id;
        l.occupiedShardIds.add(id);

        emit ShardIDSet(collection, id);
    }
}
