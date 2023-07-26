// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetuaMint_chunk256to128
/// @dev PerpetualMint test contract for testing expected behavior of the chunk256to128 function
contract PerpetualMint_chunk256to128 is PerpetualMintTest, L2ForkTest {
    /// @dev tests that uint256 values are chunked to uint128 values correct
    function testFuzz_chunk256to128(uint256 value) public view {
        uint128[2] memory chunks = perpetualMint.exposed_chunk256to128(value);

        assert((uint256(chunks[1]) << 128) | uint256(chunks[0]) == value);
    }
}
