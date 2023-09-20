// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

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
    function setUp() public override {
        super.setUp();

        // reset tiers to empty
        perpetualMint.setTiers(
            TiersData({
                tierMultipliers: new uint256[](0),
                tierRisks: new uint32[](0)
            })
        );
    }

    /// @dev tests the setting of TiersData
    function test_setTiers() external {
        perpetualMint.setTiers(testTiersData);

        TiersData memory tiersData = perpetualMint.tiers();

        for (uint8 i = 0; i < tiersData.tierRisks.length; ++i) {
            assert(
                testTiersData.tierMultipliers[i] == tiersData.tierMultipliers[i]
            );

            assert(testTiersData.tierRisks[i] == tiersData.tierRisks[i]);
        }
    }

    /// @dev tests for the TiersSet event emission after new tiers are set
    function test_setTiersEmitsTiersSetEvent() external {
        vm.expectEmit();
        emit TiersSet(testTiersData);

        perpetualMint.setTiers(testTiersData);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setTiersRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setTiers(testTiersData);
    }
}
