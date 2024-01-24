// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { GasMode, YieldMode } from "./DataTypes.sol";

/// @title IBlast
/// @notice Interface for the Blast yield contract
interface IBlast {
    /// @notice Used to claim all gas for a contract, regardless of tax
    /// @param contractAddress The address of the contract to claim gas for
    /// @param recipientOfGas The address of the recipient of the gas
    /// @return gasClaimed The amount of gas claimed
    function claimAllGas(
        address contractAddress,
        address recipientOfGas
    ) external returns (uint256 gasClaimed);

    /// @notice Used to claim all yield for a contract
    /// @param contractAddress The address of the contract to claim yield for
    /// @param recipientOfYield The address of the recipient of the yield
    /// @return yieldClaimed The amount of yield claimed
    function claimAllYield(
        address contractAddress,
        address recipientOfYield
    ) external returns (uint256 yieldClaimed);

    /// @notice Used to claim a specific amounts of gas for a contract
    /// @param contractAddress The address of the contract to claim gas for
    /// @param recipientOfGas The address of the recipient of the gas
    /// @param gasToClaim The amount of gas to claim
    /// @param gasSecondsToConsume The amount of gas seconds to consume
    /// @return gasClaimed The amount of gas claimed
    function claimGas(
        address contractAddress,
        address recipientOfGas,
        uint256 gasToClaim,
        uint256 gasSecondsToConsume
    ) external returns (uint256 gasClaimed);

    /// @notice Used to claim all gas for a contract, at a specified minimum claim rate
    /// @param contractAddress The address of the contract to claim gas for
    /// @param recipientOfGas The address of the recipient of the gas
    /// @param minClaimRateBips The minimum claim rate to be used
    /// @return gasClaimed The amount of gas claimed
    function claimGasAtMinClaimRate(
        address contractAddress,
        address recipientOfGas,
        uint256 minClaimRateBips
    ) external returns (uint256 gasClaimed);

    /// @notice Used to claim all fully vested for a contract, 0% tax
    /// @param contractAddress The address of the contract to claim gas for
    /// @param recipientOfGas The address of the recipient of the gas
    /// @return gasClaimed The amount of gas claimed
    function claimMaxGas(
        address contractAddress,
        address recipientOfGas
    ) external returns (uint256 gasClaimed);

    /// @notice Used to claim a specific amounts of yield for a contract
    /// @param contractAddress The address of the contract to claim yield for
    /// @param recipientOfYield The address of the recipient of the yield
    /// @param amount The amount of yield to claim
    /// @return yieldClaimed The amount of yield claimed
    function claimYield(
        address contractAddress,
        address recipientOfYield,
        uint256 amount
    ) external returns (uint256 yieldClaimed);

    /// @notice Used to configure the Blast yield & gas settings for a contract
    /// @param yieldMode The yield mode to be configured for the contract
    /// @param gasMode The gas mode to be configured for the contract
    /// @param governor The address of the governor to be configured for the contract
    function configure(
        YieldMode yieldMode,
        GasMode gasMode,
        address governor
    ) external;

    /// @notice Used to configure a contract to have automatic yield
    function configureAutomaticYield() external;

    /// @notice Used to configure a contract to have automatic yield on behalf of a contract
    /// @param contractAddress The address of the contract to be configured
    function configureAutomaticYieldOnBehalf(address contractAddress) external;

    /// @notice Used to configure a contract to have claimble gas
    function configureClaimableGas() external;

    /// @notice Used to configure a contract to have claimble gas on behalf of a contract
    /// @param contractAddress The address of the contract to be configured
    function configureClaimableGasOnBehalf(address contractAddress) external;

    /// @notice Used to configure a contract to have claimble yield
    function configureClaimableYield() external;

    /// @notice Used to configure a contract to have claimble yield on behalf of a contract
    /// @param contractAddress The address of the contract to be configured
    function configureClaimableYieldOnBehalf(address contractAddress) external;

    /// @notice Used to configure the Blast yield & gas settings for a contract on behalf of a contract
    /// @param contractAddress The address of the contract to be configured
    /// @param yieldMode The yield mode to be configured for the contract
    /// @param gasMode The gas mode to be configured for the contract
    /// @param governor The address of the governor to be configured for the contract
    function configureContract(
        address contractAddress,
        YieldMode yieldMode,
        GasMode gasMode,
        address governor
    ) external;

    /// @notice Used to configure a governor for a contract
    /// @param governor The address of the governor to be configured for the contract
    function configureGovernor(address governor) external;

    /// @notice Used to configure a governor for a contract on behalf of a contract
    /// @param newGovernor The address of the new governor to be configured for the contract
    /// @param contractAddress The address of the contract to be configured
    function configureGovernorOnBehalf(
        address newGovernor,
        address contractAddress
    ) external;

    /// @notice Used to configure a contract to not have claimable gas
    function configureVoidGas() external;

    /// @notice Used to configure a contract to not have claimable gas on behalf of a contract
    /// @param contractAddress The address of the contract to be configured
    function configureVoidGasOnBehalf(address contractAddress) external;

    /// @notice Used to configure a contract to not have yield
    function configureVoidYield() external;

    /// @notice Used to configure a contract to not have yield on behalf of a contract
    /// @param contractAddress The address of the contract to be configured
    function configureVoidYieldOnBehalf(address contractAddress) external;

    /// @notice Used to read the amount of yield that can be claimed for a contract
    /// @param contractAddress The address of the contract to read the claimable yield for
    /// @return claimableYield The amount of yield that can be claimed
    function readClaimableYield(
        address contractAddress
    ) external view returns (uint256 claimableYield);

    /// @notice Used to read the gas parameters for a contract
    /// @param contractAddress The address of the contract to read the gas parameters for
    /// @return etherSeconds The amount of ether seconds for the contract
    /// @return etherBalance The amount of ether balance for the contract
    /// @return lastUpdated The timestamp of the last update for the contract
    /// @return gasMode The gas mode for the contract
    function readGasParams(
        address contractAddress
    )
        external
        view
        returns (
            uint256 etherSeconds,
            uint256 etherBalance,
            uint256 lastUpdated,
            GasMode gasMode
        );

    /// @notice Used to read the yield mode for a contract
    /// @param contractAddress The address of the contract to read the yield mode for
    /// @return yieldMode The yield mode for the contract
    function readYieldConfiguration(
        address contractAddress
    ) external view returns (YieldMode yieldMode);
}
