// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintViewBlastSupra } from "./IPerpetualMintView.sol";
import { IPerpetualMintViewBlast } from "../IPerpetualMintView.sol";
import { MintResultDataBlast } from "../../Storage.sol";
import { PerpetualMintViewSupra } from "../../Supra/PerpetualMintView.sol";

/// @title PerpetualMintViewBlastSupra
/// @dev Supra VRF-specific PerpetualMintView facet contract
contract PerpetualMintViewBlastSupra is
    IPerpetualMintViewBlastSupra,
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

    /// @inheritdoc IPerpetualMintViewBlastSupra
    function calculateMintResultBlastSupra(
        address collection,
        uint8 numberOfMints,
        uint256[2] calldata signature,
        uint256 pricePerMint
    ) external view returns (MintResultDataBlast memory result) {
        result = _calculateMintResultBlastSupra(
            collection,
            numberOfMints,
            signature,
            pricePerMint
        );
    }
}
