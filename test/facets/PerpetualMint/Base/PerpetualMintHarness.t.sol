// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintHarness } from "../PerpetualMintHarness.t.sol";

/// @title PerpetualMintHarness_Base
/// @dev exposes PerpetualMint_Base external & internal functions for testing
contract PerpetualMintHarness_Base is PerpetualMintHarness {
    constructor(address vrf) PerpetualMintHarness(vrf) {}

    function attemptBatchMintForMintWithEth(
        uint32 numberOfMints
    ) external payable override whenNotPaused {
        _attemptBatchMintForMintWithEthBase(msg.sender, uint8(numberOfMints));
    }

    function attemptBatchMintForMintWithMint(
        uint32 numberOfMints
    ) external override whenNotPaused {
        _attemptBatchMintForMintWithMintBase(msg.sender, uint8(numberOfMints));
    }

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
