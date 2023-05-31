// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

library ExecutorStorage {
    struct Layout {
        address executor;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("insrt.contracts.storage.executor");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
