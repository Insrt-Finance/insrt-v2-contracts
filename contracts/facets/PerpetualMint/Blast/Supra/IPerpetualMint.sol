// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title IPerpetualMintBlastSupra
/// @dev Extension interface of the PerpetualMintBlastSupra facet
interface IPerpetualMintBlastSupra {
    /// @notice sets the risk for Blast yield
    /// @param risk risk of Blast yield
    function setBlastYieldRisk(uint32 risk) external;
}
