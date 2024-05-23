// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

/// @dev DataTypes.sol defines PerpetualMint struct data types used throughout the PerpetualMint facet contracts

/// @dev Represents the shared data used in the internal calculation of a given mint result
struct CalculateMintResult_SharedData {
    /// @dev The current collection's mint fee distribution ratio in basis points
    uint32 collectionMintFeeDistributionRatioBP;
    /// @dev The current collection's mint referral fee in basis points
    uint32 collectionReferralFeeBP;
    /// @dev The current collection's set risk of ruin (if applicable)
    uint32 collectionRisk;
    /// @dev The current mint for ETH consolation fee in basis points
    uint32 mintForEthConsolationFeeBP;
    /// @dev The current mint protocol fee in basis points
    uint32 mintFeeBP;
    /// @dev The used risk reward ratio for the mint attempt
    uint32 riskRewardRatio;
    /// @dev The current ETH to $MINT conversion ratio
    uint256 ethToMintRatio;
    /// @dev The current collection's mint multiplier
    uint256 collectionMintMultiplier;
    /// @dev The current collection's mint price
    uint256 collectionMintPrice;
    /// @dev The calculated mint price adjustment factor
    uint256 mintPriceAdjustmentFactor;
    /// @dev The current mint for $MINT consolation tier data
    MintTokenTiersData mintTokenTiers;
    /// @dev The current mint for collection & mint for ETH consolation tier data
    TiersData tiers;
}

/// @dev Represents data specific to a collection
struct CollectionData {
    /// @dev keeps track of mint requests which have not yet been fulfilled
    /// @dev used to implement the collection risk & collection mint multiplier update "state-machine" check
    EnumerableSet.UintSet pendingRequests;
    /// @dev price of mint attempt in ETH (native token) for a collection
    uint256 mintPrice;
    /// @dev risk of ruin for a collection
    uint32 risk;
    /// @dev mint fee distribution ratio for a collection in basis points
    uint32 mintFeeDistributionRatioBP;
    /// @dev mint consolation multiplier for a collection
    uint256 mintMultiplier;
    /// @dev collection-specific mint referral fee in basis points
    uint32 referralFeeBP;
}

/// @dev Represents data specific to mint for ETH paid in ETH for Supra VRF-specific mint requests.
struct MintForEthWithEthParametersSupra {
    address minter;
    address referrer;
    uint8 numberOfMints;
    uint8 wordsPerMint;
    uint32 riskRewardRatio;
    uint256 ethPrizeValueInWei;
    uint256 msgValue;
    uint256 pricePerSpin;
}

/// @dev Represents data specific to mint for ETH paid in $MINT for Supra VRF-specific mint requests.
struct MintForEthWithMintParametersSupra {
    address minter;
    address referrer;
    uint8 numberOfMints;
    uint8 wordsPerMint;
    uint32 riskRewardRatio;
    uint256 ethPrizeValueInWei;
    uint256 ethToMintRatio;
    uint256 pricePerMint;
    uint256 pricePerSpinInWei;
    uint256 ethRequired;
}

/// @dev Represents the outcome of a single mint attempt.
struct MintOutcome {
    /// @dev The index of the tier in which the outcome falls under
    uint256 tierIndex;
    /// @dev The multiplier of the tier, scaled by BASIS
    uint256 tierMultiplier;
    /// @dev The risk or probability of landing in this tier, scaled by BASIS
    uint256 tierRisk;
    /// @dev The amount of $MINT to be issued if this outcome is hit, in units of wei
    uint256 mintAmount;
}

/// @dev Represents the total result of a batch mint attempt.
struct MintResultData {
    /// @dev An array containing the outcomes of each individual mint attempt
    MintOutcome[] mintOutcomes;
    /// @dev The total amount of $MINT to be issued based on all outcomes, in units of wei
    uint256 totalMintAmount;
    /// @dev The total number of successful mint attempts where a prize was won
    uint256 totalSuccessfulMints;
    /// @dev The total ETH value of all prizes won, in units of wei
    uint256 totalPrizeValueAmount;
}

/// @dev Represents the total result of a batch mint attempt on Blast.
struct MintResultDataBlast {
    /// @dev An array containing the outcomes of each individual mint attempt
    MintOutcome[] mintOutcomes;
    /// @dev The total amount of Blast yield received, in units of wei
    uint256 totalBlastYieldAmount;
    /// @dev The total amount of $MINT to be issued based on all outcomes, in units of wei
    uint256 totalMintAmount;
    /// @dev The total number of successful mint attempts where a prize was won
    uint256 totalSuccessfulMints;
    /// @dev The total ETH value of all prizes won, in units of wei
    uint256 totalPrizeValueAmount;
}

/// @dev Represents data specific to $MINT mint for $MINT consolation tiers
struct MintTokenTiersData {
    /// @dev assumed ordered array of risks for each tier
    uint32[] tierRisks;
    /// @dev assumed ordered array of $MINT consolation multipliers for each tier
    uint256[] tierMultipliers;
}

/// @dev Represents data specific to mint requests
/// @dev Updated as a new request is made and removed when the request is fulfilled
struct RequestData {
    /// @dev address of collection for mint attempt
    address collection;
    /// @dev address of minter who made the request
    address minter;
    /// @dev adjustment factor based on the ratio of the price per mint paid to the full price per mint
    uint256 mintPriceAdjustmentFactor;
    /// @dev the mint request mint earnings fee per spin in ETH (denominated in wei)
    uint256 mintEarningsFeePerSpin;
    /// @dev prize value in ETH (denominated in wei) at the time of the mint request
    uint256 prizeValueInWei;
    /// @dev risk reward ratio for the mint request
    uint32 riskRewardRatio;
}

/// @dev Represents data specific to $MINT mint for collection consolation tiers
struct TiersData {
    /// @dev assumed ordered array of risks for each tier
    uint32[] tierRisks;
    /// @dev assumed ordered array of $MINT consolation multipliers for each tier
    uint256[] tierMultipliers;
}

/// @dev Encapsulates variables related to Chainlink VRF
/// @dev see: https://docs.chain.link/vrf/v2/subscription#set-up-your-contract-and-request
struct VRFConfig {
    /// @dev Chainlink identifier for prioritizing transactions
    /// different keyhashes have different gas prices thus different priorities
    bytes32 keyHash;
    /// @dev id of Chainlink subscription to VRF for PerpetualMint contract
    uint64 subscriptionId;
    /// @dev maximum amount of gas a user is willing to pay for completing the callback VRF function
    uint32 callbackGasLimit;
    /// @dev number of block confirmations the VRF service will wait to respond
    uint16 minConfirmations;
}
