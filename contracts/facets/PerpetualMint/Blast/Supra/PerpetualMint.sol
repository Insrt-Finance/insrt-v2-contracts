// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintBlastSupra } from "./IPerpetualMint.sol";
import { IPerpetualMint } from "../../IPerpetualMint.sol";
import { PerpetualMintSupra } from "../../Supra/PerpetualMint.sol";

/// @title PerpetualMintBlastSupra
/// @dev Blast Supra VRF-specific overrides for PerpetualMint
contract PerpetualMintBlastSupra is
    IPerpetualMintBlastSupra,
    PerpetualMintSupra
{
    /// @dev number of words used in mints for $MINT
    uint8 private constant TWO_WORDS = 2;

    /// @dev number of words used in mints for collections
    uint8 private constant THREE_WORDS = 3;

    constructor(address vrf) PerpetualMintSupra(vrf) {}

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintForMintWithEth(
        address referrer,
        uint32 numberOfMints
    )
        external
        payable
        override(IPerpetualMint, PerpetualMintSupra)
        whenNotPaused
    {
        _attemptBatchMintForMintWithEthSupra(
            msg.sender,
            referrer,
            uint8(numberOfMints),
            TWO_WORDS
        );
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintForMintWithMint(
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external override(IPerpetualMint, PerpetualMintSupra) whenNotPaused {
        _attemptBatchMintForMintWithMintSupra(
            msg.sender,
            referrer,
            pricePerMint,
            uint8(numberOfMints),
            TWO_WORDS
        );
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintWithEth(
        address collection,
        address referrer,
        uint32 numberOfMints
    )
        external
        payable
        override(IPerpetualMint, PerpetualMintSupra)
        whenNotPaused
    {
        _attemptBatchMintWithEthSupra(
            msg.sender,
            collection,
            referrer,
            uint8(numberOfMints),
            THREE_WORDS
        );
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintWithMint(
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external override(IPerpetualMint, PerpetualMintSupra) whenNotPaused {
        _attemptBatchMintWithMintSupra(
            msg.sender,
            collection,
            referrer,
            pricePerMint,
            uint8(numberOfMints),
            THREE_WORDS
        );
    }

    /// @inheritdoc IPerpetualMintBlastSupra
    function setBlastYieldRisk(uint32 risk) external onlyOwner {
        _setBlastYieldRisk(risk);
    }

    /// @notice VRF Coordinator callback
    /// @param requestId id of request for random values
    /// @param randomWords random values returned from VRF coordinator
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        _fulfillRandomWordsBlast(requestId, randomWords);
    }
}
