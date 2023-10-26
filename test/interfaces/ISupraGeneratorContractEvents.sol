// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title ISupraGeneratorContractEvents
/// @notice Interface for Supra VRF Generator Contract Events
interface ISupraGeneratorContractEvents {
    /// @notice It will put the logs for the Generated request with necessary parameters
    /// @dev This event will be emitted when random number request generated
    /// @param nonce nonce is an incremental counter which is associated with request
    /// @param instanceId Instance Identification Number
    /// @param callerContract Contract address from which request has been generated
    /// @param functionName Function which we have to callback to fulfill request
    /// @param rngCount Number of random numbers requested
    /// @param numConfirmations Number of Confirmations
    /// @param clientSeed Client seed is used to add extra randomness
    /// @param clientWalletAddress is the wallet to which the request is associated
    event RequestGenerated(
        uint256 nonce,
        uint256 instanceId,
        address callerContract,
        string functionName,
        uint8 rngCount,
        uint256 numConfirmations,
        uint256 clientSeed,
        address clientWalletAddress
    );
}
