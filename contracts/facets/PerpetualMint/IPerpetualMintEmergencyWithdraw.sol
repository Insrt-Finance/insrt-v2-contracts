// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title IPerpetualMintEmergencyWithdraw
/// @dev Interface of the IPerpetualMintEmergencyWithdraw facet
interface IPerpetualMintEmergencyWithdraw {
    /// @notice sends all the ETH balance to `to` address and delete buckets where ETH was accounted for
    /// @param to address to receive all ETH balance
    function withdrawAllFunds(address to) external;
}
