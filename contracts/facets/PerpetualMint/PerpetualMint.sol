// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMint } from "./IPerpetualMint.sol";
import { PerpetualMintInternal } from "./PerpetualMintInternal.sol";
import { MintTokenTiersData, PerpetualMintStorage as Storage, TiersData, VRFConfig } from "./Storage.sol";

/// @title PerpetualMint
/// @dev PerpetualMint facet containing all protocol-specific externally called functions
contract PerpetualMint is IPerpetualMint, PerpetualMintInternal {
    constructor(address vrf) PerpetualMintInternal(vrf) {}

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintForMintWithEth(
        address referrer,
        uint32 numberOfMints
    ) external payable virtual whenNotPaused {
        _attemptBatchMintForMintWithEth(msg.sender, referrer, numberOfMints);
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintForMintWithMint(
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external virtual whenNotPaused {
        _attemptBatchMintForMintWithMint(
            msg.sender,
            referrer,
            pricePerMint,
            numberOfMints
        );
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintWithEth(
        address collection,
        address referrer,
        uint32 numberOfMints
    ) external payable virtual whenNotPaused {
        _attemptBatchMintWithEth(
            msg.sender,
            collection,
            referrer,
            numberOfMints
        );
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintWithMint(
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external virtual whenNotPaused {
        _attemptBatchMintWithMint(
            msg.sender,
            collection,
            referrer,
            pricePerMint,
            numberOfMints
        );
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
    function claimMintEarnings(uint256 amount) external onlyOwner {
        _claimMintEarnings(msg.sender, amount);
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
    function fundConsolationFees() external payable {
        _fundConsolationFees();
    }

    /// @inheritdoc IPerpetualMint
    function mintAirdrop(uint256 amount) external payable onlyOwner {
        _mintAirdrop(amount);
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
    function setCollectionMintFeeDistributionRatioBP(
        address collection,
        uint32 ratioBP
    ) external onlyOwner {
        _setCollectionMintFeeDistributionRatioBP(collection, ratioBP);
    }

    /// @inheritdoc IPerpetualMint
    function setCollectionMintMultiplier(
        address collection,
        uint256 multiplier
    ) external onlyOwner {
        _setCollectionMintMultiplier(collection, multiplier);
    }

    /// @inheritdoc IPerpetualMint
    function setCollectionMintPrice(
        address collection,
        uint256 price
    ) external onlyOwner {
        _setCollectionMintPrice(collection, price);
    }

    /// @inheritdoc IPerpetualMint
    function setCollectionReferralFeeBP(
        address collection,
        uint32 referralFeeBP
    ) external onlyOwner {
        _setCollectionReferralFeeBP(collection, referralFeeBP);
    }

    /// @inheritdoc IPerpetualMint
    function setCollectionRisk(
        address collection,
        uint32 risk
    ) external onlyOwner {
        _setCollectionRisk(collection, risk);
    }

    /// @inheritdoc IPerpetualMint
    function setCollectionConsolationFeeBP(
        uint32 _collectionConsolationFeeBP
    ) external onlyOwner {
        _setCollectionConsolationFeeBP(_collectionConsolationFeeBP);
    }

    /// @inheritdoc IPerpetualMint
    function setDefaultCollectionReferralFeeBP(
        uint32 referralFeeBP
    ) external onlyOwner {
        _setDefaultCollectionReferralFeeBP(referralFeeBP);
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
    function setMintTokenConsolationFeeBP(
        uint32 _mintTokenConsolationFeeBP
    ) external onlyOwner {
        _setMintTokenConsolationFeeBP(_mintTokenConsolationFeeBP);
    }

    /// @inheritdoc IPerpetualMint
    function setMintTokenTiers(
        MintTokenTiersData calldata mintTokenTiers
    ) external onlyOwner {
        _setMintTokenTiers(mintTokenTiers);
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
    function setRedeemPaused(bool status) external onlyOwner {
        _setRedeemPaused(status);
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
    function setVRFSubscriptionBalanceThreshold(
        uint96 _vrfSubscriptionBalanceThreshold
    ) external onlyOwner {
        _setVRFSubscriptionBalanceThreshold(_vrfSubscriptionBalanceThreshold);
    }

    /// @inheritdoc IPerpetualMint
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Chainlink VRF Coordinator callback
    /// @param requestId id of request for random values
    /// @param randomWords random values returned from Chainlink VRF coordination
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual override {
        _fulfillRandomWords(requestId, randomWords);
    }
}
