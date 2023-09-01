// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";
import { TiersData } from "../../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMint_setTiers
/// @dev PerpetualMint test contract for testing expected behavior of the setTiers function
contract PerpetualMint_setTiers is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    TiersData testTiersData;

    /// @dev first tier $MINT amount (lowest amount)
    uint256 internal constant firstTierMintAmount = 1 ether;

    /// @dev number of tiers
    uint8 internal constant testNumberOfTiers = 5;

    function setUp() public override {
        super.setUp();

        uint256[] memory tierMintAmounts = new uint256[](testNumberOfTiers);
        uint32[] memory tierRisks = new uint32[](testNumberOfTiers);

        // exponentially decreasing probabilities, from highest to lowest
        uint32[testNumberOfTiers] memory testRisks = [
            600000000, // 60%
            250000000, // 25%
            100000000, // 10%
            40000000, // 4%
            10000000 // 1%
        ];

        uint256 initialMintAmount = firstTierMintAmount;

        for (uint8 i = 0; i < testNumberOfTiers; ++i) {
            tierMintAmounts[i] = initialMintAmount;

            initialMintAmount *= 2; // double the mint amount for each tier

            tierRisks[i] = testRisks[i];
        }

        testTiersData = TiersData({
            tierMintAmounts: tierMintAmounts,
            tierRisks: tierRisks
        });
    }

    /// @dev tests the setting of TiersData
    function test_setTiers() external {
        perpetualMint.setTiers(testTiersData);

        TiersData memory tiersData = perpetualMint.tiers();

        for (uint8 i = 0; i < tiersData.tierRisks.length; ++i) {
            assert(
                testTiersData.tierMintAmounts[i] == tiersData.tierMintAmounts[i]
            );

            assert(testTiersData.tierRisks[i] == tiersData.tierRisks[i]);
        }
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setTiersRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(NON_OWNER);
        perpetualMint.setTiers(testTiersData);
    }
}
