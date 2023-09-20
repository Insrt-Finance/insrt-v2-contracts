// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title PerpetualMint_normalizeValue
/// @dev PerpetualMint test contract for testing expected behavior of the _normalizeValue function
contract PerpetualMint_normalizeValue is ArbForkTest, PerpetualMintTest {
    /// @dev tests that values are normalized to a basis correctly
    function testFuzz_normalizeValue(
        uint256 value,
        uint32 basis
    ) external view {
        // basis is assumed to never be 0 by default
        if (basis != 0) {
            assert(
                value % basis ==
                    perpetualMint.exposed_normalizeValue(value, basis)
            );
        }
    }
}
