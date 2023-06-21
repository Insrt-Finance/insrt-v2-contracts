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

    /**
     * @notice thrown when an incorrent amount of ETH is received
     */
    error IncorrectETHReceived();

    /**
     * @notice emitted when the outcome of an attempted mint is resolved
     * @param collection address of collection that attempted mint is for
     * @param result success status of mint attempt
     */
    event OutcomeResolved(address collection, bool result);

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

        _resolveOutcome(
            l.requestUser[requestId],
            l.requestCollection[requestId],
            randomWords
        );
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

        s.layout().requestUser[requestId] = account;
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
        l.totalCollectionEarnings[collection] += msg.value - mintFee;

        _requestRandomWords(account, 1);
    }

    /**
     * @notice selects the ERC721 token which was won after a successfull mint attempt
     * @param collection address of collection
     * @param randomValue seed used to select the tokenId
     */
    function _selectERC721Token(
        address collection,
        uint32 randomValue
    ) internal view returns (uint256 tokenId) {
        s.Layout storage l = s.layout();

        uint256 tokenIndex;
        uint256 cumulativeRisk;

        do {
            cumulativeRisk += l.tokenRisks[collection][
                l.escrowedERC721TokenIds[collection].at(tokenIndex)
            ];
            ++tokenIndex;
        } while (cumulativeRisk <= randomValue);

        tokenId = l.escrowedERC721TokenIds[collection].at(tokenIndex - 1);
    }

    /**
     * @notice calculations the weighted collection-wide risk of an ERC721 collection
     * @param collection address of collection
     * @return risk value of collection-wide risk
     */
    function _collectionRiskERC721(
        address collection
    ) internal view returns (uint256 risk) {
        s.Layout storage l = s.layout();
        risk =
            l.totalCollectionRisk[collection] /
            l.escrowedERC721TokenIds[collection].length();
    }

    /**
     * @notice resolves the outcome of an attempted mint
     * @param account address attempting the mint
     * @param collection address of collection which token may be minted from
     * @param randomWords random values relating to attempt
     */
    function _resolveOutcome(
        address account,
        address collection,
        uint256[] memory randomWords
    ) private {
        s.Layout storage l = s.layout();

        //can chunk x2 instead for optimal efficiency - need clarity on game mechanism
        bytes4[8] memory randomValues = _chunkBytes32(bytes32(randomWords[0]));

        bool isERC721 = l.collectionType[collection];
        bool result;

        if (isERC721) {
            result =
                _collectionRiskERC721(collection) >
                _normalizeValue(uint32(randomValues[0]));
        }

        if (!result) {
            _mint(account, l.id);
            ++l.id;
        }

        //accounts only for ERC721 tokens
        //TODO: add ERC1155 support
        if (result && isERC721) {
            uint256 wonTokenId = _selectERC721Token(
                collection,
                uint32(randomValues[1])
            );
            address previousOwner = l.escrowedERC721TokenOwner[collection][
                wonTokenId
            ];

            _updateAccountEarnings(collection, previousOwner);

            --l.accountEscrowedERC721TokenAmount[previousOwner][collection];
            ++l.accountEscrowedERC721TokenAmount[account][collection];

            l.escrowedERC721TokenOwner[collection][wonTokenId] = account;
        }

        emit OutcomeResolved(collection, result);
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

        l.collectionUserEarnings[collection][account] +=
            (l.totalCollectionEarnings[collection] *
                l.accountEscrowedERC721TokenAmount[account][collection]) /
            l.escrowedERC721TokenIds[collection].length() -
            l.collectionUserDeductions[collection][account];

        l.collectionUserDeductions[collection][account] = l
            .collectionUserEarnings[collection][account];
    }

    /**
     * @notice splits a bytes32 value into 8 bytes4 values
     * @param value bytes32 value
     * @return chunks array of 8 bytes4 values
     */
    function _chunkBytes32(
        bytes32 value
    ) private pure returns (bytes4[8] memory chunks) {
        unchecked {
            for (uint256 i = 0; i < 8; ++i) {
                bytes4 chunk = bytes4(value << (i * 32));
                chunks[i] = chunk;
            }
        }
    }

    /**
     * @notice ensures a value is within the BASIS range
     * @param value value to normalize
     * @return normalizedValue value after normalization
     */
    function _normalizeValue(
        uint32 value
    ) private pure returns (uint32 normalizedValue) {
        normalizedValue = value % BASIS;
    }
}
