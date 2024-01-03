// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintView_Base } from "./IPerpetualMintView.sol";
import { PerpetualMintView } from "../PerpetualMintView.sol";
import { MintResultData } from "../Storage.sol";

/// @title PerpetualMintView_Base
/// @dev Base-specific PerpetualMintView facet contract
contract PerpetualMintView_Base is IPerpetualMintView_Base, PerpetualMintView {
    constructor(address vrf) PerpetualMintView(vrf) {}

    /// @inheritdoc IPerpetualMintView_Base
    function calculateMintResultBase(
        address collection,
        uint8 numberOfMints,
        uint256[2] calldata signature,
        uint256 pricePerMint
    ) external view returns (MintResultData memory result) {
        result = _calculateMintResultBase(
            collection,
            numberOfMints,
            signature,
            pricePerMint
        );
    }
}
