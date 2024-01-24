// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { Core } from "../Core.sol";
import { GasMode, IBlast, YieldMode } from "./IBlast.sol";

/// @title CoreBlast
/// @dev The Blast-specific Core Diamond.
contract CoreBlast is Core {
    constructor(
        address mintToken,
        string memory receiptName,
        string memory receiptSymbol
    ) Core(mintToken, receiptName, receiptSymbol) {
        // Configure the yield & claimable gas settings for the Blast Core diamond
        IBlast(0x4300000000000000000000000000000000000002).configure(
            YieldMode.AUTOMATIC,
            GasMode.CLAIMABLE,
            address(this)
        );
    }
}
