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
        uint256 tokenRisk
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
        uint256 tokenRisk
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

    /// @notice attempts a batch mint for the minter for a single collection
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMint(
        address minter,
        address collection,
        uint32 numberOfMints
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 msgValue = msg.value;

        if (numberOfMints == 0) {
            revert InvalidNumberOfMints();
        }

        if (!l.activeCollections.contains(collection)) {
            revert CollectionNotActive();
        }

        if (msgValue != l.collectionMintPrice[collection] * numberOfMints) {
            revert IncorrectETHReceived();
        }

        uint256 mintFee = (msgValue * l.mintFeeBP) / BASIS;

        l.protocolFees += mintFee;
        l.collectionEarnings[collection] += msgValue - mintFee;

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = l.collectionType[collection] == AssetType.ERC721
            ? NUM_WORDS_ERC721_MINT * numberOfMints // 2 words per mint, current max of 250 mints per tx
            : NUM_WORDS_ERC1155_MINT * numberOfMints; // 3 words per mint, current max of 160 mints per tx

        _requestRandomWords(l, minter, collection, numWords);
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
    ) internal view returns (uint256 risk) {
        Storage.Layout storage l = Storage.layout();
        risk = l.totalRisk[collection] / l.totalActiveTokens[collection];
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
    function _enforceBasis(uint256 value) internal pure {
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
    function _enforceNonZeroRisk(uint256 risk) internal pure {
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

            uint256 activeTokens = l.activeERC1155Tokens[depositor][collection][
                tokenId
            ];

            uint256 riskChange = amount *
                l.depositorTokenRisk[depositor][collection][tokenId];
            l.totalRisk[collection] -= riskChange;
            l.totalActiveTokens[collection] -= amount;
            l.totalDepositorRisk[depositor][collection] -= riskChange;
            l.activeERC1155Tokens[depositor][collection][tokenId] -= amount;
            l.inactiveERC1155Tokens[depositor][collection][tokenId] += amount;

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

            uint256 oldRisk = l.tokenRisk[collection][tokenId];

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
        uint256 value,
        uint256 basis
    ) internal pure returns (uint256 normalizedValue) {
        normalizedValue = value % basis;
    }

    /// @notice Reactivates a set of idled ERC1155 tokens by setting their risks to the provided values
    /// @param depositor address of depositor
    /// @param collection address of ERC1155 collection
    /// @param risks an array of new risks for each token
    /// @param tokenIds an array of token ids to reactivate
    /// @param amounts an array of token amounts to reactivate
    function _reactivateERC1155Assets(
        address depositor,
        address collection,
        uint256[] calldata risks,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 tokenIdsLength = tokenIds.length;

        // ensure tokenIds, risks, and amounts arrays are the same length
        if (
            tokenIdsLength != risks.length || tokenIdsLength != amounts.length
        ) {
            revert ArrayLengthMismatch();
        }

        // ensure collection is ERC1155
        if (l.collectionType[collection] != AssetType.ERC1155) {
            revert CollectionTypeMismatch();
        }

        // update the depositor's collection earnings
        _updateDepositorEarnings(depositor, collection);

        // iterate over the token ids
        for (uint256 i; i < tokenIdsLength; ++i) {
            _reactivateSingleERC1155Asset(
                l,
                depositor,
                collection,
                tokenIds[i],
                amounts[i],
                risks[i]
            );
        }

        // add the collection to the set of active collections
        l.activeCollections.add(collection);

        emit ERC1155AssetsReactivated(
            depositor,
            collection,
            risks,
            tokenIds,
            amounts
        );
    }

    /// @notice Reactivates a single idled ERC1155 token by setting its risk to the provided value
    /// @param l the PerpetualMint storage layout
    /// @param depositor address of depositor
    /// @param collection address of ERC1155 collection
    /// @param tokenId token id to reactivate
    /// @param amount token amount to reactivate
    /// @param risk new risk value for the token
    function _reactivateSingleERC1155Asset(
        Storage.Layout storage l,
        address depositor,
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint256 risk
    ) internal {
        // If the sender does not have any ERC1155 tokens of the specified ID available to reactivate, revert the transaction
        if (l.inactiveERC1155Tokens[msg.sender][collection][tokenId] == 0) {
            revert OnlyEscrowedTokenOwner();
        }

        // ensure the new risk is within the BASIS range
        _enforceBasis(risk);

        // ensure the new risk is greater than zero
        _enforceNonZeroRisk(risk);

        // get the old risk value for the token
        uint256 oldRisk = l.depositorTokenRisk[depositor][collection][tokenId];

        uint256 riskChange;

        // If the new risk is greater than the old risk, calculate the change in risk and
        // update the token risk, total depositor risk, and total risk
        if (risk > oldRisk) {
            riskChange =
                (risk - oldRisk) *
                l.activeERC1155Tokens[depositor][collection][tokenId] +
                risk *
                amount;

            l.tokenRisk[collection][tokenId] += riskChange;

            l.totalDepositorRisk[depositor][collection] += riskChange;

            l.totalRisk[collection] += riskChange;
        } else {
            // Otherwise, calculate the change in active and inactive token risks
            // and adjust the token risk, total depositor risk, and total risk accordingly
            uint256 activeTokenRiskChange = (oldRisk - risk) *
                l.activeERC1155Tokens[depositor][collection][tokenId];

            uint256 inactiveTokenRiskChange = risk * amount;

            if (activeTokenRiskChange > inactiveTokenRiskChange) {
                riskChange = activeTokenRiskChange - inactiveTokenRiskChange;

                l.tokenRisk[collection][tokenId] -= riskChange;

                l.totalDepositorRisk[depositor][collection] -= riskChange;

                l.totalRisk[collection] -= riskChange;
            } else {
                riskChange = inactiveTokenRiskChange - activeTokenRiskChange;

                l.tokenRisk[collection][tokenId] += riskChange;

                l.totalDepositorRisk[depositor][collection] += riskChange;

                l.totalRisk[collection] += riskChange;
            }
        }

        // add the depositor to the set of active owners for the token ID in the collection
        l.activeERC1155Owners[collection][tokenId].add(depositor);

        // update the amount of active ERC1155 tokens for the depositor and the token ID in the collection
        l.activeERC1155Tokens[depositor][collection][tokenId] += amount;

        // add the token ID to the set of active token IDs in the collection
        l.activeTokenIds[collection].add(tokenId);

        // set the new risk for the depositor and the token ID in the collection
        // currently for ERC1155 tokens, the risk is always the same for all token IDs in the collection
        l.depositorTokenRisk[depositor][collection][tokenId] = risk;

        // subtract the amount of inactive ERC1155 tokens for the depositor and the token ID in the collection
        l.inactiveERC1155Tokens[depositor][collection][tokenId] -= amount;

        // update the total number of active tokens in the collection
        l.totalActiveTokens[collection] += amount;
    }

    /// @notice Reactivates a set of idled ERC721 tokens by setting their risks to the provided values
    /// @param depositor address of depositor
    /// @param collection address of ERC721 collection
    /// @param risks an array of new risks for each token
    /// @param tokenIds an array of token ids
    function _reactivateERC721Assets(
        address depositor,
        address collection,
        uint256[] calldata risks,
        uint256[] calldata tokenIds
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 numberOfTokens = tokenIds.length;

        // ensure tokenIds and risks arrays are the same length
        if (numberOfTokens != risks.length) {
            revert ArrayLengthMismatch();
        }

        // ensure collection is ERC721
        if (l.collectionType[collection] != AssetType.ERC721) {
            revert CollectionTypeMismatch();
        }

        // update the depositor's collection earnings
        _updateDepositorEarnings(depositor, collection);

        // iterate over the token ids
        for (uint256 i; i < numberOfTokens; ++i) {
            // ensure the depositor owns the token
            _enforceERC721Ownership(l, depositor, collection, tokenIds[i]);

            // ensure the new risk is within the BASIS range
            _enforceBasis(risks[i]);

            // ensure the new risk is non-zero
            _enforceNonZeroRisk(risks[i]);

            // ensure the specified token is not currently active
            if (l.tokenRisk[collection][tokenIds[i]] != 0) {
                revert TokenAlreadyActive();
            }

            // set the new token risk
            l.tokenRisk[collection][tokenIds[i]] = risks[i];

            // update the global collection risk
            l.totalRisk[collection] += risks[i];

            // add the token to the active token list
            l.activeTokenIds[collection].add(tokenIds[i]);

            // update the depositor's total risk for the collection
            l.totalDepositorRisk[depositor][collection] += risks[i];
        }

        // update the global active token count for the collection
        l.totalActiveTokens[collection] += numberOfTokens;

        // update the depositor's active token count for the collection
        l.activeTokens[depositor][collection] += numberOfTokens;

        // update the depositor's inactive token count for the collection
        l.inactiveTokens[depositor][collection] -= numberOfTokens;

        emit ERC721AssetsReactivated(depositor, collection, risks, tokenIds);
    }

    /// @notice requests random values from Chainlink VRF
    /// @param l the PerpetualMint storage layout
    /// @param minter address calling this function
    /// @param collection address of collection to attempt mint for
    /// @param numWords amount of random values to request
    function _requestRandomWords(
        Storage.Layout storage l,
        address minter,
        address collection,
        uint32 numWords
    ) internal {
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

        bool result = _averageCollectionRisk(collection) >
            _normalizeValue(randomWords[0], BASIS);

        //TODO: update based on consolation spec
        if (!result) {
            _mint(minter, l.id);
            ++l.id;
        }

        if (result) {
            uint256 tokenId = _selectToken(collection, randomWords[1]);

            address oldOwner = _selectERC1155Owner(
                collection,
                tokenId,
                randomWords[2]
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

        bool result = _averageCollectionRisk(collection) >
            _normalizeValue(randomWords[0], BASIS);

        //TODO: update based on consolation spec
        if (!result) {
            _mint(minter, l.id);
            ++l.id;
        }

        if (result) {
            uint256 tokenId = _selectToken(collection, randomWords[1]);

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
        uint256 randomValue
    ) internal view returns (address owner) {
        Storage.Layout storage l = Storage.layout();

        EnumerableSet.AddressSet storage owners = l.activeERC1155Owners[
            collection
        ][tokenId];

        uint256 tokenIndex;
        uint256 cumulativeRisk;
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
        } while (cumulativeRisk < normalizedValue);
    }

    /// @notice selects the token which was won after a successfull mint attempt
    /// @param collection address of collection
    /// @param randomValue seed used to select the tokenId
    /// @return tokenId id of won token
    function _selectToken(
        address collection,
        uint256 randomValue
    ) internal view returns (uint256 tokenId) {
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

    /// @notice sets the mint fee in basis points
    /// @param mintFeeBP mint fee in basis points
    function _setMintFeeBP(uint32 mintFeeBP) internal {
        Storage.layout().mintFeeBP = mintFeeBP;
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
        uint256[] calldata risks
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
                amounts[i],
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
        uint256[] calldata risks
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
            uint256 risk = risks[i];

            _enforceBasis(risk);
            _enforceNonZeroRisk(risk);

            if (depositor != l.escrowedERC721Owner[collection][tokenIds[i]]) {
                revert OnlyEscrowedTokenOwner();
            }

            uint256 oldRisk = l.tokenRisk[collection][tokenId];

            l.tokenRisk[collection][tokenId] = risk;
            uint256 riskChange;

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
        uint256 amount,
        uint256 risk
    ) internal {
        Storage.Layout storage l = Storage.layout();

        _enforceBasis(risk);
        _enforceNonZeroRisk(risk);
        _enforceERC1155Ownership(l, depositor, collection, tokenId);

        uint256 oldRisk = l.depositorTokenRisk[depositor][collection][tokenId];
        uint256 riskChange;

        if (risk > oldRisk) {
            riskChange =
                (risk - oldRisk) *
                l.activeERC1155Tokens[depositor][collection][tokenId] +
                risk *
                amount;
            l.totalDepositorRisk[depositor][collection] += riskChange;
            l.tokenRisk[collection][tokenId] += riskChange;
        } else {
            uint256 activeTokenRiskChange = (oldRisk - risk) *
                l.activeERC1155Tokens[depositor][collection][tokenId];
            uint256 inactiveTokenRiskChange = risk * amount;

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
