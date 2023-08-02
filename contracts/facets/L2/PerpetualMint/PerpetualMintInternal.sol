// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { VRFCoordinatorV2Interface } from "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { ERC721BaseInternal } from "@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";

import { IPerpetualMintInternal } from "./IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "./Storage.sol";
import { AssetType } from "../../../enums/AssetType.sol";

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

    /// @dev random words to be requested from ChainlinkVRF for each mint attempt
    /// depending on asset type attemping to be minted
    uint32 internal constant NUM_WORDS_ERC721_MINT = 2;
    uint32 internal constant NUM_WORDS_ERC1155_MINT = 3;

    /// @dev address of Chainlink VRFCoordinatorV2 contract
    address private immutable VRF;

    constructor(address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
        VRF = vrfCoordinator;
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
    /// @param tokenRisk risk of token set by from address prior to transfer
    function _assignEscrowedERC1155Asset(
        address from,
        address to,
        address collection,
        uint256 tokenId,
        uint64 tokenRisk
    ) internal {
        Storage.Layout storage l = Storage.layout();

        _updateDepositorEarnings(from, collection);
        _updateDepositorEarnings(to, collection);

        --l.activeERC1155Tokens[from][collection][tokenId];
        ++l.inactiveERC1155Tokens[to][collection][tokenId];
        --l.totalActiveTokens[collection];
        l.totalRisk[collection] -= tokenRisk;
        l.tokenRisk[collection][tokenId] -= tokenRisk;
        l.totalDepositorRisk[from][collection] -= tokenRisk;

        if (l.activeERC1155Tokens[from][collection][tokenId] == 0) {
            l.activeERC1155Owners[collection][tokenId].remove(from);
            l.depositorTokenRisk[from][collection][tokenId] = 0;
        }

        if (l.tokenRisk[collection][tokenId] == 0) {
            l.activeTokenIds[collection].remove(tokenId);
        }
    }

    /// @notice assigns an ERC721 asset from one account to another, updating the required
    /// state variables simultaneously
    /// @param from address asset currently is escrowed for
    /// @param to address that asset will be assigned to
    /// @param collection address of ERC721 collection
    /// @param tokenId token id
    /// @param tokenRisk risk of token set by from address prior to transfer
    function _assignEscrowedERC721Asset(
        address from,
        address to,
        address collection,
        uint256 tokenId,
        uint64 tokenRisk
    ) internal {
        Storage.Layout storage l = Storage.layout();

        _updateDepositorEarnings(from, collection);
        _updateDepositorEarnings(to, collection);

        --l.activeTokens[from][collection];
        ++l.inactiveTokens[to][collection];

        l.activeTokenIds[collection].remove(tokenId);
        l.escrowedERC721Owner[collection][tokenId] = to;
        l.totalRisk[collection] -= tokenRisk;
        l.totalDepositorRisk[from][collection] -= tokenRisk;
        --l.totalActiveTokens[collection];
        l.tokenRisk[collection][tokenId] = 0;
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

        uint32 numWords = l.collectionType[collection] == AssetType.ERC721
            ? NUM_WORDS_ERC721_MINT
            : NUM_WORDS_ERC1155_MINT;

        _requestRandomWords(minter, collection, numWords);
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
    ) internal pure returns (uint64[2] memory chunks) {
        unchecked {
            for (uint64 i = 0; i < 2; ++i) {
                chunks[i] = uint64(value >> (i * 64));
            }
        }
    }

    /// @notice splits a uint256 value into 2 uint128 values
    /// @param value uint256 value
    /// @return chunks array of 2 uint128 values
    function _chunk256to128(
        uint256 value
    ) internal pure returns (uint128[2] memory chunks) {
        unchecked {
            for (uint256 i = 0; i < 2; ++i) {
                chunks[i] = uint128(value >> (i * 128));
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

        //TODO: should set to depositorDeductions and not to 0
        l.depositorEarnings[depositor][collection] = 0;
        payable(depositor).sendValue(earnings);
    }

    /// @notice enforces that a value does not exceed the BASIS
    /// @param value value to check
    function _enforceBasis(uint64 value) internal pure {
        if (value > BASIS) {
            revert BasisExceeded();
        }
    }

    /// @notice enforces that a depositor is an owner of a tokenId in an ERC1155 collection
    /// @param l storage struct for PerpetualMint
    /// @param depositor address of depositor
    /// @param collection address of ERC1155 collection
    /// @param tokenId id of token
    /// will be deprecated upon PR consolidation
    function _enforceERC1155Ownership(
        Storage.Layout storage l,
        address depositor,
        address collection,
        uint256 tokenId
    ) internal view {
        if (
            l.inactiveERC1155Tokens[depositor][collection][tokenId] +
                l.activeERC1155Tokens[depositor][collection][tokenId] ==
            0
        ) {
            revert OnlyEscrowedTokenOwner();
        }
    }

    /// @notice enforces that a depositor is the owner of an ERC721 token
    /// @param l storage struct for PerpetualMint
    /// @param depositor address of depositor
    /// @param collection address of ERC721 collection
    /// @param tokenId id of token
    function _enforceERC721Ownership(
        Storage.Layout storage l,
        address depositor,
        address collection,
        uint256 tokenId
    ) internal view {
        if (depositor != l.escrowedERC721Owner[collection][tokenId]) {
            revert OnlyEscrowedTokenOwner();
        }
    }

    /// @notice enforces that a risk value is non-zero
    /// @param risk value to check
    function _enforceNonZeroRisk(uint64 risk) internal pure {
        if (risk == 0) {
            revert TokenRiskMustBeNonZero();
        }
    }

    /// @notice enforces that two uint256 arrays have the same length
    /// @param firstArr first array
    /// @param secondArr second array
    function _enforceUint256ArrayLengthMatch(
        uint256[] calldata firstArr,
        uint256[] calldata secondArr
    ) internal pure {
        if (firstArr.length != secondArr.length) {
            revert ArrayLengthMismatch();
        }
    }

    /// @notice returns owner of escrowed ERC721 token
    /// @param collection address of collection
    /// @param tokenId id of token
    /// @return owner address of token owner
    function _escrowedERC721TokenOwner(
        address collection,
        uint256 tokenId
    ) internal view returns (address owner) {
        owner = Storage.layout().escrowedERC721Owner[collection][tokenId];
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

        if (l.collectionType[collection] == AssetType.ERC721) {
            _resolveERC721Mint(minter, collection, randomWords);
        } else {
            _resolveERC1155Mint(minter, collection, randomWords);
        }
    }

    /// @notice sets the token risk of a set of ERC1155 tokens to zero thereby making them idle - still escrowed
    /// by the PerpetualMint contracts but not actively accruing earnings nor incurring risk from mint attempts
    /// @param depositor address of depositor of token
    /// @param collection address of ERC1155 collection
    /// @param tokenIds ids of token of collection
    /// @param amounts amount of each tokenId to idle
    function _idleERC1155Tokens(
        address depositor,
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal {
        Storage.Layout storage l = Storage.layout();

        _updateDepositorEarnings(depositor, collection);

        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            _enforceERC1155Ownership(l, depositor, collection, tokenId);

            uint64 activeTokens = l.activeERC1155Tokens[depositor][collection][
                tokenId
            ];

            uint64 riskChange = uint64(amount) *
                l.depositorTokenRisk[depositor][collection][tokenId];
            l.totalRisk[collection] -= riskChange;
            l.totalActiveTokens[collection] -= amount;
            l.totalDepositorRisk[depositor][collection] -= riskChange;
            l.activeERC1155Tokens[depositor][collection][tokenId] -= uint64(
                amount
            );
            l.inactiveERC1155Tokens[depositor][collection][tokenId] += uint64(
                amount
            );

            if (amount == activeTokens) {
                l.depositorTokenRisk[depositor][collection][tokenId] = 0;
                l.activeERC1155Owners[collection][tokenId].remove(depositor);
            }
        }
    }

    /// @notice sets the token risk of a set of ERC721 tokens to zero thereby making them idle - still escrowed
    /// by the PerpetualMint contracts but not actively accruing earnings nor incurring risk from mint attemps
    /// @param depositor address of depositor of token
    /// @param collection address of ERC721 collection
    /// @param tokenIds ids of token of collection
    function _idleERC721Tokens(
        address depositor,
        address collection,
        uint256[] calldata tokenIds
    ) internal {
        Storage.Layout storage l = Storage.layout();

        _updateDepositorEarnings(depositor, collection);

        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            _enforceERC721Ownership(l, depositor, collection, tokenId);

            uint64 oldRisk = l.tokenRisk[collection][tokenId];

            l.totalRisk[collection] -= oldRisk;
            l.activeTokenIds[collection].remove(tokenId);
            --l.totalActiveTokens[collection];
            --l.activeTokens[depositor][collection];
            ++l.inactiveTokens[depositor][collection];
            l.totalDepositorRisk[depositor][collection] -= oldRisk;
            l.tokenRisk[collection][tokenId] = 0;
        }
    }

    /// @notice ensures a value is within the BASIS range
    /// @param value value to normalize
    /// @return normalizedValue value after normalization
    function _normalizeValue(
        uint128 value,
        uint128 basis
    ) internal pure returns (uint128 normalizedValue) {
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
            l.vrfConfig.keyHash,
            l.vrfConfig.subscriptionId,
            l.vrfConfig.minConfirmations,
            l.vrfConfig.callbackGasLimit,
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

            _assignEscrowedERC1155Asset(
                oldOwner,
                minter,
                collection,
                tokenId,
                l.depositorTokenRisk[oldOwner][collection][tokenId]
            );
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
            _normalizeValue(randomValues[0], BASIS);

        //TODO: update based on consolation spec
        if (!result) {
            _mint(minter, l.id);
            ++l.id;
        }

        if (result) {
            uint256 tokenId = _selectToken(collection, randomValues[1]);

            _assignEscrowedERC721Asset(
                l.escrowedERC721Owner[collection][tokenId],
                minter,
                collection,
                tokenId,
                l.tokenRisk[collection][tokenId]
            );
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
    ) internal view returns (address owner) {
        Storage.Layout storage l = Storage.layout();

        EnumerableSet.AddressSet storage owners = l.activeERC1155Owners[
            collection
        ][tokenId];

        uint256 tokenIndex;
        uint64 cumulativeRisk;
        uint64 normalizedValue = randomValue % l.tokenRisk[collection][tokenId];

        /// @dev identifies the owner index at which the the cumulative risk is less than
        /// the normalized value, in order to select the owner at the index
        do {
            owner = owners.at(tokenIndex);
            cumulativeRisk +=
                l.depositorTokenRisk[owner][collection][tokenId] *
                l.activeERC1155Tokens[owner][collection][tokenId];
            ++tokenIndex;
        } while (cumulativeRisk < normalizedValue);
    }

    /// @notice selects the token which was won after a successfull mint attempt
    /// @param collection address of collection
    /// @param randomValue seed used to select the tokenId
    /// @return tokenId id of won token
    function _selectToken(
        address collection,
        uint128 randomValue
    ) internal view returns (uint256 tokenId) {
        Storage.Layout storage l = Storage.layout();

        EnumerableSet.UintSet storage tokenIds = l.activeTokenIds[collection];

        uint256 tokenIndex;
        uint64 cumulativeRisk;
        uint64 normalizedValue = uint64(randomValue % l.totalRisk[collection]);

        /// @dev identifies the token index at which the the cumulative risk is less than
        /// the normalized value, in order to select the tokenId at the index
        do {
            tokenId = tokenIds.at(tokenIndex);
            cumulativeRisk += l.tokenRisk[collection][tokenId];
            ++tokenIndex;
        } while (cumulativeRisk < normalizedValue);
    }

    /// @notice set the mint price for a given collection
    /// @param collection address of collection
    /// @param price mint price of the collection
    function _setCollectionMintPrice(
        address collection,
        uint256 price
    ) internal {
        Storage.layout().collectionMintPrice[collection] = price;
        emit MintPriceSet(collection, price);
    }

    /// @notice sets the Chainlink VRF config
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF
    function _setVRFConfig(Storage.VRFConfig calldata config) internal {
        Storage.layout().vrfConfig = config;
        emit VRFConfigSet(config);
    }

    /// @notice updates the earnings of a depositor  based on current conditions
    /// @param collection address of collection earnings relate to
    /// @param depositor address of depositor
    function _updateDepositorEarnings(
        address depositor,
        address collection
    ) internal {
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

    /// @notice updates the risk associated with escrowed ERC1155 tokens of a depositor
    /// @param depositor address of escrowed token owner
    /// @param collection address of token collection
    /// @param tokenIds array of token ids
    /// @param amounts amount of inactive tokens to activate for each tokenId
    /// @param risks array of new risk values for token ids
    function _updateERC1155TokenRisks(
        address depositor,
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint64[] calldata risks
    ) internal {
        Storage.Layout storage l = Storage.layout();

        if (
            tokenIds.length != amounts.length || tokenIds.length != risks.length
        ) {
            revert ArrayLengthMismatch();
        }

        if (l.collectionType[collection] != AssetType.ERC1155) {
            revert CollectionTypeMismatch();
        }

        _updateDepositorEarnings(depositor, collection);

        for (uint256 i; i < tokenIds.length; ++i) {
            _updateSingleERC1155TokenRisk(
                depositor,
                collection,
                tokenIds[i],
                uint64(amounts[i]),
                risks[i]
            );
        }
    }

    /// @notice updates the risk associated with an escrowed ERC721 tokens of a depositor
    /// @param depositor address of escrowed token owner
    /// @param collection address of token collection
    /// @param tokenIds array of token ids
    /// @param risks array of new risk values for token ids
    function _updateERC721TokenRisks(
        address depositor,
        address collection,
        uint256[] calldata tokenIds,
        uint64[] calldata risks
    ) internal {
        Storage.Layout storage l = Storage.layout();

        if (tokenIds.length != risks.length) {
            revert ArrayLengthMismatch();
        }

        if (l.collectionType[collection] != AssetType.ERC721) {
            revert CollectionTypeMismatch();
        }

        _updateDepositorEarnings(depositor, collection);

        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            uint64 risk = risks[i];

            if (risk > BASIS) {
                revert BasisExceeded();
            }

            if (risk == 0) {
                revert TokenRiskMustBeNonZero();
            }

            if (depositor != l.escrowedERC721Owner[collection][tokenIds[i]]) {
                revert OnlyEscrowedTokenOwner();
            }

            uint64 oldRisk = l.tokenRisk[collection][tokenId];

            l.tokenRisk[collection][tokenId] = risk;
            uint64 riskChange;

            if (risk > oldRisk) {
                riskChange = risk - oldRisk;
                l.totalRisk[collection] += riskChange;
                l.totalDepositorRisk[depositor][collection] += riskChange;
            } else {
                riskChange = oldRisk - risk;
                l.totalRisk[collection] -= riskChange;
                l.totalDepositorRisk[depositor][collection] -= riskChange;
            }
        }
    }

    /// @notice updates the risk for a single ERC1155 tokenId
    /// @param depositor address of escrowed token owner
    /// @param collection address of token collection
    /// @param tokenId id of token
    /// @param amount amount of inactive tokens to activate for tokenId
    /// @param risk new risk value for token id
    function _updateSingleERC1155TokenRisk(
        address depositor,
        address collection,
        uint256 tokenId,
        uint64 amount,
        uint64 risk
    ) internal {
        Storage.Layout storage l = Storage.layout();

        _enforceBasis(risk);
        _enforceNonZeroRisk(risk);
        _enforceERC1155Ownership(l, depositor, collection, tokenId);

        uint64 oldRisk = l.depositorTokenRisk[depositor][collection][tokenId];
        uint64 riskChange;

        if (risk > oldRisk) {
            riskChange =
                (risk - oldRisk) *
                l.activeERC1155Tokens[depositor][collection][tokenId] +
                risk *
                amount;
            l.totalDepositorRisk[depositor][collection] += riskChange;
            l.tokenRisk[collection][tokenId] += riskChange;
        } else {
            uint64 activeTokenRiskChange = (oldRisk - risk) *
                l.activeERC1155Tokens[depositor][collection][tokenId];
            uint64 inactiveTokenRiskChange = risk * amount;

            // determine whether overall risk increases or decreases - determined
            // from whether enough inactive tokens are activated to exceed the decrease
            // of active token risk
            // if the changes are equal, no state changes need to be made - eg when the risk
            // value is set to half of its previous amount, and the inactive tokens are equal to
            // the active tokens
            if (activeTokenRiskChange > inactiveTokenRiskChange) {
                riskChange = activeTokenRiskChange - inactiveTokenRiskChange;
                l.totalDepositorRisk[depositor][collection] -= riskChange;
                l.tokenRisk[collection][tokenId] -= riskChange;
            } else {
                riskChange = inactiveTokenRiskChange - activeTokenRiskChange;
                l.totalDepositorRisk[depositor][collection] += riskChange;
                l.tokenRisk[collection][tokenId] += riskChange;
            }
        }

        l.activeERC1155Tokens[depositor][collection][tokenId] += amount;
        l.inactiveERC1155Tokens[depositor][collection][tokenId] -= amount;
        l.depositorTokenRisk[depositor][collection][tokenId] = risk;
    }
}
