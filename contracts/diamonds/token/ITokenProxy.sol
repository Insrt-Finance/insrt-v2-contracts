// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { IToken } from "../../facets/token/IToken.sol";

/// @title ITokenProxy
/// @dev The ITokenProxy interface
interface ITokenProxy is ISolidStateDiamond, IToken {

}
