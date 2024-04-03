// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { IPerpetualMintViewSupraBlast } from "../../facets/PerpetualMint/Blast/Supra/IPerpetualMintView.sol";
import { IPerpetualMintAdminBlast } from "../../facets/PerpetualMint/Blast/IPerpetualMintAdmin.sol";
import { IPerpetualMint } from "../../facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintAdmin } from "../../facets/PerpetualMint/IPerpetualMintAdmin.sol";
import { IPerpetualMintBase } from "../../facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintInternal } from "../../facets/PerpetualMint/IPerpetualMintInternal.sol";
import { IPerpetualMintView } from "../../facets/PerpetualMint/IPerpetualMintView.sol";
import { IPerpetualMintViewSupra } from "../../facets/PerpetualMint/Supra/IPerpetualMintView.sol";

/// @title ICore
/// @dev The Core diamond interface.
interface ICore is
    IPerpetualMint,
    IPerpetualMintAdmin,
    IPerpetualMintAdminBlast,
    IPerpetualMintBase,
    IPerpetualMintInternal,
    IPerpetualMintView,
    IPerpetualMintViewSupraBlast,
    IPerpetualMintViewSupra,
    ISolidStateDiamond
{

}
