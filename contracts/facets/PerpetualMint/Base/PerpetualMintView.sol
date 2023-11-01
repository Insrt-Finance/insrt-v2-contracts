// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintViewBase } from "./IPerpetualMintView.sol";
import { PerpetualMintView } from "../PerpetualMintView.sol";
import { MintResultData } from "../Storage.sol";

/// @title PerpetualMintViewBase facet contract
/// @dev Base-specific PerpetualMintView
contract PerpetualMintViewBase is IPerpetualMintViewBase, PerpetualMintView {
    constructor(address vrf) PerpetualMintView(vrf) {}

    /// @inheritdoc IPerpetualMintViewBase
    function calculateMintResultBase(
        address collection,
        uint8 numberOfMints,
        uint256[2] calldata signature
    ) external view returns (MintResultData memory result) {
        result = _calculateMintResultBase(collection, numberOfMints, signature);
    }
}
