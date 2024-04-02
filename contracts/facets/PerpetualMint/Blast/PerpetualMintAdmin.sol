// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintAdminBlast } from "./IPerpetualMintAdmin.sol";
import { PerpetualMintAdmin } from "../PerpetualMintAdmin.sol";

/// @title PerpetualMintAdminBlast
/// @dev Blast-specific PerpetualMintAdmin facet
contract PerpetualMintAdminBlast is
    IPerpetualMintAdminBlast,
    PerpetualMintAdmin
{
    constructor(address vrf) PerpetualMintAdmin(vrf) {}

    /// @inheritdoc IPerpetualMintAdminBlast
    function setBlastYieldRisk(uint32 risk) external onlyOwner {
        _setBlastYieldRisk(risk);
    }
}
