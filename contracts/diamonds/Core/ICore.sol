// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { IPerpetualMint } from "../../facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintBase } from "../../facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../facets/PerpetualMint/IPerpetualMintView.sol";
import { IPerpetualMintViewSupra } from "../../facets/PerpetualMint/Supra/IPerpetualMintView.sol";

/// @title ICore
/// @dev The Core diamond interface.
interface ICore is
    IPerpetualMint,
    IPerpetualMintBase,
    IPerpetualMintView,
    IPerpetualMintViewSupra,
    ISolidStateDiamond
{

}
