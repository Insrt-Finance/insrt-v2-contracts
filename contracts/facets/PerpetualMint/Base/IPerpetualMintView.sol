// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { MintResultData } from "../Storage.sol";

/// @title IPerpetualMintView_Base
/// @dev Extension interface of the PerpetualMintView_Base facet
interface IPerpetualMintView_Base {
    /// @notice calculates the Base-specific mint result of a given number of mint attempts for a given collection using given signature as randomness
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    /// @param signature signature value to use as randomness in calculation
    /// @param pricePerMint price paid per mint for collection (denominated in units of wei)
    function calculateMintResultBase(
        address collection,
        uint8 numberOfMints,
        uint256[2] calldata signature,
        uint256 pricePerMint
    ) external view returns (MintResultData memory result);
}
