// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintHarness } from "./IPerpetualMintHarness.sol";
import { IPerpetualMintHarnessBlast } from "./Blast/IPerpetualMintHarness.sol";
import { IVRFConsumerBaseV2 } from "../../interfaces/IVRFConsumerBaseV2.sol";
import { IPerpetualMintViewSupraBlast } from "../../../contracts/facets/PerpetualMint/Blast/Supra/IPerpetualMintView.sol";
import { IPerpetualMintAdminBlast } from "../../../contracts/facets/PerpetualMint/Blast/IPerpetualMintAdmin.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintAdmin } from "../../../contracts/facets/PerpetualMint/IPerpetualMintAdmin.sol";
import { IPerpetualMintBase } from "../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";

/// @title IPerpetualMintTest
/// @dev aggregates all interfaces for ease of function selector mapping
interface IPerpetualMintTest is
    IPerpetualMint,
    IPerpetualMintAdmin,
    IPerpetualMintAdminBlast,
    IPerpetualMintBase,
    IPerpetualMintView,
    IPerpetualMintViewSupraBlast,
    IPerpetualMintHarness,
    IPerpetualMintHarnessBlast,
    IVRFConsumerBaseV2
{

}
