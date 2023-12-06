// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMint } from "../IPerpetualMint.sol";
import { PerpetualMint } from "../PerpetualMint.sol";

/// @title PerpetualMint_Base
/// @dev Base-specific overrides for PerpetualMint
contract PerpetualMint_Base is PerpetualMint {
    constructor(address vrf) PerpetualMint(vrf) {}

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintForMintWithEth(
        uint32 numberOfMints
    ) external payable override whenNotPaused {
        _attemptBatchMintForMintWithEthBase(msg.sender, uint8(numberOfMints));
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintForMintWithMint(
        uint32 numberOfMints
    ) external override whenNotPaused {
        _attemptBatchMintForMintWithMintBase(msg.sender, uint8(numberOfMints));
    }

    /// @inheritdoc IPerpetualMint
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

    /// @inheritdoc IPerpetualMint
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
