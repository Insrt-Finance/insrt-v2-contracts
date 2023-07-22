// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMint } from "../../../../contracts/facets/L2/PerpetualMint/IPerpetualMint.sol";
import { IDepositFacetMock } from "../../../interfaces/IDepositFacetMock.sol";
import { IPerpetualMintHarness } from "./IPerpetualMintHarness.t.sol";

/// @title IPerpetualMintTest
/// @dev aggregates all interfaces for ease of function selector mapping
interface IPerpetualMintTest is
    IPerpetualMint,
    IPerpetualMintHarness,
    IDepositFacetMock
{

}
