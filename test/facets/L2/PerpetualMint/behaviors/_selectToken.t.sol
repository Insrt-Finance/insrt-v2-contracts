// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_selectToken
/// @dev PerpetualMint test contract for testing expected behavior of the selectToken function
contract PerpetualMint_selectToken is PerpetualMintTest, L2ForkTest {
    function setUp() public override {
        super.setUp();

        depositBoredApeYachtClubAssetsMock();
    }

    /// @dev ensures correct token is selected
    function testFuzz_selectToken(uint128 randomValue) public view {
        /// calculate total risk and picking number
        uint64 totalRisk = riskOne + riskTwo;
        uint64 pickingNumber = uint64(randomValue % totalRisk);

        uint256 expectedId = riskOne < pickingNumber
            ? BORED_APE_YACHT_CLUB_TOKEN_ID_TWO
            : BORED_APE_YACHT_CLUB_TOKEN_ID_ONE;

        assert(
            perpetualMint.exposed_selectToken(
                BORED_APE_YACHT_CLUB,
                randomValue
            ) == expectedId
        );
    }
}
