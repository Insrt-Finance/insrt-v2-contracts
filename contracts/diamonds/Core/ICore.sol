// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintView_Base } from "../../facets/PerpetualMint/Base/IPerpetualMintView.sol";
import { IPerpetualMint } from "../../facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintBase } from "../../facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../facets/PerpetualMint/IPerpetualMintView.sol";

/// @title ICore
/// @dev The Core diamond interface.
interface ICore is
    IPerpetualMint,
    IPerpetualMintBase,
    IPerpetualMintView,
    IPerpetualMintView_Base
{

}
