// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { EnumerableSet } from "@solidstate-solidity/data/EnumerableSet.sol";

library PerpetualMintStorage {
    struct Layout {
        mapping(uint256 requestId => address account) requestUser;
        mapping(uint256 requestId => address collection) requestCollection;
        mapping(address collection => EnumerableSet.UintSet tokenIds) escrowedTokenIds;
        mapping(address collection => mapping(uint256 tokenId => mapping(uint256 amount => EnumerableSet.UintSet risks))) tokenRisks;
        mapping(address collection => mapping(uint256 amount => mapping(uint256 risk => EnumerableSet.UintSet tokenIds))) tokensAtRisk;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.PerpetualMintStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
