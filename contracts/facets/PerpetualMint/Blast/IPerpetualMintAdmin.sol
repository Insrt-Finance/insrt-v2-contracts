// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintAdmin } from "../IPerpetualMintAdmin.sol";

/// @title IPerpetualMintAdminBlast
/// @dev Extension interface of the PerpetualMintAdmin facet
interface IPerpetualMintAdminBlast is IPerpetualMintAdmin {
    /// @notice sets the risk for Blast yield
    /// @param risk risk of Blast yield
    function setBlastYieldRisk(uint32 risk) external;
}
