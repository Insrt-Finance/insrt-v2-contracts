// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintHarness, RequestData } from "../IPerpetualMintHarness.sol";

/// @title IPerpetualMintHarnessBlast
/// @dev Extended Blast-specific interface for the PerpetualMintHarness contract
interface IPerpetualMintHarnessBlast is IPerpetualMintHarness {
    /// @dev exposes _resolveMintsBlast
    function exposed_resolveMintsBlast(
        address minter,
        address collection,
        uint256 mintPriceAdjustmentFactor,
        uint256[] memory randomWords
    ) external;

    /// @dev exposes _resolveMintsForEthBlast
    function exposed_resolveMintsForEthBlast(
        RequestData calldata request,
        uint256[] memory randomWords
    ) external;

    /// @dev exposes _resolveMintsForMintBlast
    function exposed_resolveMintsForMintBlast(
        address minter,
        uint256 mintPriceAdjustmentFactor,
        uint256[] memory randomWords
    ) external;
}
