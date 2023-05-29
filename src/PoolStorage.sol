// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { EnumerableSet } from '@solidstate-solidity/data/EnumerableSet.sol';

library PoolStorage {
    struct Layout {
        mapping(address collection => bool status) whitelistedCollections;
        mapping(address collection => EnumerableSet.UintSet tokenIds) poolAssets; //perhaps rename
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('insrt.contracts.storage.INLP');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}