// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMint } from "../../../../contracts/facets/L2/PerpetualMint/IPerpetualMint.sol";
import { IL2AssetHandlerMock } from "../../../interfaces/IL2AssetHandlerMock.sol";
import { IPerpetualMintHarness } from "./IPerpetualMintHarness.sol";

/// @title IPerpetualMintTest
/// @dev aggregates all interfaces for ease of function selector mapping
interface IPerpetualMintTest is
    IPerpetualMint,
    IPerpetualMintHarness,
    IL2AssetHandlerMock
{

}
