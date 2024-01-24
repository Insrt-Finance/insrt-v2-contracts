// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMint } from "../IPerpetualMint.sol";
import { PerpetualMint } from "../PerpetualMint.sol";

/// @title PerpetualMintSupra
/// @dev Supra VRF-specific overrides for PerpetualMint
contract PerpetualMintSupra is PerpetualMint {
    constructor(address vrf) PerpetualMint(vrf) {}

    /// @inheritdoc IPerpetualMint
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

    /// @inheritdoc IPerpetualMint
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

    /// @inheritdoc IPerpetualMint
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

    /// @inheritdoc IPerpetualMint
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
