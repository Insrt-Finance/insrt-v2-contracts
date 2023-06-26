// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

library PerpetualMintStorage {
    struct Layout {
        uint256 protocolFees;
        uint64 id;
        uint32 mintFeeBP;
        mapping(uint256 requestId => address account) requestAccount;
        mapping(uint256 requestId => address collection) requestCollection;
        mapping(address collection => bool isERC721) collectionType;
        //ERC721
        mapping(address collection => uint256 amount) totalCollectionERC721Earnings;
        mapping(address collection => uint256 mintPrice) collectionMintPrice;
        mapping(address collection => uint128 risk) totalCollectionRisk;
        mapping(address collection => EnumerableSet.UintSet tokenIds) escrowedTokenIds;
        mapping(address collection => mapping(uint256 tokenId => uint256 risk)) tokenRisksERC721;
        mapping(address collection => mapping(address account => uint256 amount)) accountERC721Deductions;
        mapping(address collection => mapping(uint256 tokenId => address account)) escrowedERC721TokenOwner;
        mapping(address collection => mapping(address account => uint256 amount)) accountEscrowedERC721TokenAmount; //could convert to EnumerableSet.UintSet
        //ERC1155
        mapping(address collection => mapping(uint256 tokenId => uint256 amount)) collectionTokenMintPrice;
        mapping(address collection => mapping(uint256 tokenId => uint256 amount)) totalCollectionTokenEarnings;
        mapping(address collection => mapping(uint256 tokenId => uint256 amount)) escrowedERC1155TokenAmount;
        mapping(address collection => mapping(uint256 tokenId => uint256 risk)) totalCollectionERC1155TokenRisk;
        mapping(address collection => mapping(uint256 tokenId => EnumerableSet.UintSet risks)) tokenRisksERC1155;
        mapping(address collection => mapping(uint256 tokenId => EnumerableSet.AddressSet accounts)) escrowedERC1155TokenOwners;
        mapping(address collection => mapping(address account => EnumerableSet.UintSet tokenIds)) accountEscrowedERC1155TokenIds;
        mapping(address collection => mapping(uint256 tokenId => mapping(address account => uint256 amount))) accountEscrowedERC1155TokenAmount;
        mapping(address collection => mapping(uint256 tokenId => mapping(address account => EnumerableSet.UintSet amounts))) collectionTokenAmounts;
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
