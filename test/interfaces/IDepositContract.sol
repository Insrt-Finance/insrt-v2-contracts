// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title IDepositContract
/// @notice Interface for the Supra VRF Deposit Contract
interface IDepositContract {
    /// @notice Allows SupraAdmin to add a client to the whitelist.
    /// @param _clientAddress The address of the client being added.
    /// @param _isSnap A boolean value indicating whether the client is a Snap user or not.
    function addClientToWhitelist(
        address _clientAddress,
        bool _isSnap
    ) external;

    /// @notice Allows a client to add a contract to their whitelist.
    /// @param _contractAddress The address of the contract being added.
    function addContractToWhitelist(address _contractAddress) external;

    /// @notice Allows a client to deposit funds into their account.
    function depositFundClient() external payable;

    /// @notice Remove a client from the whitelist
    /// @param _clientAddress The address of the client to remove
    function removeClientFromWhitelist(address _clientAddress) external;

    /// @notice Removes a contract from a client's whitelist.
    /// Only the client who added the contract can remove it.
    /// @param _contractAddress The address of the contract to remove.
    function removeContractFromWhitelist(address _contractAddress) external;

    /// @notice Allows a client to withdraw their funds.
    /// @param _amount The amount to be withdrawn.
    /// Emits a ClientWithdrawal event.
    function withdrawFundClient(uint256 _amount) external;
}
