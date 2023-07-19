// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L1ForkTest } from "../../../../L1ForkTest.t.sol";
import "forge-std/console.sol";

/// @title PerpetualMint_selectToken
/// @dev PerpetualMint test contract for testing expected behavior of the selectToken function
contract PerpetualMint_selectToken is PerpetualMintTest, L1ForkTest {
    function setUp() public override {
        super.setUp();

        depositBoredApeYachtClubAssetsMock();
    }

    /// @dev ensures correct token is selected
    function testFuzz_selectToken(uint64 randomValue) public view {
        /// calculate total risk and picking number
        uint64 totalRisk = riskOne + riskTwo;
        uint64 pickingNumber = randomValue % totalRisk;

        uint256 expectedId = pickingNumber < riskOne
            ? boredApeYachtClubTokenIds[0]
            : boredApeYachtClubTokenIds[1];

        assert(
            perpetualMint.exposed_selectToken(
                BORED_APE_YACHT_CLUB,
                randomValue
            ) == expectedId
        );
    }
}
