// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { MintOutcome, MintResultData, MintTokenTiersData, PerpetualMintStorage as Storage, TiersData, VRFConfig } from "./Storage.sol";

/// @title IPerpetualMint
/// @dev Interface of the PerpetualMint facet
interface IPerpetualMint {
    /// @notice Attempts a batch mint for the msg.sender for $MINT using ETH as payment.
    /// @param referrer referrer address for mint attempts
    /// @param numberOfMints number of mints to attempt
    function attemptBatchMintForMintWithEth(
        address referrer,
        uint32 numberOfMints
    ) external payable;

    /// @notice Attempts a batch mint for the msg.sender for $MINT using $MINT tokens as payment.
    /// @param referrer referrer address for mint attempts
    /// @param pricePerMint price per mint for collection ($MINT denominated in units of wei)
    /// @param numberOfMints number of mints to attempt
    function attemptBatchMintForMintWithMint(
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external;

    /// @notice Attempts a batch mint for the msg.sender for a single collection using ETH as payment.
    /// @param collection address of collection for mint attempts
    /// @param referrer referrer address for mint attempts
    /// @param numberOfMints number of mints to attempt
    function attemptBatchMintWithEth(
        address collection,
        address referrer,
        uint32 numberOfMints
    ) external payable;

    /// @notice Attempts a batch mint for the msg.sender for a single collection using $MINT tokens as payment.
    /// @param collection address of collection for mint attempts
    /// @param referrer referrer address for mint attempts
    /// @param pricePerMint price per mint for collection ($MINT denominated in units of wei)
    /// @param numberOfMints number of mints to attempt
    function attemptBatchMintWithMint(
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external;

    /// @notice burns a receipt after a claim request is fulfilled
    /// @param tokenId id of receipt to burn
    function burnReceipt(uint256 tokenId) external;

    /// @notice Cancels a claim for a given claimer for given token ID
    /// @param claimer address of rejected claimer
    /// @param tokenId token ID of rejected claim
    function cancelClaim(address claimer, uint256 tokenId) external;

    /// @notice claims all accrued mint earnings across collections
    function claimMintEarnings() external;

    /// @notice Initiates a claim for a prize for a given collection
    /// @param prizeRecipient address of intended prize recipient
    /// @param tokenId token ID of prize, which is the prize collection address encoded as uint256
    function claimPrize(address prizeRecipient, uint256 tokenId) external;

    /// @notice claims all accrued protocol fees
    function claimProtocolFees() external;

    /// @notice funds the consolation fees pool with ETH
    function fundConsolationFees() external payable;

    /// @notice mints an amount of mintToken tokens to the mintToken contract in exchange for ETH
    /// @param amount amount of mintToken tokens to mint
    function mintAirdrop(uint256 amount) external payable;

    /// @notice Triggers paused state, _ONLY FOR attemptBatchMint FUNCTIONS_ when contract is unpaused.
    function pause() external;

    /// @notice redeems an amount of $MINT tokens for ETH (native token) for the msg.sender
    /// @param amount amount of $MINT
    function redeem(uint256 amount) external;

    /// @notice sets the mint fee distribution ratio in basis points for a given collection
    /// @param collection address of collection
    /// @param ratioBP new mint fee distribution ratio in basis points
    function setCollectionMintFeeDistributionRatioBP(
        address collection,
        uint32 ratioBP
    ) external;

    /// @notice sets the mint multiplier for a given collection
    /// @param collection address of collection
    /// @param multiplier mint multiplier of collection
    function setCollectionMintMultiplier(
        address collection,
        uint256 multiplier
    ) external;

    /// @notice set the mint price for a given collection
    /// @param collection address of collection
    /// @param price mint price of the collection
    function setCollectionMintPrice(address collection, uint256 price) external;

    /// @notice sets the mint referral fee for a given collection in basis points
    /// @param collection address of collection
    /// @param referralFeeBP new mint referral fee for collection in basis points
    function setCollectionReferralFeeBP(
        address collection,
        uint32 referralFeeBP
    ) external;

    /// @notice sets the risk of a given collection
    /// @param collection address of collection
    /// @param risk new risk value for collection
    function setCollectionRisk(address collection, uint32 risk) external;

    /// @notice sets the minting for a collection consolation fee in basis points
    /// @param collectionConsolationFeeBP minting for a collection consolation fee in basis points
    function setCollectionConsolationFeeBP(
        uint32 collectionConsolationFeeBP
    ) external;

    /// @notice sets the default mint referral fee for collections in basis points
    /// @param referralFeeBP new default mint referral fee for collections in basis points
    function setDefaultCollectionReferralFeeBP(uint32 referralFeeBP) external;

    /// @notice sets the ratio of ETH (native token) to $MINT for mint attempts using $MINT as payment
    /// @param ratio ratio of ETH to $MINT
    function setEthToMintRatio(uint256 ratio) external;

    /// @notice sets the mint fee in basis points
    /// @param mintFeeBP mint fee in basis points
    function setMintFeeBP(uint32 mintFeeBP) external;

    /// @notice sets the address of the mint consolation token
    /// @param mintToken address of the mint consolation token
    function setMintToken(address mintToken) external;

    /// @notice sets the minting for $MINT consolation fee in basis points
    /// @param mintTokenConsolationFeeBP minting for $MINT consolation fee in basis points
    function setMintTokenConsolationFeeBP(
        uint32 mintTokenConsolationFeeBP
    ) external;

    /// @notice sets the mint for $MINT consolation tiers
    /// @param mintTokenTiersData MintTokenTiersData struct holding all related data to mint for $MINT consolation tiers
    function setMintTokenTiers(
        MintTokenTiersData calldata mintTokenTiersData
    ) external;

    /// @notice sets the baseURI for the ERC1155 token receipts
    /// @param baseURI URI string
    function setReceiptBaseURI(string calldata baseURI) external;

    /// @notice sets the tokenURI for ERC1155 token receipts
    /// @param tokenId token ID, which is the collection address encoded as uint256
    /// @param tokenURI URI string
    function setReceiptTokenURI(
        uint256 tokenId,
        string calldata tokenURI
    ) external;

    /// @notice sets the status of the redeemPaused state
    /// @param status boolean indicating whether redeeming is paused
    function setRedeemPaused(bool status) external;

    /// @notice sets the redemption fee in basis points
    /// @param _redemptionFeeBP redemption fee in basis points
    function setRedemptionFeeBP(uint32 _redemptionFeeBP) external;

    /// @notice sets the mint for collection $MINT consolation tiers
    /// @param tiersData TiersData struct holding all related data to mint for collection $MINT consolation tiers
    function setTiers(TiersData calldata tiersData) external;

    /// @notice sets the Chainlink VRF config
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF setup
    function setVRFConfig(VRFConfig calldata config) external;

    /// @notice sets the minimum threshold for the VRF subscription balance in LINK tokens
    /// @param vrfSubscriptionBalanceThreshold minimum threshold for the VRF subscription balance in LINK tokens
    function setVRFSubscriptionBalanceThreshold(
        uint96 vrfSubscriptionBalanceThreshold
    ) external;

    /// @notice Triggers unpaused state, _ONLY FOR attemptBatchMint FUNCTIONS_ when contract is unpaused.
    function unpause() external;
}
