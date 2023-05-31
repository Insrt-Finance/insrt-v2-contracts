// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {EnumerableSet} from "@solidstate-solidity/data/EnumerableSet.sol";

library PoolStorage {
    struct Layout {
        mapping(address collection => EnumerableSet.UintSet tokenIds) poolAssets; //perhaps rename
        mapping(address collection => uint256 shardId) collectionShardId;
        mapping(address collection => uint256 amount) tokenShards;
        mapping(address collection => uint256 amount) unclaimedShards;
        EnumerableSet.UintSet occupiedShardIds;
        EnumerableSet.AddressSet whitelistedCollections;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("insrt.contracts.storage.INLP");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
