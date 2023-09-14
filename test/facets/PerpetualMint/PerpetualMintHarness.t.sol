// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { IPerpetualMintHarness } from "./IPerpetualMintHarness.sol";
import { VRFConsumerBaseV2Mock } from "../../mocks/VRFConsumerBaseV2Mock.sol";
import { PerpetualMint } from "../../../contracts/facets/PerpetualMint/PerpetualMint.sol";
import { CollectionData, RequestData, PerpetualMintStorage as Storage, TiersData, VRFConfig } from "../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMintHarness
/// @dev exposes internal PerpetualMint internal functions for testing
contract PerpetualMintHarness is
    IPerpetualMintHarness,
    PerpetualMint,
    VRFConsumerBaseV2Mock
{
    using EnumerableSet for EnumerableSet.UintSet;

    constructor(address vrf, address mintToken) PerpetualMint(vrf, mintToken) {}

    /// @inheritdoc IPerpetualMintHarness
    function exposed_balanceOf(
        address account,
        uint256 tokenId
    ) external view returns (uint256 balance) {
        balance = _balanceOf(account, tokenId);
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_enforceBasis(uint32 risk) external pure {
        _enforceBasis(risk);
    }

    function exposed_enforceNoPendingMints(address collection) external view {
        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        _enforceNoPendingMints(collectionData);
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_normalizeValue(
        uint256 value,
        uint32 basis
    ) external pure returns (uint256 normalizedValue) {
        normalizedValue = _normalizeValue(value, basis);
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_pendingRequestsAdd(
        address collection,
        uint256 requestId
    ) external {
        Storage.layout().collections[collection].pendingRequests.add(requestId);
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_pendingRequestsAt(
        address collection,
        uint256 index
    ) external view returns (uint256 requestId) {
        requestId = Storage.layout().collections[collection].pendingRequests.at(
            index
        );
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_pendingRequestsLength(
        address collection
    ) external view returns (uint256 length) {
        length = Storage
            .layout()
            .collections[collection]
            .pendingRequests
            .length();
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_requestRandomWords(
        address minter,
        address collection,
        uint32 numWords
    ) external {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        _requestRandomWords(l, collectionData, minter, collection, numWords);
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_requests(
        uint256 requestId
    ) external view returns (address minter, address collection) {
        RequestData storage request = Storage.layout().requests[requestId];

        (minter, collection) = (request.minter, request.collection);
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_resolveMints(
        address minter,
        address collection,
        uint256[] memory randomWords
    ) external {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        TiersData memory tiersData = l.tiers;

        _resolveMints(
            l.mintToken,
            collectionData,
            tiersData,
            minter,
            collection,
            randomWords
        );
    }

    /// @inheritdoc IPerpetualMintHarness
    function mintReceipts(address collection, uint256 receiptAmount) external {
        _safeMint(
            msg.sender,
            uint256(bytes32(abi.encode(collection))),
            receiptAmount,
            ""
        );
    }

    /// @inheritdoc IPerpetualMintHarness
    function setConsolationFees(uint256 amount) external {
        Storage.layout().consolationFees = amount;
    }

    /// @inheritdoc IPerpetualMintHarness
    function setMintEarnings(uint256 amount) external {
        Storage.layout().mintEarnings = amount;
    }

    /// @inheritdoc IPerpetualMintHarness
    function setProtocolFees(uint256 amount) external {
        Storage.layout().protocolFees = amount;
    }

    /// @inheritdoc IPerpetualMintHarness
    function setRequests(
        uint256 requestId,
        address minter,
        address collection
    ) external {
        Storage.layout().requests[requestId] = RequestData({
            minter: minter,
            collection: collection
        });
    }
}
