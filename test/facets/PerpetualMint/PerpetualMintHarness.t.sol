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

    constructor(address vrf) PerpetualMint(vrf) {}

    /// @inheritdoc IPerpetualMintHarness
    function exposed_balanceOf(
        address account,
        uint256 tokenId
    ) external view returns (uint256 balance) {
        balance = _balanceOf(account, tokenId);
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_basis() external pure returns (uint32 basis) {
        basis = BASIS;
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
        uint32 numWords,
        bool paidInEth
    ) external {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        _requestRandomWords(
            l,
            collectionData,
            minter,
            collection,
            numWords,
            paidInEth
        );
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_requests(
        uint256 requestId
    )
        external
        view
        returns (address minter, address collection, bool paidInEth)
    {
        RequestData storage request = Storage.layout().requests[requestId];

        (minter, collection, paidInEth) = (
            request.minter,
            request.collection,
            request.paidInEth
        );
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_resolveMints(
        address minter,
        address collection,
        uint256[] memory randomWords,
        bool paidInEth
    ) external {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        TiersData memory tiersData = l.tiers;

        _resolveMints(
            collectionData,
            tiersData,
            minter,
            collection,
            randomWords,
            paidInEth
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
        address collection,
        bool paidInEth
    ) external {
        Storage.layout().requests[requestId] = RequestData({
            minter: minter,
            collection: collection,
            paidInEth: paidInEth
        });
    }
}
