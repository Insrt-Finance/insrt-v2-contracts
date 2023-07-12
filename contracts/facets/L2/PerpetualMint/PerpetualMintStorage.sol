// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

library PerpetualMintStorage {
    ///add note for each variable in storage w short explanation
    struct Layout {
        /// @dev amount of protocol fees accrued in ETH (native token) from mint attempts
        uint256 protocolFees;
        /// @dev tokenId for minting consolation prizes (will be reworked)
        uint64 id;
        /// @dev mint fee in basis points
        uint32 mintFeeBP;
        /// @dev set of collections which have had assets deposited - used to claim earnings for users
        EnumerableSet.AddressSet activeCollections; //may be useless, if we want to remove "claimAllEarnings"
        /// @dev links the request made to chainlink VRF for random words to a Minter
        mapping(uint256 requestId => address minter) requestMinter;
        /// @dev links the request made to chainlink VRF for random words to a collection
        mapping(uint256 requestId => address collection) requestCollection;
        /// @dev indicates whether a collection is an ERC721 or ERC1155 with a boolean isERC721
        mapping(address collection => bool isERC721) collectionType;
        /// @dev total amount of ETH (native token) earned for a collection from mint attempts
        mapping(address collection => uint256 amount) collectionEarnings;
        /// @dev price of mint attempt in ETH (native token) for a collection
        mapping(address collection => uint256 mintPrice) collectionMintPrice;
        /// @dev sum of risk of every asset in a collection
        mapping(address collection => uint128 risk) totalRisk;
        /// @dev amount of token which may be minted for a collection
        mapping(address collection => uint256 amount) totalActiveTokens;
        /// @dev group of tokenIds which may be minted for a collection
        mapping(address collection => EnumerableSet.UintSet tokenIds) activeTokenIds;
        ///make account first & account => depositor
        /// @dev amont of deductions in ETH (native token) for a depositor for a collecion
        mapping(address collection => mapping(address account => uint256 amount)) accountDeductions;
        /// @dev amont of earnings in ETH (native token) for a depositor for a collecion
        mapping(address collection => mapping(address account => uint256 amount)) accountEarnings;
        /// @dev amount of tokens escrowed by the contract on behalf of a depositor for a collection
        /// which are able to be minted via mint attempts
        mapping(address collection => mapping(address account => uint256 amount)) activeTokens;
        /// @dev amount of tokens escrowed by the contract on behalf of a depositor for a collection
        /// which are not able to be minted via mint attempts
        mapping(address collection => mapping(address account => uint256 amount)) inactiveTokens;
        /// @dev sum of risks of tokens deposited by a depositor for a collection
        mapping(address collection => mapping(address account => uint256 amount)) totalAccountRisk;
        ///until here (make account first)
        /// @dev sum of risk across all tokens of the same id for a collection
        /// for ERC721 collcetions, this is just for a single token
        mapping(address collection => mapping(uint256 tokenId => uint256 risk)) tokenRisk;
        //ERC721
        /// @dev links the current owner of an escrowed token of a collection
        /// source of truth for checking which address may change token state (withdraw, setRisk etc)
        mapping(address collection => mapping(uint256 tokenId => address account)) escrowedERC721Owner;
        //ERC1155
        /// @dev set of owners of each tokenId for an ERC1155 collection
        mapping(address collection => mapping(uint256 tokenId => EnumerableSet.AddressSet accounts)) escrowedERC1155Owners;
        /// @dev risk for a given tokenId in an ERC1155 for an account
        /// an implication is that even if a depositor has deposited 5 tokens of the same tokenId, their risk is the same
        mapping(address collection => mapping(uint256 tokenId => mapping(address account => uint64 risk))) accountTokenRisk;
        /// @dev sum of all individual token risks of a token for an ERC1155 collection
        mapping(address collection => mapping(uint256 tokenId => uint64 risk)) totalTokenRisk;
        /// @dev set of ERC1155 token owners which have tokens escrowed and available for minting, of a given tokenId for a collection
        mapping(address collection => mapping(uint256 tokenId => EnumerableSet.AddressSet accounts)) activeERC1155Owners;
        /// @dev number of tokens of particular tokenId for an ERC1155 collection of a user which are able to be minted
        mapping(address collection => mapping(uint256 tokenId => mapping(address account => uint256 amount))) activeERC1155Tokens;
        /// @dev number of tokens of particular tokenId for an ERC1155 collection of a user which are not able to be minted
        mapping(address collection => mapping(uint256 tokenId => mapping(address account => uint256 amount))) inactiveERC1155Tokens;
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
