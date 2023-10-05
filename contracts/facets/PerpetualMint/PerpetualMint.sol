// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { Ownable } from "@solidstate/contracts/access/ownable/Ownable.sol";
import { ERC165Base } from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import { Pausable } from "@solidstate/contracts/security/pausable/Pausable.sol";
import { ERC1155Base } from "@solidstate/contracts/token/ERC1155/base/ERC1155Base.sol";
import { ERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155Metadata.sol";

import { ERC1155MetadataExtension } from "./ERC1155MetadataExtension.sol";
import { IPerpetualMint } from "./IPerpetualMint.sol";
import { PerpetualMintInternal } from "./PerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage, TiersData, VRFConfig } from "./Storage.sol";

/// @title PerpetualMint facet contract
/// @dev contains all externally called functions
contract PerpetualMint is
    ERC1155Base,
    ERC1155Metadata,
    ERC165Base,
    IPerpetualMint,
    Ownable,
    Pausable,
    ERC1155MetadataExtension,
    PerpetualMintInternal
{
    constructor(address vrf) PerpetualMintInternal(vrf) {}

    /// @inheritdoc IPerpetualMint
    function accruedConsolationFees()
        external
        view
        returns (uint256 accruedFees)
    {
        accruedFees = _accruedConsolationFees();
    }

    /// @inheritdoc IPerpetualMint
    function accruedMintEarnings()
        external
        view
        returns (uint256 accruedEarnings)
    {
        accruedEarnings = _accruedMintEarnings();
    }

    /// @inheritdoc IPerpetualMint
    function accruedProtocolFees() external view returns (uint256 accruedFees) {
        accruedFees = _accruedProtocolFees();
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintWithEth(
        address collection,
        uint32 numberOfMints
    ) external payable whenNotPaused {
        _attemptBatchMintWithEth(msg.sender, collection, numberOfMints);
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintWithMint(
        address collection,
        uint32 numberOfMints
    ) external whenNotPaused {
        _attemptBatchMintWithMint(msg.sender, collection, numberOfMints);
    }

    /// @inheritdoc IPerpetualMint
    function BASIS() external pure returns (uint32 value) {
        value = _BASIS();
    }

    /// @inheritdoc IPerpetualMint
    function burnReceipt(uint256 tokenId) external onlyOwner {
        _burnReceipt(tokenId);
    }

    /// @inheritdoc IPerpetualMint
    function cancelClaim(address claimer, uint256 tokenId) external onlyOwner {
        _cancelClaim(claimer, tokenId);
    }

    /// @inheritdoc IPerpetualMint
    function claimMintEarnings() external onlyOwner {
        _claimMintEarnings(msg.sender);
    }

    /// @inheritdoc IPerpetualMint
    function claimPrize(address prizeRecipient, uint256 tokenId) external {
        _claimPrize(msg.sender, prizeRecipient, tokenId);
    }

    /// @inheritdoc IPerpetualMint
    function claimProtocolFees() external onlyOwner {
        _claimProtocolFees(msg.sender);
    }

    /// @inheritdoc IPerpetualMint
    function collectionMintPrice(
        address collection
    ) external view returns (uint256 mintPrice) {
        mintPrice = _collectionMintPrice(
            Storage.layout().collections[collection]
        );
    }

    /// @inheritdoc IPerpetualMint
    function collectionRisk(
        address collection
    ) external view returns (uint32 risk) {
        risk = _collectionRisk(Storage.layout().collections[collection]);
    }

    /// @inheritdoc IPerpetualMint
    function consolationFeeBP()
        external
        view
        returns (uint32 consolationFeeBasisPoints)
    {
        consolationFeeBasisPoints = _consolationFeeBP();
    }

    /// @inheritdoc IPerpetualMint
    function defaultCollectionMintPrice()
        external
        pure
        returns (uint256 mintPrice)
    {
        mintPrice = _defaultCollectionMintPrice();
    }

    /// @inheritdoc IPerpetualMint
    function defaultCollectionRisk() external pure returns (uint32 risk) {
        risk = _defaultCollectionRisk();
    }

    /// @inheritdoc IPerpetualMint
    function defaultEthToMintRatio() external pure returns (uint32 ratio) {
        ratio = _defaultEthToMintRatio();
    }

    /// @inheritdoc IPerpetualMint
    function ethToMintRatio() external view returns (uint256 ratio) {
        ratio = _ethToMintRatio(Storage.layout());
    }

    /// @notice mints an amount of mintToken tokens to the mintToken contract in exchange for ETH
    /// @param amount amount of mintToken tokens to mint
    function mintAirdrop(uint256 amount) external payable onlyOwner {
        _mintAirdrop(amount);
    }

    /// @inheritdoc IPerpetualMint
    function mintFeeBP() external view returns (uint32 mintFeeBasisPoints) {
        mintFeeBasisPoints = _mintFeeBP();
    }

    /// @inheritdoc IPerpetualMint
    function mintToken() external view returns (address token) {
        token = _mintToken();
    }

    /// @inheritdoc IPerpetualMint
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @inheritdoc IPerpetualMint
    function pause() external onlyOwner {
        _pause();
    }

    /// @inheritdoc IPerpetualMint
    function redeem(uint256 amount) external {
        _redeem(msg.sender, amount);
    }

    /// @inheritdoc IPerpetualMint
    function redemptionFeeBP() external view returns (uint32 feeBP) {
        feeBP = _redemptionFeeBP();
    }

    /// @inheritdoc IPerpetualMint
    function setCollectionMintPrice(
        address collection,
        uint256 price
    ) external onlyOwner {
        _setCollectionMintPrice(collection, price);
    }

    /// @inheritdoc IPerpetualMint
    function setCollectionRisk(
        address collection,
        uint32 risk
    ) external onlyOwner {
        _setCollectionRisk(collection, risk);
    }

    /// @inheritdoc IPerpetualMint
    function setConsolationFeeBP(uint32 _consolationFeeBP) external onlyOwner {
        _setConsolationFeeBP(_consolationFeeBP);
    }

    /// @inheritdoc IPerpetualMint
    function setEthToMintRatio(uint256 ratio) external onlyOwner {
        _setEthToMintRatio(ratio);
    }

    /// @inheritdoc IPerpetualMint
    function setMintFeeBP(uint32 _mintFeeBP) external onlyOwner {
        _setMintFeeBP(_mintFeeBP);
    }

    /// @inheritdoc IPerpetualMint
    function setMintToken(address _mintToken) external onlyOwner {
        _setMintToken(_mintToken);
    }

    /// @inheritdoc IPerpetualMint
    function setReceiptBaseURI(string calldata baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /// @inheritdoc IPerpetualMint
    function setReceiptTokenURI(
        uint256 tokenId,
        string calldata tokenURI
    ) external onlyOwner {
        _setTokenURI(tokenId, tokenURI);
    }

    /// @inheritdoc IPerpetualMint
    function setRedemptionFeeBP(uint32 _redemptionFeeBP) external onlyOwner {
        _setRedemptionFeeBP(_redemptionFeeBP);
    }

    /// @inheritdoc IPerpetualMint
    function setTiers(TiersData calldata tiersData) external onlyOwner {
        _setTiers(tiersData);
    }

    /// @inheritdoc IPerpetualMint
    function setVRFConfig(VRFConfig calldata config) external onlyOwner {
        _setVRFConfig(config);
    }

    /// @inheritdoc IPerpetualMint
    function tiers() external view returns (TiersData memory tiersData) {
        tiersData = _tiers();
    }

    /// @inheritdoc IPerpetualMint
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @inheritdoc IPerpetualMint
    function vrfConfig() external view returns (VRFConfig memory config) {
        config = _vrfConfig();
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
