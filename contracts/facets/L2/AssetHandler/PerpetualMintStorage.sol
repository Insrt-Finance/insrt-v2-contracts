// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

library PerpetualMintStorage {
    struct Layout {
        uint256 protocolFees;
        uint64 id;
        uint32 mintFeeBP;
        uint32 protocolFeeBP;
        mapping(uint256 requestId => address account) requestUser;
        mapping(uint256 requestId => address collection) requestCollection;
        mapping(address collection => bool isERC721) collectionType;
        mapping(address collection => uint128 risks) totalCollectionRisk;
        mapping(address collection => mapping(uint256 tokenId => uint256 risk)) tokenRisks;
        mapping(address collection => EnumerableSet.UintSet tokenIds) escrowedTokenIds;
        mapping(address collection => uint256 mintPrice) collectionMintPrice;
        mapping(address collection => uint256 amount) totalCollectionEarnings;
        mapping(address collection => mapping(uint256 tokenId => uint256 amount)) totalCollectionTokenEarnings;
        mapping(address collection => mapping(address account => uint256 amount)) collectionUserDeductions;
        mapping(address collection => mapping(uint256 tokenId => address account)) escrowedERC721TokenOwner;
        mapping(address collection => mapping(uint256 tokenId => EnumerableSet.AddressSet accounts)) escrowedERC1155TokenOwners;
        mapping(address collection => mapping(uint256 tokenId => mapping(address account => uint256 amount))) accountEscrowedERC1155TokenAmount;
        mapping(address collection => mapping(uint256 tokenId => uint256 amount)) escrowedERC1155TokenAmount;
        mapping(address collection => mapping(address account => EnumerableSet.UintSet tokenIds)) accountEscrowedERC1155TokenIds;
        mapping(address collection => mapping(address account => uint256 amount)) accountEscrowedERC721TokenAmount; //could onvert to EnumerableSet.UintSet
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
