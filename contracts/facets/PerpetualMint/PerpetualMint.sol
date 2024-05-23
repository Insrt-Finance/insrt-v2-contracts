// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMint } from "./IPerpetualMint.sol";
import { PerpetualMintInternal } from "./PerpetualMintInternal.sol";

/// @title PerpetualMint
/// @dev PerpetualMint facet containing all protocol-specific externally called functions
contract PerpetualMint is IPerpetualMint, PerpetualMintInternal {
    constructor(address vrf) PerpetualMintInternal(vrf) {}

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintForEthWithEth(
        address referrer,
        uint32 numberOfMints,
        uint256 ethPrizeValueInWei,
        uint32
    ) external payable virtual whenNotPaused {
        _attemptBatchMintForEthWithEth(
            msg.sender,
            referrer,
            numberOfMints,
            ethPrizeValueInWei
        );
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintForEthWithMint(
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints,
        uint256 ethPrizeValueInWei,
        uint32
    ) external virtual whenNotPaused {
        _attemptBatchMintForEthWithMint(
            msg.sender,
            referrer,
            pricePerMint,
            numberOfMints,
            ethPrizeValueInWei
        );
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintForMintWithEth(
        address referrer,
        uint32 numberOfMints
    ) external payable virtual whenNotPaused {
        _attemptBatchMintForMintWithEth(msg.sender, referrer, numberOfMints);
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintForMintWithMint(
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external virtual whenNotPaused {
        _attemptBatchMintForMintWithMint(
            msg.sender,
            referrer,
            pricePerMint,
            numberOfMints
        );
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintWithEth(
        address collection,
        address referrer,
        uint32 numberOfMints
    ) external payable virtual whenNotPaused {
        _attemptBatchMintWithEth(
            msg.sender,
            collection,
            referrer,
            numberOfMints
        );
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintWithMint(
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external virtual whenNotPaused {
        _attemptBatchMintWithMint(
            msg.sender,
            collection,
            referrer,
            pricePerMint,
            numberOfMints
        );
    }

    /// @inheritdoc IPerpetualMint
    function claimPrize(address prizeRecipient, uint256 tokenId) external {
        _claimPrize(msg.sender, prizeRecipient, tokenId);
    }

    /// @inheritdoc IPerpetualMint
    function fundConsolationFees() external payable {
        _fundConsolationFees();
    }

    /// @inheritdoc IPerpetualMint
    function redeem(uint256 amount) external {
        _redeem(msg.sender, amount);
    }

    /// @notice Chainlink VRF Coordinator callback
    /// @param requestId id of request for random values
    /// @param randomWords random values returned from Chainlink VRF coordination
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual override {
        _fulfillRandomWords(requestId, randomWords);
    }
}
