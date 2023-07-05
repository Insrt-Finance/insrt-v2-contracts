// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

library PerpetualMintStorage {
    //note: must add whitelist collections mapping
    struct Layout {
        uint256 protocolFees;
        uint64 id;
        uint32 mintFeeBP;
        mapping(uint256 requestId => address account) requestAccount;
        mapping(uint256 requestId => address collection) requestCollection;
        mapping(address collection => bool status) isWhitelisted;
        mapping(address collection => bool isERC721) collectionType;
        mapping(address collection => uint256 amount) collectionEarnings;
        mapping(address collection => uint256 mintPrice) collectionMintPrice;
        mapping(address collection => uint128 risk) totalRisk;
        mapping(address collection => mapping(address account => uint256 amount)) accountDeductions;
        mapping(address collection => mapping(address account => uint256 amount)) accountEarnings;
        mapping(address collection => mapping(uint256 tokenId => uint256 risk)) tokenRisk;
        //ERC721
        mapping(address collection => mapping(uint256 tokenId => address account)) escrowedERC721TokenOwner;
        //ERC1155
        mapping(address collection => mapping(uint256 tokenId => EnumerableSet.AddressSet accounts)) escrowedERC1155TokenOwners;
        mapping(address collection => mapping(uint256 tokenId => mapping(address account => uint64 risk))) accountTokenRisk;
        mapping(address collection => mapping(uint256 tokenId => uint64 risk)) totalERC1155TokenRisk;
        mapping(address collection => mapping(uint256 tokenId => mapping(address account => uint256 amount))) escrowedERC1155TokenAmount;
        //activity storage
        mapping(address collection => EnumerableSet.UintSet tokenIds) activeTokenIds;
        mapping(address collection => uint256 amount) totalActiveTokens;
        mapping(address collection => mapping(address account => uint256 amount)) inactiveTokens;
        mapping(address collection => mapping(address account => uint256 amount)) activeTokens;
        mapping(address collection => mapping(uint256 tokenId => EnumerableSet.AddressSet accounts)) activeERC1155TokenOwners;
        mapping(address collection => mapping(uint256 tokenId => mapping(address account => uint256 amount))) activeERC1155TokenAmount;
        mapping(address collection => mapping(uint256 tokenId => mapping(address account => uint256 amount))) inactiveERC1155TokenAmount;
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