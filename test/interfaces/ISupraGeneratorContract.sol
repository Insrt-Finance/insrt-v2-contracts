// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title ISupraGeneratorContract
/// @notice Interface for Supra VRF Generator Contract
interface ISupraGeneratorContract {
    /// @notice Getter for returning the Generator contract's Instance Identification Number
    /// @return instanceId Instance Identification Number
    function instanceId() external view returns (uint256 instanceId);
}
