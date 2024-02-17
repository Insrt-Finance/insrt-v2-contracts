// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "../../IPerpetualMint.sol";

/// @title IPerpetualMintBlastSupra
/// @dev Extension interface of the PerpetualMintBlastSupra facet
interface IPerpetualMintBlastSupra is IPerpetualMint {
    /// @notice sets the risk for Blast yield
    /// @param risk risk of Blast yield
    function setBlastYieldRisk(uint32 risk) external;
}
