// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/StdStorage.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_averageCollectionRisk
/// @dev PerpetualMint test contract for testing expected behavior of the averageCollectionRisk function
contract PerpetualMint_averageCollectionRisk is PerpetualMintTest, L2ForkTest {
    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();

        depositBoredApeYachtClubAssetsMock();
    }

    /// @dev tests that the average collection risk value returned is as expected
    function test_averageCollectionRisk() public view {
        //calculate average risk of escrowed BAYC assets
        uint64 averageRisk = (riskOne + riskTwo) / 2;

        uint64 storedRiskOne = _tokenRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds[0]
        );
        uint64 storedRiskTwo = _tokenRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds[1]
        );

        assert(riskOne == storedRiskOne);
        assert(riskTwo == storedRiskTwo);

        assert(
            averageRisk ==
                perpetualMint.averageCollectionRisk(BORED_APE_YACHT_CLUB)
        );
    }
}
