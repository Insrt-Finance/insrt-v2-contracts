// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title PerpetualMint_setRedemptionFeeBP
/// @dev PerpetualMint test contract for testing expected behavior of the setRedemptionFeeBP function
contract PerpetualMint_setRedemptionFeeBP is ArbForkTest, PerpetualMintTest {
    /// @dev redemption fee basis points to test, 1.0%
    uint32 redemptionFeeBP = 10000000;

    function setUp() public override {
        super.setUp();
    }

    /// @dev tests the setting of a redemption fee basis points
    function testFuzz_setRedemptionFeeBP(uint32 _redemptionFeeBP) external {
        // it is assumed we will never set redemptionFeeBP to 0
        if (_redemptionFeeBP != 0) {
            assert(perpetualMint.redemptionFeeBP() == 0);

            perpetualMint.setRedemptionFeeBP(_redemptionFeeBP);

            assert(_redemptionFeeBP == perpetualMint.redemptionFeeBP());
        }
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setRedemptionFeeBPRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setRedemptionFeeBP(redemptionFeeBP);
    }
}