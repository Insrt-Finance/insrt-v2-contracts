// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";
import { MintTokenTiersData } from "../../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMint_setMintTokenTiers
/// @dev PerpetualMint test contract for testing expected behavior of the setMintTokenTiers function
contract PerpetualMint_setMintTokenTiers is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    function setUp() public override {
        super.setUp();

        // reset tiers to empty
        perpetualMint.setMintTokenTiers(
            MintTokenTiersData({
                tierMultipliers: new uint256[](0),
                tierRisks: new uint32[](0)
            })
        );
    }

    /// @dev tests the setting of MintTokenTiersData
    function test_setMintTokenTiers() external {
        perpetualMint.setMintTokenTiers(testMintTokenTiersData);

        MintTokenTiersData memory mintTokenTiersData = perpetualMint
            .mintTokenTiers();

        for (uint8 i = 0; i < mintTokenTiersData.tierRisks.length; ++i) {
            assert(
                testMintTokenTiersData.tierMultipliers[i] ==
                    mintTokenTiersData.tierMultipliers[i]
            );

            assert(
                testMintTokenTiersData.tierRisks[i] ==
                    mintTokenTiersData.tierRisks[i]
            );
        }
    }

    /// @dev tests for the MintTokenTiersSet event emission after new tiers are set
    function test_setMintTokenTiersEmitsTiersSetEvent() external {
        vm.expectEmit();
        emit MintTokenTiersSet(testMintTokenTiersData);

        perpetualMint.setMintTokenTiers(testMintTokenTiersData);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setMintTokenTiersRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setMintTokenTiers(testMintTokenTiersData);
    }
}
