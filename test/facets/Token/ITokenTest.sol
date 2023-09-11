// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { ITokenHarness } from "./ITokenHarness.sol";
import { IToken } from "../../../contracts/facets/Token/IToken.sol";

/// @title ITokenHarness
/// @dev aggregates all interfaces for ease of function selector mapping
interface ITokenTest is IToken, ITokenHarness {

}
