// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintHarness } from "./IPerpetualMintHarness.sol";
import { IVRFConsumerBaseV2 } from "../../interfaces/IVRFConsumerBaseV2.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintBase } from "../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";

/// @title IPerpetualMintTest
/// @dev aggregates all interfaces for ease of function selector mapping
interface IPerpetualMintTest is
    IPerpetualMint,
    IPerpetualMintBase,
    IPerpetualMintView,
    IPerpetualMintHarness,
    IVRFConsumerBaseV2
{

}
