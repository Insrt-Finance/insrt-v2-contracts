// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintAdmin } from "./IPerpetualMintAdmin.sol";
import { PerpetualMintInternal } from "./PerpetualMintInternal.sol";
import { MintTokenTiersData, TiersData, VRFConfig } from "./Storage.sol";

/// @title PerpetualMintAdmin
/// @dev PerpetualMintAdmin facet containing all administrative protocol-specific externally called functions
contract PerpetualMintAdmin is IPerpetualMintAdmin, PerpetualMintInternal {
    constructor(address vrf) PerpetualMintInternal(vrf) {}

    /// @inheritdoc IPerpetualMintAdmin
    function burnReceipt(uint256 tokenId) external onlyOwner {
        _burnReceipt(tokenId);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function cancelClaim(address claimer, uint256 tokenId) external onlyOwner {
        _cancelClaim(claimer, tokenId);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function claimMintEarnings() external onlyOwner {
        _claimMintEarnings(msg.sender);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function claimMintEarnings(uint256 amount) external onlyOwner {
        _claimMintEarnings(msg.sender, amount);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function claimProtocolFees() external onlyOwner {
        _claimProtocolFees(msg.sender);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function mintAirdrop(uint256 amount) external payable onlyOwner {
        _mintAirdrop(amount);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function pause() external onlyOwner {
        _pause();
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setCollectionMintFeeDistributionRatioBP(
        address collection,
        uint32 ratioBP
    ) external onlyOwner {
        _setCollectionMintFeeDistributionRatioBP(collection, ratioBP);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setCollectionMintMultiplier(
        address collection,
        uint256 multiplier
    ) external onlyOwner {
        _setCollectionMintMultiplier(collection, multiplier);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setCollectionMintPrice(
        address collection,
        uint256 price
    ) external onlyOwner {
        _setCollectionMintPrice(collection, price);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setCollectionReferralFeeBP(
        address collection,
        uint32 referralFeeBP
    ) external onlyOwner {
        _setCollectionReferralFeeBP(collection, referralFeeBP);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setCollectionRisk(
        address collection,
        uint32 risk
    ) external onlyOwner {
        _setCollectionRisk(collection, risk);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setCollectionConsolationFeeBP(
        uint32 _collectionConsolationFeeBP
    ) external onlyOwner {
        _setCollectionConsolationFeeBP(_collectionConsolationFeeBP);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setDefaultCollectionReferralFeeBP(
        uint32 referralFeeBP
    ) external onlyOwner {
        _setDefaultCollectionReferralFeeBP(referralFeeBP);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setEthToMintRatio(uint256 ratio) external onlyOwner {
        _setEthToMintRatio(ratio);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setMintFeeBP(uint32 _mintFeeBP) external onlyOwner {
        _setMintFeeBP(_mintFeeBP);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setMintToken(address _mintToken) external onlyOwner {
        _setMintToken(_mintToken);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setMintTokenConsolationFeeBP(
        uint32 _mintTokenConsolationFeeBP
    ) external onlyOwner {
        _setMintTokenConsolationFeeBP(_mintTokenConsolationFeeBP);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setMintTokenTiers(
        MintTokenTiersData calldata mintTokenTiers
    ) external onlyOwner {
        _setMintTokenTiers(mintTokenTiers);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setReceiptBaseURI(string calldata baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setReceiptTokenURI(
        uint256 tokenId,
        string calldata tokenURI
    ) external onlyOwner {
        _setTokenURI(tokenId, tokenURI);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setRedeemPaused(bool status) external onlyOwner {
        _setRedeemPaused(status);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setRedemptionFeeBP(uint32 _redemptionFeeBP) external onlyOwner {
        _setRedemptionFeeBP(_redemptionFeeBP);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setTiers(TiersData calldata tiersData) external onlyOwner {
        _setTiers(tiersData);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setVRFConfig(VRFConfig calldata config) external onlyOwner {
        _setVRFConfig(config);
    }

    /// @inheritdoc IPerpetualMintAdmin
    function setVRFSubscriptionBalanceThreshold(
        uint96 _vrfSubscriptionBalanceThreshold
    ) external onlyOwner {
        _setVRFSubscriptionBalanceThreshold(_vrfSubscriptionBalanceThreshold);
    }

    /// @inheritdoc IPerpetualMintAdmin
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
