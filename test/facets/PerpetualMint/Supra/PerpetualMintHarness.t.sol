// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintHarness } from "../PerpetualMintHarness.t.sol";

/// @title PerpetualMintHarnessSupra
/// @dev exposes PerpetualMintSupra external & internal functions for testing
contract PerpetualMintHarnessSupra is PerpetualMintHarness {
    /// @dev number of words used in mints for $MINT
    uint8 private constant ONE_WORD = 1;

    /// @dev number of words used in mints for ETH & mints for collections
    uint8 private constant TWO_WORDS = 2;

    constructor(address vrf) PerpetualMintHarness(vrf) {}

    function attemptBatchMintForEthWithEth(
        address referrer,
        uint32 numberOfMints,
        uint256 ethPrizeValueInWei,
        uint32 riskRewardRatio
    ) external payable override whenNotPaused {
        _attemptBatchMintForEthWithEthSupra(
            msg.sender,
            referrer,
            uint8(numberOfMints),
            TWO_WORDS,
            riskRewardRatio,
            ethPrizeValueInWei
        );
    }

    function attemptBatchMintForEthWithMint(
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints,
        uint256 ethPrizeValueInWei,
        uint32 riskRewardRatio
    ) external override whenNotPaused {
        _attemptBatchMintForEthWithMintSupra(
            msg.sender,
            referrer,
            pricePerMint,
            uint8(numberOfMints),
            TWO_WORDS,
            riskRewardRatio,
            ethPrizeValueInWei
        );
    }

    function attemptBatchMintForMintWithEth(
        address referrer,
        uint32 numberOfMints
    ) external payable override whenNotPaused {
        _attemptBatchMintForMintWithEthSupra(
            msg.sender,
            referrer,
            uint8(numberOfMints),
            ONE_WORD
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
            uint8(numberOfMints),
            ONE_WORD
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
            uint8(numberOfMints),
            TWO_WORDS
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
            uint8(numberOfMints),
            TWO_WORDS
        );
    }
}
