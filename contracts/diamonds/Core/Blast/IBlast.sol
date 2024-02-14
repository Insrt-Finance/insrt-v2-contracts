// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { GasMode, YieldMode } from "./DataTypes.sol";

/// @title IBlast
/// @notice Interface for the Blast precompile contract
interface IBlast {
    /// @notice Claims all gas for a specific contract. Called by an authorized user
    /// @param contractAddress The address of the contract for which all gas is to be claimed
    /// @param recipientOfGas The address of the recipient of the gas
    /// @return gasClaimed The amount of gas that was claimed
    function claimAllGas(
        address contractAddress,
        address recipientOfGas
    ) external returns (uint256 gasClaimed);

    /// @notice Claims all yield for a specific contract. Called by an authorized user
    /// @param contractAddress The address of the contract for which all yield is to be claimed
    /// @param recipientOfYield The address of the recipient of the yield
    /// @return yieldClaimed The amount of yield that was claimed
    function claimAllYield(
        address contractAddress,
        address recipientOfYield
    ) external returns (uint256 yieldClaimed);

    /// @notice Claims a specific amount of gas for a specific contract. claim rate governed by integral of gas over time
    /// @param contractAddress The address of the contract for which gas is to be claimed
    /// @param recipientOfGas The address of the recipient of the gas
    /// @param gasToClaim The amount of gas to be claimed
    /// @param gasSecondsToConsume The amount of gas seconds to consume
    /// @return gasClaimed The amount of gas that was claimed
    function claimGas(
        address contractAddress,
        address recipientOfGas,
        uint256 gasToClaim,
        uint256 gasSecondsToConsume
    ) external returns (uint256 gasClaimed);

    /// @notice Claims gas at a minimum claim rate for a specific contract. Called by an authorized user
    /// @param contractAddress The address of the contract for which gas is to be claimed
    /// @param recipientOfGas The address of the recipient of the gas
    /// @param minClaimRateBips The minimum claim rate in basis points
    /// @return gasClaimed The amount of gas that was claimed
    function claimGasAtMinClaimRate(
        address contractAddress,
        address recipientOfGas,
        uint256 minClaimRateBips
    ) external returns (uint256 gasClaimed);

    /// @notice Claims gas available to be claimed at max claim rate for a specific contract. Called by an authorized user
    /// @param contractAddress The address of the contract for which maximum gas is to be claimed
    /// @param recipientOfGas The address of the recipient of the gas
    /// @return gasClaimed The amount of gas that was claimed
    function claimMaxGas(
        address contractAddress,
        address recipientOfGas
    ) external returns (uint256 gasClaimed);

    /// @notice Claims yield for a specific contract. Called by an authorized user
    /// @param contractAddress The address of the contract for which yield is to be claimed
    /// @param recipientOfYield The address of the recipient of the yield
    /// @param amount The amount of yield to be claimed
    /// @return yieldClaimed The amount of yield that was claimed
    function claimYield(
        address contractAddress,
        address recipientOfYield,
        uint256 amount
    ) external returns (uint256 yieldClaimed);

    /// @notice contract configures its yield and gas modes and sets the governor. called by contract
    /// @param yieldMode The yield mode to be set
    /// @param gasMode The gas mode to be set
    /// @param governor The address of the governor to be set
    function configure(
        YieldMode yieldMode,
        GasMode gasMode,
        address governor
    ) external;

    /// @notice Configures the yield mode to AUTOMATIC for the contract that calls this function
    function configureAutomaticYield() external;

    /// @notice Configures the yield mode to AUTOMATIC for a specific contract. Called by an authorized user
    /// @param contractAddress The address of the contract to be configured
    function configureAutomaticYieldOnBehalf(address contractAddress) external;

    /// @notice Configures the gas mode to CLAIMABLE for the contract that calls this function
    function configureClaimableGas() external;

    /// @notice Configures the gas mode to CLAIMABLE for a specific contract. Called by an authorized user
    /// @param contractAddress The address of the contract to be configured
    function configureClaimableGasOnBehalf(address contractAddress) external;

    /// @notice Configures the yield mode to CLAIMABLE for the contract that calls this function
    function configureClaimableYield() external;

    /// @notice Configures the yield mode to CLAIMABLE for a specific contract. Called by an authorized user
    /// @param contractAddress The address of the contract to be configured
    function configureClaimableYieldOnBehalf(address contractAddress) external;

    ///@notice Configures the yield and gas modes and sets the governor for a specific contract. called by authorized user
    /// @param contractAddress The address of the contract to be configured
    /// @param yieldMode The yield mode to be set
    /// @param gasMode The gas mode to be set
    /// @param newGovernor The address of the new governor to be set
    function configureContract(
        address contractAddress,
        YieldMode yieldMode,
        GasMode gasMode,
        address newGovernor
    ) external;

    /// @notice Configures the governor for the contract that calls this function
    /// @param governor The address of the governor to be configured for the contract
    function configureGovernor(address governor) external;

    /// @notice Configures the governor for a specific contract. Called by an authorized user
    /// @param newGovernor The address of the new governor to be configured for the contract
    /// @param contractAddress The address of the contract to be configured
    function configureGovernorOnBehalf(
        address newGovernor,
        address contractAddress
    ) external;

    /// @notice Configures the gas mode to VOID for the contract that calls this function
    function configureVoidGas() external;

    /// @notice Configures the gas mode to void for a specific contract. Called by an authorized user
    /// @param contractAddress The address of the contract to be configured
    function configureVoidGasOnBehalf(address contractAddress) external;

    /// @notice Configures the yield mode to VOID for the contract that calls this function
    function configureVoidYield() external;

    /// @notice Configures the yield mode to VOID for a specific contract. Called by an authorized user
    /// @param contractAddress The address of the contract to be configured
    function configureVoidYieldOnBehalf(address contractAddress) external;

    /// @notice Used to read the amount of yield that can be claimed for a contract
    /// @param contractAddress The address of the contract to read the claimable yield for
    /// @return claimableYield The claimable yield
    function readClaimableYield(
        address contractAddress
    ) external view returns (uint256 claimableYield);

    /// @notice Reads the gas parameters for a specific contract.
    /// @param contractAddress The address of the contract for which the gas parameters are to be read
    /// @return etherSeconds uint256 representing the accumulated ether seconds
    /// @return etherBalance uint256 representing ether balance
    /// @return lastUpdated uint256 representing last update timestamp
    /// @return gasMode The uint8 gas mode enum for the contract
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

    /// @notice Reads the yield configuration for a specific contract
    /// @param contractAddress The address of the contract for which the yield configuration is to be read
    /// @return yieldMode The uint8 yield mode enum for the contract
    function readYieldConfiguration(
        address contractAddress
    ) external view returns (YieldMode yieldMode);
}
