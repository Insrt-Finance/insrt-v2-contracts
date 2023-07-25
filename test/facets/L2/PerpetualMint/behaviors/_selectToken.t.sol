// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { L1ForkTest } from "../../../../L1ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_selectToken
/// @dev PerpetualMint test contract for testing expected behavior of the selectToken function
contract PerpetualMint_selectToken is PerpetualMintTest, L1ForkTest {
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
            ? boredApeYachtClubTokenIds[1]
            : boredApeYachtClubTokenIds[0];

        assert(
            perpetualMint.exposed_selectToken(
                BORED_APE_YACHT_CLUB,
                randomValue
            ) == expectedId
        );
    }
}
