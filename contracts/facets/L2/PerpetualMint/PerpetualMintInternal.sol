// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { VRFCoordinatorV2Interface } from "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { ERC721BaseInternal } from "@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";

import { IPerpetualMintInternal } from "./IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "./Storage.sol";

/// @title PerpetualMintInternal facet contract
/// @dev defines modularly all logic for the PerpetualMint mechanism in internal functions
abstract contract PerpetualMintInternal is
    VRFConsumerBaseV2,
    ERC721BaseInternal,
    IPerpetualMintInternal
{
    using AddressUtils for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev denominator used in percentage calculations
    uint32 internal constant BASIS = 1000000000;

    /// @dev see: https://docs.chain.link/vrf/v2/subscription#set-up-your-contract-and-request
    /// @dev Chainlink identifier for prioritizing transactions
    /// different keyhashes have different gas prices thus different priorities
    bytes32 private immutable KEY_HASH;
    /// @dev address of Cchainlink VRFCoordinatorV2 contract
    address private immutable VRF;
    /// @dev id of Chainlink subscription to VRF for PerpetualMint contract
    /// TODO: identify whether this needs to be updated thus be stored in storage
    uint64 private immutable SUBSCRIPTION_ID;
    /// @dev maximum amount of gas a user is willing to pay for completing the callback VRF function
    uint32 private immutable CALLBACK_GAS_LIMIT;
    /// @dev number of block confirmations the VRF service will wait to respond
    uint16 private immutable MIN_CONFIRMATIONS;

    constructor(
        bytes32 keyHash,
        address vrfCoordinator,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint16 minConfirmations
    ) VRFConsumerBaseV2(vrfCoordinator) {
        KEY_HASH = keyHash;
        VRF = vrfCoordinator;
        SUBSCRIPTION_ID = subscriptionId;
        CALLBACK_GAS_LIMIT = callbackGasLimit;
        MIN_CONFIRMATIONS = minConfirmations;
    }

    /// @notice calculates the available earnings for a depositor across all collections
    /// @param depositor address of depositor
    /// @return allEarnings amount of available earnings across all collections
    function _allAvailableEarnings(
        address depositor
    ) internal view returns (uint256 allEarnings) {
        EnumerableSet.AddressSet storage collections = Storage
            .layout()
            .activeCollections;
        uint256 length = collections.length();

        unchecked {
            for (uint256 i; i < length; ++i) {
                allEarnings += _availableEarnings(depositor, collections.at(i));
            }
        }
    }

    /// @notice assigns an ERC1155 asset from one account to another, updating the required
    /// state variables simultaneously
    /// @param from address asset currently is escrowed for
    /// @param to address that asset will be assigned to
    /// @param collection address of ERC1155 collection
    /// @param tokenId token id
    function _assignEscrowedERC1155Asset(
        address from,
        address to,
        address collection,
        uint256 tokenId
    ) private {
        Storage.Layout storage l = Storage.layout();

        --l.activeERC1155Tokens[from][collection][tokenId];
        ++l.inactiveERC1155Tokens[to][collection][tokenId];

        if (l.activeERC1155Tokens[from][collection][tokenId] == 0) {
            l.activeERC1155Owners[collection][tokenId].remove(from);
            delete l.depositorTokenRisk[from][collection][tokenId];
        }
    }

    /// @notice attempts to mint a token from a collection for a minter
    /// @param minter address of minter
    /// @param collection address of collection which token may be minted from
    function _attemptMint(address minter, address collection) internal {
        Storage.Layout storage l = Storage.layout();

        if (msg.value != l.collectionMintPrice[collection]) {
            revert IncorrectETHReceived();
        }

        uint256 mintFee = (msg.value * l.mintFeeBP) / BASIS;

        l.protocolFees += mintFee;
        l.collectionEarnings[collection] += msg.value - mintFee;

        _requestRandomWords(minter, collection, 1);
    }

    /// @notice calculates the available earnings for a depositor for a given collection
    /// @param depositor address of depositor
    /// @param collection address of collection
    /// @return earnings amount of available earnings
    function _availableEarnings(
        address depositor,
        address collection
    ) internal view returns (uint256 earnings) {
        Storage.Layout storage l = Storage.layout();

        earnings =
            l.depositorEarnings[depositor][collection] +
            ((l.collectionEarnings[collection] *
                l.totalDepositorRisk[depositor][collection]) /
                l.totalRisk[collection]) -
            l.depositorDeductions[depositor][collection];
    }

    /// @notice calculations the weighted collection-wide risk of a collection
    /// @param collection address of collection
    /// @return risk value of collection-wide risk
    function _averageCollectionRisk(
        address collection
    ) internal view returns (uint128 risk) {
        Storage.Layout storage l = Storage.layout();
        risk =
            l.totalRisk[collection] /
            uint128(l.totalActiveTokens[collection]);
    }

    /// @notice splits a uint128 value into 2 uint64 values
    /// @param value uint128 value
    /// @return chunks array of 2 uint64 values
    function _chunk128to64(
        uint128 value
    ) private pure returns (uint64[2] memory chunks) {
        unchecked {
            for (uint64 i = 0; i < 2; ++i) {
                chunks[i] = uint64(value << (i * 64));
            }
        }
    }

    /// @notice splits a uint256 value into 2 uint128 values
    /// @param value uint256 value
    /// @return chunks array of 2 uint128 values
    function _chunk256to128(
        uint256 value
    ) private pure returns (uint128[2] memory chunks) {
        unchecked {
            for (uint256 i = 0; i < 2; ++i) {
                chunks[i] = uint128(value << (i * 128));
            }
        }
    }

    /// @notice claims all earnings across collections of a depositor
    /// @param depositor address of depositor
    function _claimAllEarnings(address depositor) internal {
        EnumerableSet.AddressSet storage collections = Storage
            .layout()
            .activeCollections;
        uint256 length = collections.length();

        unchecked {
            for (uint256 i; i < length; ++i) {
                _claimEarnings(depositor, collections.at(i));
            }
        }
    }

    /// @notice claims all earnings of a collection for a depositor
    /// @param depositor address of acount
    /// @param collection address of collection
    function _claimEarnings(address depositor, address collection) internal {
        Storage.Layout storage l = Storage.layout();

        _updateDepositorEarnings(depositor, collection);
        uint256 earnings = l.depositorEarnings[depositor][collection];

        delete l.depositorEarnings[depositor][collection];
        payable(depositor).sendValue(earnings);
    }

    /// @notice returns the product of the amount of assets of a collction with the BASIS
    /// @param collection address of collection
    /// @return basis product of the amoutn of assets with the basis
    /// Note: May not need
    function _cumulativeBasis(
        address collection
    ) private view returns (uint256 basis) {
        basis = Storage.layout().totalActiveTokens[collection] * BASIS;
    }

    /// @notice internal Chainlink VRF callback
    /// @notice is executed by the ChainlinkVRF Coordinator contract
    /// @param requestId id of chainlinkVRF request
    /// @param randomWords random values return by ChainlinkVRF Coordinator
    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual {
        Storage.Layout storage l = Storage.layout();

        address minter = l.requestMinter[requestId];
        address collection = l.requestCollection[requestId];

        if (l.collectionType[collection]) {
            _resolveERC721Mint(minter, collection, randomWords);
        } else {
            _resolveERC1155Mint(minter, collection, randomWords);
        }
    }

    /// @notice ensures a value is within the BASIS range
    /// @param value value to normalize
    /// @return normalizedValue value after normalization
    function _normalizeValue(
        uint128 value,
        uint128 basis
    ) private pure returns (uint128 normalizedValue) {
        normalizedValue = value % basis;
    }

    /// @notice requests random values from Chainlink VRF
    /// @param minter address calling this function
    /// @param collection address of collection to attempt mint for
    /// @param numWords amount of random values to request
    function _requestRandomWords(
        address minter,
        address collection,
        uint32 numWords
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 requestId = VRFCoordinatorV2Interface(VRF).requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            MIN_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            numWords
        );

        l.requestMinter[requestId] = minter;
        l.requestCollection[requestId] = collection;
    }

    /// @notice resolves the outcome of an attempted mint of an ERC1155 collection
    /// @param minter address of mitner
    /// @param collection address of collection which token may be minted from
    /// @param randomWords random values relating to attempt
    function _resolveERC1155Mint(
        address minter,
        address collection,
        uint256[] memory randomWords
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint128[2] memory randomValues = _chunk256to128(randomWords[0]);

        bool result = _averageCollectionRisk(collection) >
            _normalizeValue(uint128(randomValues[0]), BASIS);

        //TODO: update based on consolation spec
        if (!result) {
            _mint(minter, l.id);
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

            _updateDepositorEarnings(oldOwner, collection);
            _updateDepositorEarnings(minter, collection);

            _assignEscrowedERC1155Asset(oldOwner, minter, collection, tokenId);
        }

        emit ERC1155MintResolved(collection, result);
    }

    /// @notice resolves the outcome of an attempted mint of an ERC721 collection
    /// @param minter address of minter
    /// @param collection address of collection which token may be minted from
    /// @param randomWords random values relating to attempt
    function _resolveERC721Mint(
        address minter,
        address collection,
        uint256[] memory randomWords
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint128[2] memory randomValues = _chunk256to128(randomWords[0]);

        bool result = _averageCollectionRisk(collection) >
            _normalizeValue(uint128(randomValues[0]), BASIS);

        //TODO: update based on consolation spec
        if (!result) {
            _mint(minter, l.id);
            ++l.id;
        }

        if (result) {
            uint256 tokenId = _selectToken(collection, randomValues[1]);

            address oldOwner = l.escrowedERC721Owner[collection][tokenId];

            _updateDepositorEarnings(oldOwner, collection);
            _updateDepositorEarnings(minter, collection);

            --l.activeTokens[oldOwner][collection];
            ++l.inactiveTokens[minter][collection];

            l.activeTokenIds[collection].remove(tokenId);
            l.escrowedERC721Owner[collection][tokenId] = minter;
        }

        emit ERC721MintResolved(collection, result);
    }

    /// @notice selects the account which will have an ERC1155 reassigned to the successful minter
    /// @param collection address of ERC1155 collection
    /// @param tokenId id of token
    /// @param randomValue random value used for selection
    /// @return owner address of selected account
    function _selectERC1155Owner(
        address collection,
        uint256 tokenId,
        uint64 randomValue
    ) private view returns (address owner) {
        Storage.Layout storage l = Storage.layout();

        EnumerableSet.AddressSet storage owners = l.activeERC1155Owners[
            collection
        ][tokenId];

        uint256 cumulativeRisk;
        uint256 tokenIndex;
        uint256 normalizedValue = randomValue %
            l.tokenRisk[collection][tokenId];

        /// @dev identifies the owner index at which the the cumulative risk is less than
        /// the normalized value, in order to select the owner at the index
        do {
            owner = owners.at(tokenIndex);
            cumulativeRisk +=
                l.depositorTokenRisk[owner][collection][tokenId] *
                l.activeERC1155Tokens[owner][collection][tokenId];
            ++tokenIndex;
        } while (cumulativeRisk <= normalizedValue);
    }

    /// @notice selects the token which was won after a successfull mint attempt
    /// @param collection address of collection
    /// @param randomValue seed used to select the tokenId
    /// @return tokenId id of won token
    function _selectToken(
        address collection,
        uint128 randomValue
    ) private view returns (uint256 tokenId) {
        Storage.Layout storage l = Storage.layout();

        EnumerableSet.UintSet storage tokenIds = l.activeTokenIds[collection];

        uint256 tokenIndex;
        uint256 cumulativeRisk;
        uint256 normalizedValue = randomValue % l.totalRisk[collection];

        /// @dev identifies the token index at which the the cumulative risk is less than
        /// the normalized value, in order to select the tokenId at the index
        do {
            tokenId = tokenIds.at(tokenIndex);
            cumulativeRisk += l.tokenRisk[collection][tokenId];
            ++tokenIndex;
        } while (cumulativeRisk <= normalizedValue);
    }

    /// @notice updates the earnings of a depositor  based on current conitions
    /// @param collection address of collection earnings relate to
    /// @param depositor address of depositor
    function _updateDepositorEarnings(
        address depositor,
        address collection
    ) private {
        Storage.Layout storage l = Storage.layout();

        uint256 totalDepositorRisk = l.totalDepositorRisk[depositor][
            collection
        ];

        if (totalDepositorRisk != 0) {
            l.depositorEarnings[depositor][collection] +=
                ((l.collectionEarnings[collection] * totalDepositorRisk) /
                    l.totalRisk[collection]) -
                l.depositorDeductions[depositor][collection];

            l.depositorDeductions[depositor][collection] = l.depositorEarnings[
                depositor
            ][collection];
        } else {
            l.depositorDeductions[depositor][collection] = l.collectionEarnings[
                collection
            ];
        }
    }
}
