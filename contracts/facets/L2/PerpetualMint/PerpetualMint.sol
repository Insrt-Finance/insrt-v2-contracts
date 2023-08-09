// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { Ownable } from "@solidstate/contracts/access/ownable/Ownable.sol";

import { IPerpetualMint } from "./IPerpetualMint.sol";
import { PerpetualMintInternal } from "./PerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "./Storage.sol";

/// @title PerpetualMint facet contract
/// @dev contains all externally called functions
contract PerpetualMint is IPerpetualMint, PerpetualMintInternal, Ownable {
    constructor(address vrf) PerpetualMintInternal(vrf) {}

    /// @inheritdoc IPerpetualMint
    function allAvailableEarnings()
        external
        view
        returns (uint256 allEarnings)
    {
        allEarnings = _allAvailableEarnings(msg.sender);
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMint(
        address collection,
        uint32 numberOfMints
    ) external payable {
        _attemptBatchMint(msg.sender, collection, numberOfMints);
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
    ) external view returns (uint256 risk) {
        Storage.Layout storage l = Storage.layout();

        risk = _averageCollectionRisk(l, collection);
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
    function idleERC1155Tokens(
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external {
        _idleERC1155Tokens(msg.sender, collection, tokenIds, amounts);
    }

    /// @inheritdoc IPerpetualMint
    function idleERC721Tokens(
        address collection,
        uint256[] calldata tokenIds
    ) external {
        _idleERC721Tokens(msg.sender, collection, tokenIds);
    }

    /// @inheritdoc IPerpetualMint
    function reactivateERC1155Assets(
        address collection,
        uint256[] calldata risks,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external {
        _reactivateERC1155Assets(
            msg.sender,
            collection,
            risks,
            tokenIds,
            amounts
        );
    }

    /// @inheritdoc IPerpetualMint
    function reactivateERC721Assets(
        address collection,
        uint256[] calldata risks,
        uint256[] calldata tokenIds
    ) external {
        _reactivateERC721Assets(msg.sender, collection, risks, tokenIds);
    }

    /// @inheritdoc IPerpetualMint
    function setCollectionMintPrice(
        address collection,
        uint256 price
    ) external onlyOwner {
        _setCollectionMintPrice(collection, price);
    }

    /// @inheritdoc IPerpetualMint
    function setMintFeeBP(uint32 mintFeeBP) external onlyOwner {
        _setMintFeeBP(mintFeeBP);
    }

    /// @inheritdoc IPerpetualMint
    function setVRFConfig(
        Storage.VRFConfig calldata config
    ) external onlyOwner {
        _setVRFConfig(config);
    }

    /// @inheritdoc IPerpetualMint
    function updateERC1155TokenRisks(
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata risks
    ) external {
        _updateERC1155TokenRisks(msg.sender, collection, tokenIds, risks);
    }

    /// @inheritdoc IPerpetualMint
    function updateERC721TokenRisks(
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata risks
    ) external {
        _updateERC721TokenRisks(msg.sender, collection, tokenIds, risks);
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
