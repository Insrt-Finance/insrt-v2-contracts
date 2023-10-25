// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintHarness } from "../PerpetualMintHarness.t.sol";

/// @title PerpetualMintHarnessBase
/// @dev exposes PerpetualMintBase external & internal functions for testing
contract PerpetualMintHarnessBase is PerpetualMintHarness {
    constructor(address vrf) PerpetualMintHarness(vrf) {}

    function attemptBatchMintWithEth(
        address collection,
        uint32 numberOfMints
    ) external payable override whenNotPaused {
        _attemptBatchMintWithEthBase(
            msg.sender,
            collection,
            uint8(numberOfMints)
        );
    }

    function attemptBatchMintWithMint(
        address collection,
        uint32 numberOfMints
    ) external override whenNotPaused {
        _attemptBatchMintWithMintBase(
            msg.sender,
            collection,
            uint8(numberOfMints)
        );
    }
}
