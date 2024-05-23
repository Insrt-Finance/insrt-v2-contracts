// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintViewSupraBlast } from "./IPerpetualMintView.sol";
import { IPerpetualMintViewBlast } from "../IPerpetualMintView.sol";
import { MintResultDataBlast } from "../../Storage.sol";
import { PerpetualMintViewSupra } from "../../Supra/PerpetualMintView.sol";

/// @title PerpetualMintViewSupraBlast
/// @dev Supra VRF-specific PerpetualMintView facet contract
contract PerpetualMintViewSupraBlast is
    IPerpetualMintViewSupraBlast,
    PerpetualMintViewSupra
{
    constructor(address vrf) PerpetualMintViewSupra(vrf) {}

    /// @inheritdoc IPerpetualMintViewBlast
    function blastYieldRisk() external view returns (uint32 risk) {
        risk = _blastYieldRisk();
    }

    /// @inheritdoc IPerpetualMintViewBlast
    function calculateMaxClaimableGas()
        external
        view
        returns (uint256 maxClaimableGas)
    {
        maxClaimableGas = _calculateMaxClaimableGas();
    }

    /// @inheritdoc IPerpetualMintViewSupraBlast
    function calculateMintResultSupraBlast(
        address collection,
        uint8 numberOfMints,
        uint256[2] calldata signature,
        uint256 pricePerMint,
        uint256 prizeValueInWei,
        bool referralMint,
        uint32 riskRewardRatio
    ) external view returns (MintResultDataBlast memory result) {
        result = _calculateMintResultSupraBlast(
            collection,
            numberOfMints,
            signature,
            pricePerMint,
            prizeValueInWei,
            referralMint,
            riskRewardRatio
        );
    }
}
