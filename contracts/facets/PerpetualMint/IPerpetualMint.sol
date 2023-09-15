// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";

import { PerpetualMintStorage as Storage, TiersData, VRFConfig } from "./Storage.sol";

/// @title IPerpetualMint
/// @dev Interface of the PerpetualMint facet
interface IPerpetualMint is IPausable {
    /// @notice Returns the current accrued consolation fees
    /// @return accruedFees the current amount of accrued consolation fees
    function accruedConsolationFees()
        external
        view
        returns (uint256 accruedFees);

    /// @notice returns the current accrued mint earnings across all collections
    /// @return accruedEarnings the current amount of accrued mint earnings across all collections
    function accruedMintEarnings()
        external
        view
        returns (uint256 accruedEarnings);

    /// @notice returns the current accrued protocol fees
    /// @return accruedFees the current amount of accrued protocol fees
    function accruedProtocolFees() external view returns (uint256 accruedFees);

    /// @notice Attempts a batch mint for the msg.sender for a single collection using ETH as payment.
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    function attemptBatchMintWithEth(
        address collection,
        uint32 numberOfMints
    ) external payable;

    /// @notice Attempts a batch mint for the msg.sender for a single collection using $MINT tokens as payment.
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    function attemptBatchMintWithMint(
        address collection,
        uint32 numberOfMints
    ) external;

    /// @notice returns the value of BASIS
    /// @return value BASIS value
    function BASIS() external pure returns (uint32 value);

    /// @notice claims all accrued mint earnings across collections
    function claimMintEarnings() external;

    /// @notice claims all accrued protocol fees
    function claimProtocolFees() external;

    /// @notice Returns the current mint price for a collection
    /// @param collection address of collection
    /// @return mintPrice current collection mint price
    function collectionMintPrice(
        address collection
    ) external view returns (uint256 mintPrice);

    /// @notice Returns the current collection-wide risk of a collection
    /// @param collection address of collection
    /// @return risk value of collection-wide risk
    function collectionRisk(
        address collection
    ) external view returns (uint32 risk);

    /// @notice Returns the consolation fee in basis points
    /// @return consolationFeeBasisPoints consolation fee in basis points
    function consolationFeeBP()
        external
        view
        returns (uint32 consolationFeeBasisPoints);

    /// @notice Returns the default mint price for a collection
    /// @return mintPrice default collection mint price
    function defaultCollectionMintPrice()
        external
        pure
        returns (uint256 mintPrice);

    /// @notice Returns the default risk for a collection
    /// @return risk default collection risk
    function defaultCollectionRisk() external pure returns (uint32 risk);

    /// @notice Returns the default ETH to $MINT ratio
    /// @return ratio default ETH to $MINT ratio
    function defaultEthToMintRatio() external pure returns (uint32 ratio);

    /// @notice Returns the current ETH to $MINT ratio
    /// @return ratio current ETH to $MINT ratio
    function ethToMintRatio() external view returns (uint256 ratio);

    /// @notice Returns the mint fee in basis points
    /// @return mintFeeBasisPoints mint fee in basis points
    function mintFeeBP() external view returns (uint32 mintFeeBasisPoints);

    /// @notice Returns the address of the current $MINT token
    /// @return token address of the current $MINT token
    function mintToken() external view returns (address token);

    /// @notice Triggers paused state, when contract is unpaused.
    function pause() external;

    /// @notice redeems an amount of $MINT tokens for ETH (native token) for the msg.sender
    /// @param amount amount of $MINT
    function redeem(uint256 amount) external;

    /// @notice returns the current redemption fee in basis points
    /// @return feeBP redemptionFee in basis points
    function redemptionFeeBP() external view returns (uint32 feeBP);

    /// @notice set the mint price for a given collection
    /// @param collection address of collection
    /// @param price mint price of the collection
    function setCollectionMintPrice(address collection, uint256 price) external;

    /// @notice sets the risk of a given collection
    /// @param collection address of collection
    /// @param risk new risk value for collection
    function setCollectionRisk(address collection, uint32 risk) external;

    /// @notice sets the consolation fee in basis points
    /// @param consolationFeeBP consolation fee in basis points
    function setConsolationFeeBP(uint32 consolationFeeBP) external;

    /// @notice sets the ratio of ETH (native token) to $MINT for mint attempts using $MINT as payment
    /// @param ratio ratio of ETH to $MINT
    function setEthToMintRatio(uint256 ratio) external;

    /// @notice sets the mint fee in basis points
    /// @param mintFeeBP mint fee in basis points
    function setMintFeeBP(uint32 mintFeeBP) external;

    /// @notice sets the address of the mint consolation token
    /// @param mintToken address of the mint consolation token
    function setMintToken(address mintToken) external;

    /// @notice sets the redemption fee in basis points
    /// @param _redemptionFeeBP redemption fee in basis points
    function setRedemptionFeeBP(uint32 _redemptionFeeBP) external;

    /// @notice sets the $MINT consolation tiers
    /// @param tiersData TiersData struct holding all related data to $MINT consolation tiers
    function setTiers(TiersData calldata tiersData) external;

    /// @notice sets the Chainlink VRF config
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF setup
    function setVRFConfig(VRFConfig calldata config) external;

    /// @notice Returns the current $MINT consolation tiers
    function tiers() external view returns (TiersData memory tiersData);

    ///  @notice Triggers unpaused state, when contract is paused.
    function unpause() external;

    /// @notice returns the current VRF config
    /// @return config VRFConfig struct
    function vrfConfig() external view returns (VRFConfig memory config);
}
