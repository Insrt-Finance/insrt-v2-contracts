// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintHarness } from "../PerpetualMintHarness.t.sol";

/// @title PerpetualMintHarnessSupra
/// @dev exposes PerpetualMintSupra external & internal functions for testing
contract PerpetualMintHarnessSupra is PerpetualMintHarness {
    constructor(address vrf) PerpetualMintHarness(vrf) {}

    function attemptBatchMintForMintWithEth(
        address referrer,
        uint32 numberOfMints
    ) external payable override whenNotPaused {
        _attemptBatchMintForMintWithEthSupra(
            msg.sender,
            referrer,
            uint8(numberOfMints)
        );
    }

    function attemptBatchMintForMintWithMint(
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external override whenNotPaused {
        _attemptBatchMintForMintWithMintSupra(
            msg.sender,
            referrer,
            pricePerMint,
            uint8(numberOfMints)
        );
    }

    function attemptBatchMintWithEth(
        address collection,
        address referrer,
        uint32 numberOfMints
    ) external payable override whenNotPaused {
        _attemptBatchMintWithEthSupra(
            msg.sender,
            collection,
            referrer,
            uint8(numberOfMints)
        );
    }

    function attemptBatchMintWithMint(
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external override whenNotPaused {
        _attemptBatchMintWithMintSupra(
            msg.sender,
            collection,
            referrer,
            pricePerMint,
            uint8(numberOfMints)
        );
    }
}
