// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { EnumerableSet } from "@solidstate-solidity/data/EnumerableSet.sol";

library PerpetualMintStorage {
    struct Layout {
        uint256 totalFees;
        uint256 protocolFees;
        uint64 id;
        uint32 mintFeeBP;
        uint32 protocolFeeBP;
        mapping(uint256 requestId => address account) requestUser;
        mapping(uint256 requestId => address collection) requestCollection;
        mapping(address collection => uint32 risk) collectionRisks;
        mapping(address collection => uint256 mintPrice) collectionMintPrice;
        mapping(address collection => uint256 amount) collectionFees;
        mapping(address collection => mapping(address account => uint256 amount)) collectionUserFees;
        mapping(address collection => mapping(address account => uint256 amount)) collectionUserDeductions;
        mapping(address collection => EnumerableSet.UintSet tokenIds) escrowedERC721TokenIds;
        mapping(address collection => mapping(uint256 tokenId => address account)) stakedERC721TokenOwner;
        mapping(address collection => mapping(address account => uint256 amount)) stakedERC721TokenAmount;
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
