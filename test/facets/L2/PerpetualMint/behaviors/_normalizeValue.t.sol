// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { L1ForkTest } from "../../../../L1ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_normalizeValue
/// @dev PerpetualMint test contract for testing expected behavior of the normalizeValue function
contract PerpetualMint_normalizeValue is PerpetualMintTest, L1ForkTest {
    /// @dev tests that values are normalized to a basis correctly
    function testFuzz_normalizeValue(uint128 value, uint128 basis) public view {
        // basis is assumed to never be 0 by default
        if (basis != 0) {
            assert(
                value % basis ==
                    perpetualMint.exposed_normalizeValue(value, basis)
            );
        }
    }
}
