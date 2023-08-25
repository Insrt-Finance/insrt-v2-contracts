// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { AssetType } from "../../../enums/AssetType.sol";

/// @title PerpetualMintStorage
/// @dev defines storage layout for the PerpetualMint facet
library PerpetualMintStorage {
    /// @dev Encapsulates variables related to Chainlink VRF
    /// @dev see: https://docs.chain.link/vrf/v2/subscription#set-up-your-contract-and-request
    struct VRFConfig {
        /// @dev Chainlink identifier for prioritizing transactions
        /// different keyhashes have different gas prices thus different priorities
        bytes32 keyHash;
        /// @dev id of Chainlink subscription to VRF for PerpetualMint contract
        uint64 subscriptionId;
        /// @dev maximum amount of gas a user is willing to pay for completing the callback VRF function
        uint32 callbackGasLimit;
        /// @dev number of block confirmations the VRF service will wait to respond
        uint16 minConfirmations;
    }

    struct Layout {
        /// @dev all variables related to Chainlink VRF configuration
        VRFConfig vrfConfig;
        /// @dev amount of protocol fees accrued in ETH (native token) from mint attempts
        uint256 protocolFees;
        /// @dev tokenId for minting consolation prizes (will be reworked)
        uint64 id;
        /// @dev mint fee in basis points
        uint32 mintFeeBP;
        ///Collection specific
        /// @dev set of collections which have had assets deposited - used to claim earnings for users
        EnumerableSet.AddressSet activeCollections; //may be useless, if we want to remove "claimAllEarnings"
        /// @dev links the request made to chainlink VRF for random words to a Minter
        mapping(uint256 requestId => address minter) requestMinter;
        /// @dev links the request made to chainlink VRF for random words to a collection
        mapping(uint256 requestId => address collection) requestCollection;
        /// @dev indicates the type of asset for a collection
        /// Used to distinguish between different supported types of collections.
        mapping(address collection => AssetType) collectionType;
        /// @dev total amount of ETH (native token) earned for a collection from mint attempts
        mapping(address collection => uint256 amount) collectionEarnings;
        /// @dev value of collectionEarnings when totalRisk of collection was last updated
        mapping(address collection => uint256 earnings) lastCollectionEarnings;
        /// @dev base multiplier for earnings for a collection - increased every time totalRisk is updated
        mapping(address collection => uint256 multiplier) baseMultiplier;
        /// @dev price of mint attempt in ETH (native token) for a collection
        mapping(address collection => uint256 mintPrice) collectionMintPrice;
        /// @dev sum of risk of every asset in a collection
        mapping(address collection => uint256 risk) totalRisk;
        /// @dev amount of token which may be minted for a collection
        mapping(address collection => uint256 amount) totalActiveTokens;
        /// @dev group of tokenIds which may be minted for a collection
        mapping(address collection => EnumerableSet.UintSet tokenIds) activeTokenIds;
        /// @dev sum of risk across all tokens of the same id for a collection
        /// for ERC721 collections, this is just for a single token
        mapping(address collection => mapping(uint256 tokenId => uint256 risk)) tokenRisk;
        //ERC721
        /// @dev links the current owner of an escrowed token of a collection
        /// source of truth for checking which address may change token state (withdraw, setRisk etc)
        mapping(address collection => mapping(uint256 tokenId => address owner)) escrowedERC721Owner;
        //ERC1155
        /// @dev set of ERC1155 token owners which have tokens escrowed and available for minting, of a given tokenId for a collection
        mapping(address collection => mapping(uint256 tokenId => EnumerableSet.AddressSet owners)) activeERC1155Owners;
        ///User specific
        /// @dev earnings multiplier deducted from globalEarningsMultiplier for a depositor for a collection
        mapping(address depositor => mapping(address collection => uint256 multiplier)) multiplierOffset;
        /// @dev amount of earnings in ETH (native token) for a depositor for a collection
        mapping(address depositor => mapping(address collection => uint256 amount)) depositorEarnings;
        /// @dev amount of tokens escrowed by the contract on behalf of a depositor for an ERC721 collection
        /// which are able to be minted via mint attempts
        mapping(address depositor => mapping(address collection => uint256 amount)) activeTokens;
        /// @dev amount of tokens escrowed by the contract on behalf of a depositor for an ERC721 collection
        /// which are not able to be minted via mint attempts
        mapping(address depositor => mapping(address collection => uint256 amount)) inactiveTokens;
        /// @dev sum of risks of tokens deposited by a depositor for a collection
        mapping(address depositor => mapping(address collection => uint256 risk)) totalDepositorRisk;
        /// @dev risk for a given tokenId in an ERC1155 for a depositor
        /// an implication is that even if a depositor has deposited 5 tokens of the same tokenId, each token has the same risk
        mapping(address depositor => mapping(address collection => mapping(uint256 tokenId => uint256 risk))) depositorTokenRisk;
        /// @dev number of tokens of particular tokenId for an ERC1155 collection of a user which are able to be minted
        mapping(address depositor => mapping(address collection => mapping(uint256 tokenId => uint256 amount))) activeERC1155Tokens;
        /// @dev number of tokens of particular tokenId for an ERC1155 collection of a user which are not able to be minted
        mapping(address depositor => mapping(address collection => mapping(uint256 tokenId => uint256 amount))) inactiveERC1155Tokens;
        /// @dev maximum amount of active tokens allowed per collection
        uint256 maxActiveTokensLimit;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.PerpetualMint");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
