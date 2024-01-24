// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintViewSupra } from "./IPerpetualMintView.sol";
import { PerpetualMintView } from "../PerpetualMintView.sol";
import { MintResultData } from "../Storage.sol";

/// @title PerpetualMintViewSupra
/// @dev Supra VRF-specific PerpetualMintView facet contract
contract PerpetualMintViewSupra is IPerpetualMintViewSupra, PerpetualMintView {
    constructor(address vrf) PerpetualMintView(vrf) {}

    /// @inheritdoc IPerpetualMintViewSupra
    function calculateMintResultSupra(
        address collection,
        uint8 numberOfMints,
        uint256[2] calldata signature,
        uint256 pricePerMint
    ) external view returns (MintResultData memory result) {
        result = _calculateMintResultSupra(
            collection,
            numberOfMints,
            signature,
            pricePerMint
        );
    }
}
