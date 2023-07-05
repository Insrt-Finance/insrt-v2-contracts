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
     * @notice thrown when attemping to act for a collection which is not whitelisted
     */
    error CollectionNotWhitelisted();

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
     * @param collection address of collection to attempt mint for
     * @param numWords amount of random values to request
     */
    function _requestRandomWords(
        address account,
        address collection,
        uint32 numWords
    ) internal {
        s.Layout storage l = s.layout();

        if (!l.isWhitelisted[collection]) {
            revert CollectionNotWhitelisted();
        }

        uint256 requestId = VRFCoordinatorV2Interface(VRF).requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            MIN_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            numWords
        );

        l.requestAccount[requestId] = account;
        l.requestCollection[requestId] = collection;
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

        _requestRandomWords(account, collection, 1);
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

        EnumerableSet.UintSet storage tokenIds = l.activeTokenIds[collection];

        uint256 tokenIndex;
        uint256 cumulativeRisk;
        uint256 normalizedValue = randomValue % l.totalRisk[collection];

        do {
            tokenId = tokenIds.at(tokenIndex);
            cumulativeRisk += l.tokenRisk[collection][tokenId];
            ++tokenIndex;
        } while (cumulativeRisk <= normalizedValue);
    }

    /**
     * @notice selects the account which will have an ERC1155 reassigned to the successful minter
     * @param collection address of ERC1155 collection
     * @param tokenId id of token
     * @param randomValue random value used for selection
     * @return owner address of selected account
     */
    function _selectERC1155Owner(
        address collection,
        uint256 tokenId,
        uint64 randomValue
    ) internal view returns (address owner) {
        s.Layout storage l = s.layout();

        EnumerableSet.AddressSet storage owners = l.activeERC1155TokenOwners[
            collection
        ][tokenId];

        uint256 cumulativeRisk;
        uint256 tokenIndex;
        uint256 normalizedValue = randomValue %
            l.totalERC1155TokenRisk[collection][tokenId];

        do {
            owner = owners.at(tokenIndex);
            cumulativeRisk +=
                l.accountTokenRisk[collection][tokenId][owner] *
                l.activeERC1155TokenAmount[collection][tokenId][owner];
            ++tokenIndex;
        } while (cumulativeRisk <= normalizedValue);
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
            l.totalRisk[collection] /
            uint128(l.totalActiveTokens[collection]);
    }

    /**
     * @notice resolves the outcome of an attempted mint of an ERC721 collection
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
            _normalizeValue(uint128(randomValues[0]), BASIS);

        //TODO: update based on consolation spec
        if (!result) {
            _mint(account, l.id);
            ++l.id;
        }

        if (result) {
            uint256 tokenId = _selectToken(collection, randomValues[1]);

            address oldOwner = l.escrowedERC721TokenOwner[collection][tokenId];

            _updateAccountEarnings(collection, oldOwner);
            _updateAccountEarnings(collection, account);

            --l.activeTokens[collection][oldOwner];
            ++l.inactiveTokens[collection][account];

            l.activeTokenIds[collection].remove(tokenId);
            l.escrowedERC721TokenOwner[collection][tokenId] = account;
        }

        emit ERC721MintResolved(collection, result);
    }

    /**
     * @notice resolves the outcome of an attempted mint of an ERC1155 collection
     * @param account address attempting the mint
     * @param collection address of collection which token may be minted from
     * @param randomWords random values relating to attempt
     */
    function _resolveERC1155Mint(
        address account,
        address collection,
        uint256[] memory randomWords
    ) private {
        s.Layout storage l = s.layout();

        uint128[2] memory randomValues = _chunk256to128(randomWords[0]);

        bool result = _averageCollectionRisk(collection) >
            _normalizeValue(uint128(randomValues[0]), BASIS);

        //TODO: update based on consolation spec
        if (!result) {
            _mint(account, l.id);
            ++l.id;
        }

        if (result) {
            uint64[2] memory randomValues64 = _chunk128to64(randomValues[1]);

            uint256 tokenId = _selectToken(collection, randomValues64[0]);

            address oldOwner = _selectERC1155Owner(
                collection,
                tokenId,
                randomValues64[1]
            );

            _updateAccountEarnings(collection, oldOwner);
            _updateAccountEarnings(collection, account);

            _assignEscrowedERC1155Asset(oldOwner, account, collection, tokenId);
        }
    }

    /**
     * @notice assigns an ERC1155 asset from one account to another, updating the required
     * state variables simultaneously
     * @param from address asset currently is escrowed for
     * @param to address that asset will be assigned to
     * @param collection address of ERC1155 collection
     * @param tokenId token id
     */
    function _assignEscrowedERC1155Asset(
        address from,
        address to,
        address collection,
        uint256 tokenId
    ) private {
        s.Layout storage l = s.layout();

        --l.activeERC1155TokenAmount[collection][tokenId][from];
        ++l.inactiveERC1155TokenAmount[collection][tokenId][to];

        if (!l.escrowedERC1155TokenOwners[collection][tokenId].contains(to)) {
            l.escrowedERC1155TokenOwners[collection][tokenId].add(from);
        }

        if (l.activeERC1155TokenAmount[collection][tokenId][from] == 0) {
            l.activeERC1155TokenOwners[collection][tokenId].remove(from);

            delete l.accountTokenRisk[collection][tokenId][from];
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

        uint256 activeTokens = l.activeTokens[collection][account];

        if (activeTokens != 0) {
            l.accountEarnings[collection][account] +=
                ((l.collectionEarnings[collection] * activeTokens) /
                    l.totalActiveTokens[collection]) -
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

    /**
     * @notice returns the product of the amount of assets of a collction with the BASIS
     * @param collection address of collection
     * @return basis product of the amoutn of assets with the basis
     */
    function _cumulativeBasis(
        address collection
    ) private view returns (uint256 basis) {
        basis = s.layout().totalActiveTokens[collection] * BASIS;
    }
}
