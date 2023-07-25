// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { Ownable } from "@solidstate/contracts/access/ownable/Ownable.sol";

import { IPerpetualMint } from "./IPerpetualMint.sol";
import { PerpetualMintInternal } from "./PerpetualMintInternal.sol";

/// @title PerpetualMint facet contract
/// @dev contains all externally called functions
contract PerpetualMint is IPerpetualMint, PerpetualMintInternal, Ownable {
    constructor(
        bytes32 keyHash,
        address vrf,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint16 minConfirmations
    )
        PerpetualMintInternal(
            keyHash,
            vrf,
            subscriptionId,
            callbackGasLimit,
            minConfirmations
        )
    {}

    /// @inheritdoc IPerpetualMint
    function allAvailableEarnings()
        external
        view
        returns (uint256 allEarnings)
    {
        allEarnings = _allAvailableEarnings(msg.sender);
    }

    /// @inheritdoc IPerpetualMint
    function attemptMint(address collection) external {
        _attemptMint(msg.sender, collection);
    }

    /// @inheritdoc IPerpetualMint
    function availableEarnings(
        address collection
    ) external view returns (uint256 earnings) {
        earnings = _availableEarnings(msg.sender, collection);
    }

    /// @inheritdoc IPerpetualMint
    function averageCollectionRisk(
        address collection
    ) external view returns (uint128 risk) {
        risk = _averageCollectionRisk(collection);
    }

    /// @inheritdoc IPerpetualMint
    function claimAllEarnings() external {
        _claimAllEarnings(msg.sender);
    }

    /// @inheritdoc IPerpetualMint
    function claimEarnings(address collection) external {
        _claimEarnings(msg.sender, collection);
    }

    /// @inheritdoc IPerpetualMint
    function escrowedERC721TokenOwner(
        address collection,
        uint256 tokenId
    ) external view returns (address owner) {
        owner = _escrowedERC721TokenOwner(collection, tokenId);
    }

    /// @inheritdoc IPerpetualMint
    function idleToken(
        address depositor,
        address collection,
        uint256 tokenId
    ) external {
        _idleToken(depositor, collection, tokenId);
    }

    /// @inheritdoc IPerpetualMint
    function setCollectionMintPrice(
        address collection,
        uint256 price
    ) external onlyOwner {
        _setCollectionMintPrice(collection, price);
    }

    /// @inheritdoc IPerpetualMint
    function updateTokenRisk(
        address collection,
        uint256 tokenId,
        uint64 risk
    ) external {
        _updateTokenRisk(msg.sender, collection, tokenId, risk);
    }

    /// @notice Chainlink VRF Coordinator callback
    /// @param requestId id of request for random values
    /// @param randomWords random values returned from Chainlink VRF coordination
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        _fulfillRandomWords(requestId, randomWords);
    }
}
