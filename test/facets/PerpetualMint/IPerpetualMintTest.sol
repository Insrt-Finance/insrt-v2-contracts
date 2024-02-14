// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintHarnessBlast } from "./Blast/IPerpetualMintHarness.sol";
import { IPerpetualMintHarness } from "./IPerpetualMintHarness.sol";
import { IVRFConsumerBaseV2 } from "../../interfaces/IVRFConsumerBaseV2.sol";
import { IPerpetualMintBlastSupra } from "../../../contracts/facets/PerpetualMint/Blast/Supra/IPerpetualMint.sol";
import { IPerpetualMintViewBlastSupra } from "../../../contracts/facets/PerpetualMint/Blast/Supra/IPerpetualMintView.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintBase } from "../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";

/// @title IPerpetualMintTest
/// @dev aggregates all interfaces for ease of function selector mapping
interface IPerpetualMintTest is
    IPerpetualMint,
    IPerpetualMintBase,
    IPerpetualMintBlastSupra,
    IPerpetualMintView,
    IPerpetualMintViewBlastSupra,
    IPerpetualMintHarness,
    IPerpetualMintHarnessBlast,
    IVRFConsumerBaseV2
{

}
