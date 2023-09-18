// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IERC1155MetadataExtension } from "../../facets/PerpetualMint/IERC1155MetadataExtension.sol";
import { IPerpetualMint } from "../../facets/PerpetualMint/IPerpetualMint.sol";

/// @title ICore
/// @dev The Core diamond interface.
interface ICore is IERC1155MetadataExtension, IPerpetualMint {

}
