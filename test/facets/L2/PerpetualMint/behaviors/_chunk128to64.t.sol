// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetuaMint_chunk128to64
/// @dev PerpetualMint test contract for testing expected behavior of the chunk128to64 function
contract PerpetualMint_chunk128to64 is PerpetualMintTest, L2ForkTest {
    /// @dev tests that uint128 values are chunked to uint64 values correct
    function testFuzz_chunk128to64(uint128 value) public view {
        uint64[2] memory chunks = perpetualMint.exposed_chunk128to64(value);

        assert((uint128(chunks[1]) << 64) | uint128(chunks[0]) == value);
    }
}
