// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { ERC721BaseInternal } from "@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol";

import { PerpetualMintStorage as s } from "./PerpetualMintStorage.sol";

abstract contract PerpetualMintInternal is
    VRFConsumerBaseV2,
    ERC721BaseInternal
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice thrown when an incorrent amount of ETH is received
     */
    error IncorrectETHReceived();

    /**
     * @notice emitted when the outcome of an attempted mint is resolved
     * @param collection address of collection that attempted mint is for
     * @param result success status of mint attempt
     */
    event ERC721MintResolved(address collection, bool result);

    uint32 internal constant BASIS = 1000000;

    bytes32 private immutable KEY_HASH;
    address private immutable VRF;
    uint64 private immutable SUBSCRIPTION_ID;
    uint32 private immutable CALLBACK_GAS_LIMIT;
    uint16 private immutable MIN_CONFIRMATIONS;

    constructor(
        bytes32 keyHash,
        address vrfCoordinator,
        uint64 subscriptionId,
        uint16 minConfirmations,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        KEY_HASH = keyHash;
        VRF = vrfCoordinator;
        SUBSCRIPTION_ID = subscriptionId;
        CALLBACK_GAS_LIMIT = callbackGasLimit;
        MIN_CONFIRMATIONS = minConfirmations;
    }

    /**
     * @notice internal Chainlink VRF callback
     * @notice is executed by the ChainlinkVRF Coordinator contract
     * @param requestId id of chainlinkVRF request
     * @param randomWords random values return by ChainlinkVRF Coordinator
     */
    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual {
        s.Layout storage l = s.layout();

        address account = l.requestAccount[requestId];
        address collection = l.requestCollection[requestId];

        if (l.collectionType[collection]) {
            _resolveERC721Mint(account, collection, randomWords);
        } else {
            _resolveERC1155Mint(account, collection, randomWords);
        }
    }

    /**
     * @notice requests random values from Chainlink VRF
     * @param account address calling this function
     * @param numWords amount of random values to request
     */
    function _requestRandomWords(address account, uint32 numWords) internal {
        uint256 requestId = VRFCoordinatorV2Interface(VRF).requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            MIN_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            numWords
        );

        s.layout().requestAccount[requestId] = account;
    }

    /**
     * @notice attempts to mint a token from a collection for an account
     * @param account address of account minting
     * @param collection address of collection which token may be minted from
     */
    function _attemptMint(address account, address collection) internal {
        s.Layout storage l = s.layout();

        if (msg.value != l.collectionMintPrice[collection]) {
            revert IncorrectETHReceived();
        }

        uint256 mintFee = (msg.value * l.mintFeeBP) / BASIS;

        l.protocolFees += mintFee;
        l.collectionEarnings[collection] += msg.value - mintFee;

        _requestRandomWords(account, 1);
    }

    /**
     * @notice selects the token which was won after a successfull mint attempt
     * @param collection address of collection
     * @param randomValue seed used to select the tokenId
     * @return tokenId id of won token
     */
    function _selectToken(
        address collection,
        uint128 randomValue
    ) internal view returns (uint256 tokenId) {
        s.Layout storage l = s.layout();

        EnumerableSet.UintSet storage escrowedTokenIds = l
            .escrowedERC721TokenIds[collection];

        uint256 tokenIndex;
        uint256 cumulativeRisk;

        do {
            cumulativeRisk += l.tokenRisksERC721[collection][
                escrowedTokenIds.at(tokenIndex)
            ];
            ++tokenIndex;
        } while (
            cumulativeRisk <= randomValue % l.totalCollectionRisk[collection]
        );

        tokenId = escrowedTokenIds.at(tokenIndex - 1);
    }

    function _selectERC1155Owner(
        address collection,
        uint256 tokenId,
        uint64 randomValue
    ) internal view returns (address owner) {
        s.Layout storage l = s.layout();

        EnumerableSet.AddressSet storage owners = l.escrowedERC1155TokenOwners[
            collection
        ][tokenId];

        uint256 cumulativeRisk;
        uint256 tokenIndex;

        do {
            cumulativeRisk += l.accountTotalTokenRisk[collection][tokenId][
                owners.at(tokenIndex)
            ];
            ++tokenIndex;
        } while (
            cumulativeRisk <=
                randomValue % l.totalERC1155TokenRisk[collection][tokenId]
        );

        owner = owners.at(tokenIndex - 1);
    }

    /**
     * @notice calculations the weighted collection-wide risk of an ERC721 collection
     * @param collection address of collection
     * @return risk value of collection-wide risk
     */
    function _averageCollectionRisk(
        address collection
    ) internal view returns (uint128 risk) {
        s.Layout storage l = s.layout();
        risk =
            l.totalCollectionRisk[collection] /
            uint128(l.totalEscrowedTokenAmount[collection]);
    }

    /**
     * @notice resolves the outcome of an attempted mint
     * @param account address attempting the mint
     * @param collection address of collection which token may be minted from
     * @param randomWords random values relating to attempt
     */
    function _resolveERC721Mint(
        address account,
        address collection,
        uint256[] memory randomWords
    ) private {
        s.Layout storage l = s.layout();

        uint128[2] memory randomValues = _chunk256to128(randomWords[0]);

        bool result = _averageCollectionRisk(collection) >
            _normalizeValue(
                uint128(randomValues[0]),
                l.totalCollectionRisk[collection]
            );

        if (!result) {
            _mint(account, l.id);
            ++l.id;
        }

        if (result) {
            uint256 wonTokenId = _selectToken(collection, randomValues[1]);

            address previousOwner = l.escrowedERC721TokenOwner[collection][
                wonTokenId
            ];

            _updateAccountEarnings(collection, previousOwner);
            _updateAccountEarnings(collection, account);

            --l.escrowedTokenAmount[previousOwner][collection];
            ++l.escrowedTokenAmount[account][collection];

            l.escrowedERC721TokenOwner[collection][wonTokenId] = account;
        }

        emit ERC721MintResolved(collection, result);
    }

    function _resolveERC1155Mint(
        address account,
        address collection,
        uint256[] memory randomWords
    ) private {
        s.Layout storage l = s.layout();

        uint128[2] memory randomValues = _chunk256to128(randomWords[0]);

        bool result = _averageCollectionRisk(collection) >
            _normalizeValue(
                uint128(randomValues[0]),
                l.totalCollectionRisk[collection]
            );

        if (!result) {
            _mint(account, l.id);
            ++l.id;
        }

        if (result) {
            uint64[2] memory randomValues64 = _chunk128to64(randomValues[1]);

            uint256 tokenId = _selectToken(collection, randomValues64[0]);

            address previousOwner = _selectERC1155Owner(
                collection,
                tokenId,
                randomValues64[1]
            );

            _updateAccountEarnings(collection, previousOwner);
            _updateAccountEarnings(collection, account);

            --l.escrowedTokenAmount[collection][previousOwner];
            ++l.escrowedTokenAmount[collection][account];
        }
    }

    /**
     * @notice updates the earnings of an account based on current conitions
     * @param collection address of collection earnings relate to
     * @param account address of account
     */
    function _updateAccountEarnings(
        address collection,
        address account
    ) private {
        s.Layout storage l = s.layout();

        uint256 escrowedTokens = l.escrowedTokenAmount[account][collection];

        if (escrowedTokens != 0) {
            l.accountEarnings[collection][account] +=
                ((l.collectionEarnings[collection] * escrowedTokens) /
                    l.totalEscrowedTokenAmount[collection]) -
                l.accountDeductions[collection][account];

            l.accountDeductions[collection][account] = l.accountEarnings[
                collection
            ][account];
        } else {
            l.accountDeductions[collection][account] = l.collectionEarnings[
                collection
            ];
        }
    }

    /**
     * @notice splits a uint256 value into 2 uint128 values
     * @param value uint256 value
     * @return chunks array of 2 uint128 values
     */
    function _chunk256to128(
        uint256 value
    ) private pure returns (uint128[2] memory chunks) {
        unchecked {
            for (uint256 i = 0; i < 2; ++i) {
                chunks[i] = uint128(value << (i * 128));
            }
        }
    }

    /**
     * @notice splits a uint128 value into 2 uint64 values
     * @param value uint128 value
     * @return chunks array of 2 uint64 values
     */
    function _chunk128to64(
        uint128 value
    ) private pure returns (uint64[2] memory chunks) {
        unchecked {
            for (uint64 i = 0; i < 2; ++i) {
                chunks[i] = uint64(value << (i * 64));
            }
        }
    }

    /**
     * @notice ensures a value is within the BASIS range
     * @param value value to normalize
     * @return normalizedValue value after normalization
     */
    function _normalizeValue(
        uint128 value,
        uint128 basis
    ) private pure returns (uint128 normalizedValue) {
        normalizedValue = value % basis;
    }
}
